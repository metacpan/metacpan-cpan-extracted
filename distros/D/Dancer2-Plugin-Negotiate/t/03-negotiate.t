#!perl -T

use Test::Most import => ['!pass'];
use Plack::Test;
use HTTP::Request::Common;

sub islc   { is lc(shift),   lc(shift), shift; }
sub isntlc { isnt lc(shift), lc(shift), shift; }

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::Negotiate;

    set plugins => {
        Negotiate => {
            languages => [qw[ de en ]],
        },
    };

    get '/' => sub {
        template negotiate 'index';
    };

}

my $PT = Plack::Test->create( Webservice->to_app );

plan tests => 3;

subtest C => sub {
    plan tests => 2;
    my $R = $PT->request( GET('/') );
    ok $R->is_success;
    islc $R->content => 'C';
};

subtest EN => sub {
    plan tests => 3;
    my $R = $PT->request( GET( '/', 'Accept-Language' => 'en' ) );
    ok $R->is_success;
    islc $R->header( lc 'Content-Language' ) => 'en';
    islc $R->content                         => 'EN';
};

subtest DE => sub {
    plan tests => 3;
    my $R = $PT->request( GET( '/', 'Accept-Language' => 'de' ) );
    ok $R->is_success;
    islc $R->header( lc 'Content-Language' ) => 'de';
    islc $R->content                         => 'DE';
};

done_testing;
