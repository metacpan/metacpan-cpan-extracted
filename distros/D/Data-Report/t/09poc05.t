#! perl

use strict;
use warnings;
use Test::More tests => 4;

package POC::Report;

use base qw(Data::Report);

package POC::Report::Html;

use base qw(Data::Report::Plugin::Html);

sub start {
    my $self = shift;
    $self->_argcheck(3);
    $self->{_title1} = shift;
    $self->{_title2} = shift;
    $self->{_title3} = shift;
    $self->SUPER::start;
}

sub _top_heading {
    my $self = shift;
    $self->_print("<html>\n",
		  "<head>\n",
		  "<title>", $self->_html($self->{_title1}), "</title>\n",
		  '<link rel="stylesheet" href="css/', $self->get_style, '.css">', "\n",
		  "</head>\n",
		  "<body>\n",
          "<form method=\"post\" action=\"#\">\n",
		  "<p class=\"title\">", $self->_html($self->{_title1}), "</p>\n",
		  "<p class=\"subtitle\">", $self->_html($self->{_title2}), "<br>\n",
		  $self->_html($self->{_title3}), "</p>\n");
}

sub _std_stylist {
    my ($rep, $row, $col) = @_;

    # No style mods.
    return;
}

sub finish {
    my $self = shift;
    $self->_argcheck(0);
    $self->SUPER::finish;
    $self->_print("</form>\n</body>\n</html>\n");
}

package main;

my $rep = POC::Report::->create(type => "html", stylist => \&my_stylist);
isa_ok($rep, 'POC::Report::Html');

$rep->set_layout(
    [
        {
            name     => "check",
            title    => "Check",
            width    => 5,
            align    => "|",
        },
        { name => "acct", title => "Acct",   width => 6 },
        { name => "desc", title => "Report", width => 40, align => "|" },
        { name => "deb",  title => "Debet",  width => 10, align => "<" },
        { name => "crd",  title => "Credit", width => 10, align => ">" },
    ]
);

my $out = "";
$rep->set_output(\$out);
$rep->start(qw(Title_One Title_Two Title_Three_Left&Right));

is($rep->get_stylist, \&main::my_stylist, "CB: stylist");
is($rep->get_topheading, \&POC::Report::Html::_top_heading, "CB: heading");

$rep->add(
    {
        check  => "<input type=\"checkbox\" name=\"checks\" value=\"first\">",
        acct   => "one",
        desc   => "two",
        deb    => "three",
        crd    => "four",
        _style => "normal"
    }
);
$rep->add(
    {
        check  => "<input type=\"checkbox\" name=\"checks\" value=\"second\">",
        acct   => "one",
        desc   => "two",
        deb    => "three",
        crd    => "four",
        _style => "normal"
    }
);
$rep->add(
    {
        check  => "<input type=\"checkbox\" name=\"checks\" value=\"third\">",
        acct   => "one",
        desc   => "two",
        deb    => "three",
        crd    => "four",
        _style => "normal"
    }
);
$rep->add(
    {
        check  => "<input type=\"checkbox\" name=\"checks\" value=\"total\">",
        acct   => "one",
        desc   => "two",
        deb    => "three",
        crd    => "four",
        _style => "total"
    }
);
$rep->finish;
$rep->close;

my $ref; { undef $/; $ref = <DATA>; }
$ref =~ s/[\r\n]/\n/g;

is($out, $ref, "contents");

sub my_stylist {
    my ($rep, $row, $col) = @_;

    # Enable raw HTML contents for the 'check' column.
    return { raw_html => 1 }
      if $col && $col eq "check";
    return;
}

__DATA__
<html>
<head>
<title>Title_One</title>
<link rel="stylesheet" href="css/default.css">
</head>
<body>
<form method="post" action="#">
<p class="title">Title_One</p>
<p class="subtitle">Title_Two<br>
Title_Three_Left&amp;Right</p>
<table class="main">
<tr class="head">
<th align="center" class="h_check">Check</th>
<th align="left" class="h_acct">Acct</th>
<th align="center" class="h_desc">Report</th>
<th align="left" class="h_deb">Debet</th>
<th align="right" class="h_crd">Credit</th>
</tr>
<tr class="r_normal">
<td align="center" class="c_check"><input type="checkbox" name="checks" value="first"></td>
<td align="left" class="c_acct">one</td>
<td align="center" class="c_desc">two</td>
<td align="left" class="c_deb">three</td>
<td align="right" class="c_crd">four</td>
</tr>
<tr class="r_normal">
<td align="center" class="c_check"><input type="checkbox" name="checks" value="second"></td>
<td align="left" class="c_acct">one</td>
<td align="center" class="c_desc">two</td>
<td align="left" class="c_deb">three</td>
<td align="right" class="c_crd">four</td>
</tr>
<tr class="r_normal">
<td align="center" class="c_check"><input type="checkbox" name="checks" value="third"></td>
<td align="left" class="c_acct">one</td>
<td align="center" class="c_desc">two</td>
<td align="left" class="c_deb">three</td>
<td align="right" class="c_crd">four</td>
</tr>
<tr class="r_total">
<td align="center" class="c_check"><input type="checkbox" name="checks" value="total"></td>
<td align="left" class="c_acct">one</td>
<td align="center" class="c_desc">two</td>
<td align="left" class="c_deb">three</td>
<td align="right" class="c_crd">four</td>
</tr>
</table>
</form>
</body>
</html>
