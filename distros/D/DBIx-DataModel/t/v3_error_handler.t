use strict;
use warnings;
use SQL::Abstract::Test import => [qw/is_same_sql_bind/];
use DBI;
use DBIx::DataModel;
use Test::More;

my $schema = DBIx::DataModel->Schema('SCH')->Table(Foo => foo => qw/foo_id/);

# default policy : 'if_absent' without previous handler
refresh_dbh();
like error_msg(), qr/\bat\b.*?v3_error_handler.t/,          "'if_absent' (default) without previous handler";

# 'if_absent' policy with previous handler
refresh_dbh(sub {die "Previous handler"});
like error_msg(), qr/Previous/,                             "'if_absent' (default) with previous handler";

# 'none' policy
$schema->handleError_policy('none');
refresh_dbh();
like error_msg(), qr/\bat\b.*?Statement.pm/,                "'none' : no handler installed";

# 'override' policy
$schema->handleError_policy('override');
refresh_dbh(sub {die "Previous handler"});
my $msg = error_msg();
unlike $msg, qr/Previous/,                                  "'override' with previous handler - previous handler not called";
like   $msg, qr/\bat\b.*?v3_error_handler.t/,               "'override' with previous handler - new handler installed";
refresh_dbh();
like error_msg(), qr/\bat\b.*?v3_error_handler.t/,          "'override' without previous handler";

# 'combine' policy
$schema->handleError_policy('combine');
refresh_dbh();
like error_msg(), qr/\bat\b.*?v3_error_handler.t/,          "'combine', no previous handler";
refresh_dbh(sub {die "Previous handler"});
like error_msg(), qr/Previous.*\bat\b.*v3_error_handler.t/, "'combine' with previous handler";

# repeated calls to 'combine'
my $previous_dbh     = $schema->dbh;
my $previous_handler = $previous_dbh->{HandleError};
refresh_dbh();
$schema->dbh($previous_dbh);
is $schema->dbh->{HandleError}, $previous_handler,          "'combine' with previous handler already installed by DBIDM";


done_testing;


sub refresh_dbh  {
  my ($handler) = @_;
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {RaiseError => 1, AutoCommit => 1});
  $dbh->{HandleError} = $handler if $handler;
  $schema->dbh($dbh);
}

sub error_msg {
  eval {$schema->table('Foo')->select(-columns => [qw/Foo Bar/]) };
  my $err = $@;
  # note $err;
  return $err;
}

