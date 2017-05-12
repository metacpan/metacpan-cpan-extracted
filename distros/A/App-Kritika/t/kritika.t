use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;
use Test::TempDir::Tiny;
use JSON ();

use_ok 'App::Kritika';

subtest 'validate: submits correct file' => sub {
    my $tempdir = tempdir();

    my $ua      = _mock_ua();
    my $kritika = _build_kritika(
        base_url => 'http://localhost',
        token    => 'deadbeef',
        root     => $tempdir,
        ua       => $ua
    );

    _touch_file("$tempdir/file.txt", 'hello there');

    $kritika->validate("$tempdir/file.txt");

    my ($url, $form, $options) = $ua->mocked_call_args('post_form');
    is_deeply $options, {headers => {Authorization => 'Token deadbeef'}};

    is $form->{path},    'file.txt';
    is $form->{content}, 'hello there';
};

subtest 'validate: returns parsed issues' => sub {
    my $tempdir = tempdir();

    my $ua      = _mock_ua();
    my $kritika = _build_kritika(
        base_url => 'http://localhost',
        token    => 'deadbeef',
        root     => $tempdir,
        ua       => $ua
    );

    _touch_file("$tempdir/file.txt", 'hello there');

    my $issues = $kritika->validate("$tempdir/file.txt");

    is_deeply $issues, [{line_no => 1, message => 'Oops'}];
};

done_testing;

sub _mock_ua {
    my $ua = Test::MonkeyMock->new;
    $ua->mock(
        post_form => sub {
            {
                success => 1,
                content =>
                  JSON::encode_json([{line_no => 1, message => 'Oops'}])
            };
        }
    );
    return $ua;
}

sub _touch_file {
    my ($path, $content) = @_;

    open my $fh, '>', $path or die $!;
    print $fh $content if defined $content;
    close $fh;
}

sub _build_kritika { App::Kritika->new(@_) }
