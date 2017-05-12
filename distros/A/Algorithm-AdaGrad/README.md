# NAME

Algorithm::AdaGrad - AdaGrad learning algorithm.

# SYNOPSIS

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
    

# DESCRIPTION

Algorithm::AdaGrad is implementation of AdaGrad(Adaptive Gradient) online learning algorithm. 
This module can be use for binary classification.

# METHODS

## new($eta)

Constructor.
`$eta` is learning ratio.

## update($learning\_data)

Executes learning.

`$learning_data` is ArrayRef like bellow.

    $ag->update([
        { "label" => -1, "features" => { "R" => 0.0, "G" => 1.0, "B" => 0.0 } },
        { "label" => -1, "features" => { "R" => 0,   "G" => 0,   "B" => 1 } },
        { "label" => -1, "features" => { "R" => 0.0, "G" => 1.0, "B" => 1.0 } },
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 0.0, "B" => 1.0 } },
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 1.0, "B" => 0.0 } }
    ]);

`features` is set of feature-string and value(real number) pair.
`label` is a expected output label (+1 or -1).

## classify($features)

Executes binary classification. 
Returns 1 or -1.

`$features` is HashRef like bellow.

    my $result = $ag->classify({ "R" => 1.0, "G" => 1.0, "B" => 0.0 });

## save($filename)

This method dumps the internal data of an object to a file.

## load($filename)

This method restores the internal data of object from dumped file.

# SEE ALSO

John Duchi, Elad Hazan, Yoram Singer. Adaptive Subgradient Methods for Online Learning and Stochastic Optimization [http://www.magicbroom.info/Papers/DuchiHaSi10.pdf](http://www.magicbroom.info/Papers/DuchiHaSi10.pdf)

# LICENSE

Copyright (C) Hideaki Ohno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hideaki Ohno <hide.o.j55@gmail.com>
