package Acme::Meow;

use warnings;
use strict;

require Exporter;
use base qw[ Exporter ];
=head1 NAME

Acme::Meow - It's the kitty you've always wanted

=head1 VERSION

Version 0.01 - please note this is a preview release, the API may change
$Id: Meow.pm 558 2007-09-07 12:14:11Z f00li5h $
=cut

our $VERSION = '0.01';
=head1 SYNOPSIS

This module is intended for use by folks who's leases
specify that they are not allowed to have any pets

    use Acme::Meow;

    my $kitty = Acme::Meow->new();
    $kitty->pet();
    $kitty->feed();


=head1 FUNCTIONS

=head2 new - kitty constructor

Currently only abstract kitties are available so no options are available,
although they may be added in the future.

This method will take a hashref of options as required.

=cut 

sub new {
    bless{},shift
}

=head1 METHODS

=head2 pet - pet the kitty

=cut

our @snacks = qw[ milk nip ];

sub pet {
    my($kitty) =@_;

    my @reactions = qw[ purr nuzzle meow ];

    $kitty->{'<3'} ++;
    $kitty->{'favs'} = {
        snack => @snacks[ rand @snacks ]
    };

    print $kitty->_kitty_status,
          $reactions[ rand @reactions ], $kitty->{'<3'} > 15 ? '<3' : '' 
     

}


=head2 feed - give the kitty a snack

the kitty does need to eat, otherwise it will get unhealthy

=cut

sub feed {

    my($kitty) =@_;

    my @reactions = ( 'crunch', 'lap lap', '');

    if (!$kitty->is_sleeping()){
        $kitty->{'^_^'} ++; 
        $kitty->{'<3' } += 0.5;
    }
    else {
        $kitty->{'^_^'} -= 0.5; 
        $kitty->{'<3' } += 0.25;
    }

    print $kitty->_kitty_status,
        $reactions[ rand @reactions ];

}

=head1 EXPORTS

by default this package exports some methods for playing with your 
kitties.

=head2 milk - give milk to a kitty.

if not called directly on a kitty, $_ will be checked for a kitty;

=cut

our @EXPORT    = qw(&milk &nip);   # afunc is a function
# @EXPORT_OK = qw(&%hash *typeglob); # explicit prefix on &bfunc

sub milk {
    my $kitty;

    if(not @_ and ref $_ eq __PACKAGE__){
        $kitty = $_
    }
    if( @_ ){ $kitty = shift }

    $kitty->feed( 'milk' );
}

=head2 nip - give nip to a kitty.

if not called directly on a kitty, $_ will be checked for a kitty;

=cut
sub nip {

    my $kitty;

    if(not @_ and ref $_ eq __PACKAGE__){
        $kitty = $_
    }
    if( @_ ){ $kitty = shift }

    $kitty->feed( 'nip' );

}


=head2 is_sleeping

This method will tell you if your kitty is having a cat nap.
Kittens may be very cranky during their nap time, and waking them may be a bad
idea.

=cut
sub is_sleeping {

    my($kitty) =@_;
    0; #TODO: our kitties are currently insomniacs
}

=head2 _kitty_status

private 

=cut
sub _kitty_status {

    my($kitty) =@_;
    return 'zZzZ' if $kitty->is_sleeping();
    $kitty->{'<3'} > 5 ? '=-_-=' : '=^_^=';

}

=head1 AUTHOR

FOOLISH, C<< <foolish at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-meow at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Meow>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 TODO

=over 4

=item play

it'd be nince to play games with the kitty too

    $kitty->play( 'game' ); 

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Meow

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Meow>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Meow>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Meow>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Meow>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 FOOLISH, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::Meow
