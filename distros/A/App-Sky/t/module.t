#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

use Test::Differences (qw( eq_or_diff ));

use App::Sky::Module;
use App::Sky::Exception;

{
    my $m = App::Sky::Module->new(
        {
            base_upload_cmd => [qw(rsync -a -v --progress --inplace)],
            dest_upload_prefix => 'hostgator:public_html/',
            dest_upload_url_prefix => 'http://www.shlomifish.org/',
        }
    );

    # TEST
    ok ($m, 'Module App::Sky::Module was created.');

    # TEST
    eq_or_diff(
        $m->base_upload_cmd(),
        [qw(rsync -a -v --progress --inplace)],
        "base_upload_cmd was set.",
    );

    {
        my $results = $m->get_upload_results(
            {
                'filenames' => ['Shine4U.webm'],
                'target_dir' => 'Files/files/video/',
            }
        );

        # TEST
        ok ($results, "Results were returned.");

        # TEST
        eq_or_diff (
            $results->upload_cmd(),
            [qw(rsync -a -v --progress --inplace Shine4U.webm hostgator:public_html/Files/files/video/)],
            "results->upload_cmd() is correct.",
        );

        # TEST
        eq_or_diff (
            [map { $_->as_string() } @{$results->urls()}],
            [
                'http://www.shlomifish.org/Files/files/video/Shine4U.webm',
            ],
            'The result URLs are correct.',
        );
    }

    {
        my $results = $m->get_upload_results(
            {
                'filenames' => ['../../My-Lemon.webm'],
                'target_dir' => 'Files/files/video/',
            }
        );

        # TEST
        ok ($results, "../../ Results were returned.");

        # TEST
        eq_or_diff (
            $results->upload_cmd(),
            [qw(rsync -a -v --progress --inplace ../../My-Lemon.webm hostgator:public_html/Files/files/video/)],
            "../../ results->upload_cmd() is correct.",
        );

        # TEST
        eq_or_diff (
            [map { $_->as_string() } @{$results->urls()}],
            [
                'http://www.shlomifish.org/Files/files/video/My-Lemon.webm',
            ],
            'URLs for using basename.',
        );
    }

    {
        my $results = $m->get_upload_results(
            {
                'filenames' => ['/home/shlomif/progs/perl/MetaData.pm'],
                'target_dir' => 'share-dir/code/',
            }
        );

        # TEST
        ok ($results, "Absolute URL - results obj was returned.");

        # TEST
        eq_or_diff (
            $results->upload_cmd(),
            [qw(rsync -a -v --progress --inplace /home/shlomif/progs/perl/MetaData.pm hostgator:public_html/share-dir/code/)],
            "Absolute URL - results->upload_cmd() is correct.",
        );

        # TEST
        eq_or_diff (
            [map { $_->as_string() } @{$results->urls()}],
            [
                'http://www.shlomifish.org/share-dir/code/MetaData.pm',
            ],
            'Absolute URL - URLs for using basename.',
        );
    }

}

{
    my $m = App::Sky::Module->new(
        {
            base_upload_cmd => [qw(rsync -a -v --progress --inplace)],
            dest_upload_prefix => 'shlomif@perl-begin.org:sites/perl-begin',
            dest_upload_url_prefix => 'http://perl-begin.org/',
        }
    );

    {
        eval
        {
            my $results = $m->get_upload_results(
                {
                    'filenames' => ['/home/shlomif/progs/foo:bar.pm'],
                    'target_dir' => 'Files/files/code/',
                }
            );
        };

        my $E = $@;

        # TEST
        ok ($E, 'An exception was thrown.');

        # TEST
        isa_ok ($E, 'App::Sky::Exception::Upload::Filename::InvalidChars',
            'Exception is right.'
        );

        # TEST
        eq_or_diff
        (
            $E->invalid_chars(),
            [':'],
            "Invalid characters is fine.",
        );
    }
}
