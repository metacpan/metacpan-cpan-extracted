#! perl

use strict;
use warnings;
use Test::More tests => 2;

package POC::Report;

use base qw(Data::Report);

package POC::Report::Html;

use base qw(Data::Report::Plugin::Html);

sub _std_stylist {
    my ($rep, $row, $col) = @_;

    return unless $col;

    return { raw_html => 1 }
      if $col eq "address";
    return { ignore => 1 }
      if $col =~ /^city|zip$/;

    return;
}

sub add {
    my ($self, $data) = @_;

    $data->{address}
      = join('<br/>', map { $self->_html($_) } @$data{qw(address city zip)});

    $self->SUPER::add($data);
}

package main;

my $rep = POC::Report::->create(type => "html");
isa_ok($rep, 'POC::Report::Html');

$rep->set_layout(
    [
        { name => "id",      title => "ID",      width =>  4 },
        { name => "name",    title => "Name",    width => 20 },
        { name => "address", title => "Address", width => 40 },
        { name => "city",    title => "City",    width => 20 },
        { name => "zip",     title => "Zip",     width => 10 },
    ]
);

my $out = "";
$rep->set_output(\$out);
$rep->start();

$rep->add(
    {
        id      => 1,
        name    => "Rijksmuseum",
        address => "Museumplein",
        city    => "Amsterdam",
        zip     => "1000 AA",
        _style  => "normal"
    }
);

$rep->add(
    {
        id      => 2,
        name    => "Kabouterland",
        address => "Zuid&einde",
        city    => "Exloo",
        zip     => "7889 AA",
        _style  => "normal"
    }
);


$rep->finish;
$rep->close;

my $ref; { undef $/; $ref = <DATA>; }
$ref =~ s/[\r\n]/\n/g;

is($out, $ref, "contents");

__DATA__
<table class="main">
<tr class="head">
<th align="left" class="h_id">ID</th>
<th align="left" class="h_name">Name</th>
<th align="left" class="h_address">Address</th>
</tr>
<tr class="r_normal">
<td align="left" class="c_id">1</td>
<td align="left" class="c_name">Rijksmuseum</td>
<td align="left" class="c_address">Museumplein<br/>Amsterdam<br/>1000 AA</td>
</tr>
<tr class="r_normal">
<td align="left" class="c_id">2</td>
<td align="left" class="c_name">Kabouterland</td>
<td align="left" class="c_address">Zuid&amp;einde<br/>Exloo<br/>7889 AA</td>
</tr>
</table>
