use strict;
use warnings;

use Test::More;
use Scalar::Util qw(weaken);

use DBIO::Test::Storage;

# populate_more walks the fixture with a visitor and a dispatcher. They used
# to be anonymous subs held by their own variables -- a cycle that only a
# trailing "undef" resolved, so a call that died on the way (a bad Index, an
# unset !Env, an unknown inflator) left the cycle and everything the closures
# held (the visited copies of the fixture, the rows made so far) alive for the
# life of the process.
#
# The probe is an object riding through the fixture as a plain value: the
# visitor hands a non-ARRAY/HASH value on as it is, so the copy it keeps in its
# %seen table holds the object. Once the fixture is gone the object is alive
# only while something of populate_more still holds that copy.

{
  package TestDBIO::PopLeak::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components(qw/PopulateMore/);
}

{
  package TestDBIO::PopLeak::Schema::Result::Gender;
  use base 'DBIO::Core';
  __PACKAGE__->table('gender');
  __PACKAGE__->add_columns(label => { data_type => 'varchar', size => 20 });
  __PACKAGE__->set_primary_key('label');
}

{
  package TestDBIO::PopLeak::Probe;
  our $DESTROYED = 0;
  sub new { bless {}, shift }
  sub DESTROY { $DESTROYED++ }
}

TestDBIO::PopLeak::Schema->register_class(Gender => 'TestDBIO::PopLeak::Schema::Result::Gender');

TestDBIO::PopLeak::Schema->storage_type('+DBIO::Test::Storage');
my $schema = TestDBIO::PopLeak::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));

# Runs populate_more on a fixture whose data carries a probe in every row,
# lets the fixture go, and returns the weak probe, the error and the index.
sub run_populate {
  my ($tail_data) = @_;
  my $probe = TestDBIO::PopLeak::Probe->new;
  my $weak  = $probe;
  weaken $weak;

  my %index;
  my $err;
  {
    my %rows = map { ("r$_" => [ "r$_", $probe ]) } 1 .. 200;
    my $fixture = [
      { Gender => { fields => 'label', data => \%rows } },
      ( $tail_data ? { Gender => { fields => 'label', data => $tail_data->($probe) } } : () ),
    ];
    undef $probe;
    local $@;
    eval { %index = $schema->populate_more($fixture); 1 } or $err = $@;
  }
  return ($weak, $err, \%index);
}

subtest 'a finished populate_more of 200 rows holds nothing' => sub {
  my ($weak, $err, $index) = run_populate();
  ok !$err, 'it finished' or diag $err;
  is scalar(keys %$index), 200, 'every row is in the index';
  ok !defined $weak, 'the fixture value is freed with the fixture';
};

my %dies = (
  'bad !Index'       => [ qr/Bad Index in fixture: Gender\.nope/,
                          sub { { x => [ $_[0], '!Index:Gender.nope' ] } } ],
  'unset !Env'       => [ qr/No match for DBIO_POPMORE_NO_SUCH_VAR in %ENV/,
                          sub { { x => [ $_[0], '!Env:DBIO_POPMORE_NO_SUCH_VAR' ] } } ],
  'unknown inflator' => [ qr/Unknown inflator: Bogus/,
                          sub { { x => [ $_[0], '!Bogus:thing' ] } } ],
);

for my $name (sort keys %dies) {
  my ($re, $tail) = @{ $dies{$name} };
  subtest "populate_more that dies on $name leaves nothing behind" => sub {
    my ($weak, $err) = run_populate($tail);
    like $err, $re, 'it died as before';
    ok !defined $weak, 'the visited copy of the fixture is freed';
  };
}

ok $TestDBIO::PopLeak::Probe::DESTROYED >= 4, 'every probe was destroyed';

done_testing;
