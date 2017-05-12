

# 16basic_db_file.t,v 1.5 2003/09/08 15:24:55 sherzodr Exp

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
use Class::PObject::Test::Basic;
my $t = new Class::PObject::Test::Basic('db_file', File::Spec->catfile('data', 'basic', 'db_file'));
$t->run();
