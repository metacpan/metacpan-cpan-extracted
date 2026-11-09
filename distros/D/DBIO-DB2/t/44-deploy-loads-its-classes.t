use strict;
use warnings;

use Test::More;

# OFFLINE (karr k40). DBIO::DB2::Deploy names three classes through the hooks
# of DBIO::Deploy::Base -- _ddl_class, _introspect_class, _diff_class -- and
# the base calls a method on whatever they answer without loading it:
#
#   _ddl_class->install_ddl($schema)      install, and the compare deploy
#   _introspect_class->new(dbh => ...)    both sides of a diff
#   _diff_class->new(source => ...)       the diff itself
#
# So the module that names them has to have loaded them. It loaded only the
# DDL class, and
#
#   use DBIO::DB2::Deploy;
#   DBIO::DB2::Deploy->new(schema => $schema)->diff;
#
# died live with: Can't locate object method "new" via package
# "DBIO::DB2::Introspect" (perhaps you forgot to load
# "DBIO::DB2::Introspect"?) -- unless the caller happened to have loaded the
# two classes itself, which t/11-db2-fk.t does (it uses them directly) and
# t/00-load.t does for every module at once. Neither is what an application
# does: it gets the deploy class from the storage (dbio_deploy_class) and
# loads that.
#
# THIS FILE MUST LOAD NOTHING OF THIS DISTRIBUTION BUT DBIO::DB2::Deploy.
# It is its own process, so what is loaded at the first assertion is what
# that one module brought with it; a second "use DBIO::DB2::..." up here
# turns every assertion below green without the deploy class doing anything.

use DBIO::DB2::Deploy;

# The method DBIO::Deploy::Base calls on each hook's answer.
my %CALLED = (
  _ddl_class        => 'install_ddl',
  _introspect_class => 'new',
  _diff_class       => 'new',
);

for my $hook (sort keys %CALLED) {
  my $class = DBIO::DB2::Deploy->$hook;

  ok $class->can($CALLED{$hook}),
    "loading DBIO::DB2::Deploy alone, $hook ($class) answers "
  . "$CALLED{$hook} -- the call DBIO::Deploy::Base makes on it";
}

done_testing;
