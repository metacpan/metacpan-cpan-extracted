package Algorithm::MasterMind::Test_Solver;

use warnings;
use strict;
use Carp;

use lib qw(../../lib ../../../lib);

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/g; 

use base 'Exporter';
use Algorithm::MasterMind qw(check_combination);

use Test::More;

our @EXPORT_OK = qw( solve_mastermind );

sub solve_mastermind {
  my $solver = shift;
  my $secret_code = shift;
  my $length = length( $secret_code );
  my %played;
  my $first_string = $solver->issue_first;
  $played{$first_string} = 1;
  diag( "This might take a while while it finds the code $secret_code" );
  is( length( $first_string), $length, 'Issued first '. $first_string );
  $solver->feedback( check_combination( $secret_code, $first_string) );
  my $played_string = $solver->issue_next;
  my $played = 2;
  while ( $played_string ne $secret_code ) {
      is( $played{ $played_string}, undef, 'Playing '. $played_string ) ;
      $played{$played_string} = 1;
#      my (%combinations, %fitness);
      # map ( $combinations{$_->{'_str'}}++, @{$solver->{'_pop'}});
      # map ( $fitness{$_->{'_str'}} = $_->Fitness(), @{$solver->{'_pop'}});
      # for my $c ( sort {$combinations{$a} <=> $combinations{$b} } keys %combinations ) {
      # 	print "$c =>  $combinations{$c} $fitness{$c}\n" if $combinations{$c}>1 ;
      # }
      $solver->feedback( check_combination( $secret_code, $played_string) );
      $played_string = $solver->issue_next;
      $played ++;
  }
  is( $played_string, $secret_code, "Found code after ".$solver->evaluated()." combinations" );
  return [$solver->evaluated(), $played];
}

"some blacks, all white"; # Magic true value required at end of module

__END__

=head1 NAME

Algorithm::MasterMind::Test_Solver - Utility functions for testing solvers


=head1 SYNOPSIS

    use Algorithm::MasterMind::Test_Solver;

    my $secret_code = 'EAFC';
    my $population_size = 256;
    my $length = length( $secret_code );
    my @alphabet = qw( A B C D E F );
    my $solver = new Algorithm::MasterMind::Canonical_GA { alphabet => \@alphabet,
							length => length( $secret_code ),
							  pop_size => $population_size};

    solve_mastermind( $solver, $secret_code );

  
=head1 DESCRIPTION

Used mainly in the test set, but useful for testing your own algorithms

=head1 INTERFACE 

=head2 solve_mastermind($solver, $secret_code )

Tries to find the secret code via the issued solver, and performs
basic tests on the obtained combinations.

=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
