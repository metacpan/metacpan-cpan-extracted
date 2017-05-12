package Acme::RandomQuote::Base;

use warnings;
use strict;

use File::RandomLine;

=head1 NAME

Acme::RandomQuote::Base - The great new Acme::RandomQuote::Base!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Acme::RandomQuote::Base;

    my $foo = Acme::RandomQuote::Base->new( 'file' );

    print $foo->get_random_quote();

=head2 new

Creates a new Acme::RandomQuote::Base object.

    my $foo = Acme::RandomQuote::Base->new( 'file' );

=cut

sub new {
    my ( $self, $filename ) = @_;

    return bless \$filename => $self;
}

=head2 get_random_quote

Returns a random line from the selected file.

    print $foo->get_random_quote();

=cut

sub get_random_quote {
    my $self = shift;

    my $rl = File::RandomLine->new( $$self );

    return $rl->next;
}

=head1 AUTHOR

Diogo Neves, C<< <dafneves at mangaru.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Diogo Neves, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::RandomQuote::Base
