package Code::Embeddable;

our $DATE = '2015-06-18'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

# BEGIN_BLOCK: import
sub import {
    no strict 'refs';
    my $pkg = shift;
    my $caller = caller;
    my @imp = @_ ? @_ : @{__PACKAGE__.'::EXPORT'};
    for my $imp (@imp) {
        if (grep {$_ eq $imp} (@{__PACKAGE__.'::EXPORT'},
                               @{__PACKAGE__.'::EXPORT_OK'})) {
            *{"$caller\::$imp"} = \&{$imp};
        } else {
            die "$imp is not exported by ".__PACKAGE__;
        }
    }
}
# END_BLOCK: import

# BEGIN_BLOCK: pick
sub pick {
    return undef unless @_;
    return $_[@_*rand];
}
# END_BLOCK: pick

# BEGIN_BLOCK: pick_n
sub pick_n {
    my $n = shift;
    my @res;
    while (1) {
        last if @res >= $n;
        last unless @_;
        push @res, splice(@_, @_*rand(), 1);
    }
    @res;
}
# END_BLOCK: pick_n

# BEGIN_BLOCK: shuffle
sub shuffle {
    my @res;
    while (1) {
        last unless @_;
        push @res, splice(@_, @_*rand(), 1);
    }
    @res;
}
# END_BLOCK: shuffle

# copy-pasted from List::MoreUtils
# BEGIN_BLOCK: uniq
sub uniq (@) {
    my %seen = ();
    my $k;
    my $seen_undef;
    grep { defined $_ ? not $seen{ $k = $_ }++ : not $seen_undef++ } @_;
}
# END_BLOCK: uniq

1;
# ABSTRACT: Collection of routines that can be embedded e.g. using Dist::Zilla plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Embeddable - Collection of routines that can be embedded e.g. using Dist::Zilla plugin

=head1 VERSION

This document describes version 0.05 of Code::Embeddable (from Perl distribution Code-Embeddable), released on 2015-06-18.

=head1 SYNOPSIS

In F<dist.ini>:

 [InsertBlock::FromModule]

In F<lib/Your/Module.pm> (that wants to embed one or more routines):

 # INSERT_BLOCK: Code::Embeddable import
 # INSERT_BLOCK: Code::Embeddable another_func

=head1 DESCRIPTION

This module is a collection of functions that can be embedded into another
file's source code, e.g. using L<Dist::Zilla::Plugin::InsertBlock::FromModule>
(if you're using L<Dist::Zilla> to build your dists).

The functions put here are usually routines that are small, independent, and
stable (doesn't change that much). Instead of require-ing a module that contains
these routines, a client code can opt to embed them directly in its file
instead. The advantage is less dependencies (no other module to depend on) and
slightly smaller startup overhead. Compared to manual "copy-pasting" of code,
embedding using Dist::Zilla::Plugin::InsertBlock::FromModule is more
maintainable.

=head1 FUNCTIONS

=head2 import

A lightweight L<Exporter>-style exporter. Supports C<@EXPORT> and C<@EXPORT_OK>.
No support for tags.

=head2 pick(@list) => $item

Pick a random item from a list. Will return undef if C<@ary> is empty.

=head2 pick_n($n, @list) => @items

Pick C<$n> items from a list.

=head2 shuffle(@list) => @shuffled

Just like C<List::Util>'s C<shuffle>, except implemented in pure Perl and you
don't have to load the module.

=head2 uniq(@list) => @unique

Just like C<List::MoreUtils>'s C<uniq>, except implemented in pure Perl and you
don't have to load the module.

=head1 ROUTINES

These embeddable pieces of code are not function declaration:

=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertBlock::FromModule>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Code-Embeddable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Code-Embeddable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Code-Embeddable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
