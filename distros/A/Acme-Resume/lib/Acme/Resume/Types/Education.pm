use Acme::Resume::Internal;
use strict;
use warnings;

# ABSTRACT: Defines an education
# PODNAME: Acme::Resume::Types::Education
our $VERSION = '0.0103';

class Acme::Resume::Types::Education :rw {

    has school => (
        isa => Str,
        predicate => 1,
    );
    has url => (
        isa => Uri,
        coerce => 1,
        predicate => 1,
    );
    has location => (
        isa => Str,
        predicate => 1,
    );
    has program => (
        isa => Str,
        predicate => 1,
    );
    has started => (
        isa => TimeMoment,
        coerce => 1,
    );
    has left => (
        isa => TimeMoment,
        coerce => 1,
        predicate => 1,
    );
    has current => (
        isa => Bool,
        default => 0,
    );
    has description => (
        isa => Str,
    );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Resume::Types::Education - Defines an education

=head1 VERSION

Version 0.0103, released 2021-05-29.

=head1 SOURCE

L<https://github.com/Csson/p5-Acme-Resume>

=head1 HOMEPAGE

L<https://metacpan.org/release/Acme-Resume>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
