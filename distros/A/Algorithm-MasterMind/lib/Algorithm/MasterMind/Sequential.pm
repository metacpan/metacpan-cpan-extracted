package Algorithm::MasterMind::Sequential;

use warnings;
use strict;
use Carp;

use lib qw(../../lib);

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/g; 

use base 'Algorithm::MasterMind';

use Algorithm::Combinatorics qw(variations_with_repetition);

sub initialize {
  my $self = shift;
  my $options = shift || croak "Need options here";
  for my $o ( keys %$options ) {
    $self->{"_$o"} = $options->{$o}
  }
  my @alphabet = @{$self->{'_alphabet'}};
  $self->{'_engine'} = variations_with_repetition(\@alphabet, $options->{'length'});
  $self->{'_range'} = $alphabet[0]."-".$alphabet[$#alphabet];
  $self->{'_current_string'} = $alphabet[0] x $self->{'_length'};
  $self->{'_last_string'} = $alphabet[$#alphabet]x $self->{'_length'};

}

sub issue_next {
  my $self = shift;
  my $rules =  $self->number_of_rules();
  my ($match, $string, $combination);

  while ( $combination = $self->{'_engine'}->next ) {
    $string = join("", @$combination);
    $match = $self->matches($string);
    last if $match->{'matches'} == $rules;
  }
  return  $self->{'_last'} = $string;
}

"some blacks, 0 white"; # Magic true value required at end of module

__END__

=head1 NAME

Algorithm::MasterMind::Sequential - Tests each combination in turn.


=head1 SYNOPSIS

    use Algorithm::MasterMind::Sequential;

    my $secret_code = 'ADCB';
    my @alphabet = qw( A B C D E F );
    my $solver = new Algorithm::MasterMind::Sequential { alphabet => \@alphabet,
						       length => length( $secret_code ) };
    

=head1 DESCRIPTION

Test combinations in turn, starting by A x length. Should find the
solution, but complexity increases with size. Not very efficient.

=head1 INTERFACE 

=head2 initialize()

Called from base class, mainly

=head2 new ( $options )

This function, and all the rest, are directly inherited from base

=head2 issue_first ()

Issues the first combination, which might be generated in a particular
way 

=head2 issue_next()

Issues the next combination

=head2 feedback()

Obtain the result to the last combination played

=head2 guesses()

Total number of guesses

=head2 number_of_rules ()

Returns the number of rules in the algorithm

=head2 rules()

Returns the rules (combinations, blacks, whites played so far) y a
reference to array

=head2 matches( $string ) 

Returns a hash with the number of matches, and whether it matches
every rule with the number of blacks and whites it obtains with each
of them

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
