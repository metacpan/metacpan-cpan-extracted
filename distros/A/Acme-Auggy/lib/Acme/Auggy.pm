use strict;
use warnings;
package Acme::Auggy;

sub say_auggy {
    return "Auggy";
}

sub say_auggy_is {
    my ($is) = @_;

    return say_auggy . ' is ' . $is;
}

1;

# ABSTRACT: Just a module for my talk

__END__

=pod

=head1 NAME

Acme::Auggy - Just a module for my talk

=head1 VERSION

version 0.004

=head1 SYNOPSIS

This module is for demonstration purposes only.

=head1 METHODS

=head2 say_auggy

Just returns my name

=head2 say_auggy_is

Says auggy is something

=head1 AUTHOR

Augustina Ragwitz <auggy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Augustina Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
