

# 63types_db_file.t,v 1.3 2003/09/09 00:12:02 sherzodr Exp

BEGIN {
    for ( "DB_File", "Storable" ) {
        eval "require $_";
        if ( $@ ) {
            print "1..0 #Skipped: $_ is not available\n";
            exit(0)
        }
    }
}

use File::Spec;
use Class::PObject::Test::Types;
my $t = new Class::PObject::Test::Types('db_file', File::Spec->catfile('data', 'types', 'db_file'));
$t->run();
