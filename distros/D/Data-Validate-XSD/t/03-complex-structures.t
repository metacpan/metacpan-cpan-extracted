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
      { name => 'articles', type => 'article', maxOccurs => 4, minOccurs => 1 },
    ],
	article => [
      [
        { name => 'title', type => 'string' },
        [
          { name => 'name',   type => 'string' },
          { name => 'author', type => 'string' },
        ]
      ],
      { name => 'content', type => 'string' },
      { name => 'tags',    type => 'tag',  maxOccurs => 'unbounded' },
	],
	tag => [
	  { name => 'name',   type => 'string' },
	  { name => 'count',  type => 'integer' },
	]
  },
};

# Odd should pass, Even should fail.
my @dataToTest = (
  {
    input => {
      articles => [
        {
          title   => 'Correct News',
          content => 'Foo',
          tags    => [
            { name => 'tag1', count => '2' },
            { name => 'tag2', count => '0' },
          ],
        },
        {
          name    => 'Correct News',
          author  => 'This guy I Know',
          content => 'Bar',
          tags    => { name => 'tag3', count => '9' },
        },
      ]
    }
  },{
    input => {
      articles => {
        author  => 'This guy',
      }
    }
  },
);

my @errors = (
  undef,
  { 'input' => { 'articles' => { 'content' => 13, 'tags' => 13 } } },
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
