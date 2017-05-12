#!/usr/bin/perl
use warnings;
use strict;

# Tests for the error checking when loading config files.
# Loading of correct config files is adaquately tested elsewhere.

use constant BAD_CONFIG_TEST_FILES => 7;

use Test::More;
use Path::Class qw( file );
use Daizu;
use Daizu::Test qw( init_tests );

init_tests(2 * BAD_CONFIG_TEST_FILES + 67);

# Test a series of bad config files, which each have the expected error
# message embedded inside in a comment.
for my $n (1 .. BAD_CONFIG_TEST_FILES) {
    my $filename = test_filename($n);
    my $expected_error;
    {
        open my $fh, '<', $filename
            or die "error opening test file '$filename': $!\n";
        my $data = do { local $/; <$fh> };
        $data =~ /<!-- EXPECT ERROR: (.*?) -->/
            or die "can't find EXPECT ERROR information in '$filename'";
        $expected_error = $1;
    }
    eval { Daizu->new($filename) };
    ok($@, "expect error from $filename");
    like($@, qr/$expected_error/i, "right error from $filename");
}

# Check finding config file through environment variable.
eval {
    local $ENV{DAIZU_CONFIG} = test_filename(1);
    Daizu->new;
};
ok($@, 'use DAIZU_CONFIG environment variable to find config file');
like($@, qr/root element must be <config>/i, 'right error message');

# Check finding config file through default filename.
eval {
    local $Daizu::DEFAULT_CONFIG_FILENAME = test_filename(1);
    Daizu->new;
};
ok($@, 'use default filename to find config file');
like($@, qr/root element must be <config>/i, 'right error message');

# Check not being able to find a config file at all.
eval {
    local $Daizu::DEFAULT_CONFIG_FILENAME = test_filename('nonexistent');
    Daizu->new;
};
ok($@, 'error if no config file can be found');
like($@, qr/cannot find .* configuration file/i, 'right error message');


my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);
isa_ok($cms, 'Daizu', '$cms');
isa_ok($cms->ra, 'SVN::Ra', '$cms->ra');
isa_ok($cms->db, 'DBI::db', '$cms->db');
is($cms->config_filename, $Daizu::Test::TEST_CONFIG, '$cms->config_filename');

# <guid-entity>
is($cms->{default_entity}, 'example1.com,2006', 'default GUID entity');
is($cms->{path_entity}{'example.com'}, 'example2.com,2006',
   'GUID entity for path example.com');
is($cms->{path_entity}{'example.com/dir'}, 'example3.com,2006',
   'GUID entity for path example.com/dir');
is($cms->{path_entity}{'foo.com'}, 'foo.com,2006',
   'GUID entity for path foo.com');
is(scalar keys %{$cms->{path_entity}}, 3,
   'no excess GUID entities for paths');

# $cms->guid_entity
is($cms->guid_entity('non-existant'), 'example1.com,2006',
   '$cms->guid_entity: non-existant');
is($cms->guid_entity('example.com'), 'example2.com,2006',
   '$cms->guid_entity: example.com');
is($cms->guid_entity('example.com/foo/bar'), 'example2.com,2006',
   '$cms->guid_entity: example.com/foo/bar');
is($cms->guid_entity('example.com/dir'), 'example3.com,2006',
   '$cms->guid_entity: example.com/dir');
is($cms->guid_entity('example.com/dir/foo/bar'), 'example3.com,2006',
   '$cms->guid_entity: example.com/dir/foo/bar');

# <template-test>
is($cms->{template_test_path}, undef, '<template-test>');

# <plugin>
is(scalar keys %{$cms->{property_loaders}}, 1,
   'number of property loader patterns');
is(scalar @{$cms->{property_loaders}{'*'}}, 1,
   'number of property loaders for * pattern');
is(scalar @{$cms->{property_loaders}{'*'}[0]}, 2,
   'property loader has right format');
is($cms->{property_loaders}{'*'}[0][0], $cms,
   'property loader object');
is($cms->{property_loaders}{'*'}[0][1], '_std_property_loader',
   'property loader method');
is(scalar keys %{$cms->{article_loaders}}, 4,
   'number of article loader patterns');
is(scalar @{$cms->{article_loaders}{$_}{''}}, 1,
   "number of article loaders for pattern '$_'")
    for 'text/html', 'application/xhtml+xml',   # default ones
        'text/x-perl',                          # Daizu::Plugin::PodArticle
        'image/*';                              # Daizu::Plugin::PictureArticle

is(scalar keys %{$cms->{html_dom_filters}}, 5,
   'right number of HTML DOM filters');
my $SYNHI = 'Daizu::Plugin::SyntaxHighlight->do_syntax_highlighting';
is(scalar keys %{$cms->{html_dom_filters}{$SYNHI}}, 1,
   'right number of path specs for SyntaxHighlight filter');
is(scalar @{$cms->{html_dom_filters}{$SYNHI}{''}}, 2,
   'HTML DOM filter has right format');
isa_ok($cms->{html_dom_filters}{$SYNHI}{''}[0],
       'Daizu::Plugin::SyntaxHighlight',
       'syntax-highlighting DOM filter object');
is($cms->{html_dom_filters}{$SYNHI}{''}[1], 'do_syntax_highlighting',
   'syntax-highlighting DOM filter method');

# <generator>
is(scalar keys %{$cms->{generator_config}}, 2,
   'right number of generator configs');
is(scalar keys %{$cms->{generator_config}{'Daizu::Gen'}}, 1,
   'right number of Daizu::Gen configs');
{
    my $config = $cms->{generator_config}{'Daizu::Gen'}{'foo.com'};
    isa_ok($config, 'XML::LibXML::Element', 'Daizu::Gen config is an element');
    is($config->localname, 'generator', 'and it is a <generator> element');
}


# <output>
is(scalar keys %{$cms->{output}}, 2,
   'right number of output configs');
{
    # Check that the <output> elements were loaded correctly.
    my $root = $Daizu::Test::TEST_OUTPUT_DIR;
    isa_ok($cms->{output}{'http://www.example.com/'}{url}, 'URI',
           'output url for example.com');
    is($cms->{output}{'http://www.example.com/'}{url}->as_string,
       'http://www.example.com/', 'output url value for example.com');
    is($cms->{output}{'http://www.example.com/'}{path}, "$root/example.com",
       'output path for example.com');
    is($cms->{output}{'http://www.example.com/'}{redirect_map},
       "$root/example.com-redirect.map", 'output redirect-map for example.com');
    is($cms->{output}{'http://www.example.com/'}{gone_map},
       "$root/example.com-gone.map", 'output gone-map for example.com');
    is($cms->{output}{'http://www.example.com/'}{index_filename},
       'index.shtml', 'output index-filename for example.com');

    isa_ok($cms->{output}{'http://foo.com/'}{url}, 'URI',
           'output url for foo.com');
    is($cms->{output}{'http://foo.com/'}{url}->as_string,
       'http://foo.com/', 'output url value for foo.com');
    is($cms->{output}{'http://foo.com/'}{path}, "$root/foo.com",
       'output path for foo.com');
    is($cms->{output}{'http://foo.com/'}{redirect_map},
       undef, 'output redirect-map for foo.com');
    is($cms->{output}{'http://foo.com/'}{gone_map},
       undef, 'output gone-map for foo.com');
    is($cms->{output}{'http://foo.com/'}{index_filename},
       'index.html', 'output index-filename for foo.com');

    # $cms->output_config
    my ($outconf, @out);
    ($outconf, @out) = $cms->output_config('http://www.example.com/');
    is(join('|', @out), "$root/example.com||index.shtml",
       'output_config: example.com string');
    isa_ok($outconf, 'HASH', 'output_config: example.com config hash, string');
    is($outconf, $cms->{output}{'http://www.example.com/'},
       'output_config: example.com config hash value, string');
    ($outconf, @out) = $cms->output_config(URI->new('http://www.example.com/'));
    is(join('|', @out), "$root/example.com||index.shtml",
       'output_config: example.com object');
    isa_ok($outconf, 'HASH', 'output_config: example.com config hash, object');
    is($outconf, $cms->{output}{'http://www.example.com/'},
       'output_config: example.com config hash value, object');

    ($outconf, @out) = $cms->output_config('http://foo.com/');
    is(join('|', @out), "$root/foo.com||index.html",
       'output_config: http://foo.com/');
    ($outconf, @out) = $cms->output_config('http://foo.com/bar.html');
    is(join('|', @out), "$root/foo.com||bar.html",
       'output_config: http://foo.com/bar.html');
    ($outconf, @out) = $cms->output_config('http://foo.com/bar');
    is(join('|', @out), "$root/foo.com||bar",
       'output_config: http://foo.com/bar');
    ($outconf, @out) = $cms->output_config('http://foo.com/bar/baz.html');
    is(join('|', @out), "$root/foo.com|bar|baz.html",
       'output_config: http://foo.com/bar/baz.html');
    ($outconf, @out) = $cms->output_config('http://foo.com/bar/');
    is(join('|', @out), "$root/foo.com|bar|index.html",
       'output_config: http://foo.com/bar/');

    # These ones can't be output because their's no suitable config.
    ($outconf, @out) = $cms->output_config('https://foo.com/');
    is(join('|', @out), '', 'output_config: https://foo.com/');
    ($outconf, @out) = $cms->output_config('http://foo.com:81/');
    is(join('|', @out), '', 'output_config: http://foo.com:81/');
    ($outconf, @out) = $cms->output_config('http://piddle.com/');
    is(join('|', @out), '', 'output_config: http://piddle.com/');
}


sub test_filename
{
    my ($num) = @_;
    return file(qw( t data 05config ), "bad$num.xml");
}

# vi:ts=4 sw=4 expandtab filetype=perl
