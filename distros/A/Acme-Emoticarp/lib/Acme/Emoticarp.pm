## no critic (RequireUseStrict)
package Acme::Emoticarp;
{
  $Acme::Emoticarp::VERSION = '0.02';
}

## use critic (RequireUseStrict)
use strict;
use warnings;
use parent 'Exporter';
use utf8;

use Carp ();

our @EXPORT = ('o_O', 'ಠ_ಠ');

*o_O     = \&Carp::croak;
do {
    no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
    # use a symbolic reference to keep PPI happy
    *{'ಠ_ಠ'} = \&Carp::cluck;
};

sub import {
    my ( $class, @arguments ) = @_;

    $^H |= $utf8::hint_bits; ## no critic (Bangs::ProhibitBitwiseOperators)
    $class->export_to_level(1, @_);
}

1;



=pod

=encoding utf-8

=head1 NAME

Acme::Emoticarp - Carp and cluck in a more fun way.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Acme::Emoticarp; # also uses 'use utf8'

  ಠ_ಠ 'No user for this session!' unless defined $user;

  o_O 'No arguments provided.' unless @ARGV;

=head1 DESCRIPTION

This module exports aliases for L<Carp/cluck> and L<Carp/croak>
that are more amusing to use.  Because some emoticons use UTF-8
names, L<utf8> is automatically turned on in the importing environment.

=head1 FUNCTIONS

=head2 o_O

An alias for L<Carp/croak>.

=head2 ಠ_ಠ 

An alias for L<Carp/cluck>.

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hoelzro/acme-emoticarp/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut


__END__

# ABSTRACT: Carp and cluck in a more fun way.

