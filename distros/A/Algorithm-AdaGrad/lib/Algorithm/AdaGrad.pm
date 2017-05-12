package Algorithm::AdaGrad;
use 5.012;
use strict;
use warnings;
use XSLoader;

BEGIN{
    our $VERSION = "0.03";
    XSLoader::load __PACKAGE__, $VERSION;
}


1;
__END__

=encoding utf-8

=head1 NAME

Algorithm::AdaGrad - AdaGrad learning algorithm.

=head1 SYNOPSIS

    use Algorithm::AdaGrad;
    
    my $ag = Algorithm::AdaGrad->new(0.1);
    $ag->update([
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 0.0, "B" => 0.0 } },
    ]);
    $ag->update([
        { "label" => -1, "features" => { "R" => 0.0, "G" => 1.0, "B" => 0.0 } },
        { "label" => -1, "features" => { "R" => 0,   "G" => 0,   "B" => 1 } },
        { "label" => -1, "features" => { "R" => 0.0, "G" => 1.0, "B" => 1.0 } },
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 0.0, "B" => 1.0 } },
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 1.0, "B" => 0.0 } }
    ]);
    
    my $result = $ag->classify({ "R" => 1.0, "G" => 1.0, "B" => 0.0 });
    

=head1 DESCRIPTION

Algorithm::AdaGrad is implementation of AdaGrad(Adaptive Gradient) online learning algorithm. 
This module can be use for binary classification.

=head1 METHODS

=head2 new($eta)

Constructor.
C<$eta> is learning ratio.

=head2 update($learning_data)

Executes learning.

C<$learning_data> is ArrayRef like bellow.

    $ag->update([
        { "label" => -1, "features" => { "R" => 0.0, "G" => 1.0, "B" => 0.0 } },
        { "label" => -1, "features" => { "R" => 0,   "G" => 0,   "B" => 1 } },
        { "label" => -1, "features" => { "R" => 0.0, "G" => 1.0, "B" => 1.0 } },
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 0.0, "B" => 1.0 } },
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 1.0, "B" => 0.0 } }
    ]);


C<features> is set of feature-string and value(real number) pair.
C<label> is a expected output label (+1 or -1).

=head2 classify($features)

Executes binary classification. 
Returns 1 or -1.

C<$features> is HashRef like bellow.

    my $result = $ag->classify({ "R" => 1.0, "G" => 1.0, "B" => 0.0 });

=head2 save($filename)

This method dumps the internal data of an object to a file.

=head2 load($filename)

This method restores the internal data of object from dumped file.

=head1 SEE ALSO

John Duchi, Elad Hazan, Yoram Singer. Adaptive Subgradient Methods for Online Learning and Stochastic Optimization L<http://www.magicbroom.info/Papers/DuchiHaSi10.pdf>

=head1 LICENSE

Copyright (C) Hideaki Ohno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55@gmail.comE<gt>

=cut

