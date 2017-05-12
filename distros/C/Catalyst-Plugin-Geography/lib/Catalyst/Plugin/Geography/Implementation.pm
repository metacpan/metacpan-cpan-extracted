package Catalyst::Plugin::Geography::Implementation;

use strict;
use base qw[Class::Accessor::Fast Class::Data::Inheritable];

use Geography::Countries ();
use IP::Country::Fast;

__PACKAGE__->mk_classdata('lookup');
__PACKAGE__->mk_accessors('context');

__PACKAGE__->lookup( IP::Country::Fast->new );

sub new {
    my $class = shift;
    return bless( { context => shift }, $class );
}

sub code {
    my $self = shift;
    my $host = shift || $self->context->request->address;
    return $self->lookup->inet_atocc($host);
}

sub country {
    my $self = shift;
    my $code = shift || $self->code;

    unless ( $code =~ /^[A-Za-z]+$/ ) {
        $code = $self->code($code);
    }

    return undef unless $code;
    return scalar Geography::Countries::country($code);
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Geography::Implementation - The gory details.

=head1 SYNOPSIS

See L<Catalyst::Plugin::Geography>


=head1 DESCRIPTION

This module uses L<Geography::Countries> and L<IP::Country::Fast> to
return Geographical information about a remote user.

=head1 METHODS

=over 4

=item new

The constructor. Takes a L<Catalyst> context object as argument.

=item 

=item code

This method takes an optional hostname/ip, or fetches the remote
address from the context object. It looks it up using
L<IP::Country::Fast> and returns the country code.

=item country

This method takes an optional country call, or falls back 'code'.
It returns the full country name.

=back

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Geography::Implementation>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>
Marcus Ramberg, C<mramberg@cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

