

# 65types_sqlite.t,v 1.4 2003/09/09 08:46:38 sherzodr Exp

BEGIN {
    for ( "DBD::SQLite" ) {
        eval "require $_";
        if ( $@ ) {
            print "1..0 #Skipped: $_ is not available\n";
            exit(0)
        }
    }
}

require File::Spec;
my $db = File::Spec->catfile('data', 'types', 'sqlite');



use Class::PObject::Test::Types;
my $t = new Class::PObject::Test::Types('sqlite', $db);
$t->run()

