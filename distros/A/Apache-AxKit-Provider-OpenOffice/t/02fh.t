use Test;
BEGIN { plan tests => 3 }
use Apache::AxKit::Provider::OpenOffice;

$AxKit::Cfg = Fake->new;

my $provider = Apache::AxKit::Provider->new(
    Fake->new,
    key => 'test.sxw',
    );
ok($provider);

my $fh = $provider->get_fh;
ok($fh);

local $/;
my $str = <$fh>;
print $str, "\n";
ok($str, qr/<text:h/, "Test it has a heading in there");

#####################
package Fake;

sub new {
  bless {}, shift;
}

sub ContentProviderClass {
    return "Apache::AxKit::Provider::OpenOffice";
}

sub ExternalEncoding { 'UTF-8' }

sub pnotes {
    return;
}

sub dir_config {
    return;
}

sub path_info {
    return '';
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
