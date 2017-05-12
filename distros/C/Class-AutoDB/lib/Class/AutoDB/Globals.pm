package Class::AutoDB::Globals;
use strict;
use Class::Singleton;
use vars qw(@ISA);
@ISA = qw(Class::Singleton);
#use base qw(Class::WeakSingleton);
#use DBI;

# A static class (only one instance is maintained, it is "weak") for caching things.

my $OID2OBJ={};
my $OBJ2OID={};
my $DBH;
my $AUTODB;
my $REGISTRY_OID=1;		# object id for registry

sub oid2obj {$OID2OBJ}
sub obj2oid {$OBJ2OID}
sub dbh {@_>1? $DBH=$_[1]: $DBH;}
sub autodb {@_>1? $AUTODB=$_[1]: $AUTODB;}
sub registry_oid {$REGISTRY_OID}

1;

