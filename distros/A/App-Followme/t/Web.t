#!/usr/bin/env perl
use strict;

use Test::More tests => 27;

use Cwd;
use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::Web";

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir or die $!;
chmod 0755, $test_dir;

chdir $test_dir or die $!;
$test_dir = cwd();

#----------------------------------------------------------------------
# Test web_is_tag

do {
    my $tag = App::Followme::Web::web_is_tag('<p>');
    is($tag, 1, 'a tag is a tag'); # test 1

    $tag = App::Followme::Web::web_is_tag('<!-- comment -->');
    is($tag, 0, 'a comment is not a tag'); # test 2

    $tag = App::Followme::Web::web_is_tag('A sentence');
    is($tag, 0, 'plain text is not a tag'); # test 3
};

#----------------------------------------------------------------------
# Test web_tags and web_only_text

do {
    my $text = "<h1>Title</h1>\n<p>Sentence\none with a <a href=\"\">link.</a></p>\n";
    my @tokens_ok = ("<h1>", "Title", "</h1>", "\n",
                     "<p>", "Sentence\none with a ",
                     "<a href=\"\">", "link.",
                     "</a>", "</p>", "\n");

    my @tokens = App::Followme::Web::web_split_at_tags($text);
    is_deeply(\@tokens, \@tokens_ok, 'split text at tags'); # test 4

    my $only_text_ok = "Title Sentence one with a link.";
    my $only_text = web_only_text(@tokens);
    is($only_text, $only_text_ok, 'extract text from list of tags'); # test 5
};

#----------------------------------------------------------------------
# Test web_parse_tag

do {
    my $tag = App::Followme::Web::web_parse_tag('</p>');
    is_deeply($tag, {_ => '/p'}, 'parse simple tag'); # test 6

    $tag = App::Followme::Web::web_parse_tag('<base href="http://test.com">');
    is_deeply($tag, {_ => 'base', href => "http://test.com"},
              'parse tag with attribute');  # test 7

    my $token = '<meta name=keywords content="one two three" >';
    $tag = App::Followme::Web::web_parse_tag($token);
    my $tag_ok = {_ => 'meta', name => 'keywords', content => "one two three" };
    is_deeply($tag, $tag_ok, 'parse tag with two attributes'); # test 8
};

#----------------------------------------------------------------------
# Test web_only_tags

do {
    my $text = "<h1>Title</h1>\n<p>Sentence\none with a <a href=\"\">link.</a></p>\n";
    my @tokens = App::Followme::Web::web_split_at_tags($text);
    my @tags = App::Followme::Web::web_only_tags(@tokens);

    my @tags_ok = ({_ => 'h1'}, {_ => '/h1'}, {_ => 'p'},
                   {_ => 'a', href => ''}, {_ => '/a'}, {_ => '/p'});

    is_deeply(\@tags, \@tags_ok, 'get a list of the tags in a text'); # test 9
};

#----------------------------------------------------------------------
# Test web_same_tag

do {
    my $tag1 = App::Followme::Web::web_parse_tag('<p>');
    my $tag2 = App::Followme::Web::web_parse_tag('<p class="lead">');
    my $same = App::Followme::Web::web_same_tag($tag1, $tag2);
    is($same, 1, 'two tags are the same'); # test 10

    $same = App::Followme::Web::web_same_tag($tag2, $tag1);
    is($same, 0, 'two tags are not the same'); # test 11

    $tag1 = App::Followme::Web::web_parse_tag('<a href=*>');
    $tag2 = App::Followme::Web::web_parse_tag('<a href="http://www.com">');
    $same = App::Followme::Web::web_same_tag($tag1, $tag2);
    is($same, 1, 'two tags match with wildcard'); # test 12

    $tag1 = App::Followme::Web::web_parse_tag('<a href="http://www.org">');
    $tag2 = App::Followme::Web::web_parse_tag('<a href="http://www.com">');
    $same = App::Followme::Web::web_same_tag($tag1, $tag2);
    is($same, 0, 'two tags do not match on attribute'); # test 13
};

#----------------------------------------------------------------------
# Test web_match_tags and web_substitute_tags

do {
    my $text = <<'EOQ';
<title>Test Title</title>
<meta name="description" content="This is a test">
<meta name="keywords" content="one two three">
EOQ

    my $title_matcher = sub {
        my ($title, @tokens) = @_;
        $$title = web_only_text(@tokens);
        return '';
    };

    my $title;
    my $global = 0;
    my $count = web_match_tags('<title></title>', $text,
                               $title_matcher, \$title, $global);

    is($count, 1, 'count matched text'); # test 14
    is($title, 'Test Title', 'get matched text'); # test 15

    my $tag_matcher = sub {
        my ($tags, @tokens) = @_;
        push(@$tags, web_only_tags(@tokens));
        return;
    };

    $global = 1;
    my $tags = [];
    $count = web_match_tags('<meta name=* content=*>', $text,
                            $tag_matcher, $tags, $global);

    is($count, 2, 'count matched text'); # test 16
    my $tags_ok = [{_ => 'meta', name => 'description', content => 'This is a test'},
                   {_ => 'meta', name => 'keywords', content => 'one two three'}];
    is_deeply($tags, $tags_ok, 'get matched tags'); # test 17

    $global = 0;
    my $body = web_substitute_tags('<title></title>', $text,
                                   $title_matcher, \$title, $global);

    my @text = split(/\n/, $text);
    shift(@text);
    my $body_ok = join("\n", '', @text, '');

    is($body, $body_ok, 'substitute for title'); # test 18
    is($title, 'Test Title', 'get text substituted for'); # test 19
};

#----------------------------------------------------------------------
# Test substitute_sections

do {
    my $template = <<'EOQ';
<!-- section header -->
Header
<!-- endsection header -->
<!-- set $i = 0 -->
<!-- for @data -->
  <!-- set $i = $i + 1 -->
  <!-- if $i % 2 -->
Even line
  <!-- else -->
Odd line
  <!-- endif -->
<!-- endfor -->
<!-- section footer -->
Footer
<!-- endsection footer -->
EOQ

    my $sections = web_parse_sections($template);
    my @sections = sort keys %$sections;

    is_deeply(\@sections, [qw(footer header)],
              "all sections returned from web_parse_sections"); #test 20
    is($sections->{footer}, "\nFooter\n",
       "right value in footer from substitute_sections"); # test 21

    my $subtemplate = <<'EOQ';
<!-- section header -->
Another Header
<!-- endsection header -->
Another Body
<!-- section footer -->
Another Footer
<!-- endsection footer -->
EOQ

    $sections = {};
    my $text = web_substitute_sections($subtemplate, $sections);
    $text = web_substitute_sections($template, $sections);

    like($text, qr/<!-- section header -->/, "keep sections start tag"); # test 22
    like($text, qr/<!-- endsection header -->/, "keep sections end tag"); # test 23
    like($text, qr/Another Header/, "keep subsection text"); # test 24
};

#----------------------------------------------------------------------
# Test has variables

do {
    my $template = <<'EOQ';
<!-- section header -->
<title>$title</title>
<!-- set $i = 0 -->
<!-- for @metadata -->
  <!-- set $i = $i + 1 -->
  <meta name="metadata$i" content="$name" />
<!-- endfor -->
<!-- endsection header -->
EOQ

    my $has_i = web_has_variables($template, '$i');
    is($has_i, 1, "test for variable \$i"); # test 25

    my $no_j = web_has_variables($template, '$j');
    is($no_j, 0, "test for variable \$j"); # test 26

    my $has_meta = web_has_variables($template, '@metadata');
    is($has_meta, 1, "test for variable \@metadata"); # test 27
}