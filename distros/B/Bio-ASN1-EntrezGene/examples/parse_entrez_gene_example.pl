#!/usr/bin/perl

# launch it like "perl parse_entrez_gene_example.pl Homo_sapiens" (Homo_sapiens can be downloaded
# and decompressed from ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/ASN/Mammalia/Homo_sapiens.gz)
# or use the included test file "perl parse_entrez_gene_example.pl ../t/input.asn"

################################################################################
# parse_entrez_gene_example
# Purpose: Demonstrates how to use Mingyi's Entrez Gene parser and retrieve
#          each data item from Entrez Gene.  This data extraction demo is
#           very important as I spent 3-4 times more time on this script
#           than on writing, debugging, profiling, optimizing my parser!
#           It's a tedious task and I hope this script helps you (I'm sure
#           it will, if you use my parser).
# NOTE!!! This example script shows where each data item from Entrez Gene
#         is in the data structure, but it does not store much data at all!
#         Therefore you will find little data in the dumpValue($gene) gene call
#         That's because data storage is project specific.  Please store
#         the extracted data items in your script according to your own plan.
#
#         Although the author tries to show how to get all data out of Entrez Gene,
#         there is no guarantee that all data from all versions of Entrez Gene will
#         be extracted using this script.
# Copyright: (c) 2005, Mingyi Liu, GPC Biotech, Altana Research Institute.
# License: this code is licensed under Perl itself or GPL.
# Citation: Liu, M and Grigoriev, A (2005) "Fast Parsers for Entrez Gene"
#           Bioinformatics. In press
################################################################################

use strict;
use Dumpvalue;
use Benchmark;
use Bio::ASN1::EntrezGene;

my $parser = Bio::ASN1::EntrezGene->new('file' => $ARGV[0]);
my $i = 0;
while(my $result = $parser->next_seq)
{
  unless(defined $result) # this never happens, but doesn't hurt
  {
    print STDERR "bad text for round #".++$i."!\n";
    next;
  }
  $result = $result->[0] if(ref($result) eq 'ARRAY'); # this should always be true
  Dumpvalue->new->dumpValue($result); # $result contains all Entrez Gene data
  my $gene = makegene($result);
  Dumpvalue->new->dumpValue($gene); # although data are extracted, very few are stored (and thus dumped) after I edited out project-specific stuff, user should decide about the storage themselves
  last;
}

#################################################################################
# NOTE!!! this is just example that shows where each data item from Entrez Gene
#         is in the data structure, therefore I did not store all data items! But
#         for your own script, you'd probably want to store them.
# sorry I don't have time to add more comments! I hope they're easy to understand.
sub makegene
{
  my $seq = shift;
#   Dumpvalue->new->dumpValue($seq);exit;
  my $geneid = safeval($seq, '{track-info}->[0]->{geneid}');
  die "no geneid found!\n" unless $geneid; # this never happens, but doesn't hurt
  my (%protaccs, %protgis);
  my $llgene = {};

  ###################################################################################
  # it is difficult to process Entrez Gene in event-triggered functions, so
  # we'll just process items one by one to pick & choose the ones we want
  safeassign($llgene, 'description', $seq, '{gene}->[0]->{desc}');
  safeassign($llgene, 'type', $seq, '{type}');
  safeassign($llgene, 'symbol', $seq, '{gene}->[0]->{locus}'); # may be overwritten
  map { push(@{$llgene->{genenames}}, $_) } @{$seq->{gene}->[0]->{syn}} if(safeval($seq, '{gene}->[0]->{syn}'));
  $llgene->{summary} = $seq->{summary} if($seq->{summary});
  $llgene->{chromosome} = $seq->{source}->[0]->{subtype}->[0]->{name} if(safeval($seq, '{source}->[0]->{subtype}->[0]->{subtype}') eq 'chromosome');
  safeassign($llgene, 'chrmap', $seq, '{gene}->[0]->{maploc}');
  addxrefs($llgene, 'HGNC', $1) if(safeval($seq, '{gene}->[0]->{locus-tag}') =~ /HGNC:(\S+)/i);

  ##########################################
  # HomoloGene
  if($seq->{homology})
  {
    # Entrez Gene documentation seems to have errors on this one (no label, text, anchor,
    # otherwise we could provide some description)
    # NOTE!!! species could be multiple species separated by ','
    my $id = safeval($seq, '{homology}->[0]->{source}->[0]->{src}->[0]->{tag}->[0]->{id}');
    my $species = safeval($seq, '{homology}->[0]->{heading}');
  }

  ##########################################
  # OK, let's process the comments
  my $allseqs = {}; # refseq seqs
  foreach my $comment (@{$seq->{comments}})
  {
    # pubmed ids
    addxrefs($llgene, 'PUBMED', $comment->{refs}->[0]->{pmid}) if(ref($comment->{refs}) eq 'ARRAY');
    my $status = $comment->{label} if($comment->{heading} eq 'RefSeq Status');
    #####################
    # STS stuff
    if($comment->{heading} =~ /Markers.*STS\)$/)
    {
      foreach my $c (@{$comment->{comment}})
      {
        addxref($llgene, 'UNISTS', id => safeval($c, '{source}->[0]->{anchor}'),
                        acc => safeval($c, '{source}->[0]->{src}->[0]->{tag}->[0]->{id}'));
      }
    }
    ##############################################################
    # refseq stuff, DNA=>protein, domain info, we store it first
    # and assemble info for future processing
    # of variants, transcripts and proteins, (dealing with these objects
    # is by far the most time-consuming task in extracting Entrez Gene data)
    if($comment->{heading} =~ /\(RefSeq\)$/ && $comment->{products})
    {
      foreach my $product (@{$comment->{products}})
      {
        my ($acc, $gi, $trans, %ids);
        # we are probably too careful below since refseq should have accession AND gi
        $acc = $product->{accession};
        $gi = safeval($product, '{source}->[0]->{src}->[0]->{tag}->[0]->{id}');
        if($acc)
        {
          $ids{acc} = $acc;
          $trans->{acc} = $ids{acc};
          $trans->{gi} = $gi if $gi;
          $allseqs->{$acc} = $trans;
          $trans->{type} = $product->{heading} if($product->{type} ne 'mRNA');
        }
        $ids{gi} = $gi if($gi);
        if($product->{comment})
        {
          foreach my $c (@{$product->{comment}})
          {
            # check assembly info
            if($c->{heading} eq 'Source Sequence')
            {
              $trans->{assembly} = safeval($c, '{source}->[0]->{anchor}');
            }
            # check variant info
            if($c->{heading} eq 'Transcriptional Variant')
            {
              $trans->{variantcomment} = safeval($c, '{comment}->[0]->{text}');
            }
          }
        }
        #############################
        # now deal with protein
        if(ref($product->{products}) eq 'ARRAY') # protein
        {
          my ($prot);
          for(my $j = 0; $j < @{$product->{products}}; $j++)
          {
            my $p = $product->{products}->[$j];
            $acc = $p->{accession};
            $gi = safeval($p, '{source}->[0]->{src}->[0]->{tag}->[0]->{id}');
            if($gi)
            {
              $ids{'protgi' . ($j+1)} = $gi;
              $protgis{$gi} = 'protgi' . ($j+1);
            }
            if($acc)
            {
              $ids{'protacc' . ($j+1)} = $acc;
              $protgis{$acc} = 'protacc' . ($j+1);
              $prot->{acc} = $acc;
              $prot->{gi} = $gi if $gi;
              $trans->{protein}->{$acc} = $prot;
              $prot->{type} = $product->{heading} if($p->{type} ne 'peptide');
            }
            safeassign($prot, 'name', $p, '{source}->[0]->{post-text}');
            #############################
            # check domain info
            if($p->{comment})
            {
              foreach my $c1 (@{$p->{comment}})
              {
                if($c1->{heading} =~ /Domains$/)
                {
                  my @domains;
                  foreach my $c2 (@{$c1->{comment}})
                  {
                    my $dom;
                    my $tmp = safeval($c2, '{comment}->[0]->{text}');
                    $dom->{score} = $tmp =~ /Blast Score: ([0-9.-]+)/;
                    ($dom->{start}, $dom->{end}) = $tmp =~ /Location: (\d+) - (\d+)/;
                    $dom->{desc} = safeval($c2, '{source}->[0]->{anchor}');
                    $dom->{xref} = { db  => safeval($c2, '{source}->[0]->{src}->[0]->{db}'),
                                     ids => [{type=>'id',id=>safeval($c2, '{source}->[0]->{src}->[0]->{tag}->[0]->{id}')}]
                                   };
                    push(@domains, $dom);
                  }
                  $prot->{dom} = \@domains;
                }
                elsif($c1->{heading} =~ /\(CCDS\)/) # CCDS database xref
                {
                  $prot->{ccds} = safeval($c1, '{source}->[0]->{src}->[0]->{tag}->[0]->{str}');
                }
              }
            }
            ################
            # end domain
          }
        }
        ######################
        # end protein
        addxref($llgene, 'REFSEQ', %ids) if (keys %ids > 0);
      }
    }
    #########################################################
    # related seqeunces, goes into xref only
    if($comment->{heading} eq 'Related Sequences' && $comment->{products})
    {
      foreach my $product (@{$comment->{products}})
      {
        my ($acc, $gi, %ids);
        $acc = $product->{accession};
        $gi = safeval($product, '{source}->[0]->{src}->[0]->{tag}->[0]->{id}');
        $ids{gi} = $gi if $gi;
        $ids{acc} = $acc if $acc;
        if(ref($product->{products}) eq 'ARRAY')
        {
          # just in case two genbank protein's assigned to one mRNA
          for(my $j = 0; $j < @{$product->{products}}; $j++)
          {
            $acc = $product->{products}->[$j]->{accession};
            $gi = safeval($product->{products}->[$j], '{source}->[0]->{src}->[0]->{tag}->[0]->{id}');
            $ids{'protgi' . ($j+1)} = $gi if $gi;
            $ids{'protacc' . ($j+1)} = $acc if $acc;
          }
        }
        addxref($llgene, 'GENBANK', %ids) if (keys %ids > 0);
      }
    }
    ######################
    # various dblinks
    if($comment->{heading} eq 'Additional Links' && $comment->{comment})
    {
      foreach my $c (@{$comment->{comment}})
      {
        my $id = safeval($c, '{source}->[0]->{src}->[0]->{tag}->[0]->{str}');
        if($id) # add xref to llgene
        {
          my $db = uc(safeval($c, '{source}->[0]->{src}->[0]->{db}'));
          next if $db =~ /\s+/ || $db =~ /HomoloGene/i; # homologene id here is not real id, and some of dblinks' DB name are not real DBs, we temporarily use space to identify those
          my @ids = trim(split /,/, $id); # MGC sometimes has multiple ids concatenated by ','
          map { s/^$db://i; addxref($llgene, $db, 'id' => $_) } @ids; # $db: truncation useful for GDB ids
        }
        my $url = safeval($c, '{source}->[0]->{url}');
        if($url)
        {
          $url =~ s/\s//g; # some urls have linebreaks in them
          my $desc = safeval($c, '{source}->[0]->{anchor}');
        }
      }
    }

    ######################
    # Pathways
    if($comment->{heading} eq 'Pathways' && $comment->{comment})
    {
      foreach my $c (@{$comment->{comment}})
      {
        my $id = safeval($c, '{source}->[0]->{src}->[0]->{tag}->[0]->{str}');
        my $url = safeval($c, '{source}->[0]->{url}');
        if($url)
        {
          $url =~ s/\s//g; # some urls have linebreaks in them
          my $desc = ($c->{text})? $c->{text} : 'KEGG Pathway';
        }
        if($id) # add xref to llgene
        {
          my @ids = trim(split /,/, $id); # MGC sometimes has multiple ids concatenated by ','
          map { addxref($llgene, 'KEGG', 'id' => $_) } @ids; # $db: truncation useful for GDB ids
        }
      }
    }
    ######################
    # generif
    if($comment->{type} eq 'generif')
    {
      my @cs = ($comment->{heading} && ref($comment->{comment}) eq 'ARRAY')? @{$comment->{comment}} : $comment;
      foreach my $c (@cs)
      {
        my $generif = $c->{text};
        my $pmid => safeval($c, "{refs}->[0]->{pmid}");
        if($comment->{heading})
        {
          my $type = $comment->{heading};
          my ($db, $id) = makexref($c);
          my $anchor = safeval($c, '{source}->[0]->{anchor}');
          foreach my $c1 (@{$c->{comment}})
          {
            my ($db, $id) = makexref($c1);
            my ($label, $acc) = ((($c1->{label})? "$c1->{label}:" : ''), $c1->{accession});
          }
        }
        addxref($llgene, 'PUBMED', 'id' => safeval($c, "{refs}->[0]->{pmid}"));
      }
    }

    ######################
    # phenotype
    if($comment->{heading} eq 'Phenotypes')
    {
      my $detail = safeval($comment, '{comment}->[0]->{text}');
      if(safeval($comment, '{comment}->[0]->{source}'))
      {
        my $db = safeval($comment, '{comment}->[0]->{source}->[0]->{src}->[0]->{db}');
        my $id = safeval($comment, '{comment}->[0]->{source}->[0]->{src}->[0]->{tag}->[0]->{id}');
      }
    }

    ######################
    # relationships
    if($comment->{heading} eq 'Relationships')
    {
      foreach my $c (@{$comment->{comment}})
      {
        my $type = ($c->{text} =~ /related (.*)/)? $1 : $c->{text};
        my $anchor = safeval($c, '{source}->[0]->{anchor}');
        my ($db, $id) = makexref($c);
      }
    }

    ######################
    # tRNA
    if($comment->{heading} eq 'tRNA-ext')
    {
      my $trnatext = $comment->{text};
    }

    #########################################################################
    # ECNUM (documentation for Entrez Gene says it's here, so I put this in,
    # but it is actually in locus (see further below)
    if($comment->{type} =~ /property/i && $comment->{label} eq 'EC')
    {
      addxref($llgene, 'EC', 'id' => $comment->{text});
    }
  }

  my %map = ('FUNCTION'  => 'molecular function',
             'PROCESS'   => 'biological process',
             'COMPONENT' => 'cellular component');
  ##################################
  # OK, let's process the GO info
  if($seq->{properties})
  {
    foreach my $p (@{$seq->{properties}})
    {
      if($p->{heading} eq 'GeneOntology')
      {
        foreach my $c (@{$p->{comment}})
        {
          foreach my $c1 (@{$c->{comment}})
          {
            my ($db, $id) = (safeval($c1, '{source}->[0]->{src}->[0]->{db}'),
                             safeval($c1, '{source}->[0]->{src}->[0]->{tag}->[0]->{id}'));
            addxref($llgene, $db, id => $id);
            my $category = $map{uc($c->{label})};
            my $content = safeval($c1, '{source}->[0]->{anchor}');
          }
        }
      }
      elsif($p->{label} eq 'Nomenclature')
      {
        foreach my $p1 (@{$p->{properties}})
        {
          if($p1->{label} eq 'Official Symbol')
          {
            my $hugosymbol = $p1->{text};
          }
          elsif($p1->{label} eq 'Official Full Name')
          {
            my $hugoname = $p1->{text};
          }
        }
      }
    }
  }
  ##################################
  # protein aliases
  if($seq->{prot})
  {
    foreach my $p (@{$seq->{prot}})
    {
      map { my $protalias = $_ } @{$p->{name}} if(ref($p->{name}) eq 'ARRAY');
    }
  }
  #####################################################################
  # now locus, again assemble info into $allseqs for future processing
  # of variants, transcripts and proteins, (dealing with these objects
  # is by far the most time-consuming task in extracting Entrez Gene data)
  if($seq->{locus})
  {
    # judgement call:
    # we should take NC_ whenever possible and disregard NT_
    # but in absence of NC_, we use NT_ to figure out exons
    foreach my $l (@{$seq->{locus}})
    {
      if($l->{products})
      {
        foreach my $p (@{$l->{products}})
        {
          ########################################
          # let's first get the accession numbers
          my %ids;
          $ids{acc} = $p->{accession};
          my $gi = safeval($p, '{seqs}->[0]->{whole}->[0]->{gi}');
          $ids{gi} = $gi if $gi;
          my $t = $allseqs->{$p->{accession}};
          $allseqs->{$p->{accession}}->{acc} = $ids{acc} unless $allseqs->{$p->{accession}}->{acc}; # sometimes NCBI forgot to put refseq IDs into comments about Refseq sequences, e.g. Gene 616.
          $allseqs->{$p->{accession}}->{gi} = $ids{gi} unless $allseqs->{$p->{accession}}->{gi}; # sometimes NCBI forgot to put refseq IDs into comments about Refseq sequences, e.g. Gene 616.
          if($p->{products})
          {
            for(my $j = 0; $j < @{$p->{products}}; $j++)
            {
              my $p1 = $p->{products}->[$j];
              $gi = safeval($p1, '{seqs}->[0]->{whole}->[0]->{gi}');
              my ($gino, $accno) = ((($protgis{$gi})? $protgis{$gi} : 'protgi' . ($j+1)),
                                   (($protaccs{$p1->{accession}})? $protaccs{$p1->{accession}} : 'protacc' . ($j+1)));
              if($gi)
              {
                $ids{$gino} = $gi;
                $protgis{$gi} = $gino;
              }
              $ids{$accno} = $p1->{accession};
              $protaccs{$p1->{accession}} = $accno;
              $allseqs->{$p->{accession}}->{protein}->{$p1->{accession}}->{acc} = $ids{$accno} unless $allseqs->{$p->{accession}}->{protein}->{$p1->{accession}}->{acc}; # sometimes NCBI forgot to put refseq IDs into comments about Refseq sequences, e.g. Gene 616.
              $allseqs->{$p->{accession}}->{protein}->{$p1->{accession}}->{gi} = $ids{$gino} unless $allseqs->{$p->{accession}}->{protein}->{$p1->{accession}}->{gi}; # sometimes NCBI forgot to put refseq IDs into comments about Refseq sequences, e.g. Gene 616.
              if($p1->{comment} && safeval($p1, '{comment}->[0]->{type}') eq 'property' &&
                 safeval($p1, '{comment}->[0]->{label}') eq 'EC')
              {
                my $ec = safeval($p1, '{comment}->[0]->{text}');
                # change dealing with EC number to add to xref
                addxref($llgene, 'EC', 'id' => $ec);
              }
            }
          }
          addxref($llgene, 'REFSEQ', %ids); # trans and prots xrefs

          #############################################################
          # now get exon coordinates - only do the work when necessary
          unless($t && $t->{genomic} && ($t->{genomic} =~ /^NC_/ || $l->{accession} =~ /^NT_/))
          {
            $allseqs->{$p->{accession}}->{genomic} = $l->{accession};
            $allseqs->{$p->{accession}}->{type} = $p->{type};
            my $tmp = safeval($p, '{genomic-coords}->[0]->{mix}->[0]->{int}') ||
                      safeval($p, '{genomic-coords}->[0]->{int}');
            $allseqs->{$p->{accession}}->{exons} = $tmp if($tmp);
            if($p->{products})
            {
              foreach my $p1 (@{$p->{products}})
              {
                #############################################################
                # now get protein location - only do the work when necessary
                $t = $allseqs->{$p->{accession}}->{protein}->{$p1->{accession}};
                unless($t && $t->{from})
                {
                  my $tmp = safeval($p1, '{genomic-coords}->[0]->{packed-int}') ||
                            safeval($p1, '{genomic-coords}->[0]->{int}');
                  if($tmp)
                  {
                    $allseqs->{$p->{accession}}->{protein}->{$p1->{accession}}->{from} = $tmp->[0]->{from};
                    $allseqs->{$p->{accession}}->{protein}->{$p1->{accession}}->{to} = $tmp->[$#$tmp]->{to};
                  }
                }
              }
            }
          }
        }
        addxref($llgene, 'REFSEQ', 'acc' => $l->{accession},
                   'gi' => safeval($l, '{seqs}->[0]->{int}->[0]->{id}->[0]->{gi}')); # trans and prots xrefs
      }
    }
  }
  ##########################################################################
  # now that we got all info for transcripts and proteins
  # we should assemble info into variants, transcripts and proteins,
  # (dealing with these objects is by far the most time-consuming task
  # in extracting Entrez Gene data)
  # note again I edited out project-specific stuff, so the only purpose is
  # to show you where data items are, not to store everything
  my (@variants, @trans, $genestart, $geneend, $genomeacc);
  foreach my $dnaacc (keys %$allseqs)
  {
    my ($variant, $trans, $xref);
    my $t = $allseqs->{$dnaacc};
    if($t->{variantcomment})
    {
      $variant->{comment} = $t->{variantcomment};
    }
    ############################################
    # work on transcript
    $trans->{assembly} = $t->{assembly} if $t->{assembly};
    $trans->{type} = $t->{type} if $t->{type};
    $trans->{comment} = "Data from $t->{genomic}" if($t->{genomic});
    $genomeacc = $t->{genomic} unless $genomeacc;
    my $dealwithtransxref if($t->{acc} || $t->{gi}); # db should be refseq
    # now exon
    if($t->{exons})
    {
      if($t->{genomic} eq $genomeacc) # only process when the trans is on same contig as first one
      {
        $genestart = $t->{exons}->[0]->{from} if(!$genestart || $t->{exons}->[0]->{from} < $genestart);
        $geneend = $t->{exons}->[$#{$t->{exons}}]->{to} if($t->{exons}->[$#{$t->{exons}}]->{to} > $geneend);
      }
      foreach my $exon (@{$t->{exons}})
      {
        $trans->{strand} = $exon->{strand} unless $trans->{strand};
        my $start = $exon->{from}; # follow Entrez Gene style, start is always smaller than end
        my $end = $exon->{to};
        my $coordSys = "$t->{genomic}";
      }
      # finally protein
      if($t->{protein})
      {
        foreach my $pacc (keys %{$t->{protein}})
        {
          my $p = $t->{protein}->{$pacc};
          my $deal_with_prot_xref if($p->{acc}); # db should be refseq
          my $add_ccds_xref if($p->{ccds}); # db should be CCDS
          my $protname = $p->{name} if($p->{name});
          if($p->{from} || $p->{to}) # sometimes Entrez Gene forgets to annotate CDS start/end like for gene 574, NP_001178
          {
            my $protcoordSys = "$t->{genomic}";
            my $protstart = $p->{from} if $p->{from};
            my $protend = $p->{to} if $p->{to};
          }
          # domains
          if($p->{dom})
          {
            foreach my $dom (@{$p->{dom}})
            {
              my $desc = $dom->{desc};
              my $score = $dom->{score} if(defined $dom->{score});
              my $loc = { start => $dom->{start}, end=> $dom->{end}, coordSys => "$p->{acc}" };
              my $xref = $dom->{xref};
            }
          }
        }
      }
    }
    # put transcript into variant if annotated, otherwise into transcript
    if($variant)
    {
      # user can decide how to store
    }
    else
    {
      # user can decide how to store
    }
  }
  if($genestart && $geneend)
  {
    # user can decide how to store
  }

  # tracking info about how this gene has changed
  if(safeval($seq, '{track-info}->[0]->{current-id}'))
  {
    my (@ids, $newegid, $newllid);
    foreach my $id (@{$seq->{'track-info'}->[0]->{'current-id'}})
    {
      my $tmpid = safeval($id, '{tag}->[0]->{id}');
      push(@ids, "$id->{db}:$tmpid");
      $newegid = $tmpid if($id->{db} =~ /^GeneID$/i);
      $newllid = $tmpid if($id->{db} =~ /^LocusID$/i);
    }
    my $comment = "Gene moved: current IDs are: " . join(' ; ', @ids);
  }

  return $llgene;
}

# safely assign a value to $data->{$key} ($data must be hash)
sub safeassign
{
  my ($data, $key, $ds, $str) = @_;
  my $tmp = safeval($ds, $str);
  $data->{$key} = $tmp if $tmp;
  return (defined $tmp)? 1 : 0;
}

# safely extracts a value, another choice is to simply use
# eval in-line, if it fails, it fails.  Probably faster, but can't
# give feedback in-line (always has to add a couple lines dealing with
# $@ for error reporting), might still be worth it though because
# of the speed.  User can make his/her own choice here.

sub safeval
{
  my ($ds, $str) = @_; # data structure and string (we need $ds passed in because we use strict)
  my @items = split('->', $str);
  foreach (@items)
  {
    my $tmp;
    if(($tmp) = /\[(\d+)\]/)
    {
      return undef unless(ref($ds) eq 'ARRAY' && @$ds > $tmp);
      $ds = $ds->[$tmp];
    }
    elsif(($tmp) = /^{(.*?)}$/)
    {
      return undef unless(ref($ds) eq 'HASH' && $ds->{$tmp}); # this is not ideal (since one might want to return '' instead of undef when this hash value is defined as ''), but correct for our situations
      $ds = $ds->{$tmp};
    }
    else
    {
      die "wrong syntax for string:$str\n";
    }
  }
  return $ds;
}

sub addxrefs
{
  # left for user implementation since it's project-specific
}

sub addxref
{
  # left for user implementation since it's project-specific
}

# used for making xrefs listed under comments
sub makexref
{
  my $c = shift;
  my $db = safeval($c, '{source}->[0]->{src}->[0]->{db}');
  my $id = safeval($c, '{source}->[0]->{src}->[0]->{tag}->[0]->{id}') ||
           safeval($c, '{source}->[0]->{src}->[0]->{tag}->[0]->{str}');
  # change the following as suited for your project
  $id =~ $1 if($id =~ /^"(.*)"$/);
  if($db =~ /GeneID/)
  {
    $db = 'ENTREZGENE';
  }
  elsif($db =~ /Nucleotide/)
  {
    $db = 'GENBANK';
  }
  return ($db, $id);
}

sub trim
{
  my @data = @_;
  map { s/^\s+//; s/\s+$//; } (@data);
  return wantarray ? @data : $data[0];
}
