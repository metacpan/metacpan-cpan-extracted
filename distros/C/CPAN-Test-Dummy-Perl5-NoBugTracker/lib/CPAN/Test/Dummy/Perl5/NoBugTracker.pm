use strict;

package CPAN::Test::Dummy::Perl5::NoBugTracker;

$CPAN::Test::Dummy::Perl5::NoBugTracker::VERSION = '1.00';

1;


__END__

=pod

=head1 NAME

CPAN::Test::Dummy::Perl5::NoBugTracker - CPAN Test Dummy that explicitly says
there is no bug tracker

=head1 SYNOPSIS

  use CPAN::Test::Dummy::Perl5::NoBugTracker;

=head1 DESCRIPTION

This module tests the behaviour of the CPAN ecosystem in the case of a author
which does not make use of a bugtracker.

This module was created to assist Marc Lehmann and prove that parts of the
CPAN ecosystem correctly obey instructions to not have a bugtracker.

Contains no functionality, and will never do so.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
