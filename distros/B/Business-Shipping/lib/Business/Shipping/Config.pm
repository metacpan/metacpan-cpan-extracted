package Business::Shipping::Config;

=head1 NAME

Business::Shipping::Config - Configuration functions

=head1 DESCRIPTION

Among other things, this module implements a simple API on top of the 
Config::IniFiles module.

=head1 METHODS

=cut

use strict;
use warnings;

use constant DEFAULT_CONFIG_DIR => '/usr/local/B_Shipping/config';

#use constant DEFAULT_CONFIG_DIR => '~_~DEFAULT_CONFIG_DIR~_~';

use constant DEFAULT_DATA_DIR => '/usr/local/B_Shipping/data';

#use constant DEFAULT_DATA_DIR => '~_~DEFAULT_DATA_DIR~_~';

use base ('Exporter');
use Config::IniFiles;
use Business::Shipping::Logging;
use Carp;
use Cwd;
use version; our $VERSION = qv('400');
use vars qw(@EXPORT);

@EXPORT = qw/ cfg cfg_obj config_to_hash config_to_ary_of_hashes /;
$Business::Shipping::Config::config_dir             = '';
$Business::Shipping::Config::data_dir               = '';
$Business::Shipping::Config::main_config_file       = '';
$Business::Shipping::Config::data_dir_test_filename = 'this_is_the_data_dir';

sub data_dir_test_filename {
    return $Business::Shipping::Config::data_dir_test_filename;
}

# Try the current directory first.
if (-f './config/config.ini') {
    $Business::Shipping::Config::config_dir = './config';
}
if (-f './data/' . data_dir_test_filename()) {
    $Business::Shipping::Config::data_dir = './data';
}
elsif (-f '../Business-Shipping-DataFiles/data/' . data_dir_test_filename()) {
    $Business::Shipping::Config::data_dir
        = '../Business-Shipping-DataFiles/data/';
}

# Then try environment variables
$Business::Shipping::Config::data_dir   ||= $ENV{B_SHIPPING_DATA_DIR};
$Business::Shipping::Config::config_dir ||= $ENV{B_SHIPPING_CONFIG_DIR};

# Then fall back on the default.
$Business::Shipping::Config::data_dir   ||= DEFAULT_DATA_DIR;
$Business::Shipping::Config::config_dir ||= DEFAULT_CONFIG_DIR;

my $cwd = Cwd::getcwd;
die "Config dir could not be found.  Current working dir: $cwd."
    if (!-d $Business::Shipping::Config::config_dir);
die "Data dir could not be found.  Current working dir: $cwd."
    if (!-d $Business::Shipping::Config::config_dir);

$Business::Shipping::Config::main_config_file
    = "$Business::Shipping::Config::config_dir/config.ini";

if (!-f $Business::Shipping::Config::main_config_file) {
    die "Could not open main configuration file: "
        . "$Business::Shipping::Config::main_config_file: $!";
}

# Number of times to try for online requrests.  See Online.pm.
$Business::Shipping::Config::Try_Limit = 2;

tie my %cfg, 'Config::IniFiles',
    (-file => $Business::Shipping::Config::main_config_file);
my $cfg_obj = Config::IniFiles->new(
    -file => $Business::Shipping::Config::main_config_file);

=head2 cfg()

Returns config hashref.

=head2 cfg_obj()

Returns config hashref.

=head2 support_files()

Returns the path of the support_files directory.

=cut

sub cfg        { return \%cfg; }
sub cfg_obj    { return $cfg_obj; }
sub data_dir   { return $Business::Shipping::Config::data_dir }
sub config_dir { return $Business::Shipping::Config::config_dir }

=head2 config_to_hash( $ary, $del )

 $ary   Key/value pairs
 $del   Delimiter for the above array (tab is default)

Builds a hash from an array of lines containing key / value pairs, like so:

 key1    value1
 key2    value2
 key3    value3

=cut

sub config_to_hash {
    my ($ary, $delimiter) = @_;
    return unless $ary and ref($ary) eq 'ARRAY';

    $delimiter ||= "\t";
    my $hash = {};

    foreach my $line (@$ary) {
        my ($key, $val) = split($delimiter, $line);
        $hash->{$key} = $val;
    }

    return $hash;
}

=head2 config_to_ary_of_hashes( 'configuration_parameter' )

Reads in the configuration hashref ( e.g. cfg()->{ primary }->{ secondary } ),
then returns an array of hashes.  For example:

This:

 [invalid_rate_requests]
 invalid_rate_requests_ups=<<EOF
 service=XDM    to_country=Canada    reason=Not available.
 service=XDM    to_country=Brazil
 EOF

When called with this:

 my @invalid_rate_requests_ups = config_to_ary_of_hashes( 
     cfg()->{ invalid_rate_requests }->{ invalid_rate_requests_ups }
 );

Returns this:

 [ 
     {
         service    => 'XDM',
         to_country => 'Canada',
	 reason     => 'Not available.',
     },
     {
         service    => 'XDM',
         to_country => 'Brazil',
     },
 ]

=cut

sub config_to_ary_of_hashes {
    my ($cfg) = @_;

    my @ary;
    foreach my $line (@$cfg) {

        # Convert multiple tabs into one tab, remove the leading tab.
        # Split on the tabs to get key=val pairs, then split on the '='.
        $line =~ s/\t+/\t/g;
        $line =~ s/^\t//;
        my @key_val_pairs = split("\t", $line);
        next unless @key_val_pairs;

        # Each line becomes a hash.
        my $hash = {};
        foreach my $key_val_pair (@key_val_pairs) {
            my ($key, $val) = split('=', $key_val_pair);
            next unless (defined $key and defined $val);
            $hash->{$key} = $val;
        }

        push @ary, $hash if (%$hash);
    }

    return @ary;
}

=head2 data_dir_name()

The name of the data_dir (e.g. "data").

=cut

sub data_dir_name {

    # name only.
    return cfg()->{general}->{data_dir_name} || 'data';
}

=head2 data_dir()

The path of the data_dir (e.g. "/var/perl/Business-Shipping/data").

=cut

=head2 get_req_mod()

Return a list of the required modules for a given shipper.  Return all if no
shipper is given.

=cut

sub get_req_mod {
    my (%opt) = @_;
    my $shipper = $opt{shipper};

    my $req_mod = {
        'Minimum' => [
            qw/
                Any::Moose
                Log::Log4perl
                Business::Shipping
                /
        ],
        'UPS_Offline' => [
            qw/
                Business::Shipping::DataFiles
                Config::IniFiles
                /
        ],
        'UPS_Online' => [
            qw/
                CHI
                Crypt::SSLeay
                Date::Parse
                LWP::UserAgent
                XML::DOM
                XML::Simple
                /
        ],
        'USPS_Online' => [
            qw/
                CHI
                Crypt::SSLeay
                Date::Parse
                LWP::UserAgent
                XML::DOM
                XML::Simple
                /
        ],

    };
    if ($opt{get_hash}) {
        return $req_mod;
    }
    if ($shipper) {
        my $module_list = $req_mod->{$shipper};
        return @$module_list;
    }
    else {
        my @all_modules;
        foreach my $key (keys %$req_mod) {
            my $module_list = $req_mod->{$shipper};
            push @all_modules, @$module_list;
        }
        return @all_modules;
    }
}

=head2 calc_req_mod()

Determine if the required modules for each shipper are available, in turn.

=cut

sub calc_req_mod {
    my ($one_shipper) = @_;

    my @avail;
    my $req_mod = get_req_mod(get_hash => 1);

    if ($one_shipper) {
        foreach my $shipper (keys %$req_mod) {
            if ($shipper ne $one_shipper) {
                delete $req_mod->{$shipper};
            }
        }
    }
    my @to_load;
SHIPPER: while (my ($shipper, $list) = each %$req_mod) {
        @to_load = ();
    MODULE: foreach my $module (@$list) {
            eval "use $module";
            if ($@) {
                $@ = '';

                # "Could not load $module";
                next SHIPPER;
            }
            else {
                push @to_load, $module;
                next MODULE;
            }
        }
        if (!$@) {
            push @avail, $shipper;
        }
    }
    if ($one_shipper) {
        if (grep $one_shipper, @avail) {
            return 1;
        }
        else {
            return 0;
        }
    }
    else {
        return @avail;
    }
}
1;

__END__

=head1 AUTHOR

Daniel Browning, db@kavod.com, L<http://www.kavod.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2011 Daniel Browning <db@kavod.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut
