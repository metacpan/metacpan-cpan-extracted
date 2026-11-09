use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);
use lib 't/lib';
use SybaseFakeDBH;

use DBIO::Schema;
use DBIO::AccessBroker::Static;
use DBIO::Sybase::Storage::ASE;

# OFFLINE (karr k68). Under FreeTDS DBIO::Sybase::Storage::_init mixes the
# FreeTDS class into the storage, and it used to call _init again on the class
# it had made. The whole chain ran twice: DBIO::Sybase::Storage::ASE::_init
# below it did its work a second time on the same storage -- _set_max_connect
# again, and a second writer storage that threw the first away. Without a
# broker the second _set_max_connect found maxConnect= in the stored DSN and
# did nothing; with a broker core rebuilds the DSN for every connect, the part
# is gone again, and it disconnected and logged in once more (live: 3 logins
# where 2 do, t/61).
#
# Claim: _init runs once per connect -- on the main storage, one
# _set_max_connect and one writer storage, whichever client library it is,
# and with or without a broker. DBI->connect is replaced; nothing connects.

SybaseFakeDBH::install();
$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

my $DSN = 'dbi:Sybase:host=ase.example;port=5000;database=app';

my (%MAX_CONNECT, %WRITER_SET, %ASE_INIT);

{
  no warnings 'redefine';

  my $max_connect = \&DBIO::Sybase::Storage::_set_max_connect;
  *DBIO::Sybase::Storage::_set_max_connect = sub {
    $MAX_CONNECT{ refaddr $_[0] }++;
    goto &$max_connect;
  };

  my $writer = \&DBIO::Sybase::Storage::ASE::_writer_storage;
  *DBIO::Sybase::Storage::ASE::_writer_storage = sub {
    $WRITER_SET{ refaddr $_[0] }++ if @_ > 1 and defined $_[1];
    goto &$writer;
  };

  my $init = \&DBIO::Sybase::Storage::ASE::_init;
  *DBIO::Sybase::Storage::ASE::_init = sub {
    $ASE_INIT{ refaddr $_[0] }++;
    goto &$init;
  };
}

my $count = 0;
sub schema_for {
  my $class = 'T::K68::Schema' . ++$count;
  { no strict 'refs'; @{"${class}::ISA"} = ('DBIO::Schema') }
  $class->load_components('Sybase');
  return $class->connect(@_);
}

my @KEEP;

for my $case (
  [ 'FreeTDS',     $SybaseFakeDBH::FREETDS     ],
  [ 'Open Client', $SybaseFakeDBH::OPEN_CLIENT ],
) {
  my ($client, $oc_version) = @$case;
  local $SybaseFakeDBH::OC_VERSION = $oc_version;

  my %logins;

  for my $way (
    [ 'a DSN string',     sub { ($DSN, 'sa', 's3cret') } ],
    [ 'a broker (whole DSN)', sub {
        (DBIO::AccessBroker::Static->new(
          username => 'sa', password => 's3cret', dbname => $DSN,
        ))
      } ],
  ) {
    my ($via, $info) = @$way;

    %MAX_CONNECT = %WRITER_SET = %ASE_INIT = ();
    SybaseFakeDBH::reset_records();

    my $schema = schema_for($info->());
    push @KEEP, $schema;
    my $storage = $schema->storage;
    $storage->ensure_connected;

    my $id = refaddr $storage;

    is $ASE_INIT{$id}, 1,
      "$client, $via: ASE's _init ran once on the main storage";
    is $MAX_CONNECT{$id}, 1, '... _set_max_connect once';
    is $WRITER_SET{$id}, 1, '... and one writer storage was made';

    $logins{$via} = scalar @SybaseFakeDBH::CONNECTS;
    note "$client, $via: logins for the first connect: $logins{$via}";
  }

  is $logins{'a broker (whole DSN)'}, $logins{'a DSN string'},
    "$client: the first connect takes as many logins through a broker as "
  . 'with a DSN string';
}

done_testing;
