#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 23;

use Test::Differences (qw( eq_or_diff ));

use App::Sky::Manager;

package ManagerTester;

use MooX qw/late/;

use Test::More;

use Test::Differences (qw( eq_or_diff ));

has 'manager' => (isa => 'App::Sky::Manager', is => 'ro');

# TEST:$c=0;
sub test_upload_results
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($self, $args, $blurb_base) = @_;

    my $results = $self->manager->get_upload_results(
        $args->{input}
    );

    # TEST:$c++
    ok ($results, "$blurb_base - Results were returned.");

    # TEST:$c++
    eq_or_diff (
        $results->upload_cmd(),
        $args->{upload_cmd},
        "$blurb_base - results->upload_cmd() is correct.",
    );

    # TEST:$c++
    eq_or_diff (
        [map { $_->as_string() } @{$results->urls()}],
        $args->{urls},
        "$blurb_base - the result URLs are correct.",
    );

    return;
}

# TEST:$test_upload_results=$c;

# TEST:$c=0;
sub test_recursive_upload_results
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($self, $args, $blurb_base) = @_;

    my $results = $self->manager->get_recursive_upload_results(
        $args->{input}
    );

    # TEST:$c++
    ok ($results, "$blurb_base - Results were returned.");

    # TEST:$c++
    eq_or_diff (
        $results->upload_cmd(),
        $args->{upload_cmd},
        "$blurb_base - results->upload_cmd() is correct.",
    );

    # TEST:$c++
    eq_or_diff (
        [map { $_->as_string() } @{$results->urls()}],
        $args->{urls},
        "$blurb_base - the result URLs are correct.",
    );

    return;
}

# TEST:$test_recursive_upload_results=$c;

package main;

{
    my $manager = App::Sky::Manager->new(
        {
            config =>
            {
                default_site => "shlomif",
                sites =>
                {
                    shlomif =>
                    {
                        base_upload_cmd => [qw(rsync -a -v --progress --inplace)],
                        dest_upload_prefix => 'hostgator:public_html/',
                        dest_upload_url_prefix => 'http://www.shlomifish.org/',
                        sections =>
                        {
                            code =>
                            {
                                basename_re => q/\.(?:pl|pm|c|py)\z/,
                                target_dir => "Files/files/code/",
                            },
                            music =>
                            {
                                basename_re => q/\.(?:mp3|ogg|wav|aac|m4a)\z/,
                                target_dir => "Files/files/music/mp3-ogg/",
                            },
                            video =>
                            {
                                basename_re => q/\.(?:webm|flv|avi|mpeg|mpg|mp4|ogv)\z/,
                                target_dir => "Files/files/video/",
                            },
                        },
                    },
                },
            },
        },
    );

    # TEST
    ok ($manager, 'Module App::Sky::Manager was created.');

    my $tester = ManagerTester->new({ manager => $manager });

    # TEST*$test_upload_results
    $tester->test_upload_results(
        {
            input =>
            {
                'filenames' => ['/home/music/Music/mp3s/Shine 4U - Carmen and Camille-B8ehY5tutHs.mp4', ],
            },
            upload_cmd =>
            [qw(rsync -a -v --progress --inplace),
            '/home/music/Music/mp3s/Shine 4U - Carmen and Camille-B8ehY5tutHs.mp4',
            'hostgator:public_html/Files/files/video/'
            ],
            urls =>
            [
                'http://www.shlomifish.org/Files/files/video/Shine%204U%20-%20Carmen%20and%20Camille-B8ehY5tutHs.mp4',
            ],
        },
        '[mp4 file]',
    );

    # TEST*$test_upload_results
    $tester->test_upload_results(
        {
            input =>
            {
                'filenames' => ['./foobar/MyModule.pm'],
            },
            upload_cmd =>
            [qw(rsync -a -v --progress --inplace),
                './foobar/MyModule.pm',
                'hostgator:public_html/Files/files/code/'
            ],
            urls =>
            [
                'http://www.shlomifish.org/Files/files/code/MyModule.pm',
            ],
        },
        'MyModule.pm',
    );

    # TEST*$test_upload_results
    $tester->test_upload_results(
        {
            input =>
            {
                'filenames' => ['/var/tmp/test-code.c'],
            },
            upload_cmd =>
            [qw(rsync -a -v --progress --inplace),
                '/var/tmp/test-code.c',
                'hostgator:public_html/Files/files/code/'
            ],
            urls =>
            [
                'http://www.shlomifish.org/Files/files/code/test-code.c',
            ],
        },
        'test-code.c',
    );

    # TEST*$test_upload_results
    $tester->test_upload_results(
        {
            input =>
            {
                'section' => 'music',
                'filenames' => ['/home/music/Music/mp3s/Shine 4U - Carmen and Camille-B8ehY5tutHs.mp4', ],
            },
            upload_cmd =>
            [qw(rsync -a -v --progress --inplace),
            '/home/music/Music/mp3s/Shine 4U - Carmen and Camille-B8ehY5tutHs.mp4',
            'hostgator:public_html/Files/files/music/mp3-ogg/',
            ],
            urls =>
            [
                'http://www.shlomifish.org/Files/files/music/mp3-ogg/Shine%204U%20-%20Carmen%20and%20Camille-B8ehY5tutHs.mp4',
            ],
        },
        '.mp4 file to music section.',
    );

    # TEST*$test_upload_results
    $tester->test_upload_results(
        {
            input =>
            {
                'target_dir' => 'secret-music/',
                'filenames' => ['/home/music/Music/mp3s/Shine 4U - Carmen and Camille-B8ehY5tutHs.mp4', ],
            },
            upload_cmd =>
            [qw(rsync -a -v --progress --inplace),
            '/home/music/Music/mp3s/Shine 4U - Carmen and Camille-B8ehY5tutHs.mp4',
            'hostgator:public_html/secret-music/',
            ],
            urls =>
            [
                'http://www.shlomifish.org/secret-music/Shine%204U%20-%20Carmen%20and%20Camille-B8ehY5tutHs.mp4',
            ],
        },
        'target_dir',
    );
}

{
    my $manager = App::Sky::Manager->new(
        {
            config =>
            {
                default_site => "shlomif",
                sites =>
                {
                    shlomif =>
                    {
                        base_upload_cmd => [qw(rsync -a -v --progress --inplace)],
                        dest_upload_prefix => 'hostgator:public_html/',
                        dest_upload_url_prefix => 'http://www.shlomifish.org/',
                        dirs_section => 'dirs',
                        sections =>
                        {
                            code =>
                            {
                                basename_re => q/\.(?:pl|pm|c|py)\z/,
                                target_dir => "Files/files/code/",
                            },
                            dirs =>
                            {
                                basename_re => q/\.(?:MYDIR)\z/,
                                target_dir => "Files/files/dirs/",
                            },
                            music =>
                            {
                                basename_re => q/\.(?:mp3|ogg|wav|aac|m4a)\z/,
                                target_dir => "Files/files/music/mp3-ogg/",
                            },
                            video =>
                            {
                                basename_re => q/\.(?:webm|flv|avi|mpeg|mpg|mp4|ogv)\z/,
                                target_dir => "Files/files/video/",
                            },
                        },
                    },
                },
            },
        },
    );

    # TEST
    ok ($manager, 'Directories App::Sky::Manager was created.');

    my $tester = ManagerTester->new({ manager => $manager });

    # TEST*$test_recursive_upload_results
    $tester->test_recursive_upload_results(
        {
            input =>
            {
                'filenames' => ['/home/shlomif/progs/perl/cpan/App-Sky', ],
            },
            upload_cmd =>
            [qw(rsync -a -v --progress --inplace),
                '/home/shlomif/progs/perl/cpan/App-Sky',
                'hostgator:public_html/Files/files/dirs/',
            ],
            urls =>
            [
                'http://www.shlomifish.org/Files/files/dirs/App-Sky/',
            ],
        },
        'upload directory',
    );

    # TEST*$test_recursive_upload_results
    $tester->test_recursive_upload_results(
        {
            input =>
            {
                'filenames' => ['/home/shlomif/progs/perl/cpan/App-Sky/', ],
            },
            upload_cmd =>
            [qw(rsync -a -v --progress --inplace),
                '/home/shlomif/progs/perl/cpan/App-Sky',
                'hostgator:public_html/Files/files/dirs/',
            ],
            urls =>
            [
                'http://www.shlomifish.org/Files/files/dirs/App-Sky/',
            ],
        },
        'trailing slash is removed on upload directory',
    );
}

