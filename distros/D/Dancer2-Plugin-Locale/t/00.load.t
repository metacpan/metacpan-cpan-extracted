use Test::More tests => 19;    ## TODO: SOOOOO many more tests
our @warns;

use Plack::Test;
use HTTP::Request::Common;
use File::Path::Tiny ();

diag("Testing Dancer2::Plugin::Locale $Dancer2::Plugin::Locale::VERSION");

package YourDancerApp;
{
    use Dancer2;

    BEGIN {
        $SIG{__WARN__} = sub { push @warns, @_ }
    }
    use Dancer2::Plugin::Locale;

    sub _write_file {
        my ( $path, @cont ) = @_;
        if ( open my $fh, '> :encoding(UTF-8)', $path ) {
            print {$fh} @cont;
            close $fh;
        }
        else {
            die "Could not open $path: $!\n";
        }
    }

    set template => "template_toolkit";
    File::Path::Tiny::rm( config->{appdir} . '/views' );
    File::Path::Tiny::mk( config->{appdir} . '/views/tt' );
    _write_file( config->{appdir} . '/views/tt.tt',       "[% locale.maketext('Hello World') %]" );
    _write_file( config->{appdir} . '/views/tt/tag.tt',   "[% locale.get_language_tag() %]" );
    _write_file( config->{appdir} . '/views/tt/noarg.tt', "[% locale() %]" );
    _write_file( config->{appdir} . '/views/tt/argfr.tt', "[% locale('fr') %]" );

    File::Path::Tiny::rm( config->{appdir} . '/locale' );
    File::Path::Tiny::mk( config->{appdir} . '/locale' );
    File::Path::Tiny::mk( config->{appdir} . '/locale/ru.json' );
    _write_file( config->{appdir} . '/locale/fr.json',    '{"Hello World™":"Bonjour Monde™"}' );
    _write_file( config->{appdir} . '/locale/es.what',    '{"Hello World™":"Hola Mundo™"}' );
    _write_file( config->{appdir} . '/locale/ar.json',    '' );
    _write_file( config->{appdir} . '/locale/zh.json',    '{"Hello World™":' );
    _write_file( config->{appdir} . '/locale/pt-BR.what', '{"Hello World™":"Olá Mundo™"}' );
    _write_file( config->{appdir} . '/locale/en-GB.json', '{"Hello World™":"’elo Guvna"}' );

    get '/' => sub {
        return locale->maketext('Hello World');
    };

    get '/tag' => sub {
        return locale->get_language_tag;
    };

    get '/isa' => sub {
        return locale->isa('Locale::Maketext::Utils') ? "yes" : "no";
    };

    get '/reuse' => sub {
        return locale() eq locale() ? "yes" : "no";
    };

    get '/multiton' => sub {
        return locale("fr") ne locale() ? "yes" : "no";
    };

    get '/tt' => sub {
        return template 'tt';
    };

    get '/tt/tag' => sub {
        return template 'tt/tag';
    };

    get '/tt/reuse' => sub {
        return template('tt/noarg') eq template('tt/noarg') ? "yes" : "no";
    };

    get '/tt/multiton' => sub {
        return template('tt/argfr') ne template('tt/noarg') ? "yes" : "no";
    };

    get '/lex/good' => sub {
        return locale("fr")->maketext('Hello World™');
    };

    get '/lex/not_json_ext' => sub {
        return locale("es")->maketext('Hello World™');
    };

    get '/lex/empty' => sub {
        return locale("ar")->maketext('Hello World™');
    };

    get '/lex/badjson' => sub {
        return locale("zh")->maketext('Hello World™');
    };

    get '/lex/nonnormalizedtag' => sub {
        return locale("pt_br")->maketext('Hello World™');
    };

    get '/lex/dir' => sub {
        return locale("ru")->maketext('Hello World™');
    };
}

package main;

my $app  = YourDancerApp->to_app;
my $test = Plack::Test->create($app);

ok( grep( m/Skipping non-file lexicon \(ru\.json\)/,                        @warns ), "non-file lexicon gets a warning" );
ok( grep( m/Ignoring lexicon, .*zh\.json, since it containes invalid JSON/, @warns ), "bad JSON lexicon gets a warning" );
ok( grep( m/Skipping un-normalized locale named lexicon \(en-GB\.json\)/,   @warns ), "un-normalized locale lexicon gets a warning" );
ok( @warns == 3, "no unexpected warnings" ) or diag( explain( \@warns ) );

my $res = $test->request( GET '/' );
like( $res->content, qr/Hello World/, 'locale() works in code' );

$res = $test->request( GET '/tag' );
like( $res->content, qr/en/, 'locale() defaults to en in code' );

$res = $test->request( GET '/isa' );
like( $res->content, qr/yes/, 'locale() based on expected class in code' );

$res = $test->request( GET '/reuse' );
like( $res->content, qr/yes/, 'locale() object is reused in code' );

$res = $test->request( GET '/multiton' );
like( $res->content, qr/yes/, 'locale() object is multiton in code' );

$res = $test->request( GET '/tt' );
like( $res->content, qr/Hello World/, 'locale() works in template' );

$res = $test->request( GET '/tt/tag' );
like( $res->content, qr/en/, 'locale() defaults to en in template' );

$res = $test->request( GET '/tt/reuse' );
like( $res->content, qr/yes/, 'locale() object is reused in template' );

$res = $test->request( GET '/tt/multiton' );
like( $res->content, qr/yes/, 'locale() object is multiton in template' );

$res = $test->request( GET '/lex/good' );
is( $res->content, "Bonjour Monde™", 'lex: valid .json is used' );

$res = $test->request( GET '/lex/not_json_ext' );
is( $res->content, "Hello World™", 'lex: non-.json ignored' );

$res = $test->request( GET '/lex/empty' );
is( $res->content, "Hello World™", 'lex: empty is no-op' );

$res = $test->request( GET '/lex/badjson' );
is( $res->content, "Hello World™", 'lex: badjson is no-op' );

$res = $test->request( GET '/lex/nonnormalizedtag' );
is( $res->content, "Hello World™", 'lex: non-normalized tag is no-op' );

$res = $test->request( GET '/lex/dir' );
is( $res->content, "Hello World™", 'lex: dir is no-op' );
