#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use Path::Class qw( file );
use Daizu;
use Daizu::Test qw( init_tests );
use Daizu::Preview qw(
    adjust_preview_links_html adjust_preview_links_css
);

init_tests(2);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);

# adjust_preview_links_css
{
    my $input = read_file('input.css');
    my $expected = read_file('expected.css');

    my $output = '';
    {
        no warnings 'redefine';
        local *Daizu::Preview::adjust_link_for_preview = \&mock_adjust_link;

        open my $fh, '>', \$output or die "error: $!";
        adjust_preview_links_css($cms, $cms->{live_wc_id},
                                 'http://example.org/foo/bar',
                                 $input, $fh);
    }
    is($output, $expected, 'adjust_preview_links_css');
}

# adjust_preview_links_html
{
    my $input = read_file('input.html');
    my $expected = read_file('expected.html');

    my $output = '';
    {
        no warnings 'redefine';
        local *Daizu::Preview::adjust_link_for_preview = \&mock_adjust_link;

        open my $fh, '>', \$output or die "error: $!";
        adjust_preview_links_html($cms, $cms->{live_wc_id},
                                  'http://example.org/foo/bar',
                                  $input, $fh);
    }
    is($output, $expected, 'adjust_preview_links_html');
}


sub test_filename { file(qw( t data 70preview ), @_) }

sub read_file
{
    my ($test_file) = @_;
    open my $fh, '<', test_filename($test_file)
        or die "error: $!";
    local $/;
    return <$fh>;
}

sub mock_adjust_link
{
    my ($cms, $wc_id, $base_url, $urls, $value_type) = @_;
    return "preview:[$urls]";
}

# vi:ts=4 sw=4 expandtab filetype=perl
