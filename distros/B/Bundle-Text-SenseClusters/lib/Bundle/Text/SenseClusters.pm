package Bundle::Text::SenseClusters;

$VERSION = '1.05';

1;
__END__

=head1 NAME

Bundle::Text::SenseClusters - Bundle to install Text::SenseClusters and 
all of its dependent CPAN modules.

=head1 SYNOPSIS

To install L<Text::SenseClusters> and all dependent CPAN modules 
automatically, just run the following: 

 C<perl -MCPAN -e 'install Bundle::Text::SenseClusters'>

To manually install this module type the following: 

 perl Makefile.PL
 make
 make test
 make install 

=head1 DESCRIPTION

This bundle includes the core SenseClusters distribution, as well as all 
required CPAN modules. The core SenseClusters distribution consists of 
numerous Perl programs (found in the /Toolkit directory), plus SVDPACKC, 
a 3rd party C package that performs Singular Value Decomposition. 

In addition to this Bundle, you must also download and install the  
clustering toolkit Cluto, in order to make SenseClusters operational. 
There is a script called C<install.sh> in SenseClusters /External 
directory that will automatically download and install Cluto, and it 
will also compile and install SVDPACKC. 

Thus, you should be able to install SenseClusters by simply installing 
this Bundle and then going to SenseClusters/External directory and  
running the C<install.sh> script. 

=head1 CONTENTS

Carp::Clan                      	6.04     

Bit::Vector                     	7.4      

PDL                            		2.013  

Set::Scalar                    		1.29   

Algorithm::Munkres             		0.08   

Algorithm::RandomMatrixGeneration       0.06 

Math::SparseMatrix             		0.03   

Math::SparseVector            	 	0.04      

Text::NSP                      		1.31    

Text::SenseClusters                     1.05

=head1 SEE ALSO

 L<http://senseclusters.sourceforge.net>

=head1 AUTHOR

 Ted Pedersen, E<lt>tpederse at d.umn.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008,2015 by Ted Pedersen

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, 
USA.

=cut
