#!/usr/bin/perl -I..lib -Ilib
use strict;
use Test::More tests => 8;

BEGIN { use_ok("CSS::Watcher::Parser"); }

my $parser =  CSS::Watcher::Parser->new();

subtest "Comments" => sub {
    my ($classes, $ids) = $parser->parse_css(<<CSS)
/* .class1 {foo: bar; zzz: xxx} */
CSS
        ;
    is_deeply($classes, {}, "no classes");
    is_deeply($classes, {}, "no ids");
};

subtest "Simple css, class" => sub {
    my ($classes) = $parser->parse_css(<<CSS)
.class1
 {foo: bar;
  zzz: xxx}
CSS
        ;
    my $expect = {"global" => {"class1" => 1}};
    is_deeply($classes, $expect, "class selector");
    
};

subtest "Simple css, Ids" => sub {
    my ($classes, $ids) = $parser->parse_css(<<CSS)
#id1 {foo: bar; zzz: xxx} */
CSS
        ;
    my $expect = {"global" => {"id1" => 1}};
    is_deeply($ids, $expect, "id selector");
    
};

subtest "Multiple class selector" => sub {
    my ($classes) = $parser->parse_css(<<CSS)
.fv-form-horizontal.fv-form-foundation {foo: bar; zzz: xxx}
CSS
        ;

    my $expect = {"global" => {'fv-form-horizontal' => 1,
                               'fv-form-foundation' => 1}};
    is_deeply($classes, $expect, "multiple class");
    
};

subtest "Multiple class selector for tag" => sub {
    my ($classes) = $parser->parse_css(<<CSS)
div.fv-form-horizontal.fv-form-foundation {foo: bar; zzz: xxx}
CSS
        ;

    my $expect = {"div" => {'fv-form-horizontal' => 1,
                               'fv-form-foundation' => 1}};
    is_deeply($classes, $expect, "multiple class");
    
};

subtest "Complex css" => sub {
    my ($classes, $ids) = $parser->parse_css(<<CSS)
div.container {color: red}
#abc, div.col {}
/* div.container2 {color: red} */
/* minifi */
p#abc{color:green}a.small,.big{}
CSS
        ;
    my $expect_classes = {global => {big => 1},
                          div => {container => 1, col => 1},
                          a => {small => 1}};
    my $expect_ids = {global => {abc => 1},
                      p => {abc => 1}};
    is_deeply($classes, $expect_classes, "Classes list");
    is_deeply($ids, $expect_ids, "Ids list");
};

subtest '@media nested classes and ids' => sub {
    my ($classes, $ids) = $parser->parse_css(<<CSS)
\@media (min-width: 768px) {
  div.container {color: red}
  #abc, div.col {}
/* div.container2 {color: red} */
/* minifi */
p#abc{color:red}a.small,.big{}
}
CSS
        ;
    my $expect_classes = {global => {big => 1},
                          div => {container => 1, col => 1},
                          a => {small => 1}};
    my $expect_ids = {global => {abc => 1},
                      p => {abc => 1}};
    is_deeply($classes, $expect_classes, "Classes list");
    is_deeply($ids, $expect_ids, "Ids list");
}
