package DBIx::DataStore::Config::yaml;
$DBIx::DataStore::Config::yaml::VERSION = '0.097';
*DEBUG = *DBIx::DataStore::DEBUG;
*dslog = *DBIx::DataStore::dslog;

use strict;
use warnings;

use YAML::Syck qw();

my %atimes;
my %parsed;
my %config;

sub load {
    my (%args) = @_;

    # list these in most-global to most-specific order (same-named datastores defined in later configs
    # ovrerride those found in an earlier config)
    my @files = ('/etc/datastore.yml');

    if (defined $args{'use_home'} && $args{'use_home'} =~ /^\d+$/o && $args{'use_home'} > 0) {
        dslog(q{Adding user-specific configuration path.}) if DEBUG() >= 3;
        my $home = eval("use File::HomeDir qw(); File::HomeDir->my_home()");
        if ($@) {
            dslog(q{Couldn't load File::HomeDir module:}, $@);
        } else {
            push(@files, qq{$home/.datastore.yml'});
        }
    }

    my %new;

    my $updated = 0;

    CONFIG_FILE:
    foreach my $f (@files) {
        if (-r $f) {
            my $mtime = (stat(_))[9];
            if (!exists $atimes{$f} || $atimes{$f} < $mtime) {
                dslog(q{Loading configuration from}, $f) if DEBUG() >= 2;
                $parsed{$f} = YAML::Syck::LoadFile($f) || next CONFIG_FILE;
                $updated = 1;
            }
            $atimes{$f} = time();
        } else {
            dslog(q{Skipping check of configuration file}, $f) if DEBUG() >= 3;
        }
    }

    # only redo the %config hash if one of the files changed
    if ($updated) {
        dslog(q{Configuration updated.}) if DEBUG() >= 3;
        foreach my $f (@files) {
            my $def_in_file = 0;
            foreach my $name (keys %{$parsed{$f}}) {
                if (exists $parsed{$f}->{$name}->{'is_default'}
                    && exists $DBIx::DataStore::TV{lc($parsed{$f}->{$name}->{'is_default'})}) {
                    dslog(qq{Multiple defaults in configuration file $f!}) if $def_in_file && DEBUG();
                    $def_in_file = 1;
                    $config{'__DEFAULT'} = $name;
                    dslog(q{Configuration}, $name, q{marked as default.}) if DEBUG() >= 4;
                }
                $config{$name} = { %{$parsed{$f}->{$name}} }; # get a fresh copy, not a ref
            }
        }
    }

    dslog(q{Returning YAML Configuration.}) if DEBUG() >= 3;

    return \%config;
}

1;
