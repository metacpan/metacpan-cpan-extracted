#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cron::Toolkit::Tree::TreeParser;
use Cron::Toolkit::Tree::MatchVisitor;
use Time::Moment;

# Test MatchVisitor on isolated nodes (e.g., steps, ranges, lists, specials)
# Assumes TreeParser builds correct AST; focuses on traversal/match logic

plan tests => 16;

# 1-2: Basic step (*/5 minute: wildcard base / step=5)
my $step_node = Cron::Toolkit::Tree::TreeParser->parse_field('*/5', 'minute');
my $visitor10 = Cron::Toolkit::Tree::MatchVisitor->new(value => 10, tm => undef);
is $step_node->traverse($visitor10), 1, "*/5 matches minute=10 (multiple of 5)";
my $visitor7 = Cron::Toolkit::Tree::MatchVisitor->new(value => 7, tm => undef);
is $step_node->traverse($visitor7), 0, "*/5 rejects minute=7 (not multiple)";

# 3-4: Single (exact match)
my $single_node = Cron::Toolkit::Tree::TreeParser->parse_field('30', 'minute');
is $single_node->traverse(Cron::Toolkit::Tree::MatchVisitor->new(value => 30, tm => undef)), 1, "single=30 matches 30";
is $single_node->traverse(Cron::Toolkit::Tree::MatchVisitor->new(value => 31, tm => undef)), 0, "single=30 rejects 31";

# 5-6: Range (10-14 hour)
my $range_node = Cron::Toolkit::Tree::TreeParser->parse_field('10-14', 'hour');
is $range_node->traverse(Cron::Toolkit::Tree::MatchVisitor->new(value => 12, tm => undef)), 1, "10-14 matches 12";
is $range_node->traverse(Cron::Toolkit::Tree::MatchVisitor->new(value => 9, tm => undef)), 0, "10-14 rejects 9";

# 7-8: List (1,15 dom)
my $list_node = Cron::Toolkit::Tree::TreeParser->parse_field('1,15', 'dom');
is $list_node->traverse(Cron::Toolkit::Tree::MatchVisitor->new(value => 1, tm => undef)), 1, "1,15 matches 1";
is $list_node->traverse(Cron::Toolkit::Tree::MatchVisitor->new(value => 10, tm => undef)), 0, "1,15 rejects 10";

# 9-10: Step with range base (10-20/3 minute)
my $step_range_node = Cron::Toolkit::Tree::TreeParser->parse_field('10-20/3', 'minute');
is $step_range_node->traverse(Cron::Toolkit::Tree::MatchVisitor->new(value => 10, tm => undef)), 1, "10-20/3 matches 10 (start)";
is $step_range_node->traverse(Cron::Toolkit::Tree::MatchVisitor->new(value => 16, tm => undef)), 1, "10-20/3 matches 16 ((16-10)%3==0)";

# 11-12: Last (L dom, needs tm context)
my $last_node = Cron::Toolkit::Tree::TreeParser->parse_field('L', 'dom');
my $tm_oct31 = Time::Moment->new(year => 2023, month => 10, day => 31);
my $visitor_last = Cron::Toolkit::Tree::MatchVisitor->new(value => 31, tm => $tm_oct31);
is $last_node->traverse($visitor_last), 1, "L matches Oct 31 (last day)";

my $tm_oct30 = Time::Moment->new(year => 2023, month => 10, day => 30);
my $visitor_notlast = Cron::Toolkit::Tree::MatchVisitor->new(value => 30, tm => $tm_oct30);
is $last_node->traverse($visitor_notlast), 0, "L rejects Oct 30 (not last)";

# 13-14: Nth (1#2 dow, 2nd Sunday)
my $nth_node = Cron::Toolkit::Tree::TreeParser->parse_field('1#2', 'dow');
my $tm_oct8_sun = Time::Moment->new(year => 2023, month => 10, day => 8);  # 2nd Sun
is $nth_node->traverse(Cron::Toolkit::Tree::MatchVisitor->new(value => 1, tm => $tm_oct8_sun)), 1, "1#2 matches Oct 8 (2nd Sunday)";

my $tm_oct1_sun = Time::Moment->new(year => 2023, month => 10, day => 1);  # 1st Sun
is $nth_node->traverse(Cron::Toolkit::Tree::MatchVisitor->new(value => 1, tm => $tm_oct1_sun)), 0, "1#2 rejects Oct 1 (1st Sunday)";

# 15-16: Nearest Weekday (16W dom, Oct 16=Mon, weekday)
my $nw_node = Cron::Toolkit::Tree::TreeParser->parse_field('16W', 'dom');
my $tm_oct16_mon = Time::Moment->new(year => 2023, month => 10, day => 16);
my $tm_oct15_sun = $tm_oct16_mon->minus_days(1);
is $nw_node->traverse(Cron::Toolkit::Tree::MatchVisitor->new(value => 16, tm => $tm_oct16_mon)), 1, "16W matches Oct 16 (weekday)";
is $nw_node->traverse(Cron::Toolkit::Tree::MatchVisitor->new(value => 15, tm => $tm_oct15_sun)), 0, "16W rejects Oct 15 (not nearest)";

done_testing;
