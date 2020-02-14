package Data::Transmute::Rules::TreeNodeHash::StringifyParent;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-13'; # DATE
our $DIST = 'Data-Transmute-Rules-TreeNodeHash-StringifyParent'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our @RULES = (
    [transmute_nodes => {
        recurse_object => 1,
        rules => [
            [create_hash_key => {
                name => 'parent',
                replace => 1,
                value_code => sub { ref $_[0] ? "$_[0]" : $_[0] },
            }],
        ],
    }],
);

1;
# ABSTRACT: Stringify parent attributes in tree nodes to make the tree more dump-friendly

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Transmute::Rules::TreeNodeHash::StringifyParent - Stringify parent attributes in tree nodes to make the tree more dump-friendly

=head1 VERSION

This document describes version 0.001 of Data::Transmute::Rules::TreeNodeHash::StringifyParent (from Perl distribution Data-Transmute-Rules-TreeNodeHash-StringifyParent), released on 2020-02-13.

=head1 DESCRIPTION

Tree is an interlinked data structure, where a child node links back to its
parent (and the parent links back to *its* parent, and so on). This makes the
dump of a tree structure looks unwieldy; if you dump a node, you will end up
dumping the whole tree.

This rule walks the tree structure and replaces the value of hash key 'parent'
to its stringified value. This will prevent "dumping upwards" and make the
structure more dump-friendly.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Transmute-Rules-TreeNodeHash-StringifyParent>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Transmute-Rules-TreeNodeHash-StringifyParent>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Transmute-Rules-TreeNodeHash-StringifyParent>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Transmute::Rules::TreeNodeHash::StringifyChildren>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
