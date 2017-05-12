#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use Carp::Assert qw( assert );
use Path::Class qw( file );
use Encode qw( decode );
use XML::LibXML;
use Daizu;
use Daizu::Test qw( init_tests );

init_tests(9);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);
my $live_wc = $cms->live_wc;


# Daizu::Plugin::HeaderAnchor
{
    my $filter = bless {}, 'Daizu::Plugin::HeaderAnchor';
    my $input = read_xml('HeaderAnchor-input.xml');
    my $art = $filter->filter_article(undef, undef, $input);
    assert(defined $art);

    isa_ok($art, 'HASH', 'HeaderAnchor');
    is(scalar(keys %$art), 1, 'HeaderAnchor: only content returned');
    isa_ok($art->{content}, 'XML::LibXML::Document', 'HeaderAnchor: content');

    my $got = $art->{content}->documentElement->toStringC14N . "\n";
    my $expected = read_file('HeaderAnchor-expected.xml');
    $expected = decode('UTF-8', $expected, Encode::FB_CROAK);
    is($got, $expected, 'HeaderAnchor: correct output');
}


# Daizu::Plugin::ImageMetadata
{
    # First test with images found in a normal HTML article.  The actual
    # content of these articles I'm testing with are faked up so that I don't
    # have to bother adding the <img> elements to the test repository.
    my $file = $live_wc->file_at_path('foo.com/_index.html');
    assert(defined $file);
    my $input = read_xml('ImageMetadata-input-1.xml');

    my $filter = bless {}, 'Daizu::Plugin::ImageMetadata';
    my $art = $filter->filter_article($cms, $file, $input);
    assert(defined $art);

    isa_ok($art, 'HASH', 'ImageMetadata');
    is(scalar(keys %$art), 1, 'ImageMetadata: only content returned');
    isa_ok($art->{content}, 'XML::LibXML::Document', 'ImageMetadata: content');

    my $got = $art->{content}->documentElement->toStringC14N . "\n";
    my $expected = read_file('ImageMetadata-expected-1.xml');
    $expected = decode('UTF-8', $expected, Encode::FB_CROAK);
    is($got, $expected, 'ImageMetadata: correct output');

    # Same tests, but with different content and using a PictureArticle file.
    # This is slightly different because the 'dc:title' and 'dc:description'
    # properties are assumed to already be used in the article, and so
    # shouldn't also be added to the <img> element.
    $file = $live_wc->file_at_path('foo.com/blog/2005/photos/wasp-on-holly-leaf.jpg');
    assert(defined $file);
    $input = read_xml('ImageMetadata-input-2.xml');

    $art = $filter->filter_article($cms, $file, $input);
    assert(defined $art);

    $got = $art->{content}->documentElement->toStringC14N . "\n";
    $expected = read_file('ImageMetadata-expected-2.xml');
    $expected = decode('UTF-8', $expected, Encode::FB_CROAK);
    is($got, $expected,
       'ImageMetadata, on PictureArticle file: correct output');
}


sub test_filename { file(qw( t data 27articlefilter ), @_) }

# TODO perhaps some stuff like this should be moved to Daizu::Test
sub read_file
{
    my ($test_file) = @_;
    open my $fh, '<', test_filename($test_file)
        or die "error: $!";
    binmode $fh
        or die "error reading file '$test_file' in binary mode: $!";
    local $/;
    return <$fh>;
}

sub read_xml
{
    my $input = read_file(@_);
    return XML::LibXML->new->parse_string($input);
}

# vi:ts=4 sw=4 expandtab filetype=perl
