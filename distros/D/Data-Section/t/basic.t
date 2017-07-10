use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Mother;
use Child;
use Grandchild;

use I::Mother;
use I::Child;
use I::Grandchild;

use NoData;
use NoName;
use Relaxed;
use Header;
use End;

use WindowsNewlines;

my @want = (
  Mother     => { a => \"1\n",   b => \"2\n",  c => \"3\n" },
  Child      => {                b => \"22\n", c => \"33\n", d => \"44\n" },
  Grandchild => { a => \"111\n",                             d => \q{}    },
);

for (my $i = 0; $i < @want; $i += 2) {
  my $inv = $want[ $i ];

  for my $prefix ('', 'I::') {
    my $inv = "$prefix$inv";
    is_deeply(
      $inv->local_section_data,
      $want[ $i + 1 ],
      "$inv->local_section_data",
    );
  }

  is_deeply(
    $inv->merged_section_data,
    $want[ $i + 1 ],
    "$inv->merged_section_data",
  );
}

# The classes that do not begin with I:: are non-inheriting, so we do not
# expect to see (for example) the parent's "b" section propagated to the
# grandchild. -- rjbs, 2010-01-27
is_deeply(Mother    ->section_data('a'), \"1\n",   "Mother's a");
is_deeply(Mother    ->section_data('b'), \"2\n",   "Mother's b");
is_deeply(Grandchild->section_data('a'), \"111\n", "Grandchild's a");
is_deeply(Grandchild->section_data('b'), undef,   "Grandchild's b (none)");

is_deeply(
  [ sort Mother->section_data_names ],
  [ qw(a b c) ],
  "Mother section data names",
);

is_deeply(
  [ sort Mother->local_section_data_names ],
  [ qw(a b c) ],
  "Mother local section data names",
);

is_deeply(
  [ sort Mother->merged_section_data_names ],
  [ qw(a b c) ],
  "Mother merged section data names",
);

is_deeply(
  [ sort Child->section_data_names ],
  [ qw(b c d) ],
  "Child section data names",
);

is_deeply(
  [ sort Child->local_section_data_names ],
  [ qw(b c d) ],
  "Child local section data names",
);

is_deeply(
  [ sort Child->merged_section_data_names ],
  [ qw(b c d) ],
  "Child merged section data names",
);

is_deeply(I::Mother    ->section_data('a'), \"1\n",   "I::Mother's a");
is_deeply(I::Mother    ->section_data('b'), \"2\n",   "I::Mother's b");
is_deeply(I::Grandchild->section_data('a'), \"111\n", "I::Grandchild's a");
is_deeply(I::Grandchild->section_data('b'), \"22\n",  "I::Grandchild's b (via Child)");

is_deeply(
  [ sort I::Mother->section_data_names ],
  [ qw(a b c) ],
  "I::Mother section data names",
);

is_deeply(
  [ sort I::Mother->local_section_data_names ],
  [ qw(a b c) ],
  "I::Mother local section data names",
);

is_deeply(
  [ sort I::Mother->merged_section_data_names ],
  [ qw(a b c) ],
  "I::Mother merged section data names",
);

is_deeply(
  [ sort I::Child->section_data_names ],
  [ qw(a b c d) ],
  "I::Child merged section data names",
);

is_deeply(
  [ sort I::Child->local_section_data_names ],
  [ qw(b c d) ],
  "I::Child local section data names",
);

is_deeply(
  [ sort I::Child->merged_section_data_names ],
  [ qw(a b c d) ],
  "I::Child merged section data names",
);

is_deeply(
  I::Grandchild->merged_section_data,
  { a => \"111\n", b => \"22\n", c => \"33\n", d => \q{}, },
  "I::Grandchild->merged_section_data",
);

is_deeply(NoData->local_section_data, {}, "nothing found in NoData");

is_deeply(
  NoName->local_section_data,
  { a => \"1\n", b => \"2\n" },
  "default name in NoName",
);

is_deeply(
  Relaxed->local_section_data,
  { a => \"1\n", b => \"2\n" },
  "allows empty lines before the first section.",
);

is_deeply(
  Header->local_section_data,
  { a => \"1\n", b => \"2\n" },
  "test header_re",
);

is_deeply(
  End->local_section_data,
  { a => \"1\n", b => \"2\n" },
  "ignore __END__",
);

SKIP: {
  skip "perl below v5.14 on Win32 converts newlines before they reach DATA", 1
    if $^O eq 'MSWin32' and $] < 5.014;

  my $crlf = "\015\012";

  is_deeply(
    WindowsNewlines->local_section_data,
    { n => \"foo$crlf" },
    "windows newlines work",
  );
}

done_testing;
