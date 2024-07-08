# Empty module for test purposes.
#
# This module exists only to trigger the test suite, contain some
# documentation, and be something to distribute.
#
# Copyright 2018-2019, 2024 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

package Empty v2.0.0;

use 5.012;
use warnings;

# Empty function for testing purposes.
sub empty_function {
    return 42;
}

1;
__END__

=for stopwords
Allbery

=head1 NAME

Empty - Empty module for test purposes

=head1 SYNOPSIS

    use Empty;

=head1 DESCRIPTION

An empty module that does nothing, used only for test and example purposes.
It's intended to be just enough of a Perl module to create a distribution.

=head1 FUNCTIONS

=over 4

=item empty_function

Returns 42.

=back

=head1 AUTHOR

Russ Allbery <eagle@eyrie.org>

=cut
