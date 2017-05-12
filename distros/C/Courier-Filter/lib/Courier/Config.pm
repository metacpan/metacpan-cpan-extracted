#
# Courier::Config class
#
# (C) 2003-2008 Julian Mehnle <julian@mehnle.net>
# $Id: Config.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Config - Class providing configuration information for Perl modules
related to the Courier MTA

=cut

package Courier::Config;

use warnings;
use strict;

use version;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

    use Courier::Config;
    
    # Courier base configuration:
    my $config_dir          = Courier::Config->config_dir;
    my $runtime_dir         = Courier::Config->runtime_dir;
    my $courier_executable  = Courier::Config->courier_executable;
    my $courier_version     = Courier::Config->courier_version;
    
    # Courier::Filter configuration:
    my $filter_conf_file    = Courier::Config->filter_conf_file;

=head1 DESCRIPTION

This class provides configuration information for Perl modules related to the
Courier MTA, e.g. installation specific file system paths.

=cut

# Declarations:
###############################################################################

=head2 Courier base configuration

The following methods provide information about Courier's base configuration:

=over

=item B<config_dir>: returns I<string>

The base configuration directory of Courier.

=cut

use constant config_dir         => '/etc/courier';

=item B<runtime_dir>: returns I<string>

The directory where Courier keeps the message queue (C<msgq>, C<msgs>, C<tmp>)
and courierfilter sockets (C<filters>, C<allfilters>).

=cut

use constant runtime_dir        => '/var/lib/courier';  # Normally '/var/run/courier'.

=item B<courier_executable>: returns I<string>

The full path of the Courier daemon executable.

=cut

use constant courier_executable => '/usr/sbin/courier';

=item B<courier_version>: returns I<version>

The version number of the Courier installation.

=cut

my $courier_version;

sub courier_version {
    my ($self) = @_;
    my $courier_executable = $self->courier_executable;
    if (
        not defined($courier_version) and
        -x $courier_executable
    ) {
        my $courier_version_string = `$courier_executable --version`;
        if (
            $? == 0 and
            $courier_version_string =~ /^Courier ([^ ]+)/
        ) {
            $courier_version = version->new($1);
        }
    }
    return $courier_version;
}

=back

=head2 Courier::Filter configuration

The following Courier::Filter configuration information is provided:

=over

=item B<filter_conf_file>: returns I<string>

The absolute file name of the Courier::Filter courier-filter-perl configuration
file.

=cut

use constant filter_conf_file   => config_dir . '/filters/courier-filter-perl.conf';

=back

=cut

# Support legacy method names:

BEGIN {
    no warnings 'once';
    *COURIER_CONFIG_DIR  = \&config_dir;
    *COURIER_RUNTIME_DIR = \&runtime_dir;
    *COURIER_FILTER_CONF = \&filter_conf_file;
}

=head1 SEE ALSO

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
