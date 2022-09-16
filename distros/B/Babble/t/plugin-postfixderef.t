use strictures 2;
use Test::More;
use Babble::Plugin::PostfixDeref;
use Babble::Match;

my $pd = Babble::Plugin::PostfixDeref->new;

my @cand = (
  [ 'my $x = $foo->$*; my @y = $bar->baz->@*;',
    'my $x = ${$foo}; my @y = @{$bar->baz};' ],
  [ 'my $x = ($foo->bar->$*)->baz->@*;',
    'my $x = @{(${$foo->bar})->baz};' ],
  [ 'my @val = $foo->@{qw(key names)};',
    'my @val = @{$foo}{qw(key names)};' ],
  [ 'my $val = $foo[0];',
    'my $val = $foo[0];' ],
  [ 'my $val = $foo[$idx];',
    'my $val = $foo[$idx];' ],
  [ '$bar->{key0}{key1}',
    '$bar->{key0}{key1}' ],
  [ '$bar->{key0}{key1}->@*',
    '@{$bar->{key0}{key1}}' ],
  [ '$bar->{key0}{key1}->@[@idx]',
    '@{$bar->{key0}{key1}}[@idx]' ],
  [ 'my %val = $foo->%[@idx];',
    'my %val = %{$foo}[@idx];' ],
  [ 'my %val = $foo->%{qw(key names)};',
    'my %val = %{$foo}{qw(key names)};' ],

  [ '$foo->@* = qw(a b c);',
    '@{$foo} = qw(a b c);' ],
  [ 'push $foo->@*, "another one";',
    'push @{$foo}, "another one";' ],

  [ 'qq{ $foo->@* }',
    'qq{ @{[ @{$foo} ]} }' ],
  [ 'qq{ $foo->@{qw(key names)} }',
    'qq{ @{[ @{$foo}{qw(key names)} ]} }' ],

  [ 'qq{ $foo }',
    'qq{ $foo }' ],
  [ 'qq{ $foo $bar }',
    'qq{ $foo $bar }' ],

  [ 'qq{ $foo->%* }',
    'qq{ $foo->%* }' ],
  [ 'qq{ $foo->%* $bar->@* }',
    'qq{ $foo->%* @{[ @{$bar} ]} }' ],

  [ 'qq{ $foo->$* }',
    'qq{ @{[ ${$foo} ]} }' ],

  [ '$foo->$#*',
    '$#{$foo}' ],
  [ 'qq{ $foo->$#* }',
    'qq{ @{[ $#{$foo} ]} }' ],
);

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;
  my $top = Babble::Match->new(top_rule => 'Document', text => $from);
  $pd->transform_to_plain($top);
  is($top->text, $to, "${from}");
}

done_testing;
