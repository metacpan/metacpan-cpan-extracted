#!/usr/bin/perl
##############################################################################
#
#  Data::Tools test suite -- Data::Tools::Serialization
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
use strict;
use lib 'lib', '../lib';
use Test::More;
use Data::Tools::Serialization;

ok( defined $Data::Tools::Serialization::VERSION, 'Data::Tools::Serialization loaded' );

##############################################################################
# json
##############################################################################

is( perl2json( { a => 1 } ), '{"a":1}', 'perl2json() simple hash' );
is( perl2json( [ 1, 2 ] ),   '[1,2]',   'perl2json() simple array' );

is_deeply( json2perl( '{"a":1}' ), { a => 1 }, 'json2perl() simple hash' );
is_deeply( json2perl( '[1,2]' ),   [ 1, 2 ],   'json2perl() simple array' );

my $DATA = {
           name    => 'test',
           count   => 42,
           list    => [ 1, 2, 3 ],
           nested  => { a => 'x', b => [ { c => 'y' } ] },
           empty_h => {},
           empty_a => [],
           };

is_deeply( json2perl( perl2json( $DATA ) ), $DATA, 'perl2json()/json2perl() round trip' );

eval { json2perl( 'this is not json' ) };
ok( $@, 'json2perl() dies on invalid json' );

##############################################################################
# xml -- XML::Bare is an optional runtime dependency
##############################################################################

SKIP:
{
  eval { require XML::Bare };
  skip( 'XML::Bare is not installed', 4 ) if $@;

  my $xml  = '<root><a>1</a><b>text</b></root>';
  my $perl = xml2perl( $xml );

  is( ref( $perl ), 'HASH', 'xml2perl() returns a hash reference' );
  ok( exists $perl->{ 'root' }, 'xml2perl() parsed the root element' );
  is( $perl->{ 'root' }{ 'a' }{ 'value' }, '1', 'xml2perl() parsed element values' );

  my $back = perl2xml( { root => { a => { value => 1 } } } );
  like( $back, qr/<root>/, 'perl2xml() produces xml' );
}

##############################################################################

done_testing();
