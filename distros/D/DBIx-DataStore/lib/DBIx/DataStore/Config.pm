package DBIx::DataStore::Config;
$DBIx::DataStore::Config::VERSION = '0.097';
*DEBUG = *DBIx::DataStore::DEBUG;
*dslog = *DBIx::DataStore::dslog;

use strict;
use warnings;

my $C;

sub import {
    my ($pkg, $module, $use_home) = @_;

    $module = 'yaml' if !defined $module || $module !~ /\w+/o;
    $use_home = 0 if !defined $use_home || $use_home !~ /^\d+$/o;

    dslog(q{Config module selected:}, $module) if DEBUG() >= 3;

    eval("use DBIx::DataStore::Config::${module}");
    die dslog(q{Error importing configuration module:}, $@) if $@;

    eval(qq|\$C = DBIx::DataStore::Config::${module}::load( use_home => $use_home )|);
    die dslog(q{Error loading configuration:}, $@) if $@ || !defined $C;

    _clean_config();
}

sub get_default {
    dslog(q{Configuration request for default datastore received.}) if DEBUG() >= 3;

    return get_store($C->{'__DEFAULT'});
}

sub get_store {
    my ($store_name) = @_;

    dslog(q{Configuration request for datastore}, $store_name, q{received.}) if DEBUG() >= 3;

    return unless defined $store_name && $store_name =~ /\w+/o;
    return unless defined $C && ref($C) eq 'HASH' && exists $C->{$store_name};

    dslog(q{Requested datastore}, $store_name, q{configuration being returned.}) if DEBUG() >= 3;

    return $C->{$store_name};
}

sub match_store {
    my ($packages) = @_;

    dslog(q{Configuration request for match against stack's packages received.}) if DEBUG() >= 3;

    return unless defined $packages && ref($packages) eq 'ARRAY' && scalar(@{$packages}) > 0;

    foreach my $p (@{$packages}) {
        foreach my $name (sort keys %{$C}) {
            foreach my $r (@{$C->{$name}->{'packages'}}) {
                dslog(q{Checking config}, $name, q{pattern}, $r, q{against package}, $p) if DEBUG() >= 4;
                if ($p =~ $r) {
                    dslog(q{Configuration}, $name, q{contained pattern matching package}, $p, q{in stack.}) if DEBUG() >= 3;
                    return $C->{$name};
                }
            }
        }
    }

    dslog(q{No available configuration matched package names present in current stack.}) if DEBUG() >= 3;
    return;
}

sub _clean_config {
    return unless defined $C && ref($C) eq 'HASH';

    dslog(q{Cleaning configuration data.}) if DEBUG() >= 4;

    DATASTORE:
    foreach my $name (keys %{$C}) {
        # validate default_reader setting
        if (exists $C->{$name}->{'readers'} && ref($C->{$name}->{'readers'}) eq 'HASH'
            && defined $C->{$name}->{'default_reader'}
            && !exists $C->{$name}->{'readers'}->{$C->{$name}->{'default_reader'}}) {
            # fall back to random reader if there are readers, but there is either no
            # default_reader setting, or it is invalid (this treats "random" as invalid
            # at first, but it will end up being set back to random anyway)
            $C->{$name}->{'default_reader'} = 'random' unless $C->{$name}->{'default_reader'} eq 'none';
        } elsif (!exists $C->{$name}->{'readers'} || !ref($C->{$name}->{'readers'}) eq 'HASH') {
            # set default_reader to none if there are no readers available in this datastore
            $C->{$name}->{'readers'} = {};
            $C->{$name}->{'default_reader'} = 'none';
        }

        # validate the booleans-that-default-to-true
        foreach my $k (qw( reader_failover flag_bad_readers cache_connections cache_statements prepare_statements )) {
            if (!exists $C->{$name}->{$k} || exists $DBIx::DataStore::TV{lc($C->{$name}->{$k})}) {
                $C->{$name}->{$k} = 1;
            } else {
                $C->{$name}->{$k} = 0;
            }
        }

=begin UNNECESSARY_FOR_NOW

        # validate the booleans-that-default-to-false
        foreach my $k (qw()) {
            if (!exists $C->{$name}->{$k} || exists $DBIx::DataStore::FV{lc($C->{$name}->{$k})}) {
                $C->{$name}->{$k} = 0;
            } else {
                $C->{$name}->{$k} = 1;
            }
        }
=cut

        # gather package-matching regex patterns
        my @p;
        if (exists $C->{$name}->{'packages'}) {
            my ($r);
            if (ref($C->{$name}->{'packages'}) eq 'ARRAY') {
                foreach my $pattern (@{$C->{$name}->{'packages'}}) {
                    if (eval(q|$r = qr/$pattern/oi|)) {
                        push(@p, $r) unless $@;
                    }
                }
            } elsif (length($C->{$name}->{'packages'}) > 0 && ($r = eval(q|qr/$C->{$name}->{'packages'}/oi|))) {
                push(@p, $r);
            }
        }
        $C->{$name}->{'packages'} = [ @p ];

        # validate & clean up each server's definition
        if (!defined $C->{$name}->{'primary'} || ($C->{$name}->{'primary'} = _clean_config_host($C->{$name}->{'primary'}))) {
            dslog("Invalid primary host definition! Skipping datastore $name") if DEBUG();
            next DATASTORE;
        }
        foreach my $reader (keys %{$C->{$name}->{'readers'}}) {
            unless ($C->{$name}->{'readers'}->{$reader} = _clean_config_host($C->{$name}->{'readers'}->{$reader})) {
                dslog("Invalid reader host definition! Skipping reader $reader in datastore $name") if DEBUG();
            }
        }
    }
}

sub _clean_config_host {
    my ($host) = @_;

    return unless defined $host->{'driver'} && length($host->{'driver'}) > 0;

    my %d = (
        driver    => $host->{'driver'},
    );

    foreach my $k (qw( dsn host port database user password )) {
        $d{$k} = $host->{$k} if defined $host->{$k} && length($host->{$k}) > 0;
    }

    if (defined $host->{'schemas'}) {
        if (ref($host->{'schemas'}) eq 'ARRAY') {
            $d{'schemas'} = [];
            foreach my $s (@{$host->{'schemas'}}) {
                push(@{$d{'schemas'}}, $s) if length($s) > 0;
            }
            delete $d{'schemas'} unless scalar(@{$d{'schemas'}}) > 0;
        } elsif (length($host->{'schemas'}) > 0) {
            $d{'schemas'} = [ $host->{'schemas'} ];
        }
    }

    $d{'dbd_opts'} = { AutoCommit => 1 };

    if (defined $host->{'dbd_opts'} && ref($host->{'dbd_opts'}) eq 'HASH') {
        foreach my $k (keys %{$host->{'dbd_opts'}}) {
            $d{'dbd_opts'}->{$k} = $host->{'dbd_opts'}->{$k} if length($host->{'dbd_opts'}->{$k}) > 0;
        }
    }

    return { %d };
}

1;
