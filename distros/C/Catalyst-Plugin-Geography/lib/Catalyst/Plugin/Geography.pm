package Catalyst::Plugin::Geography;

use strict;
use Catalyst::Plugin::Geography::Implementation;

our $VERSION = '0.03';

*geo = \&geography;    # Makes sri happy ;)

sub geography {
    my $c = shift;

    unless ( $c->{geography} ) {
        $c->{geography} = Catalyst::Plugin::Geography::Implementation->new($c);
    }

    return $c->{geography};
}

__END__

=head1 NAME

Catalyst::Plugin::Geography - Retrieve geographical information

=head1 SYNOPSIS

    use Catalyst qw[Geography];

    # Retrieve country or code from current user
    print $c->geography->country;
    print $c->geography->code;

    # Retrieve country or code from IP
    print $c->geography->country('66.102.9.99');
    print $c->geography->code('66.102.9.99');

    # Retrieve country or code from hostname
    print $c->geography->country('www.google.com');
    print $c->geography->code('www.google.com');
    
    # Retrieve country from code
    print $c->geography->country('US');
    
    # Alias
    print $c->geo->code('www.google.com');
    print $c->geo->country('US');


=head1 DESCRIPTION

Retrieve geographical country and country codes from users.

=head1 METHODS

=over 4

=item geo

alias to geography

=item geography

Will create or return a L<Catalyst::Plugin::Geography::Implementation>
object.

=back

=head1 SEE ALSO

L<Catalyst> L<Catalyst::Plugin::Geography::Implementation>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>
Marcus Ramberg, C<mramberg@cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut
