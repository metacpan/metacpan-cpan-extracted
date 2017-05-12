# -*-Perl-*- mode (to keep my emacs happy)
# $Id: 02roundtrip.t,v 1.3 2005/06/15 16:21:10 cmungall Exp $

use strict;
use vars qw($DEBUG);
use Test;
use Bio::Chaos;
use Bio::Chaos::ChaosGraph;
use Bio::Root::IO;

BEGIN {     
    plan tests => 12;
}

my $file_h =
  {
   'CG10833.wm.chado-xml'=>
   {n_features=>10,
    n_genes=>1,
    n_genes_subparts=>1},
   'CG16983.chado-xml'=>
   {n_features=>666,
    n_genes=>1,
    n_genes_subparts=>7},
  };

my $C = Bio::Chaos->new;

eval {
    $C->load_module("Bio::Chaos::XSLTHelper");
};
if ($@) {
    print STDERR "XSLT not installed - skipping tests\n";
    foreach (1..12) {
        ok(1);
    }
    exit 0;
}


foreach my $fkey (sort keys %$file_h) {
    my $file = Bio::Root::IO->catfile("t","data",$fkey);
    my $expected_h = $file_h->{$fkey};
      
    print "file: $file\n";
    # chado->chaos->chado->chaos

    my $cxfile = "$file.chaos";
    chado2chaos($file,$cxfile);
    check_cx($cxfile, $expected_h);

    my $chfile = "$cxfile.chado-xml";
    chaos2chado($cxfile,$chfile);

    my $cxfile2 = $chfile.".chaos";
    chado2chaos($chfile,$cxfile2);
    check_cx($cxfile2, $expected_h);
}

sub check_cx {
    my $cxfile = shift;
    my $h = shift;

    my $cx = Bio::Chaos::ChaosGraph->new(-file=>$cxfile);
    #print $cx->asciitree;
    
    my $features = $cx->get_features;
    ok(scalar(@$features),$h->{n_features});
    
    my $genes = $cx->get_features_by_type('gene');
    ok(scalar(@$genes),$h->{n_genes});
    
    my @genes_subparts =
      map {@{$cx->get_features_contained_by($_)}} @$genes;
    ok(scalar(@genes_subparts),$h->{n_genes_subparts});
    
    foreach my $f (@$features) {
        #print $f->sxpr;
    }
} 

exit 0;

sub chado2chaos {
    convert('chado','chaos',@_);
}
sub chaos2chado {
    convert('chaos','chado',@_);
}

sub convert {
    my ($from,
        $to,
        $infile,
        $outfile) = @_;
    print "\nConverting $from => $to [$outfile]\n\n";
    if ($from eq 'chado' && $to eq 'chaos') {
        my @chain = qw(chado-expand-macros cx-chado-to-chaos);
        Bio::Chaos::XSLTHelper->xsltchain($infile, $outfile, @chain);
    }
    elsif ($from eq 'chaos' && $to eq 'chado') {
        my @chain = qw(cx-chaos-to-chado chado-expand-macros chado-insert-macros);
        Bio::Chaos::XSLTHelper->xsltchain($infile, $outfile, @chain);
    }
    else {
        die;
    }
}
