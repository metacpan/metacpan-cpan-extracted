use strict;
use warnings;

use Test::More;
use Test::Exception;
use Storable ();
use DBIO::Test;

# DBIO::ResultSource::STORABLE_thaw (karr k393) resolves the frozen identity
# of a source only to a result class: with a schema one of its registered
# sources' classes, without one a loaded result class.

our @CALLED;
{
  package Probe::NotAResultClass;
  sub result_source_instance { push @main::CALLED, 'result_source_instance'; undef }
}

my $schema = DBIO::Test->init_schema(no_deploy => 1);

sub thaw_hook {
  my ($class, $moniker) = @_;
  my $ice = Storable::nfreeze({ source_moniker => $moniker, _frozen_from_class => $class });
  my $obj = bless {}, 'DBIO::ResultSource';
  $obj->DBIO::ResultSource::STORABLE_thaw(0, $ice);
  return $obj;
}

my $real_class = $schema->class('Artist');

subtest 'with a schema' => sub {
  local $DBIO::ResultSource::thaw_schema = $schema;

  lives_ok { thaw_hook($real_class, 'Artist') } 'the source\'s own class resolves';

  throws_ok { thaw_hook('Probe::NotAResultClass', 'Artist') }
    qr/is not the result class of a source registered on the schema/,
    'a class that is no registered result class is refused';
  is_deeply \@CALLED, [], 'and nothing was called on it';

  throws_ok { thaw_hook('../etc/passwd', 'Artist') } qr/is not a class name/,
    'a name that is no class name is refused';
};

subtest 'without a schema' => sub {
  local $DBIO::ResultSource::thaw_schema;
  @CALLED = ();

  throws_ok { thaw_hook('Probe::NotAResultClass', 'Artist') }
    qr/does not exist on this system|not a class name|result class/,
    'a class that is no result class is refused';
  is_deeply \@CALLED, [], 'result_source_instance of an arbitrary class is not called'
    or diag explain \@CALLED;

  throws_ok { thaw_hook('Not Loaded::Class', 'Artist') } qr/is not a class name/,
    'a name that is no class name is refused';
};

done_testing;
