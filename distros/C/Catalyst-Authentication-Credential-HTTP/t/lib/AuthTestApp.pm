package AuthTestApp;
use Catalyst qw/
    Authentication
/;
our %users;
__PACKAGE__->config(
    'Plugin::Authentication' => {
        default_realm => 'test',
        test => {
            store => {
                class => 'Minimal',
                users => \%users,
            },
            credential => {
                class => 'HTTP',
                type  => 'basic',
                password_type => 'clear',
                password_field => 'password'
            },
        },
    },
);
%users = (
    foo => { password         => "s3cr3t", },
);
__PACKAGE__->setup;

1;

