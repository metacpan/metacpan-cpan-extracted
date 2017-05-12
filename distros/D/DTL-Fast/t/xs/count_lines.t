#!/usr/bin/perl
use strict; use warnings FATAL => 'all';
use Test::More;use utf8;

use DTL::Fast;

my $SETS = [
  {
        'text' => <<'_EOM_'
This
is a
test
_EOM_
        , 'control' => 3
        , 'title' => 'Regular text'
  },
  {
        'text' => ""
        , 'control' => 0
        , 'title' => 'Empty line'
  },
  {
        'text' => undef
        , 'control' => 0
        , 'title' => 'Undef value'
  },
  {
        'text' => "\n\n\n\n\n\n\n\n\n\n"
        , 'control' => 10
        , 'title' => '10 newlines'
  },
];

foreach my $data (@$SETS)
{
    is( DTL::Fast::count_lines($data->{'text'}), $data->{'control'}, $data->{'title'});
}

done_testing();
