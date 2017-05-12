package AuthDigestDotnetTestApp;
use Catalyst qw/
    Authentication
    Cache
/;

our %users;
my $digest_pass = Digest::MD5->new;
$digest_pass->add('Mufasa2:testrealm@host.com:Circle Of Life');
%users = (
        Mufasa  => { pass         => "Circle Of Life",          },
        Mufasa2 => { pass         => $digest_pass->hexdigest, },
);
__PACKAGE__->config(
    cache => {
        backend => {
            class => 'Cache::FileCache',
        },
    },
    authentication => {
        default_realm => 'testrealm@host.com',
        realms => {
            'testrealm@host.com' => {
                store => {
                    class => 'Minimal',
                    users => \%users,
                },
                credential => {
                    class => 'HTTP',
                    type  => 'digest',
                    password_type => 'clear',
                    password_field => 'pass',
                    broken_dotnet_digest_without_query_string => 1,
                },
            },
        },
    },
);
__PACKAGE__->setup;

1;

