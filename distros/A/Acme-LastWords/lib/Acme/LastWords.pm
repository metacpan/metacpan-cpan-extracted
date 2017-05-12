package Acme::LastWords;

our $DATE = '2017-01-07'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

my @words = (
    "Dictionary.", # Joseph Wright
    "Happy.", # Raphael
    "Mozart!", # Gustav Mahler
    "I'm going, but I'm going in the name of the Lord.", # Bessie Smith
    "I'm losing it.", # Frank Sinatra
    "At fifty, everyone has the face he deserves.", # George Orwell
    "A party! Let’s have a party.", # Margaret Sanger
    # TODO: add more
);

sub new {
    my $class = shift;
    bless [$_[0]], $class;
}

sub DESTROY {
    print +(defined $_[0][0] ? $_[0][0] : $words[rand @words]), "\n";
}

1;
# ABSTRACT: Object that prints some famous last words when destroyed

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::LastWords - Object that prints some famous last words when destroyed

=head1 VERSION

This document describes version 0.002 of Acme::LastWords (from Perl distribution Acme-LastWords), released on 2017-01-07.

=head1 SYNOPSIS

 use Acme::LastWords;

 my $obj = Acme::LastWords->new;

 undef $obj; # will print e.g. "Dictionary."

Use your own last words:

 my $obj = Acme::LastWords->new("It's now or never");

=head1 DESCRIPTION

This object is for testing only.

PS: Do you want to know who uttered a particular last words? Use the source.

=for Pod::Coverage ^(new|DESTROY)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-LastWords>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-LastWords>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-LastWords>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
