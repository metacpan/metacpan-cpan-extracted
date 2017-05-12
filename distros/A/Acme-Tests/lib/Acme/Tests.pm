package Acme::Tests;
use v5.8.0;
use Spiffy -Base;
our $VERSION = '0.03';

=head1 NAME

Acme::Tests - How much do you know ?

=head1 SYNOPSIS

  perl Makefile.PL
  make test

=head1 DESCRIPTION

This module is a "test software", it has tests in the software rather
then software tests. Upon installation, you are reqruied to answered
several question, and the installation would be only successful if all
you pass them all.

=head1 HELP

So please help out providing a nice quailty test library!

=head1 COPYRIGHT

Copyright 2005,2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

use List::Util qw(shuffle);

field unanswered => {}, -init => '$self->load_tests()';
field tests => {}, -init => '$self->load_tests()';

sub data {
    my $package = shift || ref($self);
    local $SIG{__WARN__} = sub {};
    local $/;
    eval "package $package; <DATA>";
}

sub load_tests {
    my $lib = $self->data;
    my $tests = {};
    for(split(/\n----\n/,$lib)) {
        s/^\s+//; s/\s+$//s;
        next unless $_;
        my ($q,$a) = $_ =~ /(.+?)\n+Ans:\s*(.+?)\n*/s;
        next unless $q && $a;
        $tests->{$q} = lc($a);
    }
    $self->tests($tests);
    $self->unanswered([shuffle (keys %$tests)]);
}

sub next_question {
    my $una = $self->unanswered;
    my $q = shift @$una;
    $self->unanswered($una);
    return $q;
}

sub is_correct {
    my ($q,$a) = @_;
    $a =~ s/^\s+//gs;
    $a =~ s/\s+$//gs;
    return ($self->tests->{$q} eq lc($a))
}

__DATA__
Who Invents Perl ?
  (1) Larry Nelson
  (2) Larry Wall
  (3) Larry King
  (4) Some guy with "Perl" in his name
Ans: 2
----
2 + 2 = ?
Ans: 4
----
Who writes Acme.pm ?
  (1) acme
  (2) spoon
  (3) ingy
  (4) all of them
Ans: 3
----
Who plays on slashdot.org ?
  (1) Cowboy Neal
  (1) Cowboy Neal
  (1) Cowboy Neal
  (1) Cowboy Neal
Ans: 1
----
