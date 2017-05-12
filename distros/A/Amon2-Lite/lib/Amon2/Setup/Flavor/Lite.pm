use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::Lite;
use parent qw(Amon2::Setup::Flavor);

sub run {
    my ($self) = @_;

    require Amon2::Lite;
    require Amon2;

    $self->{amon2_version}      = $Amon2::VERSION;
    $self->{amon2_lite_version} = $Amon2::Lite::VERSION;

    $self->write_file('app.psgi', <<'...');
use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Amon2::Lite;

our $VERSION = '0.13';

# put your configuration here
sub load_config {
    my $c = shift;

    my $mode = $c->mode_name || 'development';

    +{
        'DBI' => [
            "dbi:SQLite:dbname=$mode.db",
            '',
            '',
        ],
    }
}

get '/' => sub {
    my $c = shift;
    return $c->render('index.tt');
};

# load plugins
__PACKAGE__->load_plugin('Web::CSRFDefender' => {
    post_only => 1,
});
# __PACKAGE__->load_plugin('DBI');
# __PACKAGE__->load_plugin('Web::FillInFormLite');
# __PACKAGE__->load_plugin('Web::JSON');

__PACKAGE__->enable_session();

__PACKAGE__->to_app(handle_static => 1);

__DATA__

@@ index.tt
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title><% $module %></title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
    <script type="text/javascript" src="[% uri_for('/static/js/main.js') %]"></script>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
    <link rel="stylesheet" href="[% uri_for('/static/css/main.css') %]">
</head>
<body>
    <div class="container">
        <header><h1><% $module %></h1></header>
        <section class="row">
            This is a <% $module %>
        </section>
        <footer>Powered by <a href="http://amon.64p.org/">Amon2::Lite</a></footer>
    </div>
</body>
</html>

@@ /static/js/main.js

@@ /static/css/main.css
footer {
    text-align: right;
}
...

    $self->write_file('Makefile.PL', <<'...');
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => '<% $module %>',
    AUTHOR        => 'Some Person <person@example.com>',
    VERSION_FROM  => 'app.psgi',
    PREREQ_PM     => {
        'Amon2'                           => '<% $amon2_version %>',
        'Amon2::Lite'                     => '<% $amon2_lite_version %>',
        'Text::Xslate'                    => '1.5006',
        'Plack::Session'                  => '0.14',
    },
    MIN_PERL_VERSION => '5.008001',
    (-d 'xt' and $ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING}) ? (
        test => {
            TESTS => 't/*.t xt/*.t',
        },
    ) : (),
);
...

    $self->write_file('t/Util.pm', <<'...');
package t::Util;
BEGIN {
    unless ($ENV{PLACK_ENV}) {
        $ENV{PLACK_ENV} = 'test';
    }
}
use parent qw/Exporter/;
use Test::More 0.96;

our @EXPORT = qw//;

{
    # utf8 hack.
    binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;
    no warnings 'redefine';
    my $code = \&Test::Builder::child;
    *Test::Builder::child = sub {
        my $builder = $code->(@_);
        binmode $builder->output,         ":utf8";
        binmode $builder->failure_output, ":utf8";
        binmode $builder->todo_output,    ":utf8";
        return $builder;
    };
}

1;
...

    $self->write_file('t/01_root.t', <<'...');
use strict;
use warnings;
use utf8;
use t::Util;
use Plack::Test;
use Plack::Util;
use Test::More;

my $app = Plack::Util::load_psgi 'app.psgi';
test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/');
        my $res = $cb->($req);
        is $res->code, 200;
        diag $res->content if $res->code != 200;
    };

done_testing;
...

    $self->write_file('xt/03_pod.t', <<'...');
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
...

    $self->write_file('.gitignore', <<'...');
Makefile
inc/
MANIFEST
*.bak
*.old
nytprof.out
nytprof/
*.db
blib/
pm_to_blib
META.json
META.yml
MYMETA.json
MYMETA.yml
...
}

1;
__END__

=head1 NAME

Amon2::Setup::Flavor::Lite - Amon2::Lite flavor

=head1 SYNOPSIS

    % amon2-setup.pl --flavor=Lite MyApp

=head1 DESCRIPTION

This is a flavor for project using Amon2::Lite.

=head1 AUTHOR

Tokuhiro Matsuno
