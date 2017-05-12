package DPKG::Log::Analyse;
BEGIN {
  $DPKG::Log::Analyse::VERSION = '1.20';
}


=head1 NAME

DPKG::Log::Analyse - Analyse a dpkg log

=head1 VERSION

version 1.20

=head1 SYNOPSIS

use DPKG::Log;

my $analyser = DPKG::Log::Analyse->new('filename' => 'dpkg.log');
$analyser->analyse;

=head1 DESCRIPTION

This module is used to analyse a dpkg log.

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
use 5.010;

use Carp;
use DPKG::Log;
use DPKG::Log::Analyse::Package;
use Params::Validate qw(:all);

=item $analser = DPKG::Log::Analyse->new('filename' => 'dpkg.log')

=item $analyser = DPKG::Log::Analyse->new('log_handle' => \$dpkg_log)

Returns a new DPKG::Log::Analyse object.
Filename parameter can be ommitted, it defaults to /var/log/dpkg.log.

Its possible to specify an existing DPKG::Log object instead of a filename.
This will be used and overrides any filename setting.

=cut
sub new {
    my $package = shift;
    $package = ref($package) if ref($package);

    my %params = validate(
        @_, {
                'filename' => { 'type' => SCALAR, 'default' => '/var/log/dpkg.log' },
                'log_handle' => { isa => 'DPKG::Log', default => undef } 
            }
    );
    
    my $self = {
        packages => {},
        newly_installed_packages => {},
        installed_and_removed => {},
        removed_packages => {},
        upgraded_packages => {},
        halfinstalled_packages => {},
        halfconfigured_packages => {},
        unpacked_packages => {},
        installed_and_removed_packages => {},
    };

    if ($params{'filename'}) {
        $self->{'filename'} = $params{'filename'};
    }
    if ($params{'log_handle'}) {
        $self->{dpkg_log} = $params{'log_handle'};
    } else {
        $self->{dpkg_log} = DPKG::Log->new('filename' => $self->{'filename'});
    }
    $self->{dpkg_log}->parse;

    bless($self, $package);

    
    return $self;
}

=item $analyser->analyse;

Analyse the debian package log.

=cut
sub analyse {
    my $self = shift;
    my $dpkg_log = $self->{dpkg_log};

    $self->{from} = $dpkg_log->{from};
    $self->{to} = $dpkg_log->{to};

    my $analysed_entries=0;
    foreach my $entry ($dpkg_log->entries) {
        next if not $entry->associated_package;
       
        $analysed_entries++;

        # Initialize data structure if this is a package
        my $package = $entry->associated_package;
        if (not defined $self->{packages}->{$package}) {
            $self->{packages}->{$package} = DPKG::Log::Analyse::Package->new('package' => $package);
        }

        if ($entry->type eq 'action') {
            my $obj = $self->{packages}->{$package};
            if ($entry->action eq 'install') {
                $self->{newly_installed_packages}->{$package} = $obj;
                $self->{packages}->{$package}->version($entry->available_version);
            } elsif ($entry->action eq 'upgrade') {
                $self->{upgraded_packages}->{$package} = $obj;
                $self->{packages}->{$package}->previous_version($entry->installed_version);
                $self->{packages}->{$package}->version($entry->available_version);
            } elsif ($entry->action eq 'remove') {
                $self->{removed_packages}->{$package} = $obj;
                $self->{packages}->{$package}->previous_version($entry->installed_version);
            }
        } elsif ($entry->type eq 'status') {
            $self->{packages}->{$package}->status($entry->status);
            $self->{packages}->{$package}->version($entry->installed_version);
        }
    }

    while (my ($package, $package_obj) = each %{$self->{packages}}) {
        if ($self->{packages}->{$package}->status eq "half-installed") {
            $self->{half_installed_packages}->{$package} = \$package_obj;
        }
        if ($self->{packages}->{$package}->status eq "half-configured") {
            $self->{half_configured_packages}->{$package} = \$package_obj;
        }
        if ($self->{packages}->{$package}->status eq "unpacked") {
            $self->{half_configured_packages}->{$package} = \$package_obj;
        }
    }

    # Remove packages from "newly_installed" if installed_version is empty
    while (my ($package, $package_obj) = each %{$self->{newly_installed_packages}}) {
        if (not $package_obj->version) {
            delete($self->{newly_installed_packages}->{$package});
            $self->{installed_and_removed_packages}->{$package} = $package_obj;
        }
    }

    # Forget about the log object once analysis is done
    $self->{dpkg_log} = undef;

    return 1;
}

=item $analyser->newly_installed_packages

Return all packages which were newly installed in the dpkg.log.

=cut
sub newly_installed_packages {
    my $self = shift;
    return $self->{newly_installed_packages};
}

=item $analyser->upgraded_packages


Return all packages which were upgraded in the dpkg.log.

=cut
sub upgraded_packages {
    my $self = shift;
    return $self->{upgraded_packages};
}

=item $analyser->removed_packages


Return all packages which were removed in the dpkg.log.

=cut
sub removed_packages {
    my $self = shift;
    return $self->{removed_packages};
}

=item $analyser->unpacked_packages


Return all packages which are left in state 'unpacked'.

=cut
sub unpacked_packages {
    my $self = shift;
    return $self->{unpacked_packages};
}

=item $analyser->halfinstalled_packages


Return all packages which are left in state 'half-installed'.

=cut
sub halfinstalled_packages {
    my $self = shift;
    return $self->{halfinstalled_packages};
}

=item $analyser->halfconfigured_packages


Return all packages which are left in state 'half-configured'.

=cut
sub halfconfigured_packages {
    my $self = shift;
    return $self->{halfconfigured_packages};
}

=item $analyser->installed_and_removed_packages

Return all packages which got installed and removed.

=cut
sub installed_and_removed_packages {
    my $self = shift;
    return $self->{installed_and_removed_packages};
}

=back

=head1 SEE ALSO

L<DPKG::Log>, L<DPKG::Log::Analyse::Package>

=head1 AUTHOR

Patrick Schoenfeld <schoenfeld@debian.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Patrick Schoenfeld <schoenfeld@debian.org>

This library is free software.
You can redistribute it and/or modify it under the same terms as perl itself.

=cut

1;
# vim: expandtab:ts=4:sw=4