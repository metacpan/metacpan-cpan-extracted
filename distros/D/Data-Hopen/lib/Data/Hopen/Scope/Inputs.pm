# Data::Hopen::Scope::Inputs - Scope that can hold multiple sets of inputs
package Data::Hopen::Scope::Inputs;
use Data::Hopen;
use Data::Hopen::Base;

our $VERSION = '0.000013';

# TODO if a class
use parent 'Data::Hopen::Scope';
use Class::Tiny {
    _sets => sub { +{} },
};

# Docs {{{1

=head1 NAME

Data::Hopen::Scope::Inputs - Scope that can hold multiple sets of inputs

=head1 SYNOPSIS

TODO Implement this.

=head1 ATTRIBUTES

=head2 _sets

Hashref of the input sets.

=cut

# }}}1

=head1 FUNCTIONS

=head2 todo

=cut

sub todo {
    my $self = shift or croak 'Need an instance';
    ...
} #todo()

# TODO if using a custom import()
#sub import {    # {{{1
#} #import()     # }}}1

#1;
__END__
# vi: set fdm=marker: #
