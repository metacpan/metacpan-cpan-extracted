package Algorithm::MasterMind::Secret;

use warnings;
use strict;
use Carp;

# Module implementation here

sub new {

  my $class = shift;
  my $string = shift || croak "No default string\n";

  my $self =  { _string => $string,
		_chars => [],
		_hash => {}};
  while ( my $c = chop( $string ) ) {
    push @{$self->{'_chars'}}, $c;
    $self->{'_hash'}{ $c }++;
  }
  @{$self->{'_alphabet'}} = keys %{$self->{'_hash'}};
  bless $self, $class;
  return $self;
}

sub string {
  return shift->{'_string'};
}

sub check {
  my %hash_secret = %{$_[0]->{'_hash'}};
  my %hash_string ;
  my $blacks = 0;
  my $string = $_[1];
  my ($c, $s);
  for my $c (@{$_[0]->{'_chars'}} ) {
    $s = chop( $string );
    if ( $c ne $s ) {
      $hash_string{ $s }++;
    } else {
      $blacks++;
      $hash_secret{ $c }--;      
    }
  }
  my $whites = 0;
  map( exists $hash_string{$_} 
       &&  ( $whites += ($hash_secret{$_} > $hash_string{$_})
	     ?$hash_string{$_}
	     :$hash_secret{$_} ), @{$_[0]->{'_alphabet'}}  );

  return{ blacks => $blacks,
	  whites => $whites } ;
}

sub check_secret  {
  my %hash_secret = %{$_[0]->{'_hash'}};
  my %hash_other_secret =  %{$_[1]->{'_hash'}};
#  my $blacks = 0;
  my $s;
  my $string = $_[1]->{'_string'};
  map(  ($s = chop( $string ) ) 
	&& ( $s eq $_ ) 
	&& (  $_[2]->{'blacks'}++,
	      $hash_secret{ $s }--,
	      $hash_other_secret{ $s }-- ), @{$_[0]->{'_chars'}});

  my $whites = 0;
  map( exists $hash_other_secret{$_} 
       &&  ( $_[2]->{'whites'} += ($hash_secret{$_} > $hash_other_secret{$_})
	     ?$hash_other_secret{$_}
	     :$hash_secret{$_} ), @{$_[0]->{'_alphabet'}}  );
  return;
}
"Can't tell"; # Magic true value required at end of module

__END__

=head1 NAME

Algorithm::MasterMind::Secret - Minimal framework for MM secrets


=head1 SYNOPSIS

    use Algorithm::MasterMind::Secret;

    my $sikrit = new Algorithm::MasterMind::Secret 'ABCD';

    my $blacks_whites = $sikrit->check('BBBB'}

=head1 DESCRIPTION

Basically a string and a hash, caches the string in a hash so that it
is faster to check against it in mastermind. This class is heavily
optimized for speed, which might result in some inconvenients. 

=head1 INTERFACE 

=head2 new ( $string )

A string in an arbitrary alphabet, but should be the same as the ones
you will use to solve

=head2 check( $string )

Checks a combination against the secret code, returning a hashref with
the number of blacks (correct in position) and whites (correct in
color, not position). The string must be a variable. So don't count on the
variable after the call. 

=head2 check_secret( $secret )

Same as above, but the argument must be a L<Algorithm::Mastermind::Secret>. 

=head2 string()

Returns the string corresponding to this secret.

=head1 CONFIGURATION AND ENVIRONMENT

Algorithm::MasterMind requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Algorithm::Evolutionary>, but only for one of the
strategies. L<Algorithm::Combinatorics>, used to generate combinations
and for exhaustive search strategies. 


=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-algorithm-mastermind@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

Other modules in CPAN which you might find more useful than this one
are at L<Games::Mastermind::Solver>, which I didn't use and extend for
no reason, although I should. Also L<Games::Mastermind::Cracker>

You can try and play this game at
http://geneura.ugr.es/~jmerelo/GenMM/mm-eda.cgi, restricted to 4 pegs
and 6 colors. The program C<mm-eda.cgi> should also be available in
the C<apps> directory of this distribution.

The development of this projects is hosted at sourceforge,
https://sourceforge.net/projects/opeal/develop, check it out for the
    latest bleeding edge release. 

If you use any of these modules for your own research, we would very
grateful if you would reference the papers that describe this, such as
this one:

 @article{merelo2010finding,
  title={{Finding Better Solutions to the Mastermind Puzzle Using Evolutionary Algorithms}},
  author={Merelo-Guerv{\'o}s, J. and Runarsson, T.},
  journal={Applications of Evolutionary Computation},
  pages={121--130},
  year={2010},
  publisher={Springer}
 }


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
