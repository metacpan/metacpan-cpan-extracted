package Algorithm::Evolutionary::Op::Population_Output;

use lib qw( ../../../../../../Algorithm-Evolutionary/lib ../Algorithm-Evolutionary/lib ); #For development and perl syntax mode

use warnings;
use strict;
use Carp;

our $VERSION =   sprintf "%d.%03d", q$Revision: 3.1 $ =~ /(\d+)\.(\d+)/g; 

use base 'Algorithm::Evolutionary::Op::Base';

sub new {
  my $class = shift;
  my $hash = { printer => shift || 
		   sub { my $member = shift; 
			 print $member->as_string, "\n"; } 
  };
  my $self = Algorithm::Evolutionary::Op::Base::new( __PACKAGE__, 1, $hash );
  return $self;
}

sub apply {
    my $self = shift;
    my $population_hashref=shift;
    for my $p (@$population_hashref) {
	$self->{'_printer'}->($p);
    }
}

"No man is an island" ; # Magic true value required at end of module
__END__

=head1 NAME

Algorithm::Evolutionary::Op::Population_Output - Flexible population printing class


=head1 SYNOPSIS

  my $pp = new Algorithm::Evolutionary::Op::Population_Output; 

  my @pop;
  for ( 1..10 ) {
    my $indi= new Algorithm::Evolutionary::Individual::String [0,1], 8;
    push @pop, $indi;
  }

  $pp->apply( \@pop );

  $pp = new Algorithm::Evolutionary::Op::Population_Output sub { my $member = shift; 
							      print $member->as_yaml, "\n"; } ; 

  $pp->apply( \@pop );

=head1 DESCRIPTION

Configurable population printing class

=head1 INTERFACE 

=head2 new( [$printer] )

C<$printer> is a closure or reference to function that receives as
input a single population member. By default, calls C<as_string> on
each member of the array hash followed by a carriage return.

=head2 apply( $population_hashref )

Applies the single-member printing function to every population member

=head1 DEPENDENCIES

Main dependence is L<Algorithm::Evolutionary>; however, it's not
included by default, since you must pick and choose the modules you
are going to actually use.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-poe-component-algorithm-evolutionary@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

  CVS Info: $Date: 2009/09/13 12:49:04 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Population_Output.pm,v 3.1 2009/09/13 12:49:04 jmerelo Exp $ 
  $Author: jmerelo $ 

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
