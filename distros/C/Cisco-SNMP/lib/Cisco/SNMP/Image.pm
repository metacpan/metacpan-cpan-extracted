package Cisco::SNMP::Image;

##################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
##################################################

use strict;
use warnings;

use Net::SNMP qw(:asn1);
use Cisco::SNMP;

our $VERSION = $Cisco::SNMP::VERSION;

our @ISA = qw(Cisco::SNMP);

##################################################
# Start Public Module
##################################################

sub _imageOID {
    return '.1.3.6.1.4.1.9.9.25.1.1.1.2';
}

sub image_info {
    my $self = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my $response = Cisco::SNMP::_snmpwalk( $session, _imageOID() );

    my %ImageHash;
    for ( @{$response} ) {
        my ( $key, $value ) = split /\$/, $_, 2;
        $key =~ s/^CW_//;
        $key = ucfirst( lc($key) );
        $value =~ s/\$$//;
        $ImageHash{$key} = $value;
    }

    no strict 'refs';
    for my $key ( keys(%ImageHash) ) {
        *{"image" . $key} = sub {
            return $ImageHash{$key};
          }
    }
    use strict;

    if ( defined $response ) {
        return bless $response, $class;
    } else {
        $Cisco::SNMP::LASTERROR = "Cannot read image MIB";
        return undef;
    }
}

sub imageString {
    my $self = shift;
    my ($idx) = @_;

    if ( not defined $idx ) {
        $idx = 0;
    } elsif ( $idx !~ /^\d+$/ ) {
        $Cisco::SNMP::LASTERROR = "Invalid image index `$idx'";
        return undef;
    }
    return $self->[$idx];
}

sub get_imageString {
    my $self = shift;
    my ($idx) = @_;

    my $s = $self->session;
    my $r = $s->get_request( varbindlist => [_imageOID() . '.' . ($idx)] );
    return $r->{_imageOID() . '.' . ($idx)};
}

##################################################
# End Public Module
##################################################

1;

__END__

##################################################
# Start POD
##################################################

=head1 NAME

Cisco::SNMP::Image - Image Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::Image;

=head1 DESCRIPTION

The following methods implement the Image MIB defined in C<CISCO-IMAGE-MIB>.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP::Image object

  my $cm = Cisco::SNMP::Image->new([OPTIONS]);

Create a new B<Cisco::SNMP::Image> object with OPTIONS as optional parameters.
See B<Cisco::SNMP> for options.

=head2 image_info() - populate image info data structure.

  my $image = $cm->image_info();

Retrieve the image MIB information from the object defined in C<$cm>.

Allows the following accessors to be called.

=head3 imageString() - return image string

  $image->imageString(#);

Return the images string from the image info data structure for 
string index '#'.

=head3 Additional Accessors

=over 4

=item B<imageBegin>

=item B<imageImage>

=item B<imageFamily>

=item B<imageFeature>

=item B<imageVersion>

=item B<imageMedia>

=item B<imageSysdescr>

=item B<imageMagic>

=item B<imageEnd>

These accessors are dynamically created with the call to C<image_info> 
based on what image strings are returned.  The above are generally the 
same for all devices; however, the MIB only specifies a generic C<imageString> 
type into which these values are loaded.

=back

=head1 DIRECT ACCESS METHODS

The following methods can be called on the B<Cisco::SNMP::Image> object 
directly to access the values directly.

=over 4

=item B<get_imageString> (#)

Get Image OIDs where (#) is the OID instance, not the index from 
C<image_info>.  If (#) not provided, uses 0.

=back

=head1 INHERITED METHODS

The following are inherited methods.  See B<Cisco::SNMP> for more information.

=over 4

=item B<close>

=item B<error>

=item B<session>

=back

=head1 EXPORT

None by default.

=head1 EXAMPLES

This distribution comes with several scripts (installed to the default
C<bin> install directory) that not only demonstrate example uses but also
provide functional execution.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2015

L<http://www.VinsWorld.com>

All rights reserved

=cut
