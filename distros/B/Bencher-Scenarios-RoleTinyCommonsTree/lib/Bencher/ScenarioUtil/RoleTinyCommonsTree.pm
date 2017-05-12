package Bencher::ScenarioUtil::RoleTinyCommonsTree;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

use strict;
use warnings;

use Data::Random::Tree qw(create_random_tree);
use Tree::Object::Hash;

use Exporter qw(import);
our @EXPORT_OK = qw($tree_h3_o15 $tree_h4_o100 $tree_h6_o1k $tree_h7_o20k);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# an example of a tiny tree
our $tree_h3_o15 = create_random_tree(
    num_objects_per_level => [2, 4, 8],
    classes => ['Tree::Object::Hash'],
);

# an example of a small tree
our $tree_h4_o100 = create_random_tree(
    num_objects_per_level => [4, 16, 64, 15],
    classes => ['Tree::Object::Hash'],
);

# an example of a small tree
our $tree_h6_o1k = create_random_tree(
    num_objects_per_level => [10, 100, 600, 200, 99],
    classes => ['Tree::Object::Hash'],
);

# this is a tree of height 7, ~20k objects. this is on par with my current
# todo.org (~750kB) which contains ~2900 todo items and ~20k Org::Element
# objects when parsed with Org::Parser.
our $tree_h7_o20k = create_random_tree(
    num_objects_per_level => [100, 3000, 5000, 8000, 3000, 1000, 300],
    classes => ['Tree::Object::Hash'],
);

1;
# ABSTRACT: Utility routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::ScenarioUtil::RoleTinyCommonsTree - Utility routines

=head1 VERSION

This document describes version 0.04 of Bencher::ScenarioUtil::RoleTinyCommonsTree (from Perl distribution Bencher-Scenarios-RoleTinyCommonsTree), released on 2017-01-25.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-RoleTinyCommonsTree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-RoleTinyCommonsTree>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-RoleTinyCommonsTree>

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
