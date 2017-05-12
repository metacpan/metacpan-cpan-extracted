# $Id: RcsConfig.pm,v 1.2 2002/04/23 04:19:05 barbee Exp $

=head1 NAME

Apache::CVS::RcsConfig - class that holds configuration information for an
RCS object

=head1 SYNOPSIS

 use Apache::CVS::RcsConfig();

 $config = Apache::CVS::RcsConfig->new();
 $extension = $config->extension();    
 $working = $config->working();    
 $binary = $config->binary();    

=head1 DESCRIPTION

The C<Apache::CVS::RcsConfig> class holds data used to configure an C<Rcs>
object.

=over 4

=cut

package Apache::CVS::RcsConfig;
use strict;

$Apache::CVS::RcsConfig::VERSION = $Apache::CVS::VERSION;

=item $config = Apache::CVS::RcsConfig->new([$extension], [$working_directory], [$rcs_binary_directory])

Construct a new C<Apache::CVS::RcsConfig> object. The first argument is the
extension of the versioned files. The second argument is the working directory
where files may be checked out to. The last argument is the directory that
contains the rcs binaries such as: co, rlog, and rcsdiff. The default for
these arguments are ',v', '/var/tmp', and /usr/bin'.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self;
    $self->{extension} = shift || ',v';
    $self->{working}   = shift || '/var/tmp';
    $self->{binary}    = shift || '/usr/bin';

    bless ($self, $class);
    return $self;
}

=item $config->extension()

Returns the extension of this configuration.

=cut

sub extension {
    my $self = shift;
    $self->{extension} = shift if scalar @_;
    return $self->{extension};
}

=item $config->working()

Returns the working directory of this configuration.

=cut

sub working {
    my $self = shift;
    $self->{working} = shift if scalar @_;
    return $self->{working};
}

=item $config->binary()

Returns the path to the RCS binaries stored in this configuration.

=cut

sub binary {
    my $self = shift;
    $self->{binary} = shift if scalar @_;
    return $self->{binary};
}

=back

=head1 SEE ALSO

L<Apache::CVS>, L<Rcs>

=head1 AUTHOR

John Barbee <F<barbee@veribox.net>>

=head1 COPYRIGHT

Copyright 2001-2002 John Barbee

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
