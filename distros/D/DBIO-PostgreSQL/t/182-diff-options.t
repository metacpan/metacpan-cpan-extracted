use strict;
use warnings;
use Test::More;

# OFFLINE test for the options of Deploy->diff (karr dbio k359).
#
# WHY it exists: core's Deploy::Base::diff(\%opts) hands the options to the diff
# class's new and refuses any key the class does not list in ->diff_options.
# The Deploy used to set foreign_keys_not_valid by poking the finished diff
# object (after the first operations call it was too late for a lazy build);
# it now passes the option through new. These claims pin: the diff class names
# the option, the deploy hands it to new (from the attribute or the caller),
# an unknown key throws, and the restricted-deploy path keeps its behaviour.

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff;

sub tbl { return ("public.$_[0]" => { schema_name => 'public', table_name => $_[0], kind => 'r' }) }

my %FK = (
  constraint_name => 'child_parent_fk',
  remote_schema   => 'public',
  remote_table    => 'parent',
  local_columns   => ['parent_id'],
  remote_columns  => ['id'],
  on_delete       => 'NO ACTION',
  on_update       => 'NO ACTION',
  is_deferrable   => 0,
);

my @SEEN;
{
  package Diff182;
  use base 'DBIO::PostgreSQL::Diff';
  sub new { my ($class, %a) = @_; push @SEEN, { %a }; return $class->SUPER::new(%a) }
}
{
  package Deploy182;
  use base 'DBIO::PostgreSQL::Deploy';
  sub _diff_class         { 'Diff182' }
  sub _introspect_current { +{ tables => { main::tbl('parent'), main::tbl('child') }, foreign_keys => { 'public.child' => [] } } }
  sub _build_target_model { +{ tables => { main::tbl('parent'), main::tbl('child') }, foreign_keys => { 'public.child' => [ {%FK} ] } } }
}
{
  package Schema182::Plain;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
{
  package Schema182::Restricted;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('public');
}

is_deeply [ DBIO::PostgreSQL::Diff->diff_options ], ['foreign_keys_not_valid'],
  'the diff class names foreign_keys_not_valid as its option';

# Caller's option reaches new.
{
  @SEEN = ();
  my $diff = Deploy182->new(schema => 'Schema182::Plain')->diff({ foreign_keys_not_valid => 1 });
  is $SEEN[0]{foreign_keys_not_valid}, 1, 'the caller\'s option is handed to new';
  like $diff->as_sql, qr/NOT VALID/, '... and is in force when the operations are built';
}

# Attribute reaches new.
{
  @SEEN = ();
  my $diff = Deploy182->new(schema => 'Schema182::Plain', foreign_keys_not_valid => 1)->diff;
  is $SEEN[0]{foreign_keys_not_valid}, 1, 'the deploy attribute is handed to new';
  like $diff->as_sql, qr/NOT VALID/, '... and writes NOT VALID';
}

# Neither: no option, valid key.
{
  @SEEN = ();
  my $diff = Deploy182->new(schema => 'Schema182::Plain')->diff;
  ok !$SEEN[0]{foreign_keys_not_valid}, 'no attribute and no option: nothing is handed on';
  unlike $diff->as_sql, qr/NOT VALID/, '... the key is added valid';
}

# Caller's value stays over the attribute.
{
  @SEEN = ();
  Deploy182->new(schema => 'Schema182::Plain', foreign_keys_not_valid => 1)
    ->diff({ foreign_keys_not_valid => 0 });
  is $SEEN[0]{foreign_keys_not_valid}, 0, 'a value the caller gave stays over the attribute';
}

# Unknown option throws.
{
  my $err = do { local $@; eval { Deploy182->new(schema => 'Schema182::Plain')->diff({ bogus => 1 }); 1 } ? '' : "$@" };
  like $err, qr/bogus/, 'an unknown option throws, naming the key';
}

# Restricted path keeps behaviour.
{
  my $diff = Deploy182->new(schema => 'Schema182::Restricted', foreign_keys_not_valid => 1)->diff;
  like $diff->as_sql, qr/NOT VALID/, 'a restricted deploy still writes NOT VALID';
  my $plain = Deploy182->new(schema => 'Schema182::Restricted')->diff;
  unlike $plain->as_sql, qr/NOT VALID/, '... and valid without the option';
}

done_testing;
