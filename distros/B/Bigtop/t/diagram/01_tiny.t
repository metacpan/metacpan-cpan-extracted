use strict;

use Test::More tests => 1;

use Bigtop::Parser qw/Diagram=GraphvizSql/;
use Bigtop::Backend::SQL; # to register keywords

my $bigtop_string = join '', <DATA>;

my $tree        = Bigtop::Parser->parse_string($bigtop_string);
my $lookup      = $tree->{application}{lookup};

my $outputs     = $tree->walk_postorder( 'output_diagram_gvsql', $lookup );
my $output      = join '', @{ $outputs };

$output =~ s/Gen[^"]*/Generated/;

my @graph       = split /\n/, $output;

my @correct_graph = split /\n/, <<'EO_CORRECT_GRAPH';
digraph g {
    graph [
        fontsize=30
        labelloc="t"
        label="Apps::Checkbook"
        splines=true
        overlap=false
        rankdir = "LR"
    ];
    node [shape=plaintext]
    ratio = auto;
    payeepayor [
      label = <
        <table border="1" cellborder="0">
          <tr> <td><font point-size="12">Payeepayor</font></td> </tr>
          <tr> <td align="left" PORT="id">id</td> </tr>
        </table>
      >
    ];
    multiplier [
      label = <
        <table border="1" cellborder="0">
          <tr> <td><font point-size="12">Multiplier</font></td> </tr>
          <tr> <td align="left" PORT="id">id</td> </tr>
          <tr> <td align="left" PORT="subid">subid</td> </tr>
        </table>
      >
    ];
    pointer [
      label = <
        <table border="1" cellborder="0">
          <tr> <td><font point-size="12">Pointer</font></td> </tr>
          <tr> <td align="left" PORT="id">id</td> </tr>
          <tr> <td align="left" PORT="refer_to">refer_to</td> </tr>
          <tr> <td align="left" PORT="other">other</td> </tr>
        </table>
      >
    ];
    pointer2 [
      label = <
        <table border="1" cellborder="0">
          <tr> <td><font point-size="12">Pointer2</font></td> </tr>
          <tr> <td align="left" PORT="id">id</td> </tr>
          <tr> <td align="left" PORT="refer_to">refer_to</td> </tr>
        </table>
      >
    ];
    date_box [
      label = "Generated"
    ];
    pointer:refer_to -> payeepayor:id
}

EO_CORRECT_GRAPH

is_deeply( \@graph, \@correct_graph, 'tiny graph' );

__DATA__
config { }
app Apps::Checkbook {
    sequence payeepayor_seq {}
    table payeepayor {
        field id    { is int4, primary_key, auto; }
        sequence payeepayor_seq;
    }
    table multiplier {
        field id    { is int4, primary_key; }
        field subid { is int4, primary_key; }
    }
    table pointer {
        field id { is int4, primary_key; }
        field refer_to {
            is int4;
            refers_to payeepayor => id;
        }
        field other { is varchar; }
    }
    table pointer2 {
        field id { is int4, primary_key; }
        field refer_to { is int4; refers_to payeepayor; }
    }
}
