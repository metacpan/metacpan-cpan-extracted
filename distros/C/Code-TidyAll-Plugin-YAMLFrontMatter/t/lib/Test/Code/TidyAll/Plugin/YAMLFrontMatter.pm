package Test::Code::TidyAll::Plugin::YAMLFrontMatter;

use strict;
use warnings;

use Test::Class::Most;

use Code::TidyAll;

use Capture::Tiny qw( capture );
use Path::Tiny qw( tempdir );

sub tidyall {
    my $self = shift;
    my %args = @_;

    my $tidyall = Code::TidyAll->new(
        quiet    => 1,
        root_dir => tempdir(
            { realpath => 1 },
            TEMPLATE => 'Code-TidyAll-XXXX',
            CLEANUP  => 1,
        ),
        plugins => {
            YAMLFrontMatter => {
                select => '*',    # everything, since we're testing
                %{ $args{conf} || {} },
            },
        },
    );

    my $result;
    capture {
        $result = $tidyall->process_source( $args{source}, 'dummy.md' );
    };

    my $expect_error = $args{expect_error};
    unless ($expect_error) {
        is( $result->state, 'checked', "state=checked [$args{desc}]" );
        is( $result->error, undef,     "no error [$args{desc}]" );
        return;
    }

    is( $result->state, 'error', "state=error [$args{desc}]" );
    like(
        $result->error || q{}, $expect_error,
        "error message [$args{desc}]"
    );
    return;
}

sub test_main : Tests {
    my $self = shift;

    $self->tidyall(
        source => "---\n---\nThis should work",
        desc   => 'Empty is okay'
    );

    $self->tidyall(
        source => 'fish',
        expect_error =>
            qr/dummy[.]md' does not start with valid YAML Front Matter/,
        desc => 'no front matter',
    );

    $self->tidyall(
        source       => qq{---\n!!!!!\n---\nThis should not work},
        expect_error => qr/Problem parsing YAML/,
        desc         => 'Bad YAML',
    );

    ## encoding handling

    $self->tidyall(
        source => "\x{EF}\x{BB}\x{BF}---\n---\nSomeone set us up the BOM",
        expect_error => qr/Starting document with UTF-8 BOM is not allowed/,
        desc         => 'BOM',
    );

    $self->tidyall(
        source =>
            "\x{fe}\x{ff}\x{00}-\x{00}-\x{00}-\x{00}\n\x{00}-\x{00}-\x{00}-\x{00}\n\x{00}!",
        conf => { encoding => 'UTF-16' },
        desc => 'UTF-16',
    );

    $self->tidyall(
        source       => "---\n---\nL\x{e9}on hates invalid UTF-8",
        expect_error => qr/File does not match encoding 'UTF-8'/,
        desc         => 'Invalid encoding',
    );

    ## required keys

    $self->tidyall(
        source       => "---\n---\nA rose by any other name",
        desc         => 'Missing one required key',
        conf         => { required_top_level_keys => 'title' },
        expect_error => qr/Missing required YAML Front Matter key: 'title'/,
    );

    $self->tidyall(
        source => "---\ntitle: B Piper\n---\nA rose by any other name",
        desc   => 'No missing key',
        conf   => { required_top_level_keys => 'title' },
    );

    $self->tidyall(
        source       => "---\ntitle: B Piper\n---\nA rose by any other name",
        desc         => 'Missing second key',
        conf         => { required_top_level_keys => 'title wibble' },
        expect_error => qr/Missing required YAML Front Matter key: 'wibble'/,
    );
}

1;
