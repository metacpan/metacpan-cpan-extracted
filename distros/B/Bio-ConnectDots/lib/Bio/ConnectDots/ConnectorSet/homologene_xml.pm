package Bio::ConnectDots::ConnectorSet::homologene_xml;
use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
  my ($self) = @_;
  my $input_fh=$self->input_fh;
	my ($homo_id, $gene_id, $tax_id, $prot_gi, %mm, %hs, %rn, %dr, $gi1, $gi2, $combine, $rec_best, %best);
	while (<$input_fh>) {
		chomp;
		if (/\<HomoloGeneEntry_hg-id\>(\d+)\<\/HomoloGeneEntry_hg-id\>/ ) {
		 	$homo_id = $1;
#			print "$homo_id\n";
		}
		if (/\<Gene_geneid\>(\d+)\<\/Gene_geneid\>/) {
			$gene_id = $1;
		# really only need gene id b/c I have the rest from ll_tmpl
		}	
		if (/\<Gene_taxid\>(\d+)\<\/Gene_taxid\>/) { 
			$tax_id = $1;
		}
		if (/\<Gene_prot-gi\>(\d+)\<\/Gene_prot-gi\>/) {
			$prot_gi = $1;
		}
		if (/\<\/Gene\>/ ) { ## this is the end of gene information
			if ( $tax_id == 9606 ) {
				%hs = ( gene => $gene_id,
						gi   => $prot_gi,
						);	
			}
			if ( $tax_id == 10090 ) {
				%mm = ( gene => $gene_id,
						gi   => $prot_gi,
						);	
			}		
			if ( $tax_id == 10116 ) {
				%rn = ( gene => $gene_id,
						gi   => $prot_gi,
						);	
			}
					
			if ( $tax_id == 7227 ) {
				%dr = ( gene => $gene_id,
						gi   => $prot_gi,
						);	
			}
		}
		#reciprical best, blast scores
		if (/\<Stats_gi1\>(\d+)\<\/Stats_gi1\>/) {
			$gi1 = $1;
		}
		if (/\<Stats_gi2\>(\d+)\<\/Stats_gi2\>/) {
			$gi2 = $1;
		}
		if ( $gi1 && $gi2) {
			my @sort = ($gi1, $gi2);
			$combine = join('', sort(@sort));
			if (/Stats_recip\-best/) {
				if (/true/) {
					$best{$combine} = "true";
				} elsif (/false/) {
					$best{$combine} = "false";
				} else {
					$best{$combine} = "~";
				}	
			}
		}
		if (/\<\/Stats\>/) {
			##put into best hash
			($gi1, $gi2, $rec_best) = ('', '', '');
		}

		if (/\<\/HomoloGeneEntry_distances\>/) {
			## put best hash into sp hashes
			$hs{"best_w_mouse"} = $best{join('', sort($hs{gi}, $mm{gi}))} if ($hs{gi} && $mm{gi});
			$hs{"best_w_rat"} = $best{join('', sort($hs{gi}, $rn{gi}))} if ($hs{gi} && $rn{gi});
			$mm{"best_w_human"} = $best{join('', sort($hs{gi}, $mm{gi}))} if ($hs{gi} && $mm{gi});
			$mm{"best_w_rat"} = $best{join('', sort($mm{gi}, $rn{gi}))} if ($mm{gi} && $rn{gi});
			$rn{"best_w_human"} = $best{join('', sort($hs{gi}, $rn{gi}))} if ($hs{gi} && $rn{gi});
			$rn{"best_w_mouse"} = $best{join('', sort($rn{gi}, $mm{gi}))} if ($rn{gi} && $mm{gi});
		}	
		if (/\<\/HomoloGeneEntry\>/) { #end of this hologene cluster
#			print "\t9606\t$hs{gene}\t$hs{gi}\tv_mm:".$hs{"best_w_mouse"}."\tv_rn:".$hs{"best_w_rat"}."\n" if $hs{gene};
#			print "\t10090\t$mm{gene}\t$mm{gi}\tv_hs:".$mm{"best_w_human"}."\tv_rn:".$mm{"best_w_rat"}."\n" if $mm{gene};
#			print "\t10116\t$rn{gene}\t$rn{gi}\tv_hs:".$rn{"best_w_human"}."\tv_mm:".$rn{"best_w_mouse"}."\n" if $rn{gene};
	## this is where the dots go in.
			$self->put_dot('Homologene_ID', $homo_id);

			$self->put_dot('9606', $hs{gene}) if ($hs{gene});
			$self->put_dot('10090', $mm{gene}) if ($mm{gene});
			$self->put_dot('10116', $rn{gene}) if ($rn{gene});
			$self->put_dot('7227', $dr{gene}) if ($rn{gene});

			$self->put_dot('9606_gi', $hs{gi}) if ($hs{gi});
			$self->put_dot('10090_gi', $mm{gi}) if ($mm{gi});
			$self->put_dot('10116_gi', $rn{gi}) if ($rn{gi});
			$self->put_dot('7227_gi', $dr{gi}) if ($rn{gi});
			
			$self->put_dot('9606_v_10090', $hs{"best_w_mouse"}) if ($hs{"best_w_mouse"});
			$self->put_dot('9606_v_10116', $hs{"best_w_rat"}) if ($hs{"best_w_rat"});
			$self->put_dot('10090_v_9606', $mm{"best_w_human"}) if ($mm{"best_w_human"});
			$self->put_dot('10090_v_10116', $mm{"best_w_rat"}) if ($mm{"best_w_rat"});
			$self->put_dot('10116_v_9606', $rn{"best_w_human"}) if ($rn{"best_w_human"});
			$self->put_dot('10116_v_10090', $rn{"best_w_mouse"}) if ($rn{"best_w_mouse"});

			return $self->have_dots; ##start all over again
		}	
	} #end of while
  return undef;
}#end of sub

1;
