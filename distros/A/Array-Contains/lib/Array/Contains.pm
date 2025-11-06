package Array::Contains;

use 5.010_001;
use strict;
use warnings;
use mro 'c3';
use English;
our $VERSION = 3.1;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(contains);

BEGIN {
    # Check perl version and decide which version of the function we are going to load.
    my $perlversion = $];
    my $basemodule = 'Array::Contains::Legacy';
    if($perlversion >= 5.042) {
        $basemodule = 'Array::Contains::Any';
    }
    #print STDERR $basemodule, "\n";

    # Import the module. require() uses a filename, not a package name. 
    my $fname = $basemodule . '.pm';
    $fname =~ s/\:\:/\//g;
    require $fname;
    $basemodule->import();

    {
        # make the contains() function in our package point to the _contains function of the sub-package
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        my $funcname = $basemodule . '::_contains';
        *{__PACKAGE__ . "::contains"} = \&$funcname;
    }
};

1;
__END__
=head1 NAME

Array::Contains - Check if an array contains a specific element

=head1 SYNOPSIS

  use Array::Contains;

  if(contains($somevalue, \@myarray)) {
    # Do something
  }

=head1 DESCRIPTION

Array::Contains is a simple replacement for the most commonly used
application of the (deprecated) Smartmatch operator: checking if an
array contains a specific element.

This module is designed for convenience and readable code rather than for
speed.

If you are running a Perl version prior to 5.42.0, this is implemented using a classic for loop.

From 5.42.0 onwards, this uses the new "any" keyword for higher performance. The API is Array::Contains shouldn't look any different to the caller, though. Just, maybe, a tiny bit faster.

=head1 FUNCTIONS

This module currently exports its only function by default:

=head2 contains()

C<contains()> takes one scalar and one array reference and returns true (1) if
the scalar is contained in the array. C<contains()> does NOT do recursive lookups,
but only looks into the root array.

=head1 SEE ALSO

L<List::Util>

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2025 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
