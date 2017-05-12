#!perl -T

use Test::Most import => ['!pass'];
use Plack::Test;
use HTTP::Request::Common;

{

    package Minifytest;
    use Dancer2;
    use Dancer2::Plugin::Minify;

    get '/' => sub {
        minify(html => <<'END');
<html>
    <!-- this is a comment to be removed -->
    <body>
        <p>
            Hey!
        </p>
        <img/>
    </body>
</html>
END
    };

}

my $PT = Plack::Test->create( Minifytest->to_app );

#plan tests => 5;
my $R = $PT->request( GET '/' );
ok $R->is_success;
my $html = $R->content;
note $html;
unlike $html, qr{\n}, 'newlines removed';
unlike $html, qr{<!--.*-->}s, 'comments removed';
unlike $html, qr{<img/>}s, 'closing slashes removed';
done_testing;
