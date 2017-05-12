# -*- Mode: Perl; -*-

=head1 NAME

7_template_00_base.t - Test the basic language functionality of CGI::Ex::Template - including many edge cases

=head1 DESCRIPTION

Test the basics of CGI::Ex::Template inheritance - but leave the full test suite to Template::Alloy.

=cut

use vars qw($module $is_tt);
BEGIN {
    $module = 'CGI::Ex::Template';
    if (grep {/tt/i} @ARGV) {
        $module = 'Template';
    }
    $is_tt = $module eq 'Template';
};

use strict;
use Test::More tests => ! $is_tt ? 46 : 45;
use Data::Dumper qw(Dumper);

use_ok($module);

###----------------------------------------------------------------###

sub process_ok { # process the value and say if it was ok
    my $str  = shift;
    my $test = shift;
    my $vars = shift || {};
    my $conf = local $vars->{'tt_config'} = $vars->{'tt_config'} || [];
    my $obj  = shift || $module->new(@$conf); # new object each time
    my $out  = '';
    my $line = (caller)[2];
    delete $vars->{'tt_config'};

    $obj->process(\$str, $vars, \$out);
    my $ok = ref($test) ? $out =~ $test : $out eq $test;
    if ($ok) {
        ok(1, "Line $line   \"$str\" => \"$out\"");
        return $obj;
    } else {
        ok(0, "Line $line   \"$str\"");
        warn "# Was:\n$out\n# Should've been:\n$test\n";
        print $obj->error if $obj->can('error');
        print Dumper $obj->parse_tree(\$str) if $obj->can('parse_tree');
        exit;
    }
}

###----------------------------------------------------------------###
print "### GET ##############################################################\n";

process_ok("[% foo %]" => "");
process_ok("[% foo %]" => "7",       {foo => 7});
process_ok("[% foo %]" => "7",       {tt_config => [VARIABLES => {foo => 7}]});
process_ok("[% foo %]" => "7",       {tt_config => [PRE_DEFINE => {foo => 7}]});
process_ok("[% foo %][% foo %][% foo %]" => "777", {foo => 7});
process_ok("[% foo() %]" => "7",     {foo => 7});
process_ok("[% foo.bar %]" => "");
process_ok("[% foo.bar %]" => "",    {foo => {}});
process_ok("[% foo.bar %]" => "7",   {foo => {bar => 7}});
process_ok("[% foo().bar %]" => "7", {foo => {bar => 7}});
process_ok("[% foo.0 %]" => "7",     {foo => [7, 2, 3]});
process_ok("[% foo.10 %]" => "",     {foo => [7, 2, 3]});
process_ok("[% foo %]" => 7,         {foo => sub { 7 }});
process_ok("[% foo(7) %]" => 7,      {foo => sub { $_[0] }});
process_ok("[% foo.length %]" => 1,  {foo => sub { 7 }});
process_ok("[% foo.0 %]" => 7,       {foo => sub { return 7, 2, 3 }});
process_ok("[% foo(bar) %]" => 7,    {foo => sub { $_[0] }, bar => 7});
process_ok("[% foo(bar.baz) %]" => 7,{foo => sub { $_[0] }, bar => {baz => 7}});

# we don't do as many tests here - leave that to Template::Alloy
# See Template::Alloy t/05_tt_base.t

###----------------------------------------------------------------###
print "### SET ##############################################################\n";

process_ok("[% SET foo bar %][% foo %]" => '');
process_ok("[% SET foo = 1 %][% foo %]" => '1');
process_ok("[% SET foo = 1  bar = 2 %][% foo %][% bar %]" => '12');
process_ok("[% SET foo  bar = 1 %][% foo %]" => '');
process_ok("[% SET foo = 1 ; bar = 1 %][% foo %]" => '1');
process_ok("[% SET foo = 1 %][% SET foo %][% foo %]" => '');

process_ok("[% SET foo = [] %][% foo.0 %]" => "");
process_ok("[% SET foo = [1, 2, 3] %][% foo.1 %]" => 2);
process_ok("[% SET foo = {} %][% foo.0 %]" => "");
process_ok("[% SET foo = {'1' => 2} %][% foo.1 %]" => "2");

process_ok("[% SET name = 1 %][% SET foo = name %][% foo %]" => "1");
process_ok("[% SET name = 1 %][% SET foo = \$name %][% foo %]" => "");
process_ok("[% SET name = 1 %][% SET foo = \${name} %][% foo %]" => "");
process_ok("[% SET name = 1 %][% SET foo = \"\$name\" %][% foo %]" => "1");
process_ok("[% SET name = 1 foo = name %][% foo %]" => '1');
process_ok("[% SET name = 1 %][% SET foo = {\$name => 2} %][% foo.1 %]" => "2");
process_ok("[% SET name = 1 %][% SET foo = {\${name} => 2} %][% foo.1 %]" => "2");

process_ok("[% SET name = 7 %][% SET foo = {'2' => name} %][% foo.2 %]" => "7");
process_ok("[% SET name = 7 %][% SET foo = {'2' => \"\$name\"} %][% foo.2 %]" => "7");

process_ok("[% SET name = 7 %][% SET foo = [1, name, 3] %][% foo.1 %]" => "7");
process_ok("[% SET name = 7 %][% SET foo = [1, \"\$name\", 3] %][% foo.1 %]" => "7");

process_ok("[% SET foo = { bar => { baz => [0, 7, 2] } } %][% foo.bar.baz.1 %]" => "7");

process_ok("[% SET foo.bar = 1 %][% foo.bar %]" => '1');
process_ok("[% SET foo.bar.baz.bing = 1 %][% foo.bar.baz.bing %]" => '1');
process_ok("[% SET foo.bar.2 = 1 %][% foo.bar.2 %] [% foo.bar.size %]" => '1 1');
process_ok("[% SET foo.bar = [] %][% SET foo.bar.2 = 1 %][% foo.bar.2 %] [% foo.bar.size %]" => '1 3');

# We don't do as many tests here - leave that to Template::Alloy
# See Template::Alloy t/05_tt_base.t

###----------------------------------------------------------------###
print "### LOOP #############################################################\n";

if (! $is_tt) {
    local $CGI::Ex::Template::QR_PRIVATE = 0;
    local $CGI::Ex::Template::QR_PRIVATE = 0; # warn clean
    CGI::Ex::Template->define_vmethod('scalar', textjoin => sub {join(shift, @_)});

    process_ok("[% var = [{key => 'a'}, {key => 'b'}, {key => 'c'}] -%]
[% LOOP var -%]
([% textjoin('|', key, __first__, __last__, __inner__, __odd__) %])
[% END -%]" => "(a|1|0|0|1)
(b|0|0|1|0)
(c|0|1|0|1)
", {tt_config => [LOOP_CONTEXT_VARS => 1]});
}

# See Template::Alloy t/05_tt_base.t

###----------------------------------------------------------------###
print "### DONE #############################################################\n";
print "### See Template::Alloy t/05_tt_base.t\n";
