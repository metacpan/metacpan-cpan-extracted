package CPAN::Test::Dummy::Perl5::Exists;

use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub dummy { 'Ms Nadda' }

1;

__END__

=pod

=head1 NAME

CPAN-Test-Dummy-Perl5-Exists - CPAN Test Dummy Exists sample module

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

        use CPAN::Test::Dummy::Perl5::Exists;
    
        my $name = CPAN::Test::Dummy::Perl5::Exists->dummy;

=head1 DESCRIPTION

This module exists for the sake of existence. Hence it's name.

This module has been created for use testing suites. It contains no
function(s) for actual use, and exists only to provide certain
guarantees regarding it's own existance.

This module will never exist in the CPAN index. It appears as a
developer release, and will never be deleted.

In the CPAN master repository, or in a full mirror, it will exist
forever as F<TAINT/CPAN-Test-Dummy-Perl5-Exists-0.01.tar.gz>.

=head2 Module Guarantees

1. Contains no functionality, and never will.

2. Has no non-core depencies, and will never posses any.

3. Exists on CPAN.

4. Does not exist in the CPAN index, and never will.

6. No release will ever be deleted from the CPAN.

=head2 Uses for This Module

This allows for several types of testing to be done.

Filename related issues can be tested with a known developer release.

The module name and path can be hard-coded into tests without risk
that the file will later dissapear.

Because it should always exist on a full mirror, but never exist on
an index-only mirror (such as those created by minicpan), then if
the mirror is already known to exist, the existance of this module
can be used to differentiate the type of a mirror between full or
index-only.

In combination with other CPAN Dummy modules, other types of
situations may also be able to be set up to test the behaviour in
those situations.

=head1 METHODS

CPAN::Test::Dummy::Perl5::Exists is derived from Adam Kennedy's
PITA::Test::Dummy::Perl5::Make.

=head2 dummy

Returns the dummy's name, in this case 'Ms Nadda'

=head1 AUTHOR

C Hutchinson, C<< <taint at cpan.org> >>

=head1 SUPPORT

None. No support is available for Ms Nadda.

=head1 SEE ALSO

L<CPAN>

=head1 COPYRIGHT & LICENSE

Copyright 2013 C Hutchinson, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

