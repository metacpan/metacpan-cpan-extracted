use strict;
use warnings;

use Cwd qw(getcwd);
use Test::More;
use Test::MonkeyMock;
use Test::TempDir::Tiny;

use_ok 'App::Kritika::Settings';

subtest 'settings: root is kept from the config' => sub {
    my $tempdir = tempdir();

    _touch_file("$tempdir/.kritikarc", "root=/");

    my $settings = _build_kritika_settings(file => "$tempdir/file.txt");

    is $settings->settings->{root}, '/';
};

subtest 'settings: detects settings from current directory' => sub {
    my $tempdir = tempdir();

    _touch_file("$tempdir/.kritikarc", "base_url=foo.com");

    my $settings = _build_kritika_settings(file => "$tempdir/file.txt");

    is_deeply $settings->settings, {root => "$tempdir", base_url => 'foo.com'};
};

subtest 'settings: detects settings going up the root' => sub {
    my $tempdir = tempdir();

    mkdir "$tempdir/nested";
    mkdir "$tempdir/nested/dir";

    _touch_file("$tempdir/.kritikarc", "base_url=foo.com");

    my $settings =
      _build_kritika_settings(file => "$tempdir/nested/dir/file.txt");

    is_deeply $settings->settings, {root => "$tempdir", base_url => 'foo.com'};
};

subtest 'settings: detects settings from relative path' => sub {
    my $tempdir = tempdir();

    mkdir "$tempdir/nested";
    mkdir "$tempdir/nested/dir";

    _touch_file("$tempdir/.kritikarc", "base_url=foo.com");

    my $cwd = getcwd;
    chdir "$tempdir/nested/dir";

    my $settings = _build_kritika_settings(file => "file.txt");

    is_deeply $settings->settings, {root => "$tempdir", base_url => 'foo.com'};

    chdir $cwd;
};

subtest 'settings: fallsback to _kritikarc' => sub {
    my $tempdir = tempdir();

    _touch_file("$tempdir/_kritikarc", "base_url=foo.com");

    my $settings = _build_kritika_settings(file => "$tempdir/file.txt");

    is $settings->settings->{base_url}, 'foo.com';
};

done_testing;

sub _touch_file {
    my ($path, $content) = @_;

    open my $fh, '>', $path or die $!;
    print $fh $content if defined $content;
    close $fh;
}

sub _build_kritika_settings { App::Kritika::Settings->new(@_) }
