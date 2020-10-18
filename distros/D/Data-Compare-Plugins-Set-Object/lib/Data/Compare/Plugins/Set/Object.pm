package Data::Compare::Plugins::Set::Object;

# ABSTRACT: plugin for Data::Compare to handle Set::Object objects

#pod =head1 DESCRIPTION
#pod
#pod Enables L<Data::Compare|Data::Compare> to Do The Right Thing for
#pod L<Set::Object|Set::Object> objects. Set::Object already has an
#pod C<equals()> method, but it only returns true if objects within two sets
#pod are exactly equal (i.e. have the same references, referring to the same
#pod object instance).  When using Data::Compare in conjunction with this
#pod plugin, objects in sets are considered the same if their B<contents> are
#pod the same.  This extends down to sets that contain arrays, hashes, or
#pod other objects supported by Data::Compare plugins.
#pod
#pod =cut

use 5.010;
use utf8;
use strict;
use warnings;

our $VERSION = '1.002';    # VERSION
use English '-no_match_vars';
use Data::Compare 0.06;
use List::Util 'first';

sub _register {
    return [ 'Set::Object', \&_so_set_compare ];
}

## no critic (Subroutines::RequireArgUnpacking)
sub _so_set_compare {
    my @sets = splice @_, 0, 2;

    # quick optimizations if sets aren't of equal size or are directly equal
    return 0 if $sets[0]->size() != $sets[1]->size();
    return 1 if $sets[0] == $sets[1];

    # loop over each of the first set's elements
    # looking for a match in the second set
    for my $element ( $sets[0]->elements() ) {
        my $matched_element = first { Data::Compare::Compare( $element, $_ ) }
        grep { ref eq ref $element } $sets[1]->elements();

        # return false if not found
        return 0 if not defined $matched_element;

        # otherwise remove from copy of second set and keep going
        $sets[1]->remove($matched_element);
    }

    # sets are equal only if we've exhausted the second set
    return $sets[1]->is_null();
}

# Data::Compare::Plugins interface requires modules to return an arrayref
## no critic (RequireEndWithOne, Lax::RequireEndWithTrueConst)
_register();

__END__

=pod

=encoding utf8

=for :stopwords Mark Gardner cpan testmatrix url bugtracker rt cpants kwalitee diff irc
mailto metadata placeholders metacpan

=head1 NAME

Data::Compare::Plugins::Set::Object - plugin for Data::Compare to handle Set::Object objects

=head1 VERSION

version 1.002

=head1 SYNOPSIS

    use 5.010;
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

Enables L<Data::Compare|Data::Compare> to Do The Right Thing for
L<Set::Object|Set::Object> objects. Set::Object already has an
C<equals()> method, but it only returns true if objects within two sets
are exactly equal (i.e. have the same references, referring to the same
object instance).  When using Data::Compare in conjunction with this
plugin, objects in sets are considered the same if their B<contents> are
the same.  This extends down to sets that contain arrays, hashes, or
other objects supported by Data::Compare plugins.

=head1 SUBROUTINES/METHODS

As a plugin to Data::Compare, the interface is the same as Data::Compare
itself: pass the reference to two data structures to the C<Compare>
function, which for historical reasons is exported by default.

Set::Object also can export certain functions, and overloads comparison
operators pertaining to sets.  Consult the
L<Set::Object documentation|Set::Object> for more information.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Data::Compare::Plugins::Set::Object

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Data-Compare-Plugins-Set-Object>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Data-Compare-Plugins-Set-Object>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Data-Compare-Plugins-Set-Object>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Data::Compare::Plugins::Set::Object>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/Data-Compare-Plugins-Set-Object/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/Data-Compare-Plugins-Set-Object>

  git clone git://github.com/mjgardner/Data-Compare-Plugins-Set-Object.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mark Gardner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
