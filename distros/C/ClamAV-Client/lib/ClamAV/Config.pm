#
# ClamAV::Config class
#
# (C) 2004-2005 Julian Mehnle <julian@mehnle.net>
# $Id: Config.pm,v 1.3 2005/01/21 22:50:14 julian Exp $
#
##############################################################################

=head1 NAME

ClamAV::Config - A Perl class providing configuration information for Perl
modules related to ClamAV

=cut

package ClamAV::Config;

=head1 VERSION

0.11

=cut

our $VERSION = 0.11;

=head1 SYNOPSIS

    use ClamAV::Config;
    
    # ClamAV base configuration:
    ClamAV::Config->config_dir;
    ClamAV::Config->clamd_config_file;
    
    # clamd run-time configuration:
    ClamAV::Config->clamd_config;
    ClamAV::Config->clamd_option($option);

=cut

use warnings;
use strict;

use Error qw(:try);

use IO::File;

# Private declarations:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

my $clamd_config;

# Interface:
##############################################################################

=head1 DESCRIPTION

This class provides configuration information for Perl modules related to the
ClamAV virus scanner, e.g. installation specific file system paths and run-time
configuration options.

=cut

sub clamd_option;

# Implementation:
##############################################################################

=head2 ClamAV base configuration

The following ClamAV base configuration information is provided as class
methods:

=over

=item B<config_dir>

The base configuration directory of ClamAV.

=cut

use constant config_dir             => '/etc/clamav';

=item B<clamd_config_file>

The absolute file name of the I<clamd> configuration file.

=cut

use constant clamd_config_file      => config_dir . '/clamd.conf';

=back

=head2 clamd run-time configuration

The following clamd run-time configuration information is provided as class
methods:

=over

=item B<clamd_config>

Returns all clamd run-time configuration options as a hash reference.

=cut

sub clamd_config {
    my ($self) = @_;
    
    return $clamd_config
        if $clamd_config;
    
    my $file = IO::File->new($self->clamd_config_file);
    if (not $file) {
        $clamd_config = {};
        throw ClamAV::Config::Error(
            'Could not open clamd config file "' . $self->clamd_config_file . '" for reading'
        );
    }
    
    while (my $line = $file->getline) {
        chomp($line);
        next if $line =~ /^\s*#/;
        if (not $line =~ /^\s*(\w+)(?:\s+(\S+))?\s*$/) {
            $clamd_config = {};
            throw ClamAV::Config::Error('Malformed line in clamd configuration file encountered');
        }
        $clamd_config->{$1} = (defined($2) ? $2 : TRUE);
    }
    
    return $clamd_config;
}

=item B<clamd_option($option)>

Returns the value of the specified clamd run-time configuration option.

=cut

sub clamd_option {
    my ($self, $option) = @_;
    return $self->clamd_config->{$option};
}

=back

=head1 SEE ALSO

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<ClamAV::Client>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

package ClamAV::Config::Error;
use base qw(Error::Simple);

package ClamAV::Config;

TRUE;

# vim:tw=79
