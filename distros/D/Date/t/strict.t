use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Test::Exception;
use lib 't/lib'; use MyTest;

my $err1 = Date::Error::parser_error;
my $err2 = Date::Error::out_of_range;

subtest 'without strict' => sub {
    my $d = Date->new("epta");
    is $d->error, Date::Error::parser_error;
    my $r = Date::Rel->new("1D - 1s");
    is $r->error, Date::Error::parser_error;
};

subtest 'use strict' => sub {
    use Date::strict;
    my $d = Date::now();
    my $r = Date::Rel->new;
    
    subtest 'date' => sub {
        throws_ok { date("epta") } $err1;
        throws_ok { Date->new("epta") } $err1;
        throws_ok { $d->set("epta") } $err1;
        throws_ok { $d > "nah" } $err1;
    };
    
    subtest 'relative date' => sub {
        throws_ok { rdate("1D - 1s") } $err1;
        throws_ok { Date::Rel->new("1D - 1s") } $err1;
        throws_ok { $r->set("1D - 1s") } $err1;
        throws_ok { $d - "1D - 1s" } $err1;
        throws_ok { $d + "1D - 1s" } $err1;
    };
};

subtest 'use strict with range checking' => sub {
    use Date::strict;
    Date::range_check(1);
    my $d = Date::now();
    
    throws_ok { date("2019-01-32") } $err2;
    throws_ok { Date->new("2019-01-32") } $err2;
    throws_ok { $d->set("2019-01-32") } $err2;
    throws_ok { date_ymd(2019, 1, 32) } $err2;
    throws_ok { Date->new_ymd(2019, 1, 32) } $err2;
    throws_ok { $d->set_ymd(2019, 1, 32) } $err2;
    throws_ok { $d->clone(-1, -1, 32) } $err2;
    throws_ok { $d > "2019-01-32" } $err2;
    
    Date::range_check(0);
};

subtest 'use strict - no strict' => sub {
    my $d = date("epta");
    is $d->error, Date::Error::parser_error;
    
    use Date::strict;
    
    throws_ok { date("epta") } $err1;
    
    no Date::strict;
    
    $d = date("epta");
    is $d->error, Date::Error::parser_error;
    
    {
        use Date::strict;
        throws_ok { date("epta") } $err1;
    }

    $d = date("epta");
    is $d->error, Date::Error::parser_error;
};

sub create_invalid_date {
    my $d = date("epta");
    is $d->error, Date::Error::parser_error;
}

subtest 'use strict does not affect foreign scopes' => sub {
    use Date::strict;
    create_invalid_date();
    pass("did not die");
};

done_testing();
