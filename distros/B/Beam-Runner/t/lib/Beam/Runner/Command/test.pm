package Beam::Runner::Command::test;
# ABSTRACT: A test command for test purposes

use strict;
use warnings;
use Moo;

our $got_args = [];

=method run

Run the test command for test purposes, setting arguments to the
C<got_args> package variable and returning the exit code C<0>.

=cut

sub run {
    my ( $self, @args ) = @_;
    $got_args = \@args;
    return 0;
}

1;
