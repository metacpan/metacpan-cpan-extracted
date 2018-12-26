#!perl -T

use Data::Tabulate::Plugin::HTMLTable;
use Test::More;
use HTML::Table;

eval "use Data::Tabulate";
plan skip_all => "Data::Tabulate is not installed" if $@;

plan tests => 1;

my @array     = (1..10);
my $tabulator = Data::Tabulate->new();

$tabulator->do_func( 'HTMLTable', 'attributes', -bgcolor => 'red', -border => 1 );

my $html = $tabulator->render('HTMLTable',{ data => \@array } );

my ($tbody,$tbody_end) = ("","");
my $version            = $HTML::Table::VERSION;
   $version            =~ s/[a-z-]//g;
   
if( $version + 0 >= 2.07 ){
    $tbody     = "\n<tbody>";
    $tbody_end = "</tbody>\n";
}

my $check     = qq~
<table border="1" bgcolor="red">$tbody
<tr><td>1</td><td>2</td><td>3</td></tr>
<tr><td>4</td><td>5</td><td>6</td></tr>
<tr><td>7</td><td>8</td><td>9</td></tr>
<tr><td>10</td><td>&nbsp;</td><td>&nbsp;</td></tr>
$tbody_end</table>
~;

is($html,$check);
