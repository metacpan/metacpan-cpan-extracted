use 5.006;    # our
use strict;
use warnings;

package App::colourhexdump::ColourProfile;

our $VERSION = '1.000003';

# ABSTRACT: A Role for Colour Profiles

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose::Role qw( requires );
use namespace::autoclean;















requires 'get_colour_for';









requires 'get_display_symbol_for';

no Moose::Role;

use Term::ANSIColor 3.00 qw( RESET );







## no critic ( RequireArgUnpacking )

sub get_string_pre {
  my ( $self, $char ) = ( $_[0], $_[1] );
  my $colourcode = $self->get_colour_for($char);
  if ( defined $colourcode ) {
    return $colourcode;
  }
  return q{};
}








## no critic ( RequireArgUnpacking )

sub get_string_post {
  my ( $self, $char ) = ( $_[0], $_[1] );
  my $colourcode = $self->get_colour_for($char);
  if ( defined $colourcode ) {
    return RESET;
  }
  return q{};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::colourhexdump::ColourProfile - A Role for Colour Profiles

=head1 VERSION

version 1.000003

=head1 SYNOPSIS

    package App::colourhexdump::ColourProfileName

    use Moose;
    with qw( App::colourhexdump::ColourProfile );

    sub get_colour_for {
        my ( $self, $char ) = @_ ;
        ...
        return "\e[31m" if /badthings/;
        return undef;    # don't colour
    }
    sub get_display_symbol_for {
        my ($self, $char) = @_ ;
        ...
        return '.' if $char =~ /badthings/
        return $char;        # printable
    }

=head1 REQUIRED METHODS

=head2 C<get_colour_for>

    my $colour = $object->get_colour_for( "\n" );

Return any string of data that should be prepended every time a given character is seen.

Generally, you only want to print ANSI Escape codes.

Don't worry about resetting things, we put a C<^[[0m> in for you.

Return C<undef> if you do not wish to apply colouring.

=head2 C<get_display_symbol_for>

    my $symbol = $object->get_display_symbol_for( "\n" );

Returns a user viewable alternative to the matched string.

=head1 METHODS

=head2 C<get_string_pre>

Wraps L</get_colour_for> and returns either a string sequence or ''.

=head2 C<get_string_post>

Wraps L</get_colour_for> and returns either an ANSI Reset Code, or '', depending
on what was returned.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
