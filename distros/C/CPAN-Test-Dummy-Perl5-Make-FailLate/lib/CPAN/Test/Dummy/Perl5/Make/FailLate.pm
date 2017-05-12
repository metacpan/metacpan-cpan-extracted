package CPAN::Test::Dummy::Perl5::Make::FailLate;
use strict;

use vars qw{$VERSION};
$VERSION = '1.02';

1;

__END__

=pod

=head1 NAME

CPAN::Test::Dummy::Perl5::Make::FailLate - CPAN Test Dummy

=head1 VERSION

This documentation refers to version 1.02.

=head1 SYNOPSIS

    use CPAN::Test::Dummy::Perl5::Make::FailLate;

=head1 DESCRIPTION

This module has been developed with the single purpose of testing
CPAN.pm itself.  

Contains no functionality, and will never do so. On the contrary, it
dies during either "make" or "perl Build".

=head1 AUTHOR

David A. Golden, based on CPAN::Test::Dummy::Perl5::Make::Failearly
by Andreas Koenig.

=head1 COPYRIGHT & LICENSE

Copyright 2007 David Golden

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
