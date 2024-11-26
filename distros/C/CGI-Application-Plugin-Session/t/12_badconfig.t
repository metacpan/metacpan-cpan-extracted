use lib './t';
use Test::More;
BEGIN {
    eval { require Test::Exception; Test::Exception->import; };
    if ( $@ ) {
        plan skip_all => 'These tests require Test::Exception';
    }
    else {
         plan tests => 3;
    }
};

{
    package TestAppBadConfig;
    @TestAppBadConfig::ISA = qw(CGI::Application);
    use CGI::Application::Plugin::Session;
};

my $app = TestAppBadConfig->new();
$app->session_config( CGI_SESSION_OPTIONS => [ "driver:invalid_driver", $app->query ] );

dies_ok(sub { $app->session }, 'creation of CGI::Session object fails with a bad config');

## sub our own testing warn handler
my $warning;
$SIG{'__WARN__'} = sub { $warning = join ' ', @_ };

## mismatch cookie name and session name
my $app2 = TestAppBadConfig->new();
$app2->session_config(
    CGI_SESSION_OPTIONS => [
        "driver:File", '1111', {}, { name => 'foobar' }
    ],
    COOKIE_PARAMS => { -name => 'monkeybeard' }
);

## should generate warning
$app2->session;

ok $warning, "cookie and session name don't match";
like $warning, qr/Cookie.*?Session/;

1;
