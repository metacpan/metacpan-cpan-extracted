# Data::Hopen::Scope::Overrides - Scope that can override each set individually
package Data::Hopen::Scope::Overrides;
use Data::Hopen;
use strict;
use Data::Hopen::Base;

our $VERSION = '0.000018';

# TODO if using exporter
use parent 'Exporter';
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    @EXPORT = qw();
    @EXPORT_OK = qw();
    %EXPORT_TAGS = (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
    );
}

# TODO if a class
use parent 'TODO';
use Class::Tiny qw(TODO);

# Docs {{{1

=head1 NAME

Data::Hopen::Scope::Overrides - Scope that can override each set individually

=head1 SYNOPSIS

TODO Implement me.  (The alternative, until then, is to use a regular
L<Data::Hopen::Scope::Hash> as an override.  However, that only holds
one set, and so does not have any way to say "override 'foo' in set 'bar'".
This package will, once implemented, have that capability.

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
