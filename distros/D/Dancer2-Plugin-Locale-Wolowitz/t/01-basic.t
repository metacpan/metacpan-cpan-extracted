use strict;
use warnings;

use HTTP::Request::Common;
use Plack::Test;
use Test::More 0.96 import => ['!pass'];

{
    package App;
    use Dancer2;
    use Dancer2::Plugin::Locale::Wolowitz;

    set confdir  => '.';
    set template=> 'template_toolkit';
    set engines => {
        session => 'Simple',
    };
    set plugins  => {
        'Locale::Wolowitz' => {
            fallback  => "en",
            lang_available => [ qw( en fr ) ],
        }
    };

    hook 'before_template_render' => sub {
        my $tokens = shift;
    };

    get '/' => sub {
        session lang => param('lang');
        my $tr = loc('welcome');
        return $tr;
    };

    get '/tmpl' => sub {
        template 'index', {}, { layout => undef };
    };

    get '/no_key' => sub {
        my $tr = loc('hello');
        return $tr;
    };

    get '/tmpl/no_key' => sub {
        template 'no_key';
    };

    get '/appdir' => sub {
        return setting('appdir');
    };

    get '/complex_key' => sub {
        my $tr = loc('path_not_found %1', [setting('appdir')]);
        return $tr;
    };

    get '/tmpl/complex_key' => sub {
        template 'complex_key', { appdir => setting('appdir') };
    };
    
    get '/force_lang' => sub {
        my $tr = loc('welcome', undef, 'en');
        return $tr;
    };
    
    get '/tmpl/force_lang' => sub {
        template 'force_lang'
    };

    true;
}

my $test = Plack::Test->create( App->to_app );

my $res = $test->request(GET "/?lang=en");
is $res->content, 'Welcome', 'check simple key english';

my $cookie = $res->{_headers}{'set-cookie'};
   $cookie =~ s/;.*$//;

$res = $test->request(GET "/tmpl", Cookie => $cookie);
is $res->content, 'Welcome', 'check simple key english (tmpl)';

$res = $test->request(GET "/no_key", Cookie => $cookie);
is $res->content, 'hello', 'check no key found english';

$res = $test->request(GET "/tmpl/no_key", Cookie => $cookie);
is $res->content, 'hello', 'check no key found english (tmpl)';

$res = $test->request(GET "/appdir", Cookie => $cookie);
my $path = $res->content;

$res = $test->request(GET '/complex_key', Cookie => $cookie);
is $res->content,  "$path not found", 'check complex key english';

$res = $test->request(GET '/tmpl/complex_key', Cookie => $cookie);
is $res->content,  "$path not found", 'check complex key english (tmpl)';

# and now for something completely different
$res = $test->request(GET "/?lang=fr", Cookie => $cookie);
is $res->content, 'Bienvenue', 'check simple key french';

$res = $test->request(GET "/tmpl", Cookie => $cookie);
is $res->content, 'Bienvenue', 'check simple key french (tmpl)';

$res = $test->request(GET "/no_key", Cookie => $cookie);
is $res->content, 'hello', 'check no key found french';

$res = $test->request(GET "/tmpl/no_key", Cookie => $cookie);
is $res->content, 'hello', 'check no key found french (tmpl)';

$res = $test->request(GET '/complex_key', Cookie => $cookie);
is $res->content,  "Repertoire $path non trouve", 'check complex key french';

$res = $test->request(GET '/tmpl/complex_key', Cookie => $cookie);
is $res->content,  "Repertoire $path non trouve", 'check complex key french (tmpl)';

# and test allowed langs
$res = $test->request(GET '/tmpl', 'Accept-Language' => "it,de;q=0.8,es;q=0.5");
is $res->content, 'Welcome', 'check simple key english (fallback)';

$res = $test->request(GET '/tmpl', 'Accept-Language' => "it,de;q=0.8,es;q=0.5,fr;0.2");
is $res->content, 'Bienvenue', 'check simple key french (accept-language)';

$res = $test->request(GET '/force_lang', 'Accept-Language' => "it,de;q=0.8,es;q=0.5,fr;0.2");
is $res->content, 'Welcome', 'check simple key force English';

$res = $test->request(GET '/tmpl/force_lang', 'Accept-Language' => "it,de;q=0.8,es;q=0.5,fr;0.2");
is $res->content, 'Welcome', 'check simple key force English';

done_testing;

