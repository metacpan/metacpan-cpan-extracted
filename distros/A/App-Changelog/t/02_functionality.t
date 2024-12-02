use strict;
use warnings;

use lib "lib";

use Test::More;
use Test::MockObject;
use App::Changelog;

subtest 'Test class initialization' => sub {
    my $generator = App::Changelog->new(
        output_file => 'test_changelog.md',
        compact     => 1,
        filter_tag  => 'v',
    );

    isa_ok( $generator, 'App::Changelog', 'Instance created successfully' );
    is( $generator->{output_file}, 'test_changelog.md', 'Correct output file' );
    is( $generator->{compact},     1,   'Compact mode enabled' );
    is( $generator->{filter_tag},  'v', 'Tag filter configured' );
};

subtest 'Test tag retrieval' => sub {
    my $mock = Test::MockObject->new();
    $mock->fake_module(
        'App::Changelog',
        _run_git_command => sub {
            my ( $self, $command ) = @_;
            if ( $command =~ /git log --pretty/ ) {
                return "abc123 Commit 1\ndef456 Commit 2";
            }
            if ( $command =~ /git tag --sort/ ) {
                return "v1.0\nv1.1\nv1.2";
            }
            if ( $command =~ /git log -1 --format/ ) {
                return "2024-01-01 12:00:00";
            }
            return '';
        }
    );

    my $generator = App::Changelog->new( output_file => 'test_changelog.md' );
    my @tags      = $generator->_get_tags();
    is_deeply(
        \@tags,
        [ 'v1.0', 'v1.1', 'v1.2' ],
        'Tags retrieved successfully'
    );
};

subtest 'Test _build_changelog_content' => sub {
    my $mocked_git_responses = {
        'git log v1.1..v1.0 --pretty=format' => "- Commit 1 (abc123)\n",
        'git log v1.2..v1.1 --pretty=format' => "- Commit 2 (def456)\n",
        'git log v1.2 --pretty=format'       => "- Commit 3 (ghy789)\n",
        'git log -1 --format=%ai v1.0'       => "2024-01-01 12:00:00",
        'git log -1 --format=%ai v1.1'       => "2024-01-01 12:00:00",
        'git log -1 --format=%ai v1.2'       => "2024-01-01 12:00:00",
    };

    my $mock = Test::MockObject->new();

    $mock->fake_module(
        'App::Changelog',
        _run_git_command => sub {
            my ( $self, $command ) = @_;
            return $mocked_git_responses->{$command} || '';
        }
    );

    my $generator = App::Changelog->new( output_file => 'test_changelog.md' );

    my @tags   = ( 'v1.0', 'v1.1', 'v1.2' );
    my $format = '--pretty=format';

    my $content = $generator->_build_changelog_content( \@tags, $format );

    my $expected_content = "# Changelog\n\n";
    $expected_content .= "## [v1.0] - 2024-01-01\n\n- Commit 1 (abc123)\n\n";
    $expected_content .= "## [v1.1] - 2024-01-01\n\n- Commit 2 (def456)\n\n";
    $expected_content .= "## [v1.2] - 2024-01-01\n\n- Commit 3 (ghy789)\n\n";

    is( $content, $expected_content, 'Changelog content generated correctly' );
};

done_testing();
