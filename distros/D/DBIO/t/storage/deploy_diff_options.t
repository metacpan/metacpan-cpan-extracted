# ABSTRACT: $deploy->diff(\%opts) hands the options to the diff class, unknown ones throw
use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't/lib';
use DBIO::Diff::Base;
use DBIO::Deploy::Base;
use DBIO::Extension::List;
use TestDBIO::Extension::Deploy;

# Deploy::Base::diff used to take no argument: an option a driver's diff class
# understands (foreign_keys_not_valid on PostgreSQL) could only be poked into
# the diff object from outside. Now the options reach the diff class's new, on
# the plain path and on the extension path alike, and a key the diff class does
# not declare in diff_options throws instead of being dropped.

{
  package T::Diff;
  use base 'DBIO::Diff::Base';
  sub diff_options { qw(fk_not_valid other_flag) }
  sub _build_operations { [] }
}

{
  package T::Diff::NoOptions;
  use base 'DBIO::Diff::Base';
  sub _build_operations { [] }
}

{
  package T::Deploy;
  use base 'TestDBIO::Extension::Deploy';
  sub _diff_class { $_[0]{diff_class} || 'T::Diff' }
}

sub deploy {
  my (%extra) = @_;
  return T::Deploy->new(
    source_model => { tables => {} },
    target_model => { tables => {} },
    dbh          => {},
    %extra,
  );
}

my %table = (age => 'TestDBIO::Extension::Age');
sub entries {
  return [ DBIO::Extension::List->new(
    declaration => [@_],
    class_table => sub { $table{ $_[0] } ? ($table{ $_[0] }) : () },
    plain_class => 'TestDBIO::Extension::Plain',
  )->entries ];
}

# --- no argument: as before ---------------------------------------------------------------
{
  my $diff = deploy()->diff;
  isa_ok $diff, 'T::Diff';
  ok !exists $diff->{fk_not_valid}, 'no argument: the diff class is handed no option';
  my $undef = deploy()->diff(undef);
  ok !exists $undef->{fk_not_valid}, 'undef is no options';
  my $empty = deploy()->diff({});
  ok !exists $empty->{fk_not_valid}, 'an empty hash is no options';
}

# --- plain path -----------------------------------------------------------------------------
{
  my $diff = deploy()->diff({ fk_not_valid => 1 });
  is $diff->{fk_not_valid}, 1, 'the option arrives in the diff class';
  ok $diff->{source} && $diff->{target}, 'source and target are still handed over';

  my $two = deploy()->diff({ fk_not_valid => 1, other_flag => 'x' });
  is $two->{other_flag}, 'x', 'every declared option arrives';

  my $zero = deploy()->diff({ fk_not_valid => 0 });
  is $zero->{fk_not_valid}, 0, 'a false value arrives as given';
}

# --- extension path -------------------------------------------------------------------------
{
  my $diff = deploy(extension_list => entries('age'))->diff({ fk_not_valid => 1 });
  is $diff->{fk_not_valid}, 1, 'extensions declared: the option arrives in the diff class';
  ok $diff->{extensions}, 'and the protocol is still handed over';
  ok !exists deploy(extension_list => entries('age'))->diff->{fk_not_valid},
    'extensions declared, no argument: no option';
}

# --- refusals -------------------------------------------------------------------------------
throws_ok { deploy()->diff({ fk_not_valid => 1, bogus_key => 1 }) }
  qr/bogus_key.*T::Diff|T::Diff.*bogus_key/s,
  'an unknown option throws and names the key and the diff class';
throws_ok { deploy(extension_list => entries('age'))->diff({ bogus_key => 1 }) }
  qr/bogus_key/, 'an unknown option throws on the extension path too';
throws_ok { deploy(diff_class => 'T::Diff::NoOptions')->diff({ fk_not_valid => 1 }) }
  qr/fk_not_valid.*T::Diff::NoOptions/s,
  'a diff class that declares no options takes none';
throws_ok { deploy()->diff('fk_not_valid') } qr/hash reference/,
  'options that are no hash reference throw';
throws_ok { deploy()->diff([ fk_not_valid => 1 ]) } qr/hash reference/,
  'an array reference throws';

is_deeply [ DBIO::Diff::Base->diff_options ], [], 'the base class declares no options';

done_testing;
