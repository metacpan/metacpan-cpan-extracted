use strict;
use warnings;
use Test::More;
use Plack::Test;
use Test::Requires qw/HTTP::Request::Common/, 'Data::Section::Simple';
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '../../lib');

my $app = do {
    use Amon2::Lite;

    __PACKAGE__->template_options(
        syntax => 'Kolon',
        module => ['Data::Dumper'],
        function => {
            pp => sub { 'pp' . shift },
        },
    );

    get '/' => sub {
        my $c = shift;
        $c->render('hoge', { hoge => 'fuga' });
    };
    get '/dumper' => sub {
        my $c = shift;
        $c->render('dumper');
    };

    __PACKAGE__->to_app();
};

test_psgi($app, sub {
    my $cb = shift;

    {
        my $res = $cb->(GET '/');
        is $res->content, "ppfuga\n\n";
    }

    {
        my $res = $cb->(GET '/dumper');
        like $res->content, qr{VAR1};
    }
});

done_testing;

__DATA__

@@ hoge
<: pp($hoge) :>

@@ dumper
<: Dumper(1) :>
