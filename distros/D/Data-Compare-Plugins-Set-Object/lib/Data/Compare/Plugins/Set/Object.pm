package Data::Compare::Plugins::Set::Object;

use 5.008;
use strict;
use warnings;
use version 0.77; our $VERSION = qv('v1.0');
use English qw(-no_match_vars);
use Data::Compare 0.06;
use List::Util qw(first);

sub _register {
    return [ 'Set::Object', \&_so_set_compare ];
}

sub _so_set_compare {
    my @sets = splice @ARG, 0, 2;

    # quick optimizations if sets aren't of equal size or are directly equal
    return 0 if $sets[0]->size() != $sets[1]->size();
    return 1 if $sets[0]         == $sets[1];

    # loop over each of the first set's elements
    # looking for a match in the second set
    for my $element ( $sets[0]->elements() ) {
        my $matched_element =
            first { Data::Compare::Compare( $element, $ARG ) }
            grep  { ref eq ref $element } $sets[1]->elements();

        # return false if not found
        return 0 if not defined $matched_element;

        # otherwise remove from copy of second set and keep going
        $sets[1]->remove($matched_element);
    }

    # sets are equal only if we've exhausted the second set
    return $sets[1]->is_null();
}

# Data::Compare::Plugins interface requires modules to return an arrayref
## no critic (RequireEndWithOne)
_register();

__END__

=head1 NAME

Data::Compare::Plugins::Set::Object - plugin for Data::Compare to handle Set::Object objects

=head1 VERSION

This document describes Data::Compare::Plugins::Set::Object version 1.0

=head1 SYNOPSIS

    use Set::Object 'set';
    use Data::Compare;

    my $foo = {
        list => [ qw(one two three) ],
        set  => set( [1], [2], [3] ),
    };
    my $bar = {
        list => [ qw(one two three) ],
        set  => set( [1], [2], [3] ),
    };

    say 'Sets in $foo and $bar are ',
        $foo->{set} == $bar->{set} ? '' : 'NOT ', 'identical.';
    say 'Data within $foo and $bar are ',
        Compare($foo, $bar) ? '' : 'NOT ', 'equal.';

=head1 DESCRIPTION

Enables L<Data::Compare> to Do The Right Thing for L<Set::Object> objects.
Set::Object already has an C<equals()> method, but it only returns true if
objects within two sets are exactly equal (i.e. have the same references,
referring to the same object instance).  When using Data::Compare in
conjuction with this plugin, objects in sets are considered the same if their
B<contents> are the same.  This extends down to sets that contain arrays,
hashes, or other objects supported by Data::Compare plugins.

=head1 SUBROUTINES/METHODS

As a plugin to Data::Compare, the interface is the same as Data::Compare
itself: pass the reference to two data structures to the C<Compare> function,
which for historical reasons is exported by default.

Set::Object also can export certain functions, and overloads comparison
operators pertaining to sets.  Consult the
L<Set::Object documentation|Set::Object> for more information.

=head1 DIAGNOSTICS

See the L<documentation for Data::Compare|Data::Compare>.

=head1 CONFIGURATION AND ENVIRONMENT

Data::Compare::Plugins::Set::Object requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over

=item L<Data::Compare> >= 0.06 (must be installed separately)

=item L<Set::Object> (must be installed separately)

=item L<English> (part of the standard Perl 5 distribution)

=item L<List::Util> (part of the standard Perl 5 distribution)

=item L<version> >= 0.77 (part of the standard Perl 5.10.1 distribution)

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests via GitHub at
L<http://github.com/mjg/Data-Compare-Plugins-Set-Object/issues>.
Please report any bugs or feature requests to
C<bug-data-compare-plugins-set-object@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Mark Gardner C<< <mjgardner@cpan.org> >>. All rights
reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.10.1 itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
