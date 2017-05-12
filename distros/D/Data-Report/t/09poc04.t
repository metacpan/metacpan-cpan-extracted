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

sub _std_heading {
    my $self = shift;
    $self->_print("<html>\n",
		  "<head>\n",
		  "<title>", $self->_html($self->{_title1}), "</title>\n",
		  '<link rel="stylesheet" href="css/', $self->get_style, '.css">', "\n",
		  "</head>\n",
		  "<body>\n",
		  "<p class=\"title\">", $self->_html($self->{_title1}), "</p>\n",
		  "<p class=\"subtitle\">", $self->_html($self->{_title2}), "<br>\n",
		  $self->_html($self->{_title3}), "</p>\n");
    $self->SUPER::_std_heading;
}

sub _std_stylist {
    my ($rep, $row, $col) = @_;

    return { line_after => 1 }
      if $row eq "total" && !$col;
    return;
}

sub finish {
    my $self = shift;
    $self->_argcheck(0);
    $self->SUPER::finish;
    $self->_print("</body>\n</html>\n");
}

package main;

my $rep = POC::Report::->create(type => "html");
isa_ok($rep, 'POC::Report::Html');

$rep->set_layout
  ([ { name => "acct", title => "Acct",   width => 6  },
     { name => "desc", title => "Report", width => 40, align => "|" },
     { name => "deb",  title => "Debet",  width => 10, align => "<" },
     { name => "crd",  title => "Credit", width => 10, align => ">" },
   ]);

my $out = "";
$rep->set_output(\$out);
$rep->start(qw(Title_One Title_Two Title_Three_Left&Right));

is($rep->get_stylist, \&POC::Report::Html::_std_stylist, "CB: stylist");
is($rep->get_heading, \&POC::Report::Html::_std_heading, "CB: heading");

$rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "normal" });
$rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "normal" });
$rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "normal" });
$rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "total"  });
$rep->finish;
$rep->close;

my $ref; { undef $/; $ref = <DATA>; }
$ref =~ s/[\r\n]/\n/g;

is($out, $ref, "contents");

__DATA__
<html>
<head>
<title>Title_One</title>
<link rel="stylesheet" href="css/default.css">
</head>
<body>
<p class="title">Title_One</p>
<p class="subtitle">Title_Two<br>
Title_Three_Left&amp;Right</p>
<table class="main">
<tr class="head">
<th align="left" class="h_acct">Acct</th>
<th align="center" class="h_desc">Report</th>
<th align="left" class="h_deb">Debet</th>
<th align="right" class="h_crd">Credit</th>
</tr>
<tr class="r_normal">
<td align="left" class="c_acct">one</td>
<td align="center" class="c_desc">two</td>
<td align="left" class="c_deb">three</td>
<td align="right" class="c_crd">four</td>
</tr>
<tr class="r_normal">
<td align="left" class="c_acct">one</td>
<td align="center" class="c_desc">two</td>
<td align="left" class="c_deb">three</td>
<td align="right" class="c_crd">four</td>
</tr>
<tr class="r_normal">
<td align="left" class="c_acct">one</td>
<td align="center" class="c_desc">two</td>
<td align="left" class="c_deb">three</td>
<td align="right" class="c_crd">four</td>
</tr>
<tr class="r_total">
<td align="left" class="c_acct">one</td>
<td align="center" class="c_desc">two</td>
<td align="left" class="c_deb">three</td>
<td align="right" class="c_crd">four</td>
</tr>
</table>
</body>
</html>
