

# 01basic_file.t,v 1.10 2005/02/20 18:05:00 sherzodr Exp

BEGIN {
    for ( "Storable" ) {
        eval "require $_";
        if ( $@ ) {
            print "1..0 #Skipped: $_ is not available\n";
            exit(0)
        }
    }
}


use File::Spec;
use Class::PObject::Test::Basic;

my $t = new Class::PObject::Test::Basic('file', File::Spec->catfile('data', 'basic', 'file'));
$t->run();




