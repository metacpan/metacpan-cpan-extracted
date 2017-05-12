package Data::LetterTree;

use 5.008007;
use strict;
use warnings;

our $VERSION = '0.1';

require XSLoader;
XSLoader::load('Data::LetterTree', $VERSION);

# Preloaded methods go here.

1;
__END__
=head1 NAME

Data::LetterTree - Native letter tree Perl binding

=head1 SYNOPSIS

    use Data::LetterTree;

    my $tree = Data::LetterTree->new();

    $tree->add_data('foo', 'stuff');
    $tree->add_data('bar', 'more');
    $tree->add_data('bar', 'stuff');

    foreach my $word (qw/foo bar baz/) {
    if ($tree->has_word($word)) {
        print "$word:" . $tree->get_data($word) . "\n";
    } else {
        print "$word: not found\n";
    }

=head1 DESCRIPTION

This module provides perl binding over a native implementation of a letter
tree, allowing to index any kind of perl scalar variable by a large set of
string with a reduced memory footprint over native perl hashes by sharing their
prefixes.

=head1 METHODS

=head2 new()

Creates and returns a new C<Data::LetterTree> object.

=head2 $tree->add_data(I<$word>, I<$data>)

Add I<$word> in the tree, pushing I<$data> in indexed values.

=head2 $tree->has_word(I<$word>)

Return a true value if I<$word> is present in the tree.

=head2 $tree->get_data(I<$word>)

Return all values indexed by I<$word> as a list.

=head1 AUTHOR

Guillaume Rousse, <Guillaume.Rousse@inria.fr>

=head1 ACKNOWLEDGEMENTS

Many thanks to Sebastien Aperghis-Tramoni and Rafaël Garcia-Suarez for helping
me with in my first XS steps...

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 INRIA

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.7 or, at your option,
any later version of Perl 5 you may have available.

=cut
