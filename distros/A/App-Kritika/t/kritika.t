use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;
use Test::Fatal;
use Test::TempDir::Tiny;
use Test::Deep;
use JSON ();

use_ok 'App::Kritika';

subtest 'validate: submits correct file' => sub {
    my $tempdir = tempdir();

    my $ua      = _mock_ua();
    my $kritika = _build_kritika(
        base_url => 'http://localhost',
        token    => 'deadbeef',
        root     => $tempdir,
        branch   => 'master',
        revision => 'deadbeef',
        ua       => $ua
    );

    _touch_file( "$tempdir/file.txt", 'hello there' );

    $kritika->validate("$tempdir/file.txt");

    my ( $url, $options ) = $ua->mocked_call_args('post');
    cmp_deeply $options,
      {
        headers =>
          { Authorization => 'Token deadbeef', Accept => 'application/json', 'X-Version' => ignore() },
        content => JSON->new->canonical(1)->encode(
            {
                branch   => 'master',
                revision => 'deadbeef',
                files    => [
                    {
                        path    => 'file.txt',
                        content => 'hello there'
                    }
                ]
            }
        )
      };
};

subtest 'validate: returns parsed issues' => sub {
    my $tempdir = tempdir();

    my $ua      = _mock_ua();
    my $kritika = _build_kritika(
        base_url => 'http://localhost',
        token    => 'deadbeef',
        root     => $tempdir,
        branch   => 'master',
        revision => 'deadbeef',
        ua       => $ua
    );

    _touch_file( "$tempdir/file.txt", 'hello there' );

    my $issues = $kritika->validate("$tempdir/file.txt");

    is_deeply $issues, [ { line_no => 1, message => 'Oops' } ];
};

subtest 'validate: throws on internal error' => sub {
    my $tempdir = tempdir();

    my $ua = _mock_ua( post =>
          sub { { success => 0, status => 599, content => 'Cant connect' } } );
    my $kritika = _build_kritika(
        base_url => 'http://localhost',
        token    => 'deadbeef',
        root     => $tempdir,
        branch   => 'master',
        revision => 'deadbeef',
        ua       => $ua
    );

    _touch_file( "$tempdir/file.txt", 'hello there' );

    like exception { $kritika->validate("$tempdir/file.txt") },
      qr/Cant connect/;
};

subtest 'validate: throws on remote error' => sub {
    my $tempdir = tempdir();

    my $ua = _mock_ua(
        post => sub { { success => 0, status => 404, reason => 'Not found' } }
    );
    my $kritika = _build_kritika(
        base_url => 'http://localhost',
        token    => 'deadbeef',
        root     => $tempdir,
        branch   => 'master',
        revision => 'deadbeef',
        ua       => $ua
    );

    _touch_file( "$tempdir/file.txt", 'hello there' );

    like exception { $kritika->validate("$tempdir/file.txt") }, qr/Not found/;
};

done_testing;

sub _mock_ua {
    my (%params) = @_;

    my $ua = Test::MonkeyMock->new;
    $ua->mock(
        post => $params{post} || sub {
            {
                success => 1,
                status  => 200,
                content =>
                  JSON::encode_json( [ { line_no => 1, message => 'Oops' } ] )
            };
        }
    );
    return $ua;
}

sub _touch_file {
    my ( $path, $content ) = @_;

    open my $fh, '>', $path or die $!;
    print $fh $content if defined $content;
    close $fh;
}

sub _build_kritika { App::Kritika->new(@_) }
