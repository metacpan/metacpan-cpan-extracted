use Test::Most tests => 2;
use Dancer::Test;
use Test::Easy qw(resub);

my $class = 'Dancer::Plugin::Swig';

use_ok $class;

sub update_swig {
  my ($key, $val) = @_;

  my $plugins = Dancer::Config::setting('plugins');
  $plugins->{Swig}{$key} = $val;
  set plugins => $plugins;

  Dancer::Plugin::Swig->reinitialize; # pick up change to $plugins
}

subtest "verify that render calls client render method" => sub {
  plan tests => 3;

  my $swig_client_render_rs = resub 'WebService::SwigClient::render' => sub {
    return '<html>foo</html>';
  };

  update_swig(service_url => 'http://somewhere.on.my.local.network');

  my $html;
  lives_ok { $html = render('test.html') } 'verify that a standard render works';
  ok $swig_client_render_rs->called;
  like $html, qr/foo/;

};


