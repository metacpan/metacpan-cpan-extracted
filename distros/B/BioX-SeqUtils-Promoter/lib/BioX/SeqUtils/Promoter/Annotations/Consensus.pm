package BioX::SeqUtils::Promoter::Annotations::Consensus;
####################################################################
#	               Charles Stephen Embry			   #
#	            MidSouth Bioinformatics Center		   #
#	        University of Arkansas Little Rock	           #
####################################################################
use base qw(BioX::SeqUtils::Promoter::Annotations::Base);
use Class::Std;
use Class::Std::Utils;

use BioX::SeqUtils::Promoter::Sequence;
use BioX::SeqUtils::Promoter::Sequences;
use DBIx::MySperql qw(DBConnect SQLExec $dbh);
use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.1.1');

{
        my %motifs_of  :ATTR( :get<motifs>   :set<motifs>   :default<[]>    :init_arg<motifs> );
                
        sub BUILD {
                my ($self, $ident, $arg_ref) = @_;
        
                return;
        }

        sub START {
                my ($self, $ident, $arg_ref) = @_;

                return;
        }
        sub print_motifs {
                my ($self, $arg_ref) = @_;
		my $motifs = $self->get_motifs();
		print join(', ', @$motifs ), "\n";
                return;
        }
	
	sub set_reg {
		my ($self, $arg_ref) = @_;
		#takes a Sequences object as a parameter
		my $bases = defined $arg_ref->{bases} ?  $arg_ref->{bases} : '';
		my $num = 0;	
		my $database = 'stephen';
		my $host     = 'localhost';
		my $user     = 'root';
		my $pass     = '2020.mbc';
		my @sequences = $bases->get_objects();
		my $id_seq;

		foreach my $seqobj(@sequences) {
		
			my $DNA = $seqobj->get_sequence();
			my $test     = $DNA;
			my $label = $sequences[$num]->get_label();
			#print "$label\n";
			my $seqlength = $self->length({ string => $sequences[$num]->get_sequence( label => $label) });
			#print "$seqlength\n";		
			$num++;
		
			#my $colors = $seqobj->get_color_list();
			my $colors;

			#print "$colors->[0]\n";
			
			#my $base = $seqobj->get_base_list();
			my $base;

			#create a default list of colors the correct length and a list of ascending numberical value
			for(my $k =0; $k <= $seqlength; $k++){
				$base->[$k] = $k;	
				$colors->[$k] = 'black';	
			}
			
			
			$id_seq .= "$label\n";	

			#connect to MySql database
			$dbh = DBConnect(database => $database, host => $host, user => $user, pass => $pass);

			my $sql = "select consensus_id, consensus_name, motif, length, color from consensus";
			my $rowsref = SQLExec( $sql, '\@@' );
			foreach my $rowref ( @$rowsref ) {
				my ( $id, $name, $motif, $length, $color ) = @$rowref;
				my $pattern = "(.*)($motif)";
				my $position;
				my $first = 1;
				#match database sequences against user data
				while ( $test =~ m/(.*?)$motif/g ) {
					if ( $first ) {
						 $position = scalar( split( '', $1 ) ) + 1;
					} else {
						 $position += scalar( split( '', $1 ) ) + $length;
					}
		
					#print "$id, $name, $motif, $position, $length, $color \n";
					$id_seq .= "$id, $name, $motif, $position, $length, $color \n";
					$first = 0;
					for (my $i = 0 ; $i <= $length - 1; $i++ ) {
						
						$colors->[$position -1 + $i] = $color;
					}
				#print "test space\n";
				#$bases->set_color({bases => $base, colors => $colors, label => $label});

				}
		
			}
		
				$bases->set_color({bases => $base, colors => $colors, label => $label});
		}
		
		open (MYFILE, '>out_consensus');
		#write a file that list in which sequence object matches where found
	        print MYFILE $id_seq;
	        close (MYFILE);

		return;
        }

}

1; # Magic true value required at end of module
__END__

=head1 NAME

BioX::SeqUtils::Promoter::Annotations::Consensus - identification core promoter elements via consensus sequences 


=head1 VERSION

This document describes BioX::SeqUtils::Promoter::Annotations::Consensus version 0.1.1


=head1 SYNOPSIS

    use BioX::SeqUtils::Promoter::Annotations::Consensus;

    my $obj = BioX::SeqUtils::Promoter::Annotations::Consensus->new({attribute => 'value'});

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
  
BioX::SeqUtils::Promoter::Annotations::Consensus requires no configuration files or environment variables.


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
C<bug-biox-sequtils-promoter-annotations-consensus@rt.cpan.org>, or through the web interface at
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
