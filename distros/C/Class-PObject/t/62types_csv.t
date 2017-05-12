

# 62types_csv.t,v 1.4 2004/05/20 06:41:53 sherzodr Exp

BEGIN {
    for ( "DBI", "DBD::CSV", "SQL::Statement" ) {
        eval "require $_";
        if ( $@ ) {
            print "1..0 #Skipped: $_ is not installed\n";
            exit(0)
        }
    }
    if ( $SQL::Statement::VERSION < 1.005 ) {
        print "1..0 #Skipped: SQL::Statement 1.005 is required. Your version is $SQL::Statement::VERSION\n";
        exit(0)
    }
}

require File::Spec;
require Class::PObject::Test::Types;

my $t = new Class::PObject::Test::Types('csv', {Dir=>File::Spec->catfile('data', 'types', 'csv')});
$t->run();

