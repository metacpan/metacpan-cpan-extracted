#+##############################################################################
#                                                                              #
# File: Config/Generator/Config.pm                                             #
#                                                                              #
# Description: Config::Generator configuration support                         #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Config::Generator::Config;
use strict;
use warnings;
our $VERSION  = "1.0";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Config::General qw(ParseConfig);
use JSON qw(from_json to_json);
use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use No::Worries::File qw(file_read);
use No::Worries::Log qw(log_debug);
use Params::Validate qw(validate validate_pos :types);
use Config::Generator qw(%Config $HomeDir @IncPath);

#
# merge the given two configuration hashes
#

sub _merge ($$);
sub _merge ($$) {
    my($hash1, $hash2) = @_;
    my($ref1, $ref2);

    dief("unexpected hash to merge: %s", $hash1) unless ref($hash1) eq "HASH";
    dief("unexpected hash to merge: %s", $hash2) unless ref($hash2) eq "HASH";
    foreach my $key (keys(%{ $hash2 })) {
        unless (defined($hash1->{$key})) {
            $hash1->{$key} = $hash2->{$key};
            next;
        }
        $ref1 = ref($hash1->{$key});
        $ref2 = ref($hash2->{$key});
        if ($ref1 eq "HASH" and $ref2 eq "HASH") {
            _merge($hash1->{$key}, $hash2->{$key});
        } elsif ($ref1 eq "ARRAY" and $ref2 eq "") {
            push(@{ $hash1->{$key} }, $hash2->{$key});
        } elsif ($ref1 eq "" and $ref2 eq "") {
            $hash1->{$key} = [ $hash1->{$key}, $hash2->{$key} ];
        } else {
            dief("unexpected values to merge: %s and %s",
                 $hash1->{$key}, $hash2->{$key});
        }
    }
}

#
# prune the given configuration hash (i.e. remove the keys with undefined value)
#

sub _prune ($);
sub _prune ($) {
    my($hash) = @_;
    my(@list);

    dief("unexpected hash to prune: %s", $hash) unless ref($hash) eq "HASH";
    foreach my $key (keys(%{ $hash })) {
        if (defined($hash->{$key})) {
            _prune($hash->{$key}) if ref($hash->{$key}) eq "HASH";
        } else {
            push(@list, $key);
        }
    }
    foreach my $key (@list) {
        delete($hash->{$key});
    }
}

#
# hack the configuration in %Config
#

my @hack_config_options = (
    { type => SCALAR, regex => qr/^(merge|set|unset)?$/ },
    { type => SCALAR },
    { type => SCALAR, optional => 1},
);

sub hack_config (@) {
    my($action, $path, $value) = validate_pos(@_, @hack_config_options);
    my(%cfg, $cfg, @names);

    @names = grep(length($_), split(/\//, $path));
    if ($action eq "merge") {
        log_debug("hack merge %s = %s", $path, $value);
        %cfg = ();
        $cfg = \%cfg;
        while (@names > 1) {
            $cfg = $cfg->{shift(@names)} = {};
        }
        $cfg->{shift(@names)} = $value;
        _merge(\%Config, \%cfg);
    } elsif ($action eq "set") {
        log_debug("hack set %s = %s", $path, $value);
        $cfg = \%Config;
        while (@names > 1) {
            if (ref($cfg->{$names[0]}) eq "HASH") {
                $cfg = $cfg->{shift(@names)};
            } else {
                $cfg = $cfg->{shift(@names)} = {};
            }
        }
        $cfg->{shift(@names)} = $value;
    } elsif ($action eq "unset") {
        log_debug("hack unset %s", $path);
        $cfg = \%Config;
        while (@names > 1) {
            if (ref($cfg->{$names[0]}) eq "HASH") {
                $cfg = $cfg->{shift(@names)};
            } else {
                $cfg = undef;
                last;
            }
        }
        delete($cfg->{shift(@names)}) if $cfg;
    } else {
        dief("unexpected hack action: %s", $action);
    }
}

#
# load the given configuration file(s) into %Config
#

sub load_config (@) {
    my(@paths) = validate_pos(@_, ({ type => SCALAR }) x (@_ || 1));
    my($json, %cfg, $cfg);

    foreach my $path (@paths) {
        log_debug("loading file %s...", $path);
        $json = $path =~ /\.json$/;
        if ($json and substr($path, 0, 1) ne "/" and not -e $path) {
            foreach my $inc (@IncPath, "$HomeDir/cfg") {
                next unless -e "$inc/$path";
                $path = "$inc/$path";
                last;
            }
        }
        if ($json) {
            $cfg = from_json(file_read($path), { relaxed => 1 });
            dief("unexpected JSON: %s", $path) unless ref($cfg) eq "HASH";
        } else {
            %cfg = ParseConfig(
                -ConfigFile            => $path,
                -ConfigPath            => [ @IncPath, "$HomeDir/cfg" ],
                -CComments             => 0,
                -IncludeAgain          => 1,
                -IncludeGlob           => 1,
                -IncludeRelative       => 1,
                -MergeDuplicateBlocks  => 1,
                -MergeDuplicateOptions => 0,
            );
            $cfg = \%cfg;
        }
        _merge(\%Config, $cfg);
    }
}

#
# merge the given configuration into %Config
#

my @merge_config_options = (
    { type => HASHREF },
);

sub merge_config ($) {
    my($cfg) = validate_pos(@_, @merge_config_options);

    _merge(\%Config, $cfg);
}

#
# prune the configuration in %Config
#

sub prune_config () {
    _prune(\%Config);
}

#
# transform the configuration in %Config into a string
#

my %stringify_config_options = (
    format => {
        optional => 1,
        type => SCALAR,
        regex => qr/^(Config::General|JSON)?$/,
    },
);

sub stringify_config (@) {
    my(%option, $cfg);

    %option = validate(@_, \%stringify_config_options);
    if (not $option{format} or $option{format} eq "Config::General") {
        $cfg = Config::General->new(
            -ConfigHash  => \%Config,
            -SplitPolicy => "equalsign",
            -SaveSorted  => 1,
        );
        return($cfg->save_string());
    }
    if ($option{format} eq "JSON") {
        return(to_json(\%Config, { pretty => 1, canonical => 1 }));
    }
    dief("unexpected configuration format: %s", $option{format});
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{"${_}_config"}++, qw(hack load merge prune stringify));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

Config::Generator::Config - Config::Generator configuration support

=head1 DESCRIPTION

This module eases the manipulation of the high-level configuration data.

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item hack_config(ACTION, PATH[, VALUE])

modify the configuration under the given PATH; ACTION can be "merge", "set" or
"unset"

=item load_config(PATH...)

load the given configuration files

=item merge_config(CONFIG)

merge the given configuration

=item prune_config()

prune the configuration (i.e. remove the keys with undefined value)

=item stringify_config([OPTIONS])

transform the configuration into a string; supported options:

=over

=item * C<format>: name of the format to use instead; possible values:

=over

=item * C<Config::General> (default)

=item * C<JSON>

=back

=back

=back

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2013-2016
