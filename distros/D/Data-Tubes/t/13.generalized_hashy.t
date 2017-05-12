use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;

use Data::Tubes::Util qw< generalized_hashy >;
ok __PACKAGE__->can('generalized_hashy'), 'imported generalized_hashy';

{
   for my $tspec (
      [
         ['whatever', default_key => ''],
         {'' => 'whatever'},
         'simple single value, default_key set',
      ],
      [
         [
            q<what: ever you: set\ \"for\" hey : >
              . q<"no 'way'" this\\ goes\\ alooone>,
            default_key => ''
         ],
         {
            ''   => 'this goes alooone',
            what => 'ever',
            you  => 'set "for"',
            hey  => "no 'way'",
         },
         'some more complex stuff'
      ],
      [
         [
            q<w/h a/t: ever, you; do | eve-r y: where |>
              . q< this: 'go|es' | this : "to:o\\"o" >,
            chunks_separator    => qr{\s*[\|]\s*},
            key_value_separator => qr{\s*:\s*},
            key_admitted        => qr{[^\|'":]},
            value_admitted      => qr{[^\|'":]},
         ],
         {
            'w/h a/t' => 'ever, you; do',
            'eve-r y' => 'where',
            this      => ['go|es', 'to:o"o'],
         },
         'constrained with different parsers, multiple keys, etc.',
      ],
     )
   {
      my ($params, $expected, $name) = @$tspec;
      my $got = generalized_hashy(@$params);
      is_deeply $got->{hash}, $expected, $name;
   } ## end for my $tspec ([['whatever'...]])
}
{
   for my $tspec (
      [
         [
            q<what: ever you: set\ \"for\" hey : >
              . q<"no 'way'" this\\ goes\\ alooone>,
            chunks_separator    => qr{\s*[\|]\s*},
            key_value_separator => qr{\s*:\s*},
            key_admitted        => qr{[^\|'":]},
            value_admitted      => qr{[^\|'":]},
         ],
         qr{failed match at 0},
         'match failure',
      ],
      [
         [
            q<what: ever | this-does-not-go!>,
            default_key => undef,
         ],
         qr{stand-alone value, no default key set},
         'missing default key',
      ],
     )
   {
      my ($params, $expected, $name) = @$tspec;
      my $got = generalized_hashy(@$params);
      like $got->{failure}, $expected, $name
         or diag Dumper $got;
   } ## end for my $tspec ([['whatever'...]])
}
{
   for my $tspec (
      [
         [
            q<what: ever | what: this-does-not-go!>,
            key_duplicate => sub { die 'whatever' },
         ],
         qr{whatever},
         'duplicate key throws exception when instructed to do so',
      ],
     )
   {
      my ($params, $expected, $name) = @$tspec;
      throws_ok { generalized_hashy(@$params) } $expected, $name;
   } ## end for my $tspec ([['whatever'...]])
}
done_testing();

