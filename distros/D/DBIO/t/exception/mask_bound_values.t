# ABSTRACT: mask_bound_values takes bound values out of an error text
use strict;
use warnings;

use Test::More;

use DBIO::Util qw(mask_bound_values);

# ADR 0075. What this file claims: the text of an error keeps its words and
# loses every bound value of at least four characters -- as written, and as
# the engine's quoting writes it (doubled quote, backslash escape); a shorter
# value stays; undef, a reference without a plain value and an empty list
# change nothing; an object with a stringification counts as its string.

my $mysql_quote = sub { (my $v = $_[0]) =~ s/(['\\])/\\$1/g; "'$v'" };
my $ansi_quote  = sub { (my $v = $_[0]) =~ s/'/''/g; "'$v'" };

is mask_bound_values(q{duplicate key value 'geheim-1'}, ['geheim-1']),
  q{duplicate key value '***'}, 'a value is masked where it stands';

is mask_bound_values(q{x geheim-1 y geheim-1 z}, ['geheim-1']),
  q{x *** y *** z}, '... every time it stands there';

# threshold: four characters mask, three stay
is mask_bound_values('key abcd, key abc', [ 'abcd', 'abc' ]),
  'key ***, key abc', 'four characters are masked, three stay';

# quote forms
my $value = q{it's a secret};
is mask_bound_values(q{bad value 'it''s a secret' in column}, [$value], $ansi_quote),
  q{bad value *** in column}, 'the doubled quote of the engine is found';
is mask_bound_values(q{bad value 'it\\'s a secret' in column}, [$value], $mysql_quote),
  q{bad value *** in column}, 'the backslash escape of the engine is found';
is mask_bound_values(q{bad value 'it''s a secret' in column}, [$value]),
  q{bad value 'it''s a secret' in column},
  'without a quote function only the written form is looked for';
is mask_bound_values(q{bad value it''s a secret}, [$value], $ansi_quote),
  q{bad value ***}, 'the form without the outer quotation marks is found';

# a quote function that dies is left out, the written form still goes
is mask_bound_values('has geheim-2 here', ['geheim-2'], sub { die 'no handle' }),
  'has *** here', 'a quote function that dies does not stop the masking';

# longest first
is mask_bound_values('got abcdefgh and abcd', [ 'abcd', 'abcdefgh' ]),
  'got *** and ***', 'a value that holds another is masked as a whole';

# nothing to mask
is mask_bound_values('boom geheim', []), 'boom geheim', 'an empty list changes nothing';
is mask_bound_values('boom geheim', undef), 'boom geheim', 'no list changes nothing';
is mask_bound_values('boom geheim', [undef]), 'boom geheim', 'undef is skipped';
is mask_bound_values('boom ARRAY', [ [ 'ARRAY' ], {}, \'ARRAY' ]), 'boom ARRAY',
  'a reference without a plain value is skipped';
is mask_bound_values(undef, ['geheim-1']), undef, 'an undef text stays undef';

# an object with a stringification counts as its string
{
  package T::Str;
  use overload '""' => sub { ${ $_[0] } }, fallback => 1;
  sub new { my $s = $_[1]; bless \$s, $_[0] }
}
is mask_bound_values('at 2026-11-02 10:00', [ T::Str->new('2026-11-02') ]),
  'at *** 10:00', 'an object with a stringification is masked as its string';

# the list of the caller is left alone
{
  my @list = (T::Str->new('abcdef'), 'xyzxyz');
  mask_bound_values('abcdef', \@list);
  isa_ok $list[0], 'T::Str', 'the list of the caller';
}

done_testing;
