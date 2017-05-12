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

    get '/' => sub {
        choose_variant(
            var1 => {
                Quality  => 1.000,
                Type     => 'text/html',
                Charset  => 'iso-8859-1',
                Language => 'en'
            },
            var2 => {
                Quality  => 0.950,
                Type     => 'text/plain',
                Charset  => 'us-ascii',
                Language => 'no'
            },
        );
    };

}

my $PT = Plack::Test->create( Webservice->to_app );

plan tests => 2;

subtest var1 => sub {
    plan tests => 2;
    my $R = $PT->request( GET('/') );
    ok $R->is_success;
    islc $R->content => 'var1';
};

subtest var2 => sub {
    plan tests => 2;
    my $R = $PT->request( GET( '/', Accept => 'text/plain' ) );
    ok $R->is_success;
    islc $R->content => 'var2';
};

done_testing;
