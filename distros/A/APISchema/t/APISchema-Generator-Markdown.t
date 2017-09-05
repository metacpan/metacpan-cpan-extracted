package t::APISchema::Generator::Markdown;
use t::test;
use t::test::fixtures;
use utf8;

use APISchema::DSL;

sub _require : Test(startup => 1) {
    my ($self) = @_;

    use_ok 'APISchema::Generator::Markdown';
}

sub instantiate : Tests {
    my $generator = APISchema::Generator::Markdown->new;
    isa_ok $generator, 'APISchema::Generator::Markdown';
}

sub generate : Tests {
    subtest 'Simple' => sub {
        my $schema = t::test::fixtures::prepare_bmi;

        my $generator = APISchema::Generator::Markdown->new;
        my $markdown = $generator->format_schema($schema);

        like $markdown, qr{# BMI API};
        like $markdown, qr{^\Q    - [BMI API](#route-BMI%20API) - `POST` /bmi\E$}m;
        like $markdown, qr!{"height":1.6,"weight":50}!;
        like $markdown, qr!|`.` |`object` | | |`required["value"]` |Body mass index |!;
        like $markdown, qr!|`.height` |`number` | |`1.6` | |Height(m) |!;
    };

    subtest 'Complex' => sub {
        my $schema = t::test::fixtures::prepare_family;

        my $generator = APISchema::Generator::Markdown->new;
        my $markdown = $generator->format_schema($schema);

        like $markdown, qr{# Family API};
        like $markdown, qr!GET /person[?]name=Alice!;
        like $markdown, qr!{"message":"OK","status":"success"}!;
        like $markdown, qr![{"age":16,"name":"Alice"},{"age":14,"name":"Charlie"}]!;
        my $text1 = <<EOS;
|`.` |`array` | |`[{"age":16,"name":"Alice"},{"age":14,"name":"Charlie"}]` | |Some people |
|`.[]` |[`person`](#resource-person) | | | |A person |
EOS
        like $markdown, qr!\Q$text1\E!;
        like $markdown, qr!|`.\[\]` |[`person`](#resource-person) | | | | |!;
        my $text2 = <<EOS;
200 OK
[{"age":16,"name":"Alice"},{"age":14,"name":"Charlie"}]
EOS
        like $markdown, qr!\Q$text2\E!;
    };

    subtest 'Status switch' => sub {
        my $schema = t::test::fixtures::prepare_status;

        my $generator = APISchema::Generator::Markdown->new;
        my $markdown = $generator->format_schema($schema);
        like $markdown, qr{#### Response `200 OK`};
        like $markdown, qr{\nHTTP/1.1 200 OK\nSucceeded!\n};
        like $markdown, qr{#### Response `400 Bad Request`};
    };

    subtest 'example with no containers' => sub {
        my $schema = APISchema::DSL::process {
          resource gender => {
            enum => ['male', 'female', 'other'],
            example => 'other',
          };
        };

        my $generator = APISchema::Generator::Markdown->new;
        my $markdown = $generator->format_schema($schema);

        like $markdown, qr/^"other"$/m;
    };

    subtest 'FETCH endpoint' => sub {
        my $schema = APISchema::DSL::process {
            FETCH '/' => {
                title => 'Fetch',
                destination => {},
            };
        };

        my $generator = APISchema::Generator::Markdown->new;
        my $markdown = $generator->format_schema($schema);

        like $markdown, qr{\Q- [Fetch](#route-Fetch) - `GET`, `HEAD` /\E}, 'FETCH expanded to GET and HEAD';
    };
}

sub generate_utf8 : Tests {
    subtest 'Simple' => sub {
        my $schema = t::test::fixtures::prepare_user;

        my $generator = APISchema::Generator::Markdown->new;
        my $markdown = $generator->format_schema($schema);

        like $markdown, qr!{\n   "first_name" : "小飼",\n   "last_name" : "弾"\n}!;
        like $markdown, qr!\Q|`.last_name` |`string` | |`"弾"` | |名 |\E!;
    };
}
