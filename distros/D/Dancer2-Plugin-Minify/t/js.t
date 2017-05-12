#!perl -T

use Test::Most import => ['!pass'];
use Plack::Test;
use HTTP::Request::Common;

{

    package Minifytest;
    use Dancer2;
    use Dancer2::Plugin::Minify;

    get '/' => sub {
        minify(js => <<'END');
/* this is a comment to be removed */
(function(){
    var upper_limit = 10;
    for (var counter = 0; counter < upper_limit; counter++) {
        print(counter * counter); // print square
    }
})();
END
    };

}

my $PT = Plack::Test->create( Minifytest->to_app );

#plan tests => 5;
my $R = $PT->request( GET '/' );
ok $R->is_success;
my $js = $R->content;
note $js;
unlike $js, qr{\n}, 'newlines removed';
unlike $js, qr{/\*.*\*/}s, 'multi-line comments removed';
unlike $js, qr{//.*\n}s, 'single-line comments removed';
unlike $js, qr{upper_limit|counter}s, 'variables obfuscated';
done_testing;
