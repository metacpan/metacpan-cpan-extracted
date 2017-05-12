package Bencher::ScenarioUtil::TreeObject;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

our %classes = (
    'Tree::Object::Hash'                 => {backend=>'hash'},
    'Tree::Object::Hash::ChildrenAsList' => {backend=>'hash'},
    'Tree::ObjectXS::Hash'               => {backend=>'hash'},

    'Tree::Object::Array'                => {backend=>'array', use_my_class=>1},
    'Tree::Object::Array::Glob'          => {backend=>'array', use_my_class=>1},
    'Tree::ObjectXS::Array'              => {backend=>'array', use_my_class=>1},

    'Tree::Object::InsideOut'            => {backend=>'insideout'},
);

our @trees_datasets = (
    {
        name => 'tiny1 (3 nodes)',
        summary => 'A tree with height=1 and 2 children per non-leaf nodes, nodes=1 + 2 = 3',
        args => {height=>1, num_children=>2},
    },
    {
        name => 'small1 (31 nodes)',
        summary => 'A tree with height=4 and 2 children per non-leaf nodes, nodes=1 + 2 + 4 + 8 + 16 = 31',
        args => {height=>4, num_children=>2},
    },
    {
        name => 'small2 (364 nodes)',
        summary => 'A tree with height=5 and 3 children per non-leaf nodes, nodes=1 + 3 + 9 + 27 + 81 + 243 = 364',
        args => {height=>5, num_children=>3},
    },
    {
        name => 'small3 (1365 nodes)',
        summary => 'A tree with height=5 and 4 children per non-leaf nodes, nodes=1 + 4 + 16 + 64 + 256 + 1024 = 1365',
        args => {height=>5, num_children=>4},
    },
    {
        name => 'medium1 (19531 nodes)',
        summary => 'A tree with height=6 and 5 children per non-leaf nodes, nodes=1 + 5 + 25 + 125 + 625 + 3125 + 15625 = 19531',
        args => {height=>6, num_children=>5},
    },
);

package # hide from PAUSE
    My::Tree::Object::Array;
use Tree::Object::Array;

package # hide from PAUSE
    My::Tree::Object::Array::Glob;
use Tree::Object::Array::Glob;

package # hide from PAUSE
    My::Tree::ObjectXS::Array;
use Tree::ObjectXS::Array;

1;
# ABSTRACT: Utility routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::ScenarioUtil::TreeObject - Utility routines

=head1 VERSION

This document describes version 0.05 of Bencher::ScenarioUtil::TreeObject (from Perl distribution Bencher-Scenarios-TreeObject), released on 2017-01-25.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-TreeObject>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-TreeObject>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-TreeObject>

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
