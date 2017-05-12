use 5.006;
use strict;
use warnings;

package App::colourhexdump::DefaultColourProfile;

our $VERSION = '1.000003';

# ABSTRACT: The default colour profile

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has with );
use namespace::autoclean;

with 'App::colourhexdump::ColourProfile';

__PACKAGE__->meta->make_immutable;
no Moose;

use Term::ANSIColor 3.00 qw( BLACK ON_RED BOLD BRIGHT_BLUE BRIGHT_YELLOW ON_YELLOW RED BLUE YELLOW );







## no critic ( Subroutines::RequireArgUnpacking )
sub get_colour_for {
  return BLACK . ON_RED                 if $_[1] =~ /\r/;
  return BOLD . BRIGHT_BLUE             if $_[1] =~ /\n/;
  return BLUE                           if $_[1] =~ / /;
  return BOLD . BRIGHT_BLUE . ON_YELLOW if $_[1] =~ /\t/;
  return RED                            if $_[1] =~ qr{[^[:print:]]};
  return                                if $_[1] =~ qr{[[:alpha:]\d]};
  return YELLOW;
}







## no critic ( Subroutines::RequireArgUnpacking )

sub get_display_symbol_for {
  return q{_} if $_[1] =~ qr{\s};
  return q{.} if $_[1] =~ qr{[^[:print:]]};
  return $_[1];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::colourhexdump::DefaultColourProfile - The default colour profile

=head1 VERSION

version 1.000003

=head1 SYNOPSIS

This is the default colour profile.

    \r           => black on red               '_'
    \n           => bold bright blue           '_'
    " "          => blue                       '_'
    \t           => bold bright blue on yellow '_'
    alphanumeric => white                      $char
    nonprintable => red                        '.'
    everything else => yellow                  $char

Invocation:

    my $cp = App::colourhexdump::DefaultColourProfile->new();
    my $colouredChar =
        $cp->get_string_pre( $char ) .
        $cp->get_dispaly_symbol_for( $char ) .
        $cp->get_string_post( $char );

=head1 METHODS

=head2 get_colour_for

See L<App::colourhexdump::ColourProfile/get_colour_for>

=head2 get_display_symbol_for

See L<App::colourhexdump::ColourProfile/get_display_symbol_for>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
