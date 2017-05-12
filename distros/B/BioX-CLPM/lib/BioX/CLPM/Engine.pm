package BioX::CLPM::Engine;
use base qw(BioX::CLPM::Base);
use BioX::CLPM::Sequence;
use BioX::CLPM::Enzyme;
use BioX::CLPM::Linker;
use BioX::CLPM::Fragments;
use Bio::Perl qw(read_sequence);
use Class::Std;
use Class::Std::Utils;
use Switch;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');

{
        my %sequences_of    :ATTR( :get<sequences>     :set<sequences>     :default<[]>      :init_arg<sequences> );
        my %enzyme_of       :ATTR( :get<enzyme>        :set<enzyme>        :default<''>      :init_arg<enzyme> );
        my %linker_of       :ATTR( :get<linker>        :set<linker>        :default<''>      :init_arg<linker> );
        my %peaks_of        :ATTR( :get<peaks>         :set<peaks>         :default<''>      :init_arg<peaks> );
        my %matches_of      :ATTR( :get<matches>       :set<matches>       :default<''>      :init_arg<matches> );
        my %fragments_of    :ATTR( :get<fragments>     :set<fragments>     :default<''>      :init_arg<fragments> );
        my %tolerance_of    :ATTR( :get<tolerance>     :set<tolerance>     :default<''>      :init_arg<tolerance> );
        my %missed_clvg_of  :ATTR( :get<missed_clvg>   :set<missed_clvg>   :default<''>      :init_arg<missed_clvg> );
        my %var_mod_of      :ATTR( :get<var_mod>       :set<var_mod>       :default<''>      :init_arg<var_mod> );
        my %stat_mod_of     :ATTR( :get<stat_mod>      :set<stat_mod>      :default<''>      :init_arg<stat_mod> );
        #my %attribute_of    :ATTR( :get<attribute>     :set<attribute>     :default<''>      :init_arg<attribute> );

	# PRIV
        sub BUILD {
                my ( $self, $ident, $arg_ref ) = @_;
		$self->db_trunc();
                return;
        }

	# PRIV
        sub START {
                my ( $self, $ident, $arg_ref ) = @_;
		if ( $arg_ref ) { $self->_run( $arg_ref ); }
                return;
        }

	# PRIV
	sub _run {
		my ( $self, $arg_ref ) = @_;

		# Add or replace sequences from id or name
		my @sequences;
		if ( defined $arg_ref->{sequences} ) {
			if ( defined $arg_ref->{sequences}->{files} ) {
				foreach my $file ( @{ $arg_ref->{sequences}->{files} } ) {
					push @sequences, $self->sequence({ file => $file }); 
				}
			}
			if ( defined $arg_ref->{sequences}->{ids} ) {
				foreach my $file ( @{ $arg_ref->{sequences}->{ids} } ) {
					#push @sequences, $self->sequence({ file => $arg_ref->{sequence_id} }); 
					# TODO retrieve by id
				}
			}
		}
		# TODO retrieve by accn
		# TODO make sure there two, otherwise raise error
		if ( @sequences ) { $self->set_sequences( \@sequences ); }

		# Add or replace enzyme from id or name
		if ( defined $arg_ref->{enzyme_id} or defined $arg_ref->{enzyme_name} ) {
			my $enzyme = $self->enzyme({ id   => $arg_ref->{enzyme_id},
			                             name => $arg_ref->{enzyme_name} }); 
			if ( $enzyme ) { $self->set_enzyme( $enzyme ); }
		}

		# Add or replace linker from id or name
		if ( defined $arg_ref->{linker_id} or defined $arg_ref->{linker_name} ) {
			my $linker = $self->linker({ id   => $arg_ref->{linker_id},
			                             name => $arg_ref->{linker_name} }); 
			if ( $linker ) { $self->set_linker( $linker ); }
		}

		# Mark linking aa's
		$self->mark_links();

		# Cleave sequence into fragments
		$self->cleave();

		# Calculate masses
		$self->masses();

		# Cross link
		$self->cross_link();

		# Match
		#$self->match();

		# Show results
		#$self->results();

                return;
        }

	# API READ ONLY
	sub sequences  { my ( $self ) = @_; return @{ $self->get_sequences() }; }
	sub seq_one    { my ( $self ) = @_; my @sequences = $self->sequences(); return $sequences[0]; }
	sub seq_two    { my ( $self ) = @_; my @sequences = $self->sequences(); return $sequences[1]; }
	sub enzyme_id  { my ( $self ) = @_; return $self->get_enzyme->get_enzyme_id(); }
	sub linker_id  { my ( $self ) = @_; return $self->get_linker->get_linker_id(); }
	sub var_mods   { my ( $self ) = @_; return %{ $self->get_var_mod() }; }

	# API
	sub run {
		my ( $self, $arg_ref ) = @_;
		if ( $arg_ref ) { $self->_run( $arg_ref ); }
                return;
        }

	# API
	sub sequence {
		my ( $self, $arg_ref ) = @_;
		my $sequence_id   = $arg_ref->{id}   ? $arg_ref->{id}   : 0;
		my $file          = $arg_ref->{file} ? $arg_ref->{file} : '';
		if ( $sequence_id ) { 
                	return BioX::CLPM::Sequence->new({ sequence_id   => $sequence_id });
        	} elsif ( $file ) {
                	return BioX::CLPM::Sequence->new({ file          => $file });
		}
        }

	# API
	sub enzyme {
		my ( $self, $arg_ref ) = @_;
		my $enzyme_id   = $arg_ref->{id}   ? $arg_ref->{id}   : 0;
		my $enzyme_name = $arg_ref->{name} ? $arg_ref->{name} : '';
		if ( $enzyme_id || $enzyme_name ) {
                	my $enzyme = BioX::CLPM::Enzyme->new({ enzyme_id   => $enzyme_id, 
        		                                       enzyme_name => $enzyme_name });
			$self->set_enzyme( $enzyme );
                	return $enzyme;
		} else {
			return $self->get_enzyme();
		}
        }

	# API
	sub linker {
		my ( $self, $arg_ref ) = @_;
		my $linker_id   = $arg_ref->{id}   ? $arg_ref->{id}   : 0;
		my $linker_name = $arg_ref->{name} ? $arg_ref->{name} : '';
		if ( $linker_id || $linker_name ) {
                	my $linker = BioX::CLPM::Linker->new({ linker_id   => $linker_id, 
		                                               linker_name => $linker_name });
			$self->set_linker( $linker );
                	return $linker;
		} else {
			return $self->get_linker();
		}
        }

	# API
	sub mark_links {
                my ( $self, $arg_ref ) = @_;
		my $linker      = defined $arg_ref->{linker}   ? $arg_ref->{linker}   : $self->get_linker();
		my @ends        = $linker->ends();
		my @sequences   = defined $arg_ref->{sequences}   ? @{ $arg_ref->{sequences} }   : $self->sequences();

		$self->_mark_links({ sequence => $sequences[0], end => $ends[0] });
		$self->_mark_links({ sequence => $sequences[1], end => $ends[1] });

		$self->set_sequences( \@sequences );
                return \@sequences;
        }
        
	# API
	sub cleave {
                my ( $self, $arg_ref ) = @_;
		my $enzyme          = $self->get_enzyme();
		my $linker          = $self->get_linker();
		my $missed_clvg     = $self->get_missed_clvg();
		my @sequences       = defined $arg_ref->{sequences}   ? @{ $arg_ref->{sequences} }   : $self->sequences();
		my @fragments;
		warn "ENGINE cleave() \n";
		my $last_index = 1;
		for ( my $i = 0; $i < @sequences; $i++ ) {
			@fragments    = $self->_cleave({ sequence => $sequences[$i], enzyme => $enzyme });
			@fragments    = $self->_missed({ fragments => \@fragments, missed_clvg => $missed_clvg });
			@fragments    = $self->_filter({ fragments => \@fragments, index => $i });
			#warn "   setting fragments " . join( ', ', @fragments ) . "\n";

			my $fragments = BioX::CLPM::Fragments->new({ sequence_id => $sequences[$i]->get_sequence_id(), index => $last_index, type => 'simple' });
			foreach my $fragment ( @fragments ) { $fragments->add({ sequence => $fragment }); }
			$sequences[$i]->set_fragments( $fragments->get_list() );
			$last_index = $fragments->get_index();
		}
		$self->set_sequences( \@sequences );
                return \@sequences;
        }
        
	# API
	sub masses {
                my ( $self, $arg_ref ) = @_;
		my %var_mods  = defined $arg_ref->{var_mod}   ? %{ $arg_ref->{var_mod} }   : $self->var_mods();
		my @sequences = defined $arg_ref->{sequences} ? @{ $arg_ref->{sequences} } : $self->sequences();
		my $aa_masses = $self->_stat_mod();
		foreach my $sequence ( @sequences ) {
			my @fragments = $sequence->fragments();
			for ( my $i = 0; $i < @fragments; $i++ ) {
				my $sequence = $fragments[$i]->get_sequence();
				my @sequence = split( //, $sequence );
				my $counts   = {};
				my $mass     = 0;
				foreach my $aa ( @sequence ) {
					$aa    = uc($aa);
					$mass += $aa_masses->{$aa};	
					$counts->{$aa}++;
				}
				# Add mass of 1 molecule of water
				$mass += 18.010565;
				$fragments[$i]->set_mass( $mass );

				# Keep counts for aa's affected by var_mod
				my $keepers = {};
				foreach my $var_mod ( keys %var_mods ) {
					$keepers->{$var_mod} = $counts->{$var_mod};
				}
				$fragments[$i]->set_counts( $keepers );
			}
			$sequence->set_fragments( \@fragments );
		}
                $self->set_sequences( \@sequences );
                return \@sequences;
        }
        
	# API
	sub cross_link {
                my ( $self, $arg_ref ) = @_;
		my $mass          = defined $arg_ref->{mass}   ? $arg_ref->{mass}   : $self->linker()->get_mass();
		#my @sequences = defined $arg_ref->{sequences} ? @{ $arg_ref->{sequences} } : $self->sequences();
		warn "ENGINE cross_link() mass $mass\n";
                #return \@sequences;
        }
        
	# PRIV
	sub _ffm {
                my ( $self, $arg_ref ) = @_;
		my $list1  = defined $arg_ref->{list1} ? $arg_ref->{list1} : [];
		my $list2  = defined $arg_ref->{list2} ? $arg_ref->{list2} : [];
		my $type   = defined $arg_ref->{type}  ? $arg_ref->{type}  : '';
		my $linker = defined $arg_ref->{linker} ? $arg_ref->{linker} : $self->get_linker();
		foreach my $frag1 ( @$list1 ) {
			foreach my $frag2 ( @$list2 ) {
				my $fragments = BioX::CLPM::Fragments->new({ type => 'linked' });
				   $fragments->add({ fragment_id_1 => $frag1->get_fragment_id(),
				                     fragment_id_2 => $frag2->get_fragment_id(), 
				                     mass          => $frag1->{mass} + $frag2->{mass} + $linker->get_mass() });
			}
		}
	}
		
	# PRIV
	sub _cleave {
                my ( $self, $arg_ref ) = @_;
		my $sequence        = defined $arg_ref->{sequence}   ? $arg_ref->{sequence}   : '';
		my $enzyme          = defined $arg_ref->{enzyme}   ? $arg_ref->{enzyme}   : $self->get_enzyme();
		my $clvg_position   = $enzyme->get_clvg_position();
		my ( $sgn, @chars ) = split( //, $enzyme->get_rule() );
		my $length          = @chars;
		my $rule            = join( '', @chars );

		my $sequence_str   = $sequence->get_cl_sequence();
		my @sequence_chars = split( //, $sequence_str );
		my $cut            = 0;
		my ( $fragment, @fragments );
		for ( my $i = 0; $i < @sequence_chars; ++$i ){
			my $aa        = $sequence_chars[$i];
			   $cut       = 0;
			   $fragment .= $aa;
			foreach my $clvg_site( $enzyme->clvg_sites() ){
				if ( uc( $aa ) eq $clvg_site ){
					my $next_chars = @sequence_chars[$i+1..$i+$length];
					unless ( uc( $next_chars ) eq $rule ){
						push( @fragments, $fragment );
						$fragment='';
					}
					$cut = 1;
				}
			}
		}
		if ( !$cut ) { push( @fragments, $fragment ); }
                return @fragments;
        }
        
	# PRIV
	sub _missed {
                my ( $self, $arg_ref ) = @_;
		my @fragments   = defined $arg_ref->{fragments} ? @{ $arg_ref->{fragments} } : ();
		my $missed_clvg = defined $arg_ref->{missed_clvg} ? $arg_ref->{missed_clvg} : 0;
		my ( @results, $k );
		for ( my $i = $missed_clvg + 1; $i > 1; $i-- ) {
			for ( my $j = 0; $j < @fragments - $i + 1; $j++ ) {
				my $new_fragment = $fragments[$j];
				for ( $k = 0; $k < $i - 1; $k++ ) {
					$new_fragment .= $fragments[$j+$k+1];
				}		
				while ( $new_fragment =~ m/[a-z]$/ and $i == $missed_clvg + 1){
					if (! $fragments[$j+$k+1] ) { last; }
					$new_fragment .= $fragments[$j+$k+1];
					$k++;	
				}
				push( @results, $new_fragment );
			}
		}
		push( @fragments, @results );
                return @fragments;
        }
        
	# PRIV
	sub _filter {
                my ( $self, $arg_ref ) = @_;
		my @fragments   = defined $arg_ref->{fragments} ? @{ $arg_ref->{fragments} } : ();
		push @fragments, my $final_fragment = pop @fragments;
		my $linker      = defined $arg_ref->{linker} ? $arg_ref->{linker} : $self->get_linker();
		my $index       = defined $arg_ref->{index} ? $arg_ref->{index} : 0;
		my @ends        = $linker->ends();
		my $end         = $ends[$index];
		my @results;

		foreach my $fragment ( @fragments ) {
			if ( $end ) { if ( $self->_has_lc($fragment) ){ if ( $self->_has_uc_last($fragment) or ( $fragment =~ m/$final_fragment$/ ) ) { push @results, $fragment; } } } 
			else        { if ( $self->_has_uc_last($fragment) or ( $fragment =~ m/$final_fragment$/ ) ) { push @results, $fragment; } }
		}
                return @results;
        }
        
	# PRIV
	sub _stat_mod {
                my ( $self, $arg_ref ) = @_;
		my $aa_masses  = defined $arg_ref->{aa_masses} ? $arg_ref->{aa_masses} : $self->load_masses();
		switch( $self->get_stat_mod() ) {
			case 'carbamidomethylated' { $aa_masses->{'C'} = $aa_masses->{'C2'} }
			case 'carboxymethylated'   { $aa_masses->{'C'} = $aa_masses->{'C3'} }
			case 'acrylamid adduct'    { $aa_masses->{'C'} = $aa_masses->{'C4'} }
			case 'oxidized methionine' { $aa_masses->{'M'} = $aa_masses->{'M2'} }
		}
                return $aa_masses;
        }
        
	# PRIV
	sub _has_lc {
                my ( $self, $str ) = @_;
		if ( $str =~m/.*[a-z]+.*/ ) { return 1; } else { return 0; }
        }
        
	# PRIV
	sub _has_uc_last {
                my ( $self, $str ) = @_;
		if( $str =~ m/[A-Z]$/ ) { return 1; } else { return 0; }
        }
        
	# PRIV
	sub _mark_links {
                my ( $self, $arg_ref ) = @_;
		my $sequence     = defined $arg_ref->{sequence}   ? $arg_ref->{sequence}   : $self->get_sequence();
		my $sequence_str = $sequence->get_sequence(); 
		my $end          = defined $arg_ref->{end}   ? $arg_ref->{end}   : $self->get_end();
		my @amino_acids  = split( '', $end );

		foreach my $amino_acid ( @amino_acids ) {
			my $amino_acid_lc = lc($amino_acid);
			   $amino_acid    = uc($amino_acid);
			$sequence_str     =~ s/$amino_acid/$amino_acid_lc/g;
		}
		$sequence->set_cl_sequence( $sequence_str );
                return $sequence;
        }
        
	# UTIL
	sub insert_run {
		my ( $self )    = @_;
		my $enzyme_id   = $self->get_enzyme->get_enzyme_id();
		my $linker_id   = $self->get_linker->get_linker_id();
		my $tolerance   = $self->get_tolerance();
		my $missed_clvg = $self->get_missed_clvg();
		my $stat_mod    = $self->get_stat_mod();
		my $var_mod     = $self->get_var_mod();
		my $sql         = "insert into run_data ( enzyme_id, linker_id, tolerance, missed_clvg, stat_mod, var_mod) values ($enzyme_id, $linker_id, $tolerance, $missed_clvg, '$stat_mod', '$var_mod' )";
		$self->sqlexec( $sql );
                   $sql        = 'select LAST_INSERT_ID()';
                my ( $run_id ) = $self->sqlexec( $sql, '\@@' );
                return $run_id;
        }
        
	# UTIL
	sub db_trunc {
		my ( $self ) = @_;
		warn "ENGINE db_trunc() \n";
		$self->sqlexec("truncate table sequences");
		$self->sqlexec("truncate table fragments");
		$self->sqlexec("truncate table final_fragment_masses");
		$self->sqlexec("truncate table run_data");
		$self->sqlexec("truncate table file_masses");
		$self->sqlexec("truncate table results");
		$self->sqlexec("truncate table precursor_masses");
	}

	# UTIL
	sub get_seq {
		my ( $self, $arg_ref ) = @_;
		my $file = $arg_ref->{file} ? $arg_ref->{file} : ''; 
		my $id   = $arg_ref->{id}   ? $arg_ref->{id}   : 0; 
		my $sequence;
		if ( -e $file ) {
			# Guess file format from extension with read_sequence() 
			my $seq_object = read_sequence( $file );
			   $sequence   = $seq_object->seq();
		} 
		elsif ( $id ) {
			# Get sequence from database
			# TODO
		}
		return $sequence;
	}

#	sub add_sequence {
#		my ( $self, $arg_ref ) = @_;
#		my @sequences = @{$self->get_sequences()};
#		push( @sequences, 
#		      BioX::CLPM::Sequence->new( { sequence     => $arg_ref->{sequence} },
#						 { sequence_id 	=> $arg_ref->{sequence_id} ? $arg_ref->{sequence_id} : (@$sequences + 1) } );
#		$self->set_sequences(\@sequences);
#	}
}

1; # Magic true value required at end of module
__END__

=head1 NAME

BioX::CLPM::Engine - Control object for mass spec peptide analysis projects


=head1 VERSION

This document describes BioX::CLPM::Engine version 0.0.1


=head1 SYNOPSIS

    use BioX::CLPM::Engine;
    
    # Run parameters
    my $file1  = '/home/mihir/clpm_perl/data/test_sequence1.fasta';
    my $file2  = '/home/mihir/clpm_perl/data/bsa_sequence.fasta';
    my $params = { enzyme_id   => 1,
    	       linker_id   => 1,
    	       sequences   => { files => [ $file1, $file2 ] },
    	       tolerance   => '500',
    	       missed_clvg => 3,
    	       stat_mod    => 'carbamidomethylated',
    	       var_mod     => { C => 160.2, M => -90.56 } };
    
    # Create engine
    my $engine = BioX::CLPM::Engine->new( $params );
    
    my @sequences = $engine->sequences();
    foreach my $sequence ( @sequences ) {
    	my @fragments = $sequence->fragments();
    	foreach my $fragment ( @fragments ) {
    		my %counts = %{ $fragment->get_counts() };
    	}
    }
    
    my $mass = $engine->linker()->get_mass();

    my $result = $engine->run();

  
=head1 DESCRIPTION


=head1 INTERFACE 

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
BioX::CLPM::Engine requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-biox-clpm-engine@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Nathan Crabtree, MidSouth Bioinformatics Center  C<< <crabtree@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Nathan Crabtree, MidSouth Bioinformatics Center C<< <crabtree@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
