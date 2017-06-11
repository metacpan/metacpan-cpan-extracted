package CracTools::App::Command::Extract;

{
  $CracTools::App::Command::Extract::DIST = 'CracTools';
}
# ABSTRACT: Extract events identified by CRAC.
# PODNAME: cractools extract
$CracTools::App::Command::Extract::VERSION = '1.251';
use CracTools::App -command;

use strict;
use warnings;

use Carp;
use CracTools;
use CracTools::Utils;
use CracTools::SAMReader;
use CracTools::SAMReader::SAMline;
use Parallel::ForkManager 0.7.6;

use constant CHUNK_SIZE => 10000000;
use constant MIN_GAP_LENGTH => 0;

sub usage_desc { "cractools extract file.bam [regions] [-r ref.fa] [-p nb_threads] [--splices splice.bed] [--mutations file.vcf] [--chimeras chimeras.tsv]" }

sub opt_spec {
  return (
    [ "p=i",  "Number of process to run", { default => 1 }       ],
    [ "r=s",  "Reference file (for VCF purpose)",       ],
    [ "splices|s=s",  "Bed file where splices will be extracted."       ],
    [ "chimeras|c=s",  "Tabulated file where chimeras will be extracted"       ],
    [ "mutations|m=s",  "VCF file where mutations will be extracted"       ],
    [ "coverless-splices",  "Consider splice that have no cover"       ],
    [ "stranded",  "Strand specific protocol", { default => 'False' }        ],
  );
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  my %valid_options = map { $_->[0] => $_->[1] } $self->opt_spec;
  $self->usage_error("Missing BAM file to extract") if @$args < 1;
  for my $name ( @$args ) {
    $self->usage_error("$name is not a valid option") if $name =~ /^-/;
  }
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $help              = $opt->{help};
  my $man               = $opt->{man};
  my $verbose           = $opt->{verbose};
  my $splices_file      = $opt->{splices};
  my $mutations_file    = $opt->{mutations};
  my $chimeras_file     = $opt->{chimeras};
  my $coverless_splices = $opt->{coverless_splices};
  my $is_stranded       = $opt->{stranded};
  my $ref_file          = $opt->{r};
  my $nb_process        = defined $opt->{p}? $opt->{p} : 1;

  my $bam_file = shift @{$args};
  pod2usage(-verbose => 1)  unless defined $bam_file;
  my $bam_reader   = CracTools::SAMReader->new($bam_file);
  my $crac_version = $bam_reader->getCracVersionNumber();
  my @regions = @{$args};
  my $min_gap_length = MIN_GAP_LENGTH;

  if(@regions == 0) {
    # If we need to explore the whole genome
    # we split it in CHUNK_SIZE regions
    my $it = CracTools::Utils::bamFileIterator($bam_file,"-H");
    while (my $line = $it->()) {
      next if $line !~ /^\@SQ/;
      my ($chr,$length) = $line =~ /^\@SQ\s+SN:(\S+)\s+LN:(\d+)/;
      for(my $i = 0; $i < $length/CHUNK_SIZE; $i++) {
        push(@regions,"$chr:".($i*CHUNK_SIZE)."-".(($i+1)*CHUNK_SIZE));
      }
    }
  }

  # Create Fork pool
  my $pm = Parallel::ForkManager->new($nb_process);

  my %chimeras;

  # data structure retrieval and handling
  $pm -> run_on_finish ( # called BEFORE the first call to start()
    sub {
      my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data_structure_reference) = @_;

      # retrieve chimeras from childs
      if (defined($data_structure_reference)) {
        my $region_chimeras = $data_structure_reference->{chimeras};
        foreach my $key (keys %{$region_chimeras}) {
          my $chim_key = $key;
          my ($chr1,$pos1,$strand1,$chr2,$pos2,$strand2) = split("@",$chim_key);
          my $reverse_key = join("@",$chr2,$pos2,$strand2*-1,$chr1,$pos1,$strand1*-1);
          if(!$is_stranded && defined $chimeras{$reverse_key}) {
            $chim_key = $reverse_key;
          }
          if(defined $chimeras{$chim_key}) {
            push(@{$chimeras{$chim_key}{reads}},@{$region_chimeras->{$key}->{reads}});
            $chimeras{$chim_key}{score} += $region_chimeras->{$key}->{score} if defined $region_chimeras->{$key}->{score};
          } else {
            $chimeras{$chim_key}{reads} = $region_chimeras->{$key}->{reads};
            $chimeras{$chim_key}{score} = $region_chimeras->{$key}->{score} if defined $region_chimeras->{$key}->{score};
          }
        }
      }
    }
  );

  my $nb_region = 0;
  # Loop over regions
  REGION:
  foreach my $region (@regions) {
    $nb_region++;

    # Fork regions
    $pm->start() and next REGION;

    # Open filehandles on output files
    my $splices_fh = CracTools::Utils::getWritingFileHandle($splices_file.".".$nb_region) if defined $splices_file;
    my $mutations_fh = CracTools::Utils::getWritingFileHandle($mutations_file.".".$nb_region) if defined $mutations_file;

    my($region_chr,$region_start,$region_end) = $region =~ /(\S+):(\d+)-(\d+)/;
    # Declare hashes that will store events
    my %splices;
    my %mutations;
    my %region_chimeras;
    my $bam_it = CracTools::Utils::bamFileIterator($bam_file,$region);
    while(my $raw_line = $bam_it->()) {
      my $line = CracTools::SAMReader::SAMline->new($raw_line);
      extractSplicesFromSAMline(\%splices,
        $line,
        $is_stranded,
        $min_gap_length,
        $coverless_splices,
        $region_chr,
        $region_start,
        $region_end,
      ) if defined $splices_fh;
      extractMutationsFromSAMline(\%mutations,
        $line,
        $is_stranded,
        $region_chr,
        $region_start,
        $region_end,
        $bam_file,
        $ref_file,
        $crac_version,
      ) if defined $mutations_fh;
      extractChimerasFromSAMline(\%region_chimeras,
        $line,
        $is_stranded,
        $region_chr,
        $region_start,
        $region_end,
      ) if defined $chimeras_file;
    }
    printSplices(\%splices,$splices_fh) if defined $splices_fh;
    printMutations(\%mutations,$mutations_fh) if defined $mutations_fh;
    $pm->finish(0,{chimeras => \%region_chimeras});
  }
  $pm->wait_all_children;

  my $chimeras_fh = CracTools::Utils::getWritingFileHandle($chimeras_file) if defined $chimeras_file;
  print $chimeras_fh "#",join("\t",qw( chr1 pos1 strand1 chr2 pos2 strand2 score reads cover)),"\n" if defined $chimeras_fh;
  printChimeras(\%chimeras,$chimeras_fh) if defined $chimeras_fh;

  # Merge Splice and Mutation files
  my $splices_fh = CracTools::Utils::getWritingFileHandle($splices_file) if defined $splices_file;
  my $mutations_fh = CracTools::Utils::getWritingFileHandle($mutations_file) if defined $mutations_file;
  # Print headers on output files
  print $splices_fh "track name=junctions\n" if defined $splices_fh;
  print $mutations_fh "##fileformat=VCFv4.1\n",
    "##source=$CracTools::DIST (v $CracTools::VERSION)\n",
    "##INFO=<ID=DP,Number=1,Type=Integer,Description=\"Total Depth\">\n",
    "##INFO=<ID=AF,Number=A,Type=Float,Description=\"Allele Frequency\">\n",
    "##INFO=<ID=CS,Number=A,Type=Float,Description=\"CRAC confidence score\">\n",
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n" if defined $mutations_fh;

  for (my $region_id = 1; $region_id <= $nb_region; $region_id++) {
    if(defined $splices_file) {
      my $fh = CracTools::Utils::getReadingFileHandle($splices_file.".".$region_id);
      while(my $line = <$fh>) { print $splices_fh $line; }
      unlink $splices_file.".".$region_id;
    }
    if(defined $mutations_file) {
      my $fh = CracTools::Utils::getReadingFileHandle($mutations_file.".".$region_id);
      while(my $line = <$fh>) { print $mutations_fh $line; }
      unlink $mutations_file.".".$region_id;
    }
  }
}


sub extractSplicesFromSAMline {
  my ($splices,$line,$is_stranded,$min_gap_length,$coverless_splices,$region_chr,$region_start,$region_end) = @_;
  # Next for secondary alignements
  if (!$line->isFlagged(256) && !$line->isFlagged(2048)) {
    # Loop over splices
    foreach my $splice (@{$line->events('Junction')}) {
      # Only report splices that belong to the query regions
      # with a gap > MIN_GAP_LENGTH
      # and with a 'normal' type (ie. not 'coverless')
      next if ($splice->{loc}->{pos} >= $region_end 
        || $splice->{loc}->{pos} < $region_start 
        || $splice->{loc}->{chr} ne $region_chr 
        || $splice->{gap} < $min_gap_length
      );

      next if $splice->{type} eq 'coverless' && !$coverless_splices;

      my @nb = $line->cigar =~ /[D|N|M|X|=](\d+)/g;
      my $mapping_length = 0;
      map {$mapping_length += $_} @nb;
      # TODO max_pos could be calculated in order to not integrate
      # an other splice that is following the current splice
      my $max_pos = $line->pos + $mapping_length;
      my $key = $splice->{loc}->{chr}."@".$splice->{loc}->{pos}."@".$splice->{gap};
      # If this is a new splice we record all information
      if(!defined $splices->{$key}) {
        $splices->{$key}{pos} = $splice->{loc}->{pos};
        $splices->{$key}{min} = $line->pos;
        $splices->{$key}{max} = $max_pos;
        $splices->{$key}{chr} = $splice->{loc}->{chr};
        $splices->{$key}{gap} = $splice->{gap};
        $splices->{$key}{cpt} = 1;
        $splices->{$key}{seq} = $line->seq;
        # If we are stranded we extract the right splice strand taking in account
        # PE specificity
        if($is_stranded) {
          if($line->isFlagged($CracTools::SAMReader::SAMline::flags{FIRST_SEGMENT})) {
            $splices->{$key}{strand} = CracTools::Utils::convertStrand($splice->{loc}->{strand}*-1);
          } else {
            $splices->{$key}{strand} = CracTools::Utils::convertStrand($splice->{loc}->{strand});
          }
        } else {
          $splices->{$key}{strand} = "+";
        }
        #if($is_stranded) {
        #  if((!$line->isFlagged(16) && $line->isFlagged(64)) || ($line->isFlagged(16) && $line->isFlagged(128))) {
        #    $splices->{$key}{strand} = "-";
        #  } else {
        #    $splices->{$key}{strand} = "+";
        #  }
        ## If we are not stranded we print the splice on the forward strand
        #} else {
        #  $splices->{$key}{strand} = "+";
        #}
      # If this is not a new splice we just update informations
      } else {
        $splices->{$key}{cpt}++;
        $splices->{$key}{max} = $max_pos if $splices->{$key}{max} < $max_pos;
        $splices->{$key}{min} = $line->pos if $splices->{$key}{min} < $line->pos;
      }
    }
  }
}

# TODO add support of not stranded RNA-Seq
sub printSplices {
  my $splices = shift;
  my $output_fh = shift;
  foreach my $splice (sort {$a->{chr} cmp $b->{chr} || $a->{pos} <=> $b->{pos}} values  %{$splices}) {

    print $output_fh join "\t", $splice->{chr},
                     $splice->{min},
                     $splice->{max},
                     "CRAC_SPLICE_CALLING",
                     $splice->{cpt},
                     $splice->{strand},
                     $splice->{min},
                     $splice->{max},
                     0,
                     2,
                     ($splice->{pos}-$splice->{min}).",".($splice->{max}-($splice->{pos}+$splice->{gap})),
                     "0,".(($splice->{pos}+$splice->{gap})-$splice->{min}), "\n";
  }
}

sub extractMutationsFromSAMline {
  my ($mutations,$line,$is_stranded,$region_chr,$region_start,$region_end,$bam_file,$ref_file,$crac_version) = @_;
  # Next for secondary alignements
  if(!$line->isFlagged(256) && !$line->isFlagged(2048)) {
    # If read has SNP
    foreach my $snp (@{$line->events('SNP')}) {
      # TODO make sure the SNP is contained in the region
      my ($chr,$pos) = ($snp->{loc}->{chr},$snp->{loc}->{pos});

      # We only add SNPS that correspond to the current region
      next if $chr ne $region_chr;
      next if $pos >= $region_end || $pos < $region_start;

      # This correspond to a 1bp deletion
      if($snp->{actual} eq '?') {
        $pos--;
        $snp->{expected} = getSeqOrNs($chr,$pos,2,$ref_file);
        $snp->{actual}    = substr $snp->{expected}, 0, 1;
      # This correspond to a 1bp insertion
      } elsif($snp->{expected} eq '?') {
        #$pos--; # Crac Already gives the position before the insertion...
        # Get deleted seq on the reference to avoid cases where a insertion
        # and a substitution are merged and CRAC has some difficulties
        # to handle that...
        #$snp->{actual}    = substr $line->seq, $snp->{pos}-1, 2;
        $snp->{actual}    = getSeqOrNs($chr,$pos,1,$ref_file).substr $line->seq,$snp->{pos}, 1;
        $snp->{expected}  = substr $snp->{actual}, 0, 1; 
      } else {
        # If this this a regular SNP, we check if CRAC's reference is right, otherwise
        # we have a problem in CRAC's calling prediction
        if(defined $ref_file && $snp->{expected} ne getSeqOrNs($chr,$pos,1,$ref_file)) {
          print STDERR "CRAC's SNP calling ($chr:$pos ".$snp->{expected}." => ".$snp->{actual}.") does not match the reference (".getSeqOrNs($chr,$pos,1,$ref_file)."), variant skipped (see read ".$line->qname." for more information)\n";
          next;
        }
      }

      # Uniq Hash key for SNP
      my $key = 'SNP'.$chr."@".$pos;

      addMutation(
        mutations   => $mutations,
        bam_file    => $bam_file,
        key         => $key,
        chr         => $chr,
        pos         => $pos,
        reference   => $snp->{expected},
        alternative => $snp->{actual},
        crac_score  => $snp->{score},
        read_id     => $line->qname,
      );
    }

    # If read has a small deletions
    foreach my $del (@{$line->events('Del')}) {
      my ($chr,$pos) = ($del->{loc}->{chr},$del->{loc}->{pos});

      # We only add deletions that correspond to the current region
      next if $pos >= $region_end || $pos < $region_start;

      # Uniq hash key for deletion
      my $key = 'Del'.$chr."@".$pos;#."@".$del->{nb};
      
      # Because VCF needs 1 base before the deletion
      # but crac gives the position before the deletion so we
      # do not need this
      if(defined $crac_version && CracTools::Utils::isVersionGreaterOrEqual($crac_version,'2.4.0')) {
        $pos--;
      }
      #$pos--;

      # Extract deleted genome sequence from reference if available
      my $reference = getSeqOrNs($chr,$pos,$del->{nb}+1,$ref_file);
      my $alternative = substr $reference, 0, 1; 

      addMutation(
        mutations   => $mutations,
        bam_file    => $bam_file,
        key         => $key,
        chr         => $chr,
        pos         => $pos,
        reference   => $reference,
        alternative => $alternative,
        crac_score  => $del->{score},
        read_id     => $line->qname,
      );
    }

    # If read has a small insertions
    foreach my $ins (@{$line->events('Ins')}) {
      my ($chr,$pos) = ($ins->{loc}->{chr},$ins->{loc}->{pos});

      # We only add insertions that correspond to the current region
      next if $pos >= $region_end || $pos < $region_start;

      # Uniq hash key for insertion
      my $key = 'Ins'.$chr."@".$pos;#."@".$ins->{nb};

      # Because VCF needs 1 base before the insertion
      if(defined $crac_version && !CracTools::Utils::isVersionGreaterOrEqual($crac_version,'2.4.0')) {
        $pos--;
      }

      # CRAC gives the position in the read after the insertion...
      my $inserted_sequence;
      if(defined $crac_version && CracTools::Utils::isVersionGreaterOrEqual($crac_version,'2.4.0')) {
        $inserted_sequence = substr $line->seq, $ins->{pos}, $ins->{nb};
      } else {
        $inserted_sequence = substr $line->seq, $ins->{pos}-$ins->{nb}+1, $ins->{nb};
      }

      my $alternative = getSeqOrNs($chr,$pos,1,$ref_file).$inserted_sequence;
      my $reference   = substr $alternative, 0, 1; 

      addMutation(
        mutations   => $mutations,
        bam_file    => $bam_file,
        key         => $key,
        chr         => $chr,
        pos         => $pos,
        reference   => $reference,
        alternative => $alternative,
        crac_score  => $ins->{score},
        read_id     => $line->qname,
      );
    }
  }
}

sub printMutations {
  my $mutations = shift;
  my $output_fh = shift;
  foreach my $mut (sort {$a->{chr} cmp $b->{chr} || $a->{pos} <=> $b->{pos}} values %{$mutations}) {
    print $output_fh join("\t",$mut->{chr},
      $mut->{pos}+1, # to be 1-based
      '.',
      $mut->{reference},
      (join ",", keys %{$mut->{alternative}}),
      '.',
      'PASS',
      'DP='.$mut->{total}.';AF='.(join ",", map{$_/$mut->{total}} values %{$mut->{alternative}}).';CS='.$mut->{crac_score}),"\n";
  }
}

## SUBROUTINES
sub addMutation {
  my %args = @_;

  # Convert sequences to the uppercase
  $args{reference}    = uc $args{reference};
  $args{alternative}  = uc $args{alternative};
  
  my $MUTATIONS = $args{mutations};
  my $key = $args{key};
  #my $key = $args{chr}."@".$args{pos};
  my $mut = $MUTATIONS->{$key};

  if(defined $mut) {
    # If this mutation position already exists but the
    # reference sequence is not the same (shorter or longer)
    # we need to update the alternative
    if($mut->{reference} ne $args{reference}) {
      # If the current reference sequence is larger that the new one
      # then we only need to update the alternative sequence of
      # the new mutation
      if(length($args{reference}) < length($mut->{reference})) {
        $args{alternative} = $args{alternative}.substr($mut->{reference},length($args{reference}));
      } elsif(length($args{reference}) > length($mut->{reference})) {
        # If the new mutation reference is larger that the old one,
        # we need to update all the previously added alternatives
        foreach my $alt (keys %{$mut->{alternative}}) {
          my $new_alt = $alt.substr($args{reference},length($mut->{reference}));
          $mut->{alternative}{$new_alt} = $mut->{alternative}{$alt};
          delete $mut->{alternative}{$alt};
        }
        # Then change the reference sequence
        $mut->{reference}  = $args{reference};
      } else {
        # If both reference are not equal but have the same length
        # then we have a problem sir
        carp "Reference (".$args{reference}.") is different than the previous one (".$mut->{reference}.") for read (".$args{read_id}.")";
        return 0;
      }
    }

    # Finally we can add the new alternative to the current mutation entry
    if(defined $MUTATIONS->{$key}{alternative}{$args{alternative}}) {
      $MUTATIONS->{$key}{alternative}{$args{alternative}}++;
    } else {
      $MUTATIONS->{$key}{alternative}{$args{alternative}} = 1;
    }
  } else {
    $MUTATIONS->{$key}{chr} = $args{chr};
    $MUTATIONS->{$key}{pos} = $args{pos};
    $MUTATIONS->{$key}{reference} = $args{reference};
    $MUTATIONS->{$key}{alternative}{$args{alternative}} = 1;
    $MUTATIONS->{$key}{crac_score} = $args{crac_score};
    $MUTATIONS->{$key}{total} = countReadCoverFromRegion($args{bam_file},$args{chr},$args{pos});
    $MUTATIONS->{$key}{total} = 1 if $MUTATIONS->{$key}{total} == 0; # Because of a bug in Crac 1.5.0 where chimeric alignements have been baddly positionned
  }
}

sub countReadCoverFromRegion {
  my ($bam_file,$chr,$pos1,$pos2) = @_;
  $pos2 = $pos1 if !defined $pos2;
  my $nb_total = 0; # Start at 0 because we will also count the current read
  my $overlap_it = CracTools::Utils::bamFileIterator($bam_file,"$chr:$pos1-$pos2");
  while(my $line = $overlap_it->()) {
    $nb_total++;
  }
  return $nb_total;
}

# TODO Create some kind of buffer to avoid repeating a query that have already been
# submited
my %retrieved_seq_buffer = ();
sub getSeqOrNs {
  my ($chr,$pos,$length,$ref_file) = @_;
  # Init seq with buffer
  my $seq = $retrieved_seq_buffer{"$chr-$pos-$length"};

  if(defined $ref_file && !defined $seq) {
    # Retrieve the seq from the reference
    $seq = CracTools::Utils::getSeqFromIndexedRef($ref_file,$chr,$pos,$length,'raw');
    # We update the buffer
    $retrieved_seq_buffer{"$chr-$pos-$length"} = $seq if defined $seq;
  }

  # If no seq is available we put N's instead
  if(!defined $seq) {
    $seq .= 'N' for(1..$length);
  }
  return $seq;
}

sub extractChimerasFromSAMline {
  my ($chimeras,$line,$is_stranded,$region_chr,$region_start,$region_end) = @_;
  # Next for secondary alignements
  if (!$line->isFlagged(256) && !$line->isFlagged(2048)) {
    # Loop over splices
    foreach my $chimera (@{$line->events('chimera')}) {
      my ($chr1,$pos1,$strand1) = @{$chimera->{loc1}}{'chr','pos','strand'};
      my ($chr2,$pos2,$strand2) = @{$chimera->{loc2}}{'chr','pos','strand'};

      my $key = join("@",$chr1,$pos1,$strand1,$chr2,$pos2,$strand2);
      my $reverse_key = join("@",$chr2,$pos2,$strand2*-1,$chr1,$pos1,$strand1*-1);

      if(!$is_stranded && defined $chimera->{$reverse_key}) {
        $key = $reverse_key;
      }elsif($is_stranded && $line->isFlagged($CracTools::SAMReader::SAMline::flags{FIRST_SEGMENT})) {
        $key = $reverse_key;
      }

      if(defined $chimeras->{$key}) {
        push(@{$chimeras->{$key}->{reads}},$line->qname);
        $chimeras->{$key}->{score} += $chimera->{score} if defined $chimera->{score};
      } else {
        $chimeras->{$key}->{reads} = [$line->qname];
        $chimeras->{$key}->{score} = $chimera->{score} if defined $chimera->{score};
      }
    }
  }
}

sub printChimeras {
  my $chimeras = shift;
  my $output_fh = shift;
  #foreach my $chimera (sort {$a->{chr1} <=> $b->{chr1} || $a->{pos1} <=> $b->{pos1}} values  %{$chimeras}) {
  foreach my $chim_key (keys  %{$chimeras}) {
    
    my($chr1,$pos1,$strand1,$chr2,$pos2,$strand2) = split("@",$chim_key);

    print $output_fh join "\t", $chr1,
                     $pos1,
                     CracTools::Utils::convertStrand($strand1),
                     $chr2,
                     $pos2,
                     CracTools::Utils::convertStrand($strand2),
                     defined $chimeras->{$chim_key}->{score}? $chimeras->{$chim_key}->{score}/@{$chimeras->{$chim_key}->{reads}} : 'N/A',
                     join(",",@{$chimeras->{$chim_key}->{reads}}),
                     scalar @{$chimeras->{$chim_key}->{reads}}
                     , "\n";
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

cractools extract - Extract events identified by CRAC.

=head1 VERSION

version 1.251

=head2 extractSplicesFromSAMline

=head2 printSplices

=head2 extractMutationsFromSAMline

=head2 printMutations

=head2 addMutation

=head2 countReadCoverFromRegion

=head2 getSeqOrNs

=head2 extractChimerasFromSAMline

=head2 printChimeras

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
