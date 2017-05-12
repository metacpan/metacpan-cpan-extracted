use Test::More;
use lib 't/lib';
use NoLang;
use File::Spec::Functions;

my $dir;
BEGIN { $dir = catdir qw( t lib ); }

use lib $dir;
use Acme::MetaSyntactic::test_ams_locale;

plan tests => 1;

# Windows or not, I do not care
unshift @INC, sub {
    my (undef, $file) = @_;

    if ($file eq 'Win32/Locale.pm') {
        my @code = ("0;");
        return sub { $_ = shift @code };
    }
};

$^O   = 'MSWin32';
$meta = Acme::MetaSyntactic::test_ams_locale->new;
is( $meta->lang, 'fr', "Correct default without Win32::Locale" );

