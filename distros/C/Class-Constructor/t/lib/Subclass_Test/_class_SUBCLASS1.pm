
package Subclass_Test::_class_SUBCLASS1;

use vars qw(@ISA);

@ISA = qw(Subclass_Test);

sub set_bam {
    my $self = shift;
    $self->_method_BAM('yes');
};



1;
