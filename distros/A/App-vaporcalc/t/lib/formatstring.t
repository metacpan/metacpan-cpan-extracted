use Test::Modern;


use App::vaporcalc::FormatString;

cmp_ok(
  format_str( 'things %and% %stuff',
    and   => 'or',
    stuff => 'some objects',
  ),
  'eq',
  'things or some objects',
  'list-style format_str'
);

cmp_ok(
  format_str( 'things %or %objects',
    {
      or      => 'and perhaps',
      objects => 'some cake',
    },
  ),
  'eq',
  'things and perhaps some cake',
  'hashref format_str'
);

cmp_ok(
  format_str( 'string with %code',
    code => sub { "things" },
  ),
  'eq',
  'string with things',
  'coderef replacement'
);

done_testing;
