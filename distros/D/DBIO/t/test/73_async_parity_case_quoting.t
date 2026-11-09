use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::AsyncParity::Cases;

# Cases 14 and 34 of the async parity table must hold on every engine:
#
#  * 14 (count-literal) writes the column `rank` into literal SQL. `rank` is a
#    reserved word on some engines, so the case asks the storage's SQL maker
#    to quote it, in the synchronous and in the async arm alike (karr k355).
#  * 34 (upsert) names its conflict target by column, not by the name of a
#    unique constraint the engine may not give that name (karr k355).

my %case = map { $_->{no} => $_ } @{ DBIO::Test::AsyncParity::Cases->cases };

# A stand-in for the async arm: records what the arm asks of the resultset.
{
  package Test::Recorder;
  sub new      { bless { schema => $_[1], call => [] }, $_[0] }
  sub storage  { $_[0]{schema}->storage }
  sub resultset { $_[0] }
  sub AUTOLOAD {
    my $self = shift;
    (my $m = our $AUTOLOAD) =~ s/.*:://;
    return if $m eq 'DESTROY';
    push @{ $self->{call} }, [ $m, @_ ];
    return $self;
  }
}

for my $quote ('"', undef, '`') {
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  $schema->storage->sql_maker->quote_char($quote);
  my $label = defined $quote ? "quote_char $quote" : 'no quote_char';
  my $q     = $quote // '';
  my $want  = "${q}rank${q} > ?";

  my $rec = Test::Recorder->new($schema);
  $case{14}{sync}->($rec);
  is $rec->{call}[-1][0], 'count_literal', "case 14 sync arm: count_literal ($label)";
  is $rec->{call}[-1][1], $want,           "case 14 sync arm: rank as the storage quotes it ($label)";

  $rec = Test::Recorder->new($schema);
  $case{14}{async}->($rec);
  is $rec->{call}[-1][0], 'count_literal_async', "case 14 async arm: count_literal_async ($label)";
  is $rec->{call}[-1][1], $want,                 "case 14 async arm: rank as the storage quotes it ($label)";
}

for my $arm (qw(sync async)) {
  my $rec = Test::Recorder->new(DBIO::Test->init_schema(no_deploy => 1));
  $case{34}{$arm}->($rec);
  my $attrs = $rec->{call}[-1][-1];
  is_deeply $attrs, { conflict_target => ['name'] },
    "case 34 $arm arm: upsert names its conflict target by column";
}

done_testing;
