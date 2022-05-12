use strict;
use warnings;

use FindBin;
use Test::More tests => 3;
use JSON::MaybeXS;

require "$FindBin::Bin/lib/validator.pl";

# TEST 1
# Test validated input equal in both cases (from validate and validated).

my $validator = Validator->new(profile_hash =>
    {
        password     => [ qw(required) ],
        password_cnf => [ qw(required same:password) ],
        role         => [ 'required', 'enum:user,agent' ]
    }
);

package App {
    use Dancer2;

    BEGIN {
        set plugins => {
            FormValidator => {
                session => {
                    namespace => '_form_validator'
                },
            },
        };
    }

    use Dancer2::Plugin::FormValidator;

    post '/' => sub {
        if (my $validated = validate profile => $validator) {
            to_json {
                'validated'          => $validated,
                'validated_from_dsl' => validated,
            };
        }
    };
}

use Plack::Test;
use HTTP::Request::Common;

my $app    = Plack::Test->create(App->to_app);
my $result = $app->request(POST '/', [password => 'pass1', password_cnf => 'pass1', role => 'agent']);

my $content = decode_json $result->content;

is_deeply(
    $content->{validated},
    $content->{validated_from_dsl},
    'Check validated result',
);


# TEST 2
# Test no validated input if validation failed.

package App2 {
    use Dancer2;

    BEGIN {
        set plugins => {
            FormValidator => {
                session => {
                    namespace => '_form_validator'
                },
            },
        };
    }

    use Dancer2::Plugin::FormValidator;

    post '/' => sub {
        if (not validate profile => $validator) {
            to_json validated;
        }
    };
}

$app    = Plack::Test->create(App2->to_app);
$result = $app->request(POST '/', [password => 'pass1', password_cnf => 'pass', role => 'agent']);

is_deeply(
    $result->content,
    '',
    'Check validated result',
);

# TEST 3
# Test no validated input after second call.

package App3 {
    use Dancer2;

    BEGIN {
        set plugins => {
            FormValidator => {
                session => {
                    namespace => '_form_validator'
                },
            },
        };
    }

    use Dancer2::Plugin::FormValidator;

    post '/' => sub {
        if (validate profile => Validator->new) {
            validated;
            to_json validated;
        }
    };
}

$app    = Plack::Test->create(App2->to_app);
$result = $app->request(POST '/', [password => 'pass1', password_cnf => 'pass1', role => 'agent']);

is_deeply(
    $result->content,
    '',
    'Check validated result',
);