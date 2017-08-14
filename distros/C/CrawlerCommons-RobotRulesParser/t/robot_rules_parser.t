#!/usr/bin/env perl

=pod

=head1 NAME

robot_rules_parser.t - unit test for ...

=head1 DESCRIPTION



=cut

# MODULE IMPORTS
########################
# Pragmas
#----------------------#
use 5.10.1;
use strict;
use warnings;
use utf8;

# CPAN/Core Imports
#----------------------#
use Const::Fast;
use Log::Log4perl qw(:easy);
use Path::Tiny;
use Test::Most;
use Try::Tiny;

# VARIABLES/CONSTANTS
########################
const my $DEBUG                 => $ENV{DEBUG} // 1;
const my $TEST                  => $ENV{TEST} // 1;

const my $LF                    => "\n";
const my $CR                    => "\r";
const my $CRLF                  => "\r\n";
const my $FAKE_ROBOTS_URL       => "http://domain.com";

# RUNTIME CONFIGURATION
########################
BEGIN {
    $| = 1;
    Log::Log4perl->easy_init($ERROR);
    use_ok('CrawlerCommons::RobotRulesParser');
}

# SM Imports
########################

# BODY
########################
# Setup
#----------------------#
try {
    # test empty rules
    subtest "test empty rules", sub { test_empty_rules(); };

    # test query param in disallow
    subtest "test query param in disallow", sub {
        test_query_param_in_disallow(); };

    # test google pattern matching
    subtest "google pattern matching", sub { test_google_pattern_matching(); };

    # test commented-out lines
    subtest "test commented-out line", sub { test_commented_out_lines(); };

    # test robots.txt always allow
    subtest "test robots.txt always allow", sub {
        test_robots_text_always_allowed(); };

    # test agent not listed
    subtest "test agent not listed", sub { test_agent_not_listed(); };

    # test non-ascii encoding
    subtest "test non-ascii encoding", sub { test_non_ascii_encoding(); };

    # test simplest allow all
    subtest "test simplest allow all", sub { test_simplest_allow_all(); };

    # test mixed endings
    subtest "test mixed endings", sub { test_mixed_endings(); };

    # test rfp cases
    subtest "test rfp cases", sub { test_rfp_cases(); };

    # test apache nutch cases
    subtest "test nutch cases", sub { test_nutch_cases(); };

    # test html markup in robots.txt
    subtest "test html markup in robots.txt", sub {
        test_html_markup_in_robots_txt(); };

    # test ignore of html
    subtest "test ignore of html", sub {
        test_ignore_of_html(); };

    # test heritrix cases
    subtest 'test heritrix cases', sub { test_heritrix_cases(); };

    # test case-sensitive paths
    subtest 'test case-sensitive paths', sub { test_case_sensitive_paths(); };

    # test empty disallow
    subtest 'test empty disallow', sub { test_empty_disallow(); };

    # test empty allow
    subtest 'test empty allow', sub { test_empty_allow(); };

    # test multi wildcard
    subtest 'test multi wildcard', sub { test_multi_wildcard(); };

    # test multi matches
    subtest 'test multi matches', sub { test_multi_matches(); };

    # test multi agent names
    subtest 'test multi agent names', sub { test_multi_agent_names(); };

    # test multi-word agent name
    subtest 'test multi-word agent name', sub { test_multi_word_agent_name(); };

    # test unsupported fields
    subtest 'test unsupported fields', sub { test_unsupported_fields(); };

    # test acap fields
    subtest 'test acap fields', sub { test_acap_fields(); };

    # test status code creation - not implemented

    # test crawl delay
    subtest 'test crawl delay', sub { test_crawl_delay(); };

    # test big crawl delay
    subtest 'test big crawl delay', sub { test_big_crawl_delay(); };

    # test broken krugle robots.txt file
    subtest "test broken krugle rotbots txt file",
      sub { test_broken_krugle_robots_txt_file() };

    # test utf-8 bom
    subtest "test robots with utf8 bom", sub { test_robots_with_utf8_bom() };

    # test utf-16le bom
    subtest "test robots with utf16le bom",
      sub { test_robots_with_utf16le_bom() };

    # test utf-16be bom
    subtest "test robots with utf16be bom",
      sub { test_robots_with_utf16be_bom() };

    # test floating point crawl delay
    subtest "test floating point crawl delay",
      sub { test_floating_point_crawl_delay() };

    # test ignoring host
    subtest "test ignoring host", sub { test_ignoring_host() };

    # test directive typos
    subtest "test directive typos", sub { test_directive_typos() };

    # test format errors
    subtest "test format errors", sub { test_format_errors() };

    # test extended standard
    subtest "test extended standard", sub { test_extended_standard() };

    # test sitemap
    subtest "test sitemap", sub { test_sitemap() };

    # test relative sitemap
    subtest "test relative sitemap", sub { test_relative_sitemap() };

    # test many user agents
    subtest "test many user agents", sub { test_many_user_agents() };

    # test malformed path in robots file
    subtest "test malformed path in robots file",
      sub { test_malformed_path_in_robots_file() };

    # test dos line endings
    subtest "test dos line endings", sub { test_dos_line_endings() };

    # test amazon robots with wildcards
    subtest "test amazon robots with wildcards",
      sub { test_amazon_robots_with_wildcards() };

    # test allow before disallow
    subtest "test allow before disallow", sub { test_allow_before_disallow() };

    # test space in multiple user agent names
    subtest "test space in multiple user agent names",
      sub { test_spaces_in_multiple_user_agent_names() };

    # test sitemap at end of file
    subtest "test sitemap at end of file",
      sub { test_sitemap_at_end_of_file() };
}
catch {
    say STDERR "Testing ended unexpectedly: $_";
};

done_testing;


# SUBROUTINES
########################
#-----------------------------------------------------------------------------#
sub create_robot_rules {
    my ($crawler_name, $content) = @_;

    my $parser = CrawlerCommons::RobotRulesParser->new;

    return
      $parser->parse_content(
        $FAKE_ROBOTS_URL,$content,"text/plain",$crawler_name);
}
#-----------------------------------------------------------------------------#
sub test_case_sensitive_paths {
    my $robots_txt =
      join $CRLF, "User-agent: *", "Allow: /AnyPage.html",
        "Allow: /somepage.html", "Disallow: /";

    my $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);
    say STDERR Data::Dumper->Dump([$robot_rules],['rules']) if $DEBUG > 1;
    is($robot_rules->is_allowed("http://www.domain.com/AnyPage.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/anypage.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/somepage.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/SomePage.html"), 0);
}
#-----------------------------------------------------------------------------#
sub test_commented_out_lines {
    my $robots_txt =
      join( $LF,
        "#user-agent: testAgent", "", "#allow: /index.html",
        "#allow: /test", "", "#user-agent: test", "", "#allow: /index.html",
        "#disallow: /test", "", "#user-agent: someAgent", "",
        "#disallow: /index.html", "#disallow: /test", "");
    my $robot_rules = create_robot_rules( "Any-darn-crawler", $robots_txt );
    is($robot_rules->is_allowed( "http://www.domain.com/anypage.html" ), 1);
}
#-----------------------------------------------------------------------------#
sub test_acap_fields {
    my $robots_txt =
      "acap-crawler: *" . $CRLF . "acap-disallow-crawl: /ultima_ora/";
    my $parser = CrawlerCommons::RobotRulesParser->new;
    my $rr = $parser->parse_content("url", $robots_txt, "text/plain", "foobot");
    is($parser->num_warnings(), 0);
}
#-----------------------------------------------------------------------------#
sub test_agent_not_listed {
    # Access is assumed to be allowed, if no rules match an agent.
    my $robots_txt = join( $CRLF,
      "User-agent: crawler1", "Disallow: /index.html", "Allow: /", "",
      "User-agent: crawler2", "Disallow: /");

    my $robot_rules = create_robot_rules("crawler3", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/anypage.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/index.html"), 1);
}
#-----------------------------------------------------------------------------#
sub test_allow_before_disallow {
    my $robots_txt = "User-agent: *" . $CRLF . "Disallow: /fish" . $CRLF .
      "Allow: /fish" . $CRLF;
    my $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);
#    say STDERR Data::Dumper->Dump([$robot_rules],['allow_disallow']) if $DEBUG;
    is($robot_rules->is_allowed("http://www.fict.com/fish"), 1);
}
#-----------------------------------------------------------------------------#
sub test_amazon_robots_with_wildcards {
    my $robot_rules = create_robot_rules("Any-darn-crawler",
        path(__FILE__)->parent->child("./robots/wildcards.txt")
          ->slurp_utf8);
#    say STDERR Data::Dumper->Dump([$robot_rules],['amzn_wildcards']) if $DEBUG;
    is($robot_rules->is_allowed("http://www.fict.com/wishlist/bogus"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/wishlist/universal/page"),
       1);
    is($robot_rules
         ->is_allowed("http://www.fict.com/anydirectoryhere/gcrnsts"),
       0);
}
#-----------------------------------------------------------------------------#
sub test_big_crawl_delay {
    my $robots_txt = "User-agent: *" . $CR . "Crawl-delay: 3600" . $CR .
      "Disallow:" . $CR;

    my $robot_rules = create_robot_rules("bixo", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/"), 0,
       "disallow all if huge crawl delay");
}
#-----------------------------------------------------------------------------#
sub test_broken_krugle_robots_txt_file {
    my $robots_txt = "User-agent: *" . $CR . "Disallow: /maintenance.html" .
      $CR . "Disallow: /perl/" . $CR . "Disallow: /cgi-bin/" . $CR .
        "Disallow: /examples/" . $CR . "Crawl-delay: 3" . $CR . "" . $CR .
          "User-agent: googlebot" . $CR . "Crawl-delay: 1" . $CR . "" . $CR .
            "User-agent: qihoobot" . $CR . "Disallow: /";

    my $robot_rules = create_robot_rules("googlebot/2.1", $robots_txt);
    is($robot_rules->is_allowed("http://www.krugle.com/examples/index.html"), 1);
}
#-----------------------------------------------------------------------------#
sub test_crawl_delay {
    my $robots_txt = "User-agent: bixo" . $CR . "Crawl-delay: 10" . $CR .
      "User-agent: foobot" . $CR . "Crawl-delay: 20" . $CR . "User-agent: *" .
        $CR . "Disallow:/baz" . $CR;

    my $robot_rules = create_robot_rules("bixo", $robots_txt);
    is(10000, $robot_rules->crawl_delay,
       "testing crawl delay for agent bixo - rule 1");

    $robots_txt = "User-agent: foobot" . $CR . "Crawl-delay: 20" . $CR .
      "User-agent: *" . $CR . "Disallow:/baz" . $CR;

    $robot_rules = create_robot_rules("bixo", $robots_txt);
    is($CrawlerCommons::RobotRules::UNSET_CRAWL_DELAY ,
       $robot_rules->crawl_delay,
       "testing crawl delay for agent bixo - rule 2");
}
#-----------------------------------------------------------------------------#
sub test_directive_typos {
    my $robot_rules =
      create_robot_rules("bot1",
        path(__FILE__)->parent->child("./robots/directive-typos-robots.txt")
          ->slurp_utf8);
    is($robot_rules->is_allowed("http://domain.com/desallow/"), 0, "desallow");
    is($robot_rules->is_allowed("http://domain.com/dissalow/"), 0, "dissalow");

    $robot_rules =
      create_robot_rules("bot2",
        path(__FILE__)->parent->child("./robots/directive-typos-robots.txt")
          ->slurp_utf8);
    is($robot_rules->is_allowed("http://domain.com/useragent/"), 0,
       "useragent");;

    $robot_rules =
      create_robot_rules("bot3",
        path(__FILE__)->parent->child("./robots/directive-typos-robots.txt")
          ->slurp_utf8);
    is($robot_rules->is_allowed("http://domain.com/useg-agent/"), 0,
       "useg-agent");

    $robot_rules =
      create_robot_rules("bot4",
        path(__FILE__)->parent->child("./robots/directive-typos-robots.txt")
          ->slurp_utf8);
    is($robot_rules->is_allowed("http://domain.com/useragent-no-colon/"), 0,
       "useragent-no-colon");
}
#-----------------------------------------------------------------------------#
sub test_dos_line_endings {
    my $robot_rules = create_robot_rules("bot1",
        path(__FILE__)->parent->child("./robots/dos-line-endings.txt")
          ->slurp_utf8);
#    say STDERR Data::Dumper->Dump([$robot_rules],['dos_line_end']) if $DEBUG;
    is($robot_rules->is_allowed("http://ford.com/"), 1, "Allowed URL");
    is($robot_rules->crawl_delay, 1000);
}
#-----------------------------------------------------------------------------#
sub test_empty_allow {
    my $robots_txt = "User-agent: *" . $CRLF . "Allow:";
    my $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/anypage.html"), 1);
}
#-----------------------------------------------------------------------------#
sub test_empty_disallow {
    my $robots_txt = "User-agent: *" . $CRLF . "Disallow:";
    my $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/anypage.html"), 1);
}
#-----------------------------------------------------------------------------#
sub test_empty_rules {
    my $robot_rules = create_robot_rules("Any-darn-crawler", "");
    is($robot_rules->is_allowed( "http://www.domain.com/anypage.html" ), 1,
       'test empty rules');
}
#-----------------------------------------------------------------------------#
sub test_extended_standard {
    my $parser = CrawlerCommons::RobotRulesParser->new;
    my $rr = $parser->parse_content(
      "url",
      path(__FILE__)->parent->child("./robots/extended-standard-robots.txt")
        ->slurp_utf8,
      "text/plain",
      "foobot");
    is($parser->num_warnings(), 0);
}
#-----------------------------------------------------------------------------#
sub test_floating_point_crawl_delay {
    my $robots_txt = "User-agent: *" . $CR . "Crawl-delay: 0.5" . $CR .
      "Disallow:" . $CR;
    my $robot_rules = create_robot_rules("bixo", $robots_txt);
    is($robot_rules->crawl_delay, 500);
}
#-----------------------------------------------------------------------------#
sub test_format_errors {
    my $robot_rules =
      create_robot_rules("bot1",
        path(__FILE__)->parent->child("./robots/format-errors-robots.txt")
          ->slurp_utf8);
    is($robot_rules->is_allowed("http://domain.com/whitespace-before-colon/"),
       0,
       "whitespace-before-colon");
    is($robot_rules->is_allowed("http://domain.com/no-colon/"), 0, "no-colon");

    $robot_rules =
      create_robot_rules("bot2",
        path(__FILE__)->parent->child("./robots/format-errors-robots.txt")
          ->slurp_utf8);
    is($robot_rules->is_allowed("http://domain.com/no-colon-useragent/"), 0,
       "no-colon-useragent");

    $robot_rules =
      create_robot_rules("bot3",
        path(__FILE__)->parent->child("./robots/format-errors-robots.txt")
          ->slurp_utf8);
    is($robot_rules->is_allowed("http://domain.com/whitespace-before-colon/"),
       1,
       "whitespace-before-colon");
}
#-----------------------------------------------------------------------------#
sub test_google_pattern_matching {
    # Test for /fish
    my $robots_txt = join( $CRLF, "User-agent: *", "Disallow: /fish", "" );
    my $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.com/fish"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fish.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fish/salmon.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fishheads"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fishheads/yummy.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fish.php?id=anything"), 0);

    is($robot_rules->is_allowed("http://www.fict.com/Fish.asp"), 1);
    is($robot_rules->is_allowed("http://www.fict.com/catfish"), 1);
    is($robot_rules->is_allowed("http://www.fict.com/?id=fish"), 1);
    is($robot_rules->is_allowed("http://www.fict.com/fis"), 1);

    # Test for /fish*
    $robots_txt = join( $CRLF, "User-agent: *", "Disallow: /fish*", "" );
    $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.com/fish"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fish.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fish/salmon.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fishheads"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fishheads/yummy.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fish.php?id=anything"), 0);

    is($robot_rules->is_allowed("http://www.fict.com/Fish.asp"), 1);
    is($robot_rules->is_allowed("http://www.fict.com/catfish"), 1);
    is($robot_rules->is_allowed("http://www.fict.com/?id=fish"), 1);
    is($robot_rules->is_allowed("http://www.fict.com/fis"), 1);

    # Test for /fish/
    $robots_txt = join($CRLF, "User-agent: *", "Disallow: /fish/", "");

    $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.com/fish/"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fish/?id=anything"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fish/salmon.htm"), 0);

    is($robot_rules->is_allowed("http://www.fict.com/fish"), 1);
    is($robot_rules->is_allowed("http://www.fict.com/fish.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.com/Fish/Salmon.asp"), 1);

    # Test for /*.php
    $robots_txt = join($CRLF, "User-agent: *", "Disallow: /*.php", "");

    $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);;
    is($robot_rules->is_allowed("http://www.fict.com/filename.php"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/folder/filename.php"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/folder/filename.php?parameters"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/folder/any.php.file.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/filename.php/"), 0);

    is($robot_rules->is_allowed("http://www.fict.com/"), 1);
    is($robot_rules->is_allowed("http://www.fict.com/windows.PHP"), 1);

    # Test for /*.php$
    $robots_txt = join($CRLF, "User-agent: *", 'Disallow: /*.php$', "");

    $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);;
    is($robot_rules->is_allowed("http://www.fict.com/filename.php"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/folder/filename.php"), 0);

    is($robot_rules->is_allowed("http://www.fict.com/filename.php?parameters"), 1);
    is($robot_rules->is_allowed("http://www.fict.com/filename.php/"), 1);
    is($robot_rules->is_allowed("http://www.fict.com/filename.php5"), 1);
    is($robot_rules->is_allowed("http://www.fict.com/windows.PHP"), 1);

    # Test for /fish*.php
    $robots_txt = join($CRLF, "User-agent: *", "Disallow: /fish*.php", "");

    $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);;
    is($robot_rules->is_allowed("http://www.fict.com/fish.php"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fishheads/catfish.php?parameters"), 0);

    is($robot_rules->is_allowed("http://www.fict.com/Fish.PHP"), 1);

    # Test rule with multiple '*' characters
    $robots_txt = join($CRLF, "User-agent: *", "Disallow: /*fish*.php", "");

    $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);;
    is($robot_rules->is_allowed("http://www.fict.com/fish.php"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/superfishheads/catfish.php?parameters"), 0);
    is($robot_rules->is_allowed("http://www.fict.com/fishheads/catfish.htm"), 1);
}
#-----------------------------------------------------------------------------#
sub test_heritrix_cases {
    my $robots_txt =
      "User-agent: *\n" . "Disallow: /cgi-bin/\n" .
      "Disallow: /details/software\n" . "\n" . "User-agent: denybot\n" .
      "Disallow: /\n" . "\n" . "User-agent: allowbot1\n" . "Disallow: \n" .
      "\n" . "User-agent: allowbot2\n" . "Disallow: /foo\n" . "Allow: /\n" .
      "\n" . "User-agent: delaybot\n" . "Disallow: /\n" . "Crawl-Delay: 20\n" .
      "Allow: /images/\n";

    my $robot_rules = create_robot_rules("Mozilla allowbot1 99.9", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/path"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/"), 1);

    $robot_rules = create_robot_rules("Mozilla allowbot2 99.9", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/path"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/foo"), 0);

    $robot_rules = create_robot_rules("Mozilla denybot 99.9", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/path"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/"), 0);
    is($CrawlerCommons::RobotRules::UNSET_CRAWL_DELAY,
       $robot_rules->crawl_delay);

    $robot_rules = create_robot_rules("Mozilla anonbot 99.9", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/path"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/cgi-bin/foo.pl"), 0);

    $robot_rules = create_robot_rules("Mozilla delaybot 99.9", $robots_txt);
    is(20000, $robot_rules->crawl_delay);
}
#-----------------------------------------------------------------------------#
sub test_html_markup_in_robots_txt {
    my $robots_txt =
      join "", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\"><HTML>\n",
        "<HEAD>\n", "<TITLE>/robots.txt</TITLE>\n", "</HEAD>\n", "<BODY>\n",
        "User-agent: anybot<BR>\n", "Disallow: <BR>\n",
        "Crawl-Delay: 10<BR>\n", "\n", "User-agent: *<BR>\n",
        "Disallow: /<BR>\n", "Crawl-Delay: 30<BR>\n", "\n", "</BODY>\n",
        "</HTML>\n";

    my $robot_rules = create_robot_rules("anybot", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/index.html"), 1);
    is(10000, $robot_rules->crawl_delay);

    $robot_rules = create_robot_rules("bogusbot", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/index.html"), 0);
    is(30000, $robot_rules->crawl_delay);
}
#-----------------------------------------------------------------------------#
sub test_ignore_of_html {
    my $robots_txt =
      "<HTML><HEAD><TITLE>Site under Maintenance</TITLE></HTML>";
    my $robot_rules = create_robot_rules("anybot", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/"), 1);
    is($robot_rules->_defer_visits, 0);
}
#-----------------------------------------------------------------------------#
sub test_ignoring_host {
    my $robot_rules = create_robot_rules("foobot",
      path(__FILE__)->parent->child("./robots/www.flot.com-robots.txt")
        ->slurp_utf8);
    is($robot_rules->is_allowed("http://www.flot.com/img/"), 0,
       "Disallow img directory")
}
#-----------------------------------------------------------------------------#
sub test_malformed_path_in_robots_file {
    my $robot_rules = create_robot_rules("bot1",
        path(__FILE__)->parent->child("./robots/malformed-path.txt")
          ->slurp_utf8);
    is($robot_rules->is_allowed(
         "http://en.wikipedia.org/wiki/Wikipedia_talk:Mediation_Committee/"),
       0, "Disallowed URL");
    is($robot_rules->is_allowed("http://en.wikipedia.org/wiki/"), 1,
       "Regular URL");
}
#-----------------------------------------------------------------------------#
sub test_many_user_agents {
    my $robot_rules = create_robot_rules("wget",
        path(__FILE__)->parent->child("./robots/many-user-agents.txt")
          ->slurp_utf8);
    is($robot_rules->is_allowed("http://domain.com/"), 0, "many-user-agents");

    $robot_rules = create_robot_rules("mysuperlongbotnamethatmatchesnothing",
        path(__FILE__)->parent->child("./robots/many-user-agents.txt")
          ->slurp_utf8);
#    say STDERR Data::Dumper->Dump([$robot_rules],['rules']);
    is($robot_rules->is_allowed("http://domain.com/"), 1, "many-user-agents");
    is($robot_rules->is_allowed("http://domain.com/bot-trap/"), 0,
       "many-user-agents");
}
#-----------------------------------------------------------------------------#
sub test_mixed_endings {
    my $robots_txt =
      join "", "# /robots.txt for http://www.fict.org/", $CRLF, 
        '# comments to webmaster@fict.org', "User-agent: unhipbot", $CR, $LF,
        "Disallow: /", $CR, "", $CRLF, "User-agent: webcrawler", $LF,
        "User-agent: excite", $CR, "Disallow: ", "\u0085", $CR,
        "User-agent: *", $CRLF, "Disallow: /org/plans.html", $LF,
        "Allow: /org/", $CR, "Allow: /serv", $CRLF, "Allow: /~mak", $LF,
        "Disallow: /", $CRLF;

    my $robot_rules = create_robot_rules("WebCrawler/3.0", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.org/"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/index.html"), 1);

    $robot_rules = create_robot_rules("Unknown/1.0", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.org/"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/index.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/robots.txt"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/server.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/services/fast.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/services/slow.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/orgo.gif"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/org/about.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/org/plans.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/%7Ejim/jim.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/%7Emak/mak.html"), 1);
}
#-----------------------------------------------------------------------------#
sub test_multi_agent_names {
    my $robots_txt =
      "User-agent: crawler1 crawler2" . $CRLF . "Disallow: /index.html" .
        $CRLF . "Allow: /";
    my $robot_rules = create_robot_rules("crawler2", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/index.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/anypage.html"), 1);
}
#-----------------------------------------------------------------------------#
sub test_multi_matches {
    my $robots_txt =
      "User-agent: crawlerbot" . $CRLF . "Disallow: /index.html" .
        $CRLF . "Allow: /" . $CRLF . $CRLF . "User-agent: crawler" . $CRLF .
          "Disallow: /";
    my $robot_rules = create_robot_rules("crawlerbot", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/index.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/anypage.html"), 1);
}
#-----------------------------------------------------------------------------#
sub test_multi_wildcard {
    my $robots_txt =
      "User-agent: *" . $CRLF . "Disallow: /index.html" . $CRLF . "Allow: /" .
        $CRLF . $CRLF . "User-agent: *" . $CRLF . "Disallow: /";
    my $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/index.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/anypage.html"), 1);
}
#-----------------------------------------------------------------------------#
sub test_multi_word_agent_name {
    my $robots_txt =
      "User-agent: Download Ninja" . $CRLF . "Disallow: /index.html" .
        $CRLF . "Allow: /";
    my $robot_rules = create_robot_rules("Download Ninja", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/index.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/anypage.html"), 1);
}
#-----------------------------------------------------------------------------#
sub test_non_ascii_encoding {
    my $robots_txt =
      join $CRLF, "User-agent: *", " # \u00A2 \u20B5", "Disallow:";

    my $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/anypage.html"), 1);
}
#-----------------------------------------------------------------------------#
sub test_nutch_cases {
    my $nutch_robots_txt =
      join( $CR,
        "User-Agent: Agent1 #foo",
        "Disallow: /a",
        "Disallow: /b/a",
        "#Disallow: /c",
        "",
        "",
        "User-Agent: Agent2 Agent3#foo",
        "User-Agent: Agent4",
        "Disallow: /d",
        "Disallow: /e/d/",
        "",
        "User-Agent: *",
        "Disallow: /foo/bar/",
        ""
      );
    my $robot_rules = create_robot_rules("Agent1", $nutch_robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/a"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/a/"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/a/bloh/foo.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/b"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/a"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/b/a/index.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/b/b/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/b/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/d"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/d/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/d"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/d/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/doh.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/f/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/foo/bar/baz.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/f/"), 1);

    $robot_rules = create_robot_rules("Agent2", $nutch_robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/a/"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/a/bloh/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/b/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/b/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/d"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/d/a"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/e/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/d"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/d/foo.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/e/doh.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/f/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/foo/bar/baz.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/f/"), 1);

    $robot_rules = create_robot_rules("Agent3", $nutch_robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/a/"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/a/bloh/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/b/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/b/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/d"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/d/a"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/e/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/d"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/d/foo.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/e/doh.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/f/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/foo/bar/baz.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/f/"), 1);

    $robot_rules = create_robot_rules("Agent4", $nutch_robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/a/"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/a/bloh/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/b/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/b/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/d"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/d/a"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/e/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/d"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/d/foo.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/e/doh.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/f/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/foo/bar/baz.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/f/"), 1);

    $robot_rules = create_robot_rules("Agent5", $nutch_robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/a/"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/a/bloh/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/b/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/b/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/d"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/d/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/d"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/d/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/doh.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/f/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/foo/bar/baz.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/f/"), 1);

    # Note that the SimpleRobotRulesParser only parses the rule set of the
    # first matching agent name. For the following example, the parser
    # returns only the rules matching 'Agent1'.
    $robot_rules = create_robot_rules("Agent5,Agent2,Agent1,Agent3,*", $nutch_robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/a"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/a/"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/a/bloh/foo.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/b"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/b/a"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/b/a/index.html"), 0);
    is($robot_rules->is_allowed("http://www.domain.com/b/b/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/c/b/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/d"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/d/a"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/a/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/d"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/d/foo.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/e/doh.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/f/index.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/foo/bar/baz.html"), 1);
    is($robot_rules->is_allowed("http://www.domain.com/f/"), 1);
}
#-----------------------------------------------------------------------------#
sub test_query_param_in_disallow {
    my $robots_txt =
      join( $CRLF,
        "User-agent: *",
        "Disallow: /index.cfm?fuseaction=sitesearch.results*" );

    my $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);

    is($robot_rules->is_allowed("http://searchservice.domain.com/index.cfm?fuseaction=sitesearch.results&type=People&qry=california&pg=2" ),
       0,
      'query param in disallow');
    
}
#-----------------------------------------------------------------------------#
sub test_relative_sitemap {
    my $robot_rules =
      create_robot_rules("bot1",
        path(__FILE__)->parent->child("./robots/relative-sitemap-robots.txt")
          ->slurp_utf8);
    is($robot_rules->sitemaps_size, 1, "Found sitemap");
}
#-----------------------------------------------------------------------------#
sub test_rfp_cases {
    # Run through all of the tests that are part of the robots.txt RFP
    # http://www.robotstxt.org/norobots-rfc.txt
    my $robots_txt =
      join $CRLF, "# /robots.txt for http://www.fict.org/",
        '# comments to webmaster@fict.org', "", "User-agent: unhipbot",
        "Disallow: /", "", "", "User-agent: webcrawler", "User-agent: excite",
        "Disallow: ", "", "User-agent: *", "Disallow: /org/plans.html",
        "Allow: /org/", "Allow: /serv", "Allow: /~mak", "Disallow: /", "";

    my $robot_rules = create_robot_rules("UnhipBot/0.1", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.org/"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/index.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/robots.txt"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/server.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/services/fast.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/services/slow.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/orgo.gif"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/org/about.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/org/plans.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/%7Ejim/jim.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/%7Emak/mak.html"), 0);

    $robot_rules = create_robot_rules("WebCrawler/3.0", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.org/"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/index.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/robots.txt"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/server.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/services/fast.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/services/slow.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/orgo.gif"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/org/about.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/org/plans.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/%7Ejim/jim.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/%7Emak/mak.html"), 1);

    $robot_rules = create_robot_rules("Excite/1.0", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.org/"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/index.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/robots.txt"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/server.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/services/fast.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/services/slow.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/orgo.gif"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/org/about.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/org/plans.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/%7Ejim/jim.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/%7Emak/mak.html"), 1);

    $robot_rules = create_robot_rules("Unknown/1.0", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.org/"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/index.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/robots.txt"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/server.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/services/fast.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/services/slow.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/orgo.gif"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/org/about.html"), 1);
    is($robot_rules->is_allowed("http://www.fict.org/org/plans.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/%7Ejim/jim.html"), 0);
    is($robot_rules->is_allowed("http://www.fict.org/%7Emak/mak.html"), 1);
}
#-----------------------------------------------------------------------------#
sub test_robots_text_always_allowed {
    my $robots_txt = join( $CRLF, "User-agent: *", "Disallow: /");
    my $robot_rules = create_robot_rules("Any-darn-crawler", "");
    is($robot_rules->is_allowed( "http://www.domain.com/robots.txt" ), 1);
}
#-----------------------------------------------------------------------------#
sub test_robots_with_utf8_bom {
    my $robot_rules = create_robot_rules("foobot",
      path(__FILE__)->parent->child("robots/robots-with-utf8-bom.txt")
        ->slurp_raw
    );

    is($robot_rules->is_allowed("http://www.domain.com/profile"), 0,
       "Disallow match against *");
}
#-----------------------------------------------------------------------------#
sub test_robots_with_utf16le_bom {
    my $robot_rules = create_robot_rules("foobot",
      path(__FILE__)->parent->child("robots/robots-with-utf16le-bom.txt")
        ->slurp_raw
    );

    is($robot_rules->is_allowed("http://www.domain.com/profile"), 0,
       "Disallow match against *");
}
#-----------------------------------------------------------------------------#
sub test_robots_with_utf16be_bom {
    my $robot_rules = create_robot_rules("foobot",
      path(__FILE__)->parent->child("robots/robots-with-utf16be-bom.txt")
        ->slurp_raw
    );

    is($robot_rules->is_allowed("http://www.domain.com/profile"), 0,
       "Disallow match against *");
}
#-----------------------------------------------------------------------------#
sub test_simplest_allow_all {
    my $robots_txt = join $CRLF, "User-agent: *", "Disallow:";
    my $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/anypage.html"), 1);
}
#-----------------------------------------------------------------------------#
sub test_sitemap_at_end_of_file {
    my $robots_txt = "User-agent: a" . $CRLF . "Disallow: /content/dam/" .
      $CRLF . $CRLF . "User-agent: b" . $CRLF . "Disallow: /content/dam/" .
        $CRLF . $CRLF . "User-agent: c" . $CRLF . "Disallow: /content/dam/" .
          $CRLF . $CRLF . $CRLF . "Sitemap: https://wwwfoocom/sitemapxml";
    my $robot_rules = create_robot_rules("a", $robots_txt);
    is($robot_rules->sitemaps_size, 1);
    is($robot_rules->get_sitemap(0), "https://wwwfoocom/sitemapxml");
}
#-----------------------------------------------------------------------------#
sub test_sitemap {
    my $robot_rules =
      create_robot_rules("bot1",
        path(__FILE__)->parent->child("./robots/sitemap-robots.txt")
          ->slurp_utf8);
    is($robot_rules->sitemaps_size, 3, "Found sitemap");
    my $url = $robot_rules->get_sitemap( 2 );
    isnt($url, lc($url), "Sitemap case check");
}
#-----------------------------------------------------------------------------#
sub test_spaces_in_multiple_user_agent_names {
    my $robots_txt =
      "User-agent: One, Two, Three" . $CRLF . "Disallow: /" . $CRLF . "" .
        $CRLF . "User-agent: *" . $CRLF . "Allow: /" . $CRLF;
    my $robot_rules = create_robot_rules("One", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.com/fish"), 0);

    $robot_rules = create_robot_rules("Two", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.com/fish"), 0);

    $robot_rules = create_robot_rules("Three", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.com/fish"), 0);

    $robot_rules = create_robot_rules("Any-darn-crawler", $robots_txt);
    is($robot_rules->is_allowed("http://www.fict.com/fish"), 1);
}
#-----------------------------------------------------------------------------#
sub test_unsupported_fields {
    my $robots_txt =
      "User-agent: crawler1" . $CRLF . "Disallow: /index.html" .
        $CRLF . "Allow: /" . $CRLF . "newfield: 234" . $CRLF .
          "User-agent: crawler2" . $CRLF . "Disallow: /";
    my $robot_rules = create_robot_rules("crawler2", $robots_txt);
    is($robot_rules->is_allowed("http://www.domain.com/anypage.html"), 0);
}
#-----------------------------------------------------------------------------#

