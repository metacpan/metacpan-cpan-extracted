package CPAN::Test::Dummy::Perl5::Make::PLExit;
use strict;

use vars qw{$VERSION};
$VERSION = '1.01';

1;

__END__

=pod

=head1 NAME

CPAN::Test::Dummy::Perl5::Make::PLExit - CPAN Test Dummy

=head1 VERSION

This documentation refers to version 1.01.

=head1 SYNOPSIS

    use CPAN::Test::Dummy::Perl5::Make::PLExit

=head1 DESCRIPTION

This module has been developed with the single purpose of testing
CPAN.pm itself.  

Contains no functionality, and will never do so. On the contrary, it
exits during either "perl Makefile.PL" or "perl Build.PL" without
creating a Makefile or Build file.

=head1 AUTHOR

David A. Golden, based on CPAN::Test::Dummy::Perl5::Make::FailLate

=head1 COPYRIGHT & LICENSE

Copyright 2007 David Golden

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
