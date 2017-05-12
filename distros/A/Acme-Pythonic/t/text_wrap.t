# -*- Mode: Python -*-

# This is a meticolous port of Text::Wrap.
#
# The intention is to test whether an example of real code is processed
# correctly.
#
# It has been written by copying the original code and doing the minimal
# changes for it to be Pythonic, which means colonizing, removing some
# parens, adding a few backslashes, etc. Comments, spacing, and all
# details have been kept.

use Test::More 'no_plan';
use Acme::Pythonic debug => 0;

package Acme::Pythonic::Text::Wrap

require Exporter

@ISA = qw(Exporter)
@EXPORT = qw(wrap fill)
@EXPORT_OK = qw($columns $break $huge)

$VERSION = 2001.09291

use vars qw($VERSION $columns $debug $break $huge $unexpand $tabstop
    $separator)
use strict

BEGIN:
    $columns = 76  # <= screen width
    $debug = 0
    $break = '\s'
    $huge = 'wrap' # alternatively: 'die' or 'overflow'
    $unexpand = 1
    $tabstop = 8
    $separator = "\n"

use Text::Tabs qw(expand unexpand)

sub wrap:
    my ($ip, $xp, @t) = @_

    local($Text::Tabs::tabstop) = $tabstop
    my $r = ""
    my $tail = pop(@t)
    my $t = expand(join("", (map { /\s+\z/ ? ( $_ ) : ($_, ' ') } @t), $tail))
    my $lead = $ip
    my $ll = $columns - length(expand($ip)) - 1
    $ll = 0 if $ll < 0
    my $nll = $columns - length(expand($xp)) - 1
    my $nl = ""
    my $remainder = ""

    use re 'taint'

    pos($t) = 0
    while $t !~ /\G\s*\Z/gc:
        if $t =~ /\G([^\n]{0,$ll})($break|\z)/xmgc:
            $r .= $unexpand \
                ? unexpand($nl . $lead . $1) \
                : $nl . $lead . $1
            $remainder = $2
        elsif $huge eq 'wrap' && $t =~ /\G([^\n]{$ll})/gc:
            $r .= $unexpand \
                ? unexpand($nl . $lead . $1) \
                : $nl . $lead . $1
            $remainder = $separator
        elsif $huge eq 'overflow' && $t =~ /\G([^\n]*?)($break|\z)/xmgc:
            $r .= $unexpand \
                ? unexpand($nl . $lead . $1) \
                : $nl . $lead . $1
            $remainder = $2
        elsif $huge eq 'die':
            die "couldn't wrap '$t'"
        else:
            die "This shouldn't happen"

        $lead = $xp
        $ll = $nll
        $nl = $separator

    $r .= $remainder

    print "-----------$r---------\n" if $debug

    print "Finish up with '$lead'\n" if $debug

    $r .= $lead . substr($t, pos($t), length($t)-pos($t)) \
        if pos($t) ne length($t)

    print "-----------$r---------\n" if $debug

    return $r


sub fill:
    my ($ip, $xp, @raw) = @_
    my @para
    my $pp

    for $pp in split(/\n\s+/, join("\n",@raw)):
        $pp =~ s/\s+/ /g
        my $x = wrap($ip, $xp, $pp)
        push(@para, $x)

    # if paragraph_indent is the same as line_indent,
    # separate paragraphs with blank lines

    my $ps = ($ip eq $xp) ? "\n\n" : "\n"
    return join ($ps, @para)

package main

$Acme::Pythonic::Text::Wrap::columns = 4

my @text = qw(foo bar baz)
is Acme::Pythonic::Text::Wrap::wrap('', '', @text), join "\n", @text

@text = "foo bar\n\n\n\n\n\n\n\nbar baz"
is Acme::Pythonic::Text::Wrap::fill('', '', @text), "foo\nbar\n\nbar\nbaz"
