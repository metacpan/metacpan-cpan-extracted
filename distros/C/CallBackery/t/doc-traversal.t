use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use CallBackeryTest qw(setupTestConfig);
use File::Temp qw(tempdir);
use File::Spec;

setupTestConfig();

my $t = Test::Mojo->new('CallBackery');

# A file outside @INC that the server process can read and that carries POD.
# Stands in for anything sensitive on the host, e.g. a config file whose
# comment block happens to start with a POD directive.
my $dir = tempdir(CLEANUP => 1);
my $secret = File::Spec->catfile($dir, 'secret.conf');
open my $fh, '>', $secret or die "cannot write $secret: $!";
print $fh "=pod\n\n  db_password = TRAVERSAL_CANARY\n";
close $fh;

# Pod::Simple::Search->find splits the requested name on '::' and rejoins the
# pieces with File::Spec->catfile, so '::' acts as a path separator that never
# looks like traversal to a browser, router or reverse proxy.
my @parts = grep { length } File::Spec->splitdir($secret);
my $traversal = ('..::' x 40) . join('::', @parts);

subtest 'path traversal via :: separated document name is rejected' => sub {
    $t->get_ok("/doc/$traversal")
      ->status_isnt(200, 'traversal request is not served');
    unlike($t->tx->res->body, qr/TRAVERSAL_CANARY/,
        'contents of a file outside @INC are not disclosed');
};

subtest 'rejected document name is not reflected back to the client' => sub {
    my $marker = '..::..::etc::REFLECTED_CANARY';
    $t->get_ok("/doc/$marker")
      ->status_is(404);
    unlike($t->tx->res->headers->location // '', qr/REFLECTED_CANARY/,
        'rejected name absent from Location header');

    # The body is Mojolicious' own 404 page. In development it echoes the
    # request path for every unmatched route, HTML escaped; in production it
    # is a static page that echoes nothing.
    my $prod = Test::Mojo->new('CallBackery');
    $prod->app->mode('production');
    $prod->get_ok("/doc/$marker")
         ->status_is(404)
         ->content_unlike(qr/REFLECTED_CANARY/,
             'rejected name absent from production 404 body');

    $t->get_ok('/doc/x"<script>alert(1)</script>')
      ->content_unlike(qr{<script>alert}, 'rejected name is not injectable');
};

subtest 'legitimate module documentation still renders' => sub {
    $t->get_ok('/doc')
      ->status_is(200)
      ->content_like(qr/CallBackery::Index/);

    $t->get_ok('/doc/CallBackery::Plugin::Doc')
      ->status_is(200)
      ->content_like(qr/Documentation Plugin/);

    # slash notation is the documented way to write '::' in a URL
    $t->get_ok('/doc/CallBackery/Plugin/Doc')
      ->status_is(200)
      ->content_like(qr/Documentation Plugin/);
};

done_testing();
