use Test::More tests => 11;

BEGIN {
use_ok( 'Data::ICal::DateTime' );
}

diag( "Testing Data::ICal::DateTime $Data::ICal::DateTime::VERSION" );

# check the import stuff
ok(Data::ICal->can('events'),"Events");
for (qw(start end duration summary description recurrence explode is_in _normalise)) {
    ok(Data::ICal::Entry::Event->can($_),"Can $_");
}


