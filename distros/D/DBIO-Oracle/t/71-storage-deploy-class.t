use strict;
use warnings;
use Test::More;

use DBIO::Storage::DBI;
use DBIO::Oracle::Storage;

# OFFLINE. Core ADR 0064: the storage names its deploy class in
# dbio_deploy_class and has no install route of its own (karr k56).
#
# CLAIM: DBIO::Oracle::Storage defines neither deploy nor
# deployment_statements -- both are core's. The old deployment_statements
# override fed the oracle_version into a SQL::Translator producer, a second
# install route beside DBIO::Oracle::Deploy; with it gone, $schema->deploy
# runs through the class dbio_deploy_class names and only that.

{
  no strict 'refs';
  for my $method (qw( deploy deployment_statements )) {
    ok !defined &{"DBIO::Oracle::Storage::$method"},
      "DBIO::Oracle::Storage defines no $method of its own";
    is(DBIO::Oracle::Storage->can($method), DBIO::Storage::DBI->can($method),
      "... \$storage->$method is DBIO::Storage::DBI's");
  }
}

is(DBIO::Oracle::Storage->dbio_deploy_class, 'DBIO::Oracle::Deploy',
  'the storage names DBIO::Oracle::Deploy as its deploy class');

# $storage->deploy installs through the named class and nothing else.
{
  package T71::Deploy;
  our @installed;
  sub new { my ($c, %a) = @_; bless {%a}, $c }
  sub install { push @installed, $_[0]{schema}; 1 }
}
$INC{'T71/Deploy.pm'} = __FILE__;

{
  package T71::Result::Widget;
  use base 'DBIO::Core';
  __PACKAGE__->table('widget');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');

  package T71::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::Oracle::Storage');
  __PACKAGE__->register_class(Widget => 'T71::Result::Widget');
}

{
  no warnings qw(redefine once);
  local *DBIO::Oracle::Storage::dbio_deploy_class = sub { 'T71::Deploy' };
  local *DBIO::Oracle::Storage::ensure_connected = sub { 1 };

  my $schema = T71::Schema->connect('dbi:Oracle:orcl', 'u', 'p');
  ok eval { $schema->storage->deploy($schema); 1 }, '$storage->deploy lives' or diag $@;
  is_deeply \@T71::Deploy::installed, [ $schema ],
    '... and the class the storage names was handed the schema, once';
}

done_testing;
