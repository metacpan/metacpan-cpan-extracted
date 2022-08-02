use 5.36.0;

use Test2::V0;

use App::Changelord::Command::Print;

my $change = App::Changelord::Command::Print->new(
    changelog => {
        project => { name => 'Foo' },
    }
);

like $change->as_markdown, qr/# Changelog for Foo/;

subtest 'homepage' => sub {
    $change->changelog->{project}{homepage} = 'the-url';

    my $header = $change->render_header;
    like $header, qr/\[Foo\]\[homepage\]/;
    like $header, qr/\Q   [homepage]: the-url/;
};

subtest 'release' => sub {
    is $change->render_release("yup, that's it"), "yup, that's it";

    like $change->render_release({
            version => 'v1.2.3',
            date => '2022-01-02',
    }) => qr/\Q## v1.2.3, 2022-01-02/;
};

subtest 'release changes' => sub {
    is $change->render_release({
            version => 'v1.2.3',
            date => '2022-01-02',
            changes => [
                'foo',
                { type => 'feat', 'desc' => 'did the thing' },
                { type => 'fix', 'desc' => 'fixed the thing' },
            ]
    }) => <<'END'
## v1.2.3, 2022-01-02

  * foo

### Features

  * did the thing

### Bug fixes

  * fixed the thing

END
};


done_testing();
