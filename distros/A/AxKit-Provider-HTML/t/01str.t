use Test;
BEGIN { plan tests => 3 }
use AxKit::Provider::HTML;

$AxKit::Cfg = Fake->new;

my $provider = Apache::AxKit::Provider->new(
    Fake->new,
    key => 'test.html',
    );
ok($provider);

my $str = $provider->get_strref;
ok($str);

print $$str;
ok($$str, qr/&lt;matt\@sergeant.org&gt;/, "Test it has my email in there");

#####################
package Fake;

sub new {
  bless {}, shift;
}

sub ContentProviderClass {
    return "AxKit::Provider::HTML";
}

sub StackTrace { 1 }

sub pnotes {
    return;
}

sub dir_config {
    return;
}

sub Apache::Request::new {
    return Fake->new;
}

sub AxKit::Debug {
}

sub AxKit::reconsecrate {
    my ($object, $class) = @_;

    bless $object, $class;
}