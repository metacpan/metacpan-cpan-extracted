#!perl -T

use Test::More tests => 6;
use strict;
use Data::Dumper;

BEGIN {
  use_ok( 'Data::Validate::XSD' );
  use_ok( 'Data::Validate::Structure' );
}

my $structure = {
  root => [
    { name => 'input', type => 'news' },
  ],

  complexTypes => {
    news => [
      { name => 'title',   type => 'string', maxLength => 20 },
      { name => 'content', type => 'string', minLength => 20 },
      { name => 'author',  type => 'token',  maxLength => 40 },
      { name => 'editor',  type => 'token',  minOccurs => 0 },
      { name => 'created', type => 'datetime' },
      { name => 'edited',  type => 'datetime', maxOccurs => 3 },
    ],
  },
};

# Odd should pass, Even should fail.
my @dataToTest = (
  { input => {
    title   => 'Correct News',
    content => 'This content should always be above 20 charters in length.',
    author  => 'mowens',
    created => '2007-11-09 20:23:12',
	edited  => '2007-11-09 20:23:12',
  } },
  { input => {
    title   => 'Bad News which has a title which is way too long for this validation to work.',
    content => 'Too Short',
    editor  => [ 'token1', 'token2' ],
    created => '2008-11-09 20:23:12',
    edited  => [ '2007-11-09 20:23:12', '2007-11-09 20:23:12', '2007-11-09 20:23:12', '2007-11-09 20:23:12' ],
  } },
);

my @errors = (
  undef,
  { input => { editor => 15, content => 3, title => 4, edited => 15, author => 13 } },
);

my $validator = Data::Validate::XSD->new( $structure, $ENV{'DEBUG'} );

ok( ref($validator) eq 'Data::Validate::XSD', 'Validator Object' );

my $even;
foreach my $data (@dataToTest) {
  my $errors = $validator->validate( $data );
  my $against = shift @errors;
  # test booliean
  if($even) {
    ok( defined($errors), 'Errors Total' );
    ok( (Data::Validate::Structure->new( $errors ) eq Data::Validate::Structure->new( $against )), 'Errors Structure' );
  } else {
    ok( not($errors), 'Passes Total' );
  }
  $even = not $even;
}

1;
