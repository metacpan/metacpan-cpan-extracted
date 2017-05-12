
package Subclass_Test::Subclass1;

use vars qw(@ISA);

@ISA = qw(Subclass_Test);

sub set_bam {
    my $self = shift;
    $self->bam('yes');
};

sub set_Type {           # used in 03-no_normalization.t
    my $self = shift;
    $self->Type('yes');
};


1;
