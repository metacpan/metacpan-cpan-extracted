package StringEvolver;
use strict;
use Algorithm::Evolve::Util ':str';
our $VERSION = '0.03';

our %configs;

sub import {
    my $class = shift;
    
    %configs = (
        gene_length    => 20,
        alphabet       => [0,1],
        reference_gene => '1' x 20,
        mutation_rate  => 0.05,
        crossover_pts  => 2,
        @_
    );
}

sub new {
    my $pkg = shift;
    my $string = shift
        || str_random($configs{gene_length}, $configs{alphabet});
    return bless { _gene => $string }, $pkg;
}

sub crossover {
    my ($pkg, $s1, $s2) = @_;
    return map { $pkg->new($_) } 
           str_crossover($s1->gene, $s2->gene, $configs{crossover_pts});
}

sub fitness {
    my $self = shift;
    return str_agreement($configs{reference_gene}, $self->gene);
}

sub mutate {
    my $self = shift;
    $self->gene(
        str_mutate($self->gene, $configs{mutation_rate}, $configs{alphabet})
    );
}

sub gene {
    my $self = shift;
    $self->{_gene} = shift if @_;
    return $self->{_gene};
}

1;
__END__

=head1 NAME

StringEvolver - A generic base critter class for use with Algorithm::Evolve

=head1 SYNOPSIS

  package StringCritters;
  use StringEvolver gene_length => 50,
                    alphabet => ['A' .. 'F'],
                    ...;
  our @ISA = ('StringEvolver');
  ## StringCritters is now a valid critter class

  sub foo_method {
      my $self = shift;
      $self->{foo}++;   ## You can add object attributes
  }
  
  sub fitness {
      my $self = shift;

      ## You can override the default inherited methods to suit the
      ## task at hand
  }

You can use this class as a base class any time your representation is a
string gene.

=head1 USE ARGUMENTS

=over

=item gene_length

The length of strings to evolve. Defaults to 20.

=item alphabet

A reference to an array of valid tokens for the genes. All elements of the
array should be single characters. Defaults to [0,1].

=item reference_gene

By default, fitness is measured as the number of characters in which a
critter's gene agrees with a reference string. However, if you are 
implementing a non-trivial evolver, you will probably override the fitness
method and this argument won't make a difference. It defaults to
C<'1' x 20>.

=item mutation_rate

If this number is less than one, then it is the probablistic mutation rate
for each character. If it is greater than or equal to one, then exactly that
many mutations will be performed per child (so it must be an integer).
Defaults to 0.05. 

=item crossover_pts

The number of crossover points when performing crossover. See
L<Algorithm::Evolve::Util|Algorithm::Evolve::Util> for more information on
crossover.

=back

=head1 INHERITED METHODS

When used as a base class, the subclass inherits the following methods:

=over

=item C<< Class->new([ $init ]) >>

When used with an argument, the new critter is created with the given
string as the initial value for its gene. Otherwise, this method
creates a random string gene over the alphabet.

=item C<< $obj->mutate() >>

Mutates the critter's gene according to the given mutation rate.

=item C<< Class->crossover($obj1, $obj2) >>

Takes two critters and returns a random crossover of the two,
according to the given number of crossover points.

=item C<< $obj->fitness() >>

Returns the fitness of the critter, measured as the number of characters
which agree with a reference string. You will probably override this method.

=item C<< $obj->gene([ $new_gene ]) >>

Returns or sets the value of the critter's string gene.

=back

=head1 SEE ALSO

L<Algorithm::Evolve|Algorithm::Evolve>, 
L<Algorithm::Evolve::Util|Algorithm::Evolve::Util>, the rest of the
F<examples/> directory.

=head1 AUTHOR

Algorithm::Evolve is written by Mike Rosulek E<lt>mike@mikero.comE<gt>. Feel 
free to contact me with comments, questions, patches, or whatever.

=head1 COPYRIGHT

Copyright (c) 2003 Mike Rosulek. All rights reserved. This module is free 
software; you can redistribute it and/or modify it under the same terms as Perl 
itself.
