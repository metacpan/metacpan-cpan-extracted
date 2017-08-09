package CFDI::Macros::Excel;

use strict;

use CFDI::Parser::Path;
use CFDI::Parser::XML;
use CFDI::Location::XPath;
use CFDI::Report::Default;
use CFDI::Output::CSV;

require Exporter;
our @EXPORT = qw(xcel xcel2 xcel3 xcel4 xcel5 excel excel2 excel3 excel4 excel5);
our @ISA = qw(Exporter);

our $VERSION = 0.21;

sub reporte(_){
  return unless my @xml = findxml $_[0];
  push @xpathheader,'xml';
  my $reporte = [\@xpathheader];
  foreach my $xml (@xml){
    my $content = eval{parse $xml};
    warn("$xml: $@"),next if $@;
    my $xpath = CFDI::Location::XPath->new($content);
    my @reg = map{xpath$xpath}@xpathdata;
    next unless @reg;
    push @reg,$xml;
    $$reporte[$#$reporte+1] = \@reg;
  }
  $reporte;
}

sub excel{
	$|=1;
	my $path = shift @_ || shift @ARGV || '.';
	my $c = (caller 1)[3];
	my $name = $c ? $c : 'excel';
	$name =~ s/.*:://;
	print "Generando reporte $name...$/";
	my $reporte = reporte $path;
	my $xml = $#$reporte;
	print "Reporte completado: procesados $xml xml$/";
	my $csv = output $reporte;
	my@t=localtime;$t[4]++;$t[5]+=1900;
	my $t = join'',map{2>length$_?"0$_":$_}reverse@t[0..5];
	my $file = "$name-$t.csv";
	open EXCEL,'>',$file or die $!;
	print EXCEL $csv if defined $csv;
	close EXCEL or warn $!;
	print "Reporte guardado como: $file$/";
}

 *xcel = *excel;
*xcel2 = *excel2;
*xcel3 = *excel3;
*xcel4 = *excel4;
*xcel5 = *excel5;
sub excel2{require CFDI::Report::Excel2;CFDI::Report::Excel2->import;&excel}
sub excel3{require CFDI::Report::Excel3;CFDI::Report::Excel3->import;&excel}
sub excel4{require CFDI::Report::Excel4;CFDI::Report::Excel4->import;&excel}
sub excel5{require CFDI::Report::Excel5;CFDI::Report::Excel5->import;&excel}

1;