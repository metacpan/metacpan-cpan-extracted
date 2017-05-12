package BioX::SeqUtils::Promoter::SaveTypes::RImage;
####################################################################
#	               Charles Stephen Embry			   #
#	            MidSouth Bioinformatics Center		   #
#	        University of Arkansas Little Rock	           #
####################################################################
use base qw(BioX::SeqUtils::Promoter::SaveTypes::Base);
use Class::Std;
use Class::Std::Utils;
use POSIX qw(ceil);
use warnings;
use strict;
use Carp;
use BioX::SeqUtils::Promoter::Sequences;
use BioX::SeqUtils::Promoter::Sequence;
use BioX::SeqUtils::Promoter::Alignment;
use BioX::SeqUtils::Promoter::Annotations::Consensus;
use BioX::SeqUtils::Promoter::Annotations;

use version; our $VERSION = qv('0.1.1');

{
        my %rcode_of  :ATTR( :get<rcode>   :set<rcode>   :default<''>    :init_arg<rcode> );
        my %width_of  :ATTR( :get<width>   :set<width>   :default<''>    :init_arg<width> );
        my %height_of  :ATTR( :get<height>   :set<height>   :default<''>    :init_arg<height> );
                
        sub BUILD {
                my ($self, $ident, $arg_ref) = @_;
                return;
        }

        sub START {
                my ($self, $ident, $arg_ref) = @_;
       		#every pdf document will have a max of 68 character perline and 58 lines per page 
		my $r_code .= 'x=c(1,68)' . "\n";
		   $r_code .= 'y=c(1,58)' . "\n";
		   #$r_code .= 'y=c(1,25)' . "\n";
		$self->set_rcode($r_code);
                return;
        }


	sub save {
                my ($self, $arg_ref) = @_;
		#sequeces object will the  parameter 
		my $sequences  = defined $arg_ref->{sequences} ?  $arg_ref->{sequences} : '';
		
		my $x_max   = 60;
		#my $y_max   = 25;
		my $y_max   = 58;
		my $image_count = 0;
		print "Save $sequences\n";

		my @sequences = $sequences->get_objects();
		print "@sequences\n";	
		
		#my $test_label = $sequences[0]->get_label();
		#my @sequences = values %$sequences;
		my $r_code = $self->get_rcode();
		my $seqcount = 0;
		my $test_label = $sequences[0]->get_label();
		#my $test_label = get_label($sequence[0]);
		
		#seen how long sequences are
		my $seqlength = $self->length({ string => $sequences[0]->get_sequence( label => $test_label) });
	
		my $max_block = ceil($seqlength/$x_max);
		
		#lots of prints and test for debugging during creation of module
		#print "@sequences\n";
		#print "seqlength is $seqlength\n";
		#my $test = ceil($test_value/$x_max);
		#print "my $max_block = ceil($seqlength/$x_max)\n";
		#my $test_value = 18;
		#print "my $test = ceil($test_value/$x_max)\n";
	
		
		my $number_seq = 0;
		foreach my $seqobjcount (@sequences) {  
		#counts number of sequence objects in the sequences object
		$number_seq++;
		}

		my $slide_count = 0;
		for (my $k = 0; $k < $max_block; $k++){
			$image_count = $k;
			print "block $k\n";
			$r_code .= 'pdf(file = "/home/stephen/BioCapstone/BioX-SeqUtils-Promoter/data/block' . $k . '.pdf",onefile=TRUE,width=8,height=7,pointsize=8)' . "\n";
		   	$r_code .= 'plot(x,y,adj=0,ann=FALSE,bty="n",mai=c(0,0,0,0),oma=c(0,0,0,0),pin=c(7,10),xaxt="n",yaxt="n",xpd=NA,col=c("000000"))' . "\n";
			foreach my $seqobj (@sequences) {  
				my $color_list = $seqobj->get_color_list();	
				my $base_list = $seqobj->get_base_list();
				my $label = $seqobj->get_label();
				#keeps a label and its data on the same line on each document
				my $ucount = $y_max - $seqcount + $slide_count;
				$seqcount++; 
				$r_code .= 'text(3,' . $ucount . ',"' . $label . '",adj=1,col=c("black"))' . "\n";
				#for ( my $i = 5; $i <= $x_max + 4; $i++ ) {
				for ( my $i = 9; $i <= $x_max + 8; $i++ ) {
					my $index = $i - 9 + ($k*$x_max);
					if($index <= $seqlength){
						my $letter = $base_list->[$index] ? $base_list->[$index] : '-';
						#print "$index\n";
						my $color = $color_list->[$index] ?  $color_list->[$index] : 'black';
						# this uses base_list and color_list from sequence objects to give every letter in sequence data a color in the PDF document
						$r_code .= 'text(' . $i . ',' . $ucount  . ',"' . $letter . '",adj=0,col=c("' . $color . '"))' . "\n";
						#print 'text(' . $i . ',' . $seqcount . ',"' . $letter . '",adj=0,col=c("' . $color . '"))' . "\n";
					}

				}

	
			}
				$slide_count = $slide_count + $number_seq;
			#every pdf device in turned off before each new pdf is made. Gets around the pdf device limit in R
			$r_code .= 'dev.off()' . "\n";
		}

		#$r_code .= 'dev.off()' . "\n";
		$self->set_rcode($r_code);	
		open (MYFILE, '>r_code.r');
	        print MYFILE $r_code;
	        close (MYFILE);
		#runs the created R script in command line
		`R CMD BATCH r_code.r r_code.out`;
		for (my $j = 0; $j < $image_count + 1; $j++){
			#creates png files for website
			my $c_image = 'convert /home/stephen/BioCapstone/BioX-SeqUtils-Promoter/data/block' . $j . '.pdf' . ' /home/stephen/BioCapstone/BioX-SeqUtils-Promoter/data/block' . $j . '.png';
			`$c_image`; 
			}

	}

	sub print { my ($self) = @_; print $self->get_rcode(); }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

BioX::SeqUtils::Promoter::SaveTypes::RImage - pdf output file with visually tagged promoter elements via R



=head1 VERSION

This document describes BioX::SeqUtils::Promoter::SaveTypes::RImage version 0.1.1


=head1 SYNOPSIS

    use BioX::SeqUtils::Promoter::SaveTypes::RImage;

    my $obj = BioX::SeqUtils::Promoter::SaveTypes::RImage->new({attribute => 'value'});

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
  
BioX::SeqUtils::Promoter::SaveTypes::RImage requires no configuration files or environment variables.


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
C<bug-biox-sequtils-promoter-savetypes-rimage@rt.cpan.org>, or through the web interface at
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
