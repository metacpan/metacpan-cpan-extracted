#!/usr/bin/perl

package Acme::Hyperindex;

=head1 NAME

Acme::Hyperindex - Look deep into structures using a list of indexes

=head1 SYNOPSIS

  use strict;
  use Acme::Hyperindex;

  my @struct = (
      { j_psi => [qw( eta_prime phi kaon )] },
      { j_psi => [qw( selectron down tau_sneutrino )] },
      { j_psi => [qw( upsilon gluino photino )] }
  );

  print @struct[[ 2, 'j_psi', 1 ]], "\n"; ### Prints gluino
  my $row = @struct[[ 1, 'j_psi' ]];      ### Row contains [qw( selectron down tau_sneutrino )]

=head1 DESCRIPTION

When you use dynamic datastructures,
the perl index syntax may not be felxible enough.
A little examle:

  my @struct = (
      {
          pion        => [
              [qw(strange j_psi positron)],
              [qw(down_squark electron gluino)],
          ],
          w_plus_wino => [
              [qw(neutralino tau kaon)],
              [qw(charm_squark photino strange_squark)]
          ],
      },
  );

Now to get to the kaon particle, normally we use:

  my $particle = $struct[0]->{w_plus_wino}->[2];
   -- or better --
  my $particle = $struct[0]{w_plus_wino}[2];

But what if you don't know how deep your datastructure is
at compile time? 'Course this is doable:

  my $particle = \@struct;
  $particle = $particle->[$_] for qw(0 pion 2);

Two problems here: Perl will tell you 'Not an ARRAY reference'
once we try to index in the hash on 'pion' with this array indexing syntax.
It's damn ugly and looks complicated.

So Acme::Hyperindex lets you index arbitrary deep into data structures:

  my $particle = @struct[[ 0, 'pion', 2 ]];
    -- or even --
  my $particle = @struct[[ @indexes ]];
    -- or --
  my $particle = @struct[[ get_index() ]];
    -- or --
  my $particle = @struct[[ $particleindexes[[ 3, 42 ]] ]];

Acme::Hyperindex now also lets you index on scalars, arrays and hashes:

  $struct[[ ... ]];
  @struct[[ ... ]];
  %struct[[ ... ]];

And lists ary auto-derefed in list context:

  my $struct = [ [qw(a b c)], [qw(d e f)] ];

  my $foo = $struct[[ 0 ]]; # $foo contains a ref to qw(a b c)
  my @foo = $struct[[ 0 ]]; # @foo contains qw(a b c)

=cut

use strict;
use warnings;

use base qw(Exporter);
use vars qw(@EXPORT $VERSION);

use Carp qw(croak);
use Filter::Simple;

@EXPORT = qw(hyperindex);

$VERSION = 0.12;

FILTER_ONLY
    code => sub {
        my $rx;
        $rx = qr{
            ([\$\@\%]) \s* (\w+) \s* \[\[
            (
                [^\[\]]*
                (?: \[[^\[]
                |   \][^\]]
                |   (?{{ $rx }}) [^\[\]]*
                )*
            )\]\]
        }x;
        ### We need while for $a[[ $b[[ ]] ]] situations
        1 while s/$rx/"hyperindex( ". ($1 eq '$' ? '' : '\\') ."$1$2, $3 )"/eg;
    };

sub hyperindex {
    my $structure = shift;
    my @indexes   = @_;

    if ( ref $structure eq 'SCALAR' ) {
        $structure = $$structure;
    }
    my $item = $structure;
    for my $index ( @indexes ) {
        if      ( ref $item eq 'HASH' ) {
            $item = $item->{$index};
        }
        elsif   ( ref $item eq 'ARRAY' ) {
            $item = $item->[$index];
        }
        else {
            ref($item) or croak "Hyperindexing on '$index', but datastructure is at maximum depth";
            die "Hmm, error in hyperindexing: index => $index item => $item";
        }
    }

    if ( ref $item ) {
        if ( ref($item) eq 'ARRAY' and wantarray ) {
            return @{$item};
        }
        if ( ref($item) eq 'HASH' and wantarray ) {
            return %$item;
        }
    }

    return $item;
}

=head1 BUGS

Perl code is hard to parse, and there are surely
situations where my parsing fails to do the right
thing.

=head1 TODO

=over 4

=item * make the sourcefilter optionally

=item * Scalar references within the datasructure..

  my $struct = [ \[qw(a b c)] ];

There should be some way to get to 'a'

=item * Generate nonexisting references optionally

When you try to index deeper than the data structure is:

  my $struct = [];
  $struct[[ 0, 'foo', 42 ]];

=back

=head1 AUTHOR

Berik Visschers <berikv@xs4all.nl>

=head1 COPYRIGHT

Copyright 2005 by Berik Visschers E<lt>berikv@xs4all.nlE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut

1
