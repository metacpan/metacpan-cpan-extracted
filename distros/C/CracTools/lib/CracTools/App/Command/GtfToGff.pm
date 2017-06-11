package CracTools::App::Command::GtfToGff;

{
  $CracTools::App::Command::GtfToGff::DIST = 'CracTools';
}
# ABSTRACT: Convert GFT2 files to GFF3 format
# PODNAME: cractools gtftogff
$CracTools::App::Command::GtfToGff::VERSION = '1.251';
use CracTools::App -command;
use CracTools::Output;

use strict;
use warnings;


sub usage_desc { "cractools gtftogff file.gtf > file.gff" }

sub opt_spec {
  return ();
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  my %valid_options = map { $_->[0] => $_->[1] } $self->opt_spec;
  $self->usage_error("Missing GTF file to convert") if @$args < 1;
  for my $name ( @$args ) {
    $self->usage_error("$name is not a valid option") if $name =~ /^-/;
  }
}

sub execute {
  my ($self, $opt, $args) = @_;

  my %genes;
  my %transcripts;
  my %features;

  my $gtf_file = shift @{$args};

  my $it = CracTools::Utils::gffFileIterator($gtf_file,'gtf');

  while(my $gtf_line = $it->()) {

    next if $gtf_line->{feature} eq 'transcript';
    next if $gtf_line->{feature} eq 'gene';
    
    my $gene_id = $gtf_line->{attributes}->{gene_id};
    my $trans_id = $gtf_line->{attributes}->{transcript_id};

    if(defined $gene_id && defined $trans_id) {

      my $feat_key = join("@",$gtf_line->{chr},
        $gtf_line->{feature},
        $gtf_line->{start},
        $gtf_line->{end}
      );

      my $id = $gtf_line->{attributes}->{$gtf_line->{feature}.'_id'};
      $id = $feat_key unless defined $id;

      if(!defined $features{$id}) {
        $features{$id} = { chr            => $gtf_line->{chr},
                                 source         => $gtf_line->{source},
                                 feature        => $gtf_line->{feature},
                                 start          => $gtf_line->{start},
                                 end            => $gtf_line->{end},
                                 score          => $gtf_line->{score},
                                 strand         => $gtf_line->{strand},
                                 frame          => $gtf_line->{frame},
                                 id             => $id,
                                 transcript_ids => [$trans_id],
                                 type           => "feature",
                               };
      } elsif(!(@{$features{$id}{transcript_ids}} ~~ $trans_id)) {
        push(@{$features{$id}{transcript_ids}},$trans_id);
      }

      if(!defined $transcripts{$trans_id}) {
        $transcripts{$trans_id} = { chr       => $gtf_line->{chr},
                                    source    => $gtf_line->{source},
                                    start     => $gtf_line->{start},
                                    end       => $gtf_line->{end},
                                    strand    => $gtf_line->{strand},
                                    gene_id   => $gene_id,
                                    transcript_id  => $trans_id,
                                    type      => "transcript",
                                  };
      } else {
        $transcripts{$trans_id}{start} = $gtf_line->{start} if $gtf_line->{start} < $transcripts{$trans_id}{start};
        $transcripts{$trans_id}{end} = $gtf_line->{end} if $gtf_line->{end} > $transcripts{$trans_id}{end};
      }

      if(!defined $genes{$gene_id}) {
        $genes{$gene_id} = { chr      => $gtf_line->{chr},
                             source   => $gtf_line->{source},
                             start    => $gtf_line->{start},
                             end      => $gtf_line->{end},
                             strand   => $gtf_line->{strand},
                             name     => $gtf_line->{attributes}->{gene_name},
                             gene_id  => $gene_id,
                             type     => "gene",
                           };
      } else {
        $genes{$gene_id}{start} = $gtf_line->{start} if $gtf_line->{start} < $genes{$gene_id}{start};
        $genes{$gene_id}{end} = $gtf_line->{end} if $gtf_line->{end} > $genes{$gene_id}{end};
      }
    }
  }

  my $output = CracTools::Output->new();
  $output->printLine("##gff-version 3");
  $output->printHeaders(args => \@ARGV);

  my @all_annotations;
  push @all_annotations, values %features;
  push @all_annotations, values %transcripts;
  push @all_annotations, values %genes;

  # Sort annotations by start pos
  my @sorted_annotations = sort {$a->{start} <=> $b->{start}} @all_annotations;

  foreach my $annot (@sorted_annotations) {
    if($annot->{type} eq "gene") {
      $output->printLine($annot->{chr},
        $annot->{source},
        "gene",
        $annot->{start},
        $annot->{end},
        ".",
        $annot->{strand},
        ".",
        "ID=$annot->{gene_id};Name=".$annot->{name},
      );
    } elsif($annot->{type} eq "transcript") {
      $output->printLine($annot->{chr},
        $annot->{source},
        "mRNA",
        $annot->{start},
        $annot->{end},
        ".",
        $annot->{strand},
        ".",
        "ID=$annot->{transcript_id};Parent=".$annot->{gene_id}
      );
    } else {
      $output->printLine($annot->{chr},
        $annot->{source},
        $annot->{feature},
        $annot->{start},
        $annot->{end},
        $annot->{score},
        $annot->{strand},
        $annot->{frame},
        "ID=$annot->{id};Parent=".join(",",@{$annot->{transcript_ids}})
      );
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

cractools gtftogff - Convert GFT2 files to GFF3 format

=head1 VERSION

version 1.251

=head1 SYNOPSIS

Convert gtf2 files to gff3, exons with same exact same coordinates are merged.

=head1 AUTHORS

=over 4

=item *

Nicolas PHILIPPE <nphilippe.research@gmail.com>

=item *

Jérôme AUDOUX <jaudoux@cpan.org>

=item *

Sacha BEAUMEUNIER <sacha.beaumeunier@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by IRMB/INSERM (Institute for Regenerative Medecine and Biotherapy / Institut National de la Santé et de la Recherche Médicale) and AxLR/SATT (Lanquedoc Roussilon / Societe d'Acceleration de Transfert de Technologie).

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
