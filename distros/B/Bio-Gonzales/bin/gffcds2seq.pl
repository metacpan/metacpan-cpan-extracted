#!/usr/bin/env perl

use warnings;
use strict;
use 5.010;

use Pod::Usage;
use Getopt::Long qw(:config auto_help);
use Bio::Gonzales::Seq::IO qw(faslurp faspew);

use Bio::Gonzales::Feat::IO::GFF3;
use List::Util qw/reduce/;
use List::MoreUtils qw/any all/;
use Bio::Perl qw/translate_as_string/;

my @child_feat_type;
my $gene_model_type = 'mRNA';

GetOptions( 'parent_feat=s' => \$gene_model_type, 'child_feat=s' => \@child_feat_type ) or pod2usage(2);
@child_feat_type = qw/CDS/ unless(@child_feat_type);
say STDERR "parent model feat: $gene_model_type";
say STDERR "child model feat: " . join( ", ", @child_feat_type );
my ( $gff_f, @scf_f ) = @ARGV;
for my $f ( $gff_f, @scf_f ) {
  die "$f does not exist" unless ( -f $f );
}

my $gffin = Bio::Gonzales::Feat::IO::GFF3->new(
  file => $gff_f,
  mode => '<',
);

my %cds_feats;

my %child_feat_type = map { $_ => 1 } @child_feat_type;
while ( my $feat = $gffin->next_feat ) {
  if ( $child_feat_type{ $feat->type } ) {
    #Bio::Gonzales::Seq::Feat
    my $p = $feat->parent_id;

    $cds_feats{$p} //= [];
    push @{ $cds_feats{$p} }, $feat;
  }
}
$gffin->close;

my %seqs;
for my $sf (@scf_f) {
  my $seqs = faslurp($sf);
  for my $s (@$seqs) {
    die if ( $seqs{ $s->id } );
    $seqs{ $s->id } = $s;
  }
}

my $out_fh = \*STDOUT;
for my $feat_set ( values %cds_feats ) {
  my @ord = sort { $a->start <=> $b->start } @$feat_set;

  print STDERR ".";
  print STDERR ";" x scalar grep { not exists( $seqs{ $_->seq_id } ) } @ord;

  @ord = grep { exists( $seqs{ $_->seq_id } ) } @ord;
  next unless ( @ord > 0 );
  # Bio::Gonzales::Seq
  my $seq_string = reduce {
    $a .= $seqs{ $b->seq_id }->subseq_as_string( [ $b->start, $b->end ] );
  }
  ( "", @ord );

  my $seq = Bio::Gonzales::Seq->new( id => $ord[0]->parent_id, seq => $seq_string );
  $seq->revcom if ( $ord[0]->strand < 0 );

  faspew( $out_fh, $seq );
}
$out_fh->close;
__END__

=head1 NAME



=head1 SYNOPSIS

  #wenn export, dann hier im qw()

=head1 DESCRIPTION

=head1 OPTIONS

=head1 SUBROUTINES
=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
