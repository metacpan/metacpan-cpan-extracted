package Utils;
# vim:ts=4:sw=4:et:ft=perl:

use strict;
use warnings;
use Carp;
use Scalar::Util qw( refaddr blessed );

use base qw(Exporter);

our @EXPORT = qw( bake );

sub enc($) {
  my $sc = shift;
  $sc =~ s/(\W)/'%'.sprintf('%02x',ord $1)/eg;
  return $sc;
}

sub bake($) {
  my $thing = shift;
  if ( my $ref = ref $thing ) {
    my @rep = qq{"$ref"=} . refaddr $thing;
    if ( blessed $thing ) { unshift @rep, '*'; }
    elsif ( 'HASH' eq $ref ) {
      push @rep, '{',
       (
        map { ( enc $_ , ':', bake( $thing->{$_} ) ) }
         sort keys %$thing
       ),
       '}';
    }
    elsif ( 'ARRAY' eq $ref ) {
      push @rep, '[', ( map { bake( $_ ) } @$thing ), ']';
    }
    return join ' ', @rep;
  }
  else {
    return enc $thing;
  }
}

1;
