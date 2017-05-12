#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

BEGIN
{
  use_ok('Data::FormValidator');
}

my $dfv;
eval { $dfv = Data::FormValidator->new( {}, 'wrong' ); };
like( $@, qr/must be a hash ref/, 'second argument must be a hash ref or die' );

eval {
  $dfv = Data::FormValidator->new('test/00_base.WRONG');
  my $results = $dfv->check( {}, 'profile1' );
};
like( $@, qr/no such file/i, 'bad profile file names should cause death' );

eval {
  $dfv = Data::FormValidator->new('test/00_base.badformat');
  my $results = $dfv->check( {}, 'profile1' );
};
like( $@, qr/return a hash ref/, 'profile files should return a hash ref' );

eval { $dfv = Data::FormValidator->new('test/00_base.profile'); };

my $results = $dfv->check( {}, 'profile1' );

ok( scalar $results->missing, 'loading a profile from a file works' );
