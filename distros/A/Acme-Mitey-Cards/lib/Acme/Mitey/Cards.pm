package Acme::Mitey::Cards;

our $VERSION   = '0.014';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Suit;
use Acme::Mitey::Cards::Card;
use Acme::Mitey::Cards::Card::Numeric;
use Acme::Mitey::Cards::Card::Face;
use Acme::Mitey::Cards::Card::Joker;
use Acme::Mitey::Cards::Set;
use Acme::Mitey::Cards::Deck;
use Acme::Mitey::Cards::Hand;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Acme::Mitey::Cards - demo of Mite

=head1 SYNOPSIS

  use Acme::Mitey::Cards;
  
  my $deck = Acme::Mitey::Cards::Deck->new->shuffle;
  my $hand = $deck->deal_hand( owner => 'Bob' );
  print $hand->to_string, "\n";

=head1 DESCRIPTION

This is a small distribution to test/demonstrate L<Mite>.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-mite/issues>.

=head1 SEE ALSO

L<Mite>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
