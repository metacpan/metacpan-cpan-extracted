# App::GitFind::Searcher - Search for files in a scope - abstract base class
package App::GitFind::Searcher;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.000002';

use parent 'App::GitFind::Class';
#use Class::Tiny qw(TODO);

use App::GitFind::Base;

# Docs {{{1

=head1 NAME

App::GitFind::Searcher - Search for files in a particular scope

=head1 SYNOPSIS

This is an abstract base class.  Subclasses search for files in
particular scopes.

=cut

# }}}1

=head1 FUNCTIONS

=head2 run

Conducts a search.  Usage:

    $searcher->run(sub { ... });

The only parameter is a callback that will be invoked as:

    $callback->(TODO);

TODO pruning, cancelling?

=cut

sub run {
    my $self = shift or (require Carp, Carp::croak 'Need an instance');
    my $callback = shift or (require Carp, Carp::croak 'Need a callback');
    ...
} #run()

1;
__END__
# vi: set fdm=marker: #
