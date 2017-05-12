# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use THelper;

use File::Temp 0.22;
my $tmp = File::Temp->new(UNLINK => 1);
print $tmp qq|hello [% IF 0 %]true[% ELSE %]false[% END %]|;
close $tmp;

my $cond_while = qq|1 [% FOREACH account IN account_numbers %] [% IF loop.first %] WHERE [% ELSE %] OR [% END %] account_number LIKE '%[% account.remove('(\\W+)') %]%' [% END %]|;
my $transformations = {trim => sub { (my $s = $_[0]) =~ s/(^\s+|\s+$)//g; $s }};

# This is mostly testing Template Toolkit which probably isn't useful
my @templates = (
  [
    {file => $tmp->filename},
    qq|hello false|
  ],
  [
    {sql => qq|hello [% IF 1 %]true[% END %]|},
    qq|hello true|
  ],
  [
    {sql => qq|hello [% "there" %]|},
    qq|hello there|
  ],
  [
    {sql => qq|hello [% "there" %]|, suffix => ', you'},
    qq|hello there, you|
  ],
  [
    {sql => qq|hello [% hello.there %]/[% hello.you %]|},
    qq|hello silly/rabbit|
  ],
  [
    {sql => qq|hello [% hello.there %]/[% hello.you %]|, prefix => 'why ', suffix => "\nhead."},
    qq|why hello silly/rabbit\nhead.|,
  ],
  [
    {sql => qq|[% MACRO pref(f) CALL query.prefer(f); pref('hello IS NULL') -%]\n[% pref('t'); query.preferences.join() %]|},
    qq|hello IS NULL t|,
  ],
  [
    {sql => qq|[% CALL query.transform('trim', 'fields', ['address']); GET query.transformations.queue.first.first %]|, transformations => $transformations},
    qq|trim|,
  ],
  [
    {sql => qq|[% CALL query.tr_fields('trim', 'address'); GET query.transformations.queue.first.first %]|, transformations => $transformations},
    qq|trim|,
  ],
  [
    {sql => $cond_while},
    qq|1   WHERE  account_number LIKE '%D001%'   OR  account_number LIKE '%D002%' |,
    {account_numbers => [' D001 ', 'D002']}
  ],
  [
    {sql => $cond_while},
    qq|1   WHERE  account_number LIKE '%D002%' |,
    {account_numbers => ['D00 2']}
  ],
  [
    {sql => $cond_while},
    qq|1 |,
    {account_numbers => []}
  ],
  [
    {sql => 'WHERE field = [% query.bind("hey") %]'},
    qq|WHERE field = ?|,
  ],
  [
    {sql => 'WHERE field = [% query.bind(":duck", "goose", {}) %]'},
    qq|WHERE field = :duck|,
  ],
  [
    {sql => 'WHERE field = $1 [% CALL query.bind("hey") %]'},
    qq|WHERE field = \$1 |,
  ],
);

{
  # __FILE__ has unix line endings; give the template native OS line-endings
  my $template = join($/, split /\n/, <<SQL) . $/;
  WHERE
    fld1 = 1

    [% IF nu_uh %] 1 [% END %]

    AND

  fld2 = 2
\x20\x20
SQL

  push(@templates,
    [
      {sql => $template},
      qq|  WHERE\n    fld1 = 1\n\n    \n\n    AND\n\n  fld2 = 2\n  \n|,
    ],
    [
      {sql => $template, squeeze_blank_lines => 1},
      qq|  WHERE\n    fld1 = 1\n    AND\n  fld2 = 2\n|,
    ],
  );
}

my $mod = 'DBIx::RoboQuery';
eval "require $mod" or die $@;
isa_ok($mod->new(sql => 'SQL'), $mod);

  # one of sql or file but not both
  throws_ok(sub { $mod->new(sql => 'SQL', file => '/dev/null') }, qr'both', 'not both');
  throws_ok(sub { $mod->new() }, qr'one of', 'one');

#my $config = test_config;
my $always = {hello => {there => 'silly', you => 'rabbit'}, nu_uh => 0};

foreach my $template ( @templates ){
  my( $in, $out, $vars ) = @$template;
  my $q = $mod->new({%$in, variables => $always});
  is($q->sql($vars), $out, 'template');
}

{
  # specifically test setting key_columns from template
  my $q = $mod->new(sql => qq|[% query.key_columns = ['goo'] %][% query.key_columns.join %]|);
  is($q->sql, 'goo', 'key_columns set and printed');
  is_deeply($q->{key_columns}, [qw(goo)], 'key_columns attribute set from template');
  $q = $mod->new(sql => qq|[% query.key_columns = ['goo'] %]|);
  is($q->sql, '', 'nothing printed');
  is_deeply($q->{key_columns}, [qw(goo)], 'key_columns attribute set from template');
}

{
  # only process the template once
  my $i = 10;
  my $q = $mod->new(sql => qq|[% boo %]hi|, variables => {boo => sub { ++$i }});
  is($q->sql, '11hi', 'sql');
  is_deeply($i, 11, 'only process once');
  is($q->sql, '11hi', 'sql');
  is_deeply($i, 11, 'only process once');
  # hack... remove the cache var to show what would happen w/o
  delete $q->{processed_sql};
  is($q->sql, '12hi', 'sql');
  is_deeply($i, 12, 'process again after deleting the cache');
  is($q->sql, '12hi', 'sql');
  is_deeply($i, 12, 'only process once');

    foreach my $sql (
      qq|[% CALL query.transform('trim', 'fields', 'help') %]hi|,
      qq|[% CALL query.tr_fields('trim', 'help') %]hi|,
      qq|[% CALL query.transform('trim', 'groups', 'helpful') %]hi|,
      qq|[% CALL query.tr_groups('trim', 'helpful') %]hi|,
    ){
  $q = $mod->new(sql => $sql, transformations => $transformations);
  $q->{transformations}->group(helpful => ['help']);
  is($q->sql, 'hi', 'sql');
  is(scalar @{$q->{transformations}->{queue}}, 1, 'only process once');
  is($q->sql, 'hi', 'sql');
  is(scalar @{$q->{transformations}->{queue}}, 1, 'only process once');
    }
}

isa_ok($mod->new(sql => "hi.")->resultset, 'DBIx::RoboQuery::ResultSet');

my $query = $mod->new(sql => ':-P');
is_deeply($query->{preferences}, undef, 'no preferences');
$query->prefer('hello', 'goodbye');
is_deeply($query->{preferences}, ['hello', 'goodbye'], 'preferences set with prefer()');
$query->prefer('see you later');
is_deeply($query->{preferences}, ['hello', 'goodbye', 'see you later'], 'preferences set with prefer()');
# passed to resultset
is_deeply($query->resultset->{preferences}, ['hello', 'goodbye', 'see you later'], 'preferences set with prefer()');

my $sub_query = 'TRoboQuery';
eval "require $sub_query";
die $@ if $@;
my $sub_resultset = "${sub_query}::ResultSet";

# automatic resultset_class
my $test_subq = $sub_query->new(sql => '');
isa_ok($test_subq, $sub_query);
isa_ok($test_subq->resultset, $sub_resultset);

# explicit resultset_class
$sub_resultset = "${sub_query}::ResultSet2";
$test_subq = $sub_query->new(sql => '', resultset_class => $sub_resultset);
isa_ok($test_subq, $sub_query);
isa_ok($test_subq->resultset, $sub_resultset);

throws_ok(sub { $sub_query->new(sql => '', resultset_class => "$sub_resultset; print STDERR qw(oops);")->resultset; },
  qr{TRoboQuery/ResultSet2printSTDERRqwoops.pm}, 'tainted module cannot be loaded');

done_testing;
