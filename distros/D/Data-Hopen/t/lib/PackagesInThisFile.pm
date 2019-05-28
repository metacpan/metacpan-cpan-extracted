package PackagesInThisFile;
use v5.014;
use strict;
use warnings;

=head1 NAME

PackagesInThisFile - list the top-level packages defined in a file

=head1 SYNOPSIS

    use PackagesInThisFile qw(foo);
    # populates @PIF
    #
When you C<use> this package from a file, the package populates package
variable C<@PIF> with the names of the top-level packages that are defined in
that file and that have a subroutine of the given name.  C<@PIF> is sorted by
line number in the file.

=cut

use Sub::Identify 'get_code_location';

sub import {
    my (undef, $sub_name) = @_;
    my (undef, $caller_filename) = caller;

    # Find all the top-level packages
    my @packages = map { s/::$//r } grep { /^\w+::$/ } keys %::;

    # Find the subroutines in those packages
    my @subs = map
                {
                    no strict 'refs';
                    no warnings 'once';
                    [$_, *{ $_ . '::' . $sub_name }{CODE}]
                }
                @packages;

    # Filter out non-CODE refs --- I was getting some of those early on
    # and I'm not sure why.
    @subs = grep { ref $_->[1] eq 'CODE' } @subs;

    # Get the filenames
    my @locns = sort { $a->[2] <=> $b->[2] }    # line number
                map { [$_->[0], get_code_location($_->[1])] }
                @subs;
    my @pif = map { ($_->[1] eq $caller_filename) ? $_->[0] : () } @locns;

    {
        no strict 'refs';
        *{caller . '::PIF'} = \@pif;
    }
}

1;
