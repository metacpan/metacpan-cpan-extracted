use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

parse

=usage

  # given $cli

  $cli->parse($data, $specs, $meta);

=description

The parse method parses command-line options using L<Getopt::Long> and does not
mutate C<@ARGV>. The first argument should be an arrayref containing the data
to be parsed; E.g. C<[@ARGV]>. The second argument should be an arrayref of
Getopt::Long option specifications. The third argument (optionally) should be
additional options to be passed along to
L<Getopt::Long::Configure|Getopt::Long/Configuring-Getopt::Long>.

=signature

parse(ArrayRef $arg1, ArrayRef $arg2, ArrayRef $arg3) : HashRef

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok 'Data::Object::Cli', 'parse';

ok 1 and done_testing;
