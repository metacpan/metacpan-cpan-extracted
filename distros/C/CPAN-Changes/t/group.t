use strict;
use warnings;
use Test::More;

use CPAN::Changes;
use CPAN::Changes::Parser;

my $parser = CPAN::Changes::Parser->new;

{
  my $changes = $parser->parse_file('corpus/dists/Module-Rename.changes');

  my $release = $changes->find_release('0.04');
  my @groups = $release->group_values;
  is scalar @groups, 1, 'one group found when no groups present';
  is eval { $groups[0]->name }, '', 'group has empty name';
}

{
  my $changes = CPAN::Changes->new;
  $changes->add_release({version => '1.0'});
  my $release = $changes->release('1.0');
  my $entry = $release->add_entry('welp');
  my $sub_entry = $entry->add_entry('welp');
  my ($group) = ($release->group_values);
  $group->set_changes(
    'guff',
    'blorf',
  );

  is join(',', map $_->text, @{$entry->entries}), 'guff,blorf',
    'set_changes properly sets entries';
}

done_testing;
