package BioX::SeqUtils::Promoter::Alignment;
####################################################################
#	               Charles Stephen Embry			   #
#	            MidSouth Bioinformatics Center		   #
#	        University of Arkansas Little Rock	           #
####################################################################
use base qw(BioX::SeqUtils::Promoter::Base);
use Class::Std;
use Class::Std::Utils;
use BioX::SeqUtils::Promoter::Sequences;
use BioX::SeqUtils::Promoter::Annotations;
use BioX::SeqUtils::Promoter::Annotations::Consensus;
use BioX::SeqUtils::Promoter::SaveTypes;
use warnings;
use strict;
use Carp;
use Bio::Perl;
use Bio::Seq;
use Bio::SeqIO;
use Bio::Tools::Run::Alignment::TCoffee;

use version; our $VERSION = qv('0.1.1');

{
        my %sequences_of  :ATTR( :get<sequences>   :set<sequences>   :default<''>    :init_arg<sequences> );
                
        sub BUILD {
                my ($self, $ident, $arg_ref) = @_;
        
 
                return;
        }

        sub START {
                my ($self, $ident, $arg_ref) = @_;
		my $sequences = BioX::SeqUtils::Promoter::Sequences->new();
		$self->set_sequences($sequences);
                return;
        }

        sub annotate {
                my ($self,  $arg_ref) = @_;
		my $filename = defined $arg_ref->{filename} ?  $arg_ref->{filename} : '';
		my $annotations = BioX::SeqUtils::Promoter::Annotations->new({type => 'Consensus', motifs => $self->get_default_motifs() });
		$annotations->print_motifs();
  
                return;
        }

        sub m_align {
                my ($self,  $arg_ref) = @_;
		#a file of fasta sequences will be a parameter
		my $afilename = defined $arg_ref->{afilename} ?  $arg_ref->{afilename} : '';
		#matrix used multiple alignment, can be Pam, Blosum or none
		my $matrix = defined $arg_ref->{matrix} ?  $arg_ref->{matrix} : '';
		#the pentaly for opening a gap in the alignment
		my $gap_open = defined $arg_ref->{gap_open} ?  $arg_ref->{gap_open} : '';
		#the pentaly for exiting a gap
		my $gap_ext = defined $arg_ref->{gap_ext} ?  $arg_ref->{gap_ext} : '';
		#name and location of output file
 		my $outfile = '/home/stephen/BioCapstone/BioX-SeqUtils-Promoter/data/tnrab1000'; 
		# Build a tcoffee alignment factory
		#my @params = ('ktuple' => 2, 'matrix' => 'BLOSUM', 'OUTFILE' => tnrab1000.aln );
		my @params = ('ktuple' => 2, 'matrix' => $matrix, 'GAPOPEN' => $gap_open, 'GAPEXT' => $gap_ext, 'OUTFILE' => $outfile);
		#my @params = ('ktuple' => 2, 'matrix' => 'Pam', 'GAPOPEN' => 10, 'GAPEXT' => 2, 'OUTFILE' => p_GO10GE2_hexr );
		#my @params = ('ktuple' => 2, 'matrix' => 'BLOSUM', 'OUTFILE' => $outfile);
		# feed a list of parameters to Tcoffee
		my $factory = Bio::Tools::Run::Alignment::TCoffee->new(@params);
		# Pass the factory a list of sequences to be aligned.
		# $aln is a SimpleAlign object.
		my $aln = $factory->align($afilename);
                
		return;
       }

        sub load_alignmentfile {
                my ($self,  $arg_ref) = @_;
		#load a output file from a multiple sequence alignment
		my $filename = defined $arg_ref->{filename} ?  $arg_ref->{filename} : '';
		my $text;
		#my $line;
		my $sequences = $self->get_sequences();

		open(IN,"<$filename");
		
		# takes each gene name and uses it as a key for a hash and the data for teh values
		<IN>;
		while($text = <IN>){
		   	if($text) { 
		   		#if($text =~/^$|^\s/){print "blank line\n"; next;}
		   		if($text =~/^$|^\s/){next;}
				my ($key, $value) = split /\s+/, $text;
				$sequences->add_segment({label => $key, sequence => $value});
			}	 
		}
		my $seqs = $sequences->get_sequences();
		foreach my $key (keys %$seqs ){ print $seqs->{$key}->get_sequence(),"\n"; }

                return;
        }

}

1; # Magic true value required at end of module
__END__

=head1 NAME

BioX::SeqUtils::Promoter::Alignment - gets sequences and performs mulitple alignement 


=head1 VERSION

This document describes BioX::SeqUtils::Promoter::Alignment version 0.1.1


=head1 SYNOPSIS

    use BioX::SeqUtils::Promoter::Alignment;

    my $obj = BioX::SeqUtils::Promoter::Alignment->new({attribute => 'value'});

    print $obj->get_attribute(), "\n";

    $obj->set_attribute('new value');

    print $obj->get_attribute(), "\n";

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


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
  
BioX::SeqUtils::Promoter::Alignment requires no configuration files or environment variables.


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
C<bug-biox-sequtils-promoter-alignment@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Charles Stephen Embry  C<< <cstephene@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Charles Stephen Embry C<< <cstephene@cpan.org> >>. All rights reserved.

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
