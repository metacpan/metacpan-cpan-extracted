package Alien::Base::ModuleBuild::Utils;

use strict;
use warnings;
use Text::Balanced qw/extract_bracketed extract_delimited extract_multiple/;
use parent 'Exporter';

# ABSTRACT: Private utilities
our $VERSION = '1.15'; # VERSION

our @EXPORT_OK = qw/find_anchor_targets pattern_has_capture_groups/;

sub find_anchor_targets {
  my $html = shift;

  my @tags = extract_multiple(
    $html,
    [ sub { extract_bracketed($_[0], '<>') } ],
    undef, 1
  );

  @tags =
    map { extract_href($_) }  # find related href=
    grep { /^<a/i }            # only anchor begin tags
    @tags;

  return @tags;
}

sub extract_href {
  my $tag = shift;
  if($tag =~ /href=(?='|")/gci) {
    my $text = scalar extract_delimited( $tag, q{'"} );
    my $delim = substr $text, 0, 1;
    $text =~ s/^$delim//;
    $text =~ s/$delim$//;
    return $text;
  } elsif ($tag =~ /href=(.*?)(?:\s|\n|>)/i) {
    return $1;
  } else {
    return ();
  }
}

sub pattern_has_capture_groups {
  my $re = shift;
  "" =~ /|$re/;
  return $#+;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Base::ModuleBuild::Utils - Private utilities

=head1 VERSION

version 1.15

=head1 AUTHOR

Original author: Joel A Berger E<lt>joel.a.berger@gmail.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

David Mertens (run4flat)

Mark Nunberg (mordy, mnunberg)

Christian Walde (Mithaldu)

Brian Wightman (MidLifeXis)

Graham Ollis (plicease)

Zaki Mughal (zmughal)

mohawk2

Vikas N Kumar (vikasnkumar)

Flavio Poletti (polettix)

Salvador Fandiño (salva)

Gianni Ceccarelli (dakkar)

Pavel Shaydo (zwon, trinitum)

Kang-min Liu (劉康民, gugod)

Nicholas Shipp (nshp)

Petr Pisar (ppisar)

Alberto Simões (ambs)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2020 by Joel A Berger.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
