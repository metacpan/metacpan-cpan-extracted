#!/usr/bin/perl

use Test;
BEGIN { plan tests => 9 }

use Class::MakeMethods::Composite::Universal;
ok( 1 );

########################################################################

sub foo {
  my $count = shift || 0;
  return 'foo' x $count;
}

ok( ! length foo() );
ok( foo(1) eq 'foo' );
ok( foo(2) eq 'foofoo' );
ok( foo(3) eq 'foofoofoo' );

Class::MakeMethods::Composite::Universal->make_patch(
  name => 'foo',
  pre_rules => [
    sub { 
      my $method = pop @_;
      if ( ! scalar @_ ) {
	@{ $method->{args} } = ( 2 );
      }
    },
    sub { 
      my $method = pop @_;
      my $count = shift;
      if ( $count > 99 ) {
	Carp::confess "Won't foo '$count' -- that's too many!"
      }
    },
  ],
  post_rules => [
    sub { 
      my $method = pop @_;
      if ( ref $method->{result} eq 'SCALAR' ) {
	${ $method->{result} } =~ s/oof/oozle-f/g;
      } elsif ( ref $method->{result} eq 'ARRAY' ) {
	map { s/oof/oozle-f/g } @{ $method->{result} };
      }
    } 
  ],
);

ok( foo(), foo(2) );
ok( foo(1), 'foo' );
ok( foo(2), 'foozle-foo' );
ok( foo(3), 'foozle-foozle-foo' );

1;
