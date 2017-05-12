#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use Carp::Assert qw( assert );
use Daizu;
use Daizu::TTProvider;
use Daizu::Test qw( init_tests );

init_tests(26);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);
my $wc = $cms->live_wc;

my $homepage_file = $wc->file_at_path('foo.com/_index.html');
my $docidx_file = $wc->file_at_path('foo.com/doc/_index.html');
my $subidx_file = $wc->file_at_path('foo.com/doc/subdir/_index.html');
my $a_file = $wc->file_at_path('foo.com/doc/subdir/a.html');
assert(defined $_)
    for $homepage_file, $docidx_file, $subidx_file, $a_file;


# Daizu::TTProvider->_load()
test_load_template($cms, $a_file,        'test1.tt',
                   'Test template 1, in foo.com/doc');
test_load_template($cms, $subidx_file,   'test1.tt',
                   'Test template 1, in foo.com/doc');
test_load_template($cms, $docidx_file,   'test1.tt',
                   'Test template 1, in foo.com/doc');
test_load_template($cms, $homepage_file, 'test1.tt',
                   undef);

test_load_template($cms, $a_file,        'test2.tt',
                   'Test template 2, in foo.com/doc');
test_load_template($cms, $subidx_file,   'test2.tt',
                   'Test template 2, in foo.com/doc');
test_load_template($cms, $docidx_file,   'test2.tt',
                   'Test template 2, in foo.com/doc');
test_load_template($cms, $homepage_file, 'test2.tt',
                   'Test template 2, in foo.com');

test_load_template($cms, $a_file,        'test3.tt',
                   'Test template 3, in foo.com');
test_load_template($cms, $subidx_file,   'test3.tt',
                   'Test template 3, in foo.com');
test_load_template($cms, $docidx_file,   'test3.tt',
                   'Test template 3, in foo.com');
test_load_template($cms, $homepage_file, 'test3.tt',
                   'Test template 3, in foo.com');

test_load_template($cms, $a_file,        'test4.tt',
                   'Test template 4, in top level');
test_load_template($cms, $subidx_file,   'test4.tt',
                   'Test template 4, in top level');
test_load_template($cms, $docidx_file,   'test4.tt',
                   'Test template 4, in top level');
test_load_template($cms, $homepage_file, 'test4.tt',
                   'Test template 4, in top level');

test_load_template($cms, $a_file,        'article_meta/pubdatetime.tt',
                   'Template to override one which is provided with Daizu.');
test_load_template($cms, $subidx_file,   'article_meta/pubdatetime.tt',
                   'Template to override one which is provided with Daizu.');
test_load_template($cms, $docidx_file,   'article_meta/pubdatetime.tt',
                   'Template to override one which is provided with Daizu.');
test_load_template($cms, $homepage_file, 'article_meta/pubdatetime.tt',
                   'Template to override one which is provided with Daizu.');
test_load_template($cms, $wc->file_at_path('example.com/foo.html'),
                   'article_meta/pubdatetime.tt',
                   '<p>[% INCLUDE article_pubdatetime.tt datetime = entry.issued_at %]</p>');

# Check that binary data is preserved.
test_load_template($cms, $homepage_file, 'binary-test.tt',
                   "foo\x00\x1B\x7F\x80\xA0\x{FF}bar");

# With template overrides in place.
test_load_template($cms, $a_file,        'test1.tt',
                   'Test template 2, in foo.com/doc',
                   { 'test1.tt' => 'test2.tt' });
test_load_template($cms, $subidx_file,   'test1.tt',
                   'Test template 2, in foo.com/doc',
                   { 'test1.tt' => 'test2.tt' });
test_load_template($cms, $docidx_file,   'test1.tt',
                   'Test template 2, in foo.com/doc',
                   { 'test1.tt' => 'test2.tt' });
test_load_template($cms, $homepage_file, 'test1.tt',
                   'Test template 2, in foo.com',
                   { 'test1.tt' => 'test2.tt' });


sub test_load_template
{
    my ($cms, $file, $template, $expected, $overrides) = @_;
    my $msg = "TTProvider: $template in $file->{path}";
    $msg .= ' with overrides'
        if defined $overrides && keys %$overrides;

    my $provider = Daizu::TTProvider->new({
        daizu_cms => $cms,
        daizu_wc_id => $file->{wc_id},
        daizu_file_path => $file->directory_path,
        daizu_template_overrides => $overrides,
    });

    my ($data, $error) = $provider->_load($template);
    my $text = $data->{text};

    # Render 'declined' as undef, so that I can compare it with $expected.
    # Other errors get reported as such.
    if ($error && $error == Template::Constants::STATUS_DECLINED) {
        $text = undef;
        $error = undef;
    }

    if ($error) {
        fail("$msg: error: $error");
    }
    else {
        $text =~ s/\n\z// if defined $text;
        is($text, $expected, $msg);
    }
}

# vi:ts=4 sw=4 expandtab filetype=perl
