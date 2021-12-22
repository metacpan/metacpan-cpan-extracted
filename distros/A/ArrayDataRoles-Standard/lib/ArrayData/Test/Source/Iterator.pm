package ArrayData::Test::Source::Iterator;

use strict;
use 5.010001;
use strict;
use warnings;
use Role::Tiny::With;
with 'ArrayDataRole::Source::Iterator';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-01'; # DATE
our $DIST = 'ArrayDataRoles-Standard'; # DIST
our $VERSION = '0.007'; # VERSION

sub new {
    my ($class, %args) = @_;
    $args{num_elems} //= 10;
    $args{random}    //= 0;

    $class->_new(
        gen_iterator => sub {
            my $i = 0;
            sub {
                $i++;
                return undef if $i > $args{num_elems}; ## no critic: Subroutines::ProhibitExplicitReturnUndef
                return $args{random} ? int(rand()*$args{num_elems} + 1) : $i;
            };
        },
    );
}

1;
# ABSTRACT: A test ArrayData module

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayData::Test::Source::Iterator - A test ArrayData module

=head1 VERSION

This document describes version 0.007 of ArrayData::Test::Source::Iterator (from Perl distribution ArrayDataRoles-Standard), released on 2021-12-01.

=head1 SYNOPSIS

 use ArrayData::Test::Source::Iterator;

 my $ary = ArrayData::Test::Soure::Iterator->new(
     # num_rows => 100,   # default is 10
     # random => 1,       # if set to true, will return elements in a random order
 );

=head1 DESCRIPTION

=head2 new

Create object.

Usage:

 my $ary = ArrayData::Test::Source::Iterator->new(%args);

Known arguments:

=over

=item * num_elems

Positive int. Default is 10.

=item * random

Bool. Default is 0.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayDataRoles-Standard>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ArrayDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
