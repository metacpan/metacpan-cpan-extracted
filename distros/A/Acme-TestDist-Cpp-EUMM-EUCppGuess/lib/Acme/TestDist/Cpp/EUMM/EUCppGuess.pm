package Acme::TestDist::Cpp::EUMM::EUCppGuess;

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( return_one ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Acme::TestDist::Cpp::EUMM::EUCppGuess', $VERSION);

sub return_one {
  returnOne();
}



1;
__END__

=encoding utf8

=head1 NAME

Acme::TestDist::Cpp::EUMM::EUCppGuess - Example C++ distribution with MakeMaker and CppGuess to test the tool chain

=begin html

<a href="https://travis-ci.org/wollmers/Acme-TestDist-Cpp-EUMM-EUCppGuess"><img src="https://travis-ci.org/wollmers/Acme-TestDist-Cpp-EUMM-EUCppGuess.png" alt="Acme-TestDist-Cpp-EUMM-EUCppGuess"></a>
<a href='https://coveralls.io/r/wollmers/Acme-TestDist-Cpp-EUMM-EUCppGuess?branch=master'><img src='https://coveralls.io/repos/wollmers/Acme-TestDist-Cpp-EUMM-EUCppGuess/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/Acme-TestDist-Cpp-EUMM-EUCppGuess'><img src='http://cpants.cpanauthors.org/dist/Acme-TestDist-Cpp-EUMM-EUCppGuess.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Acme-TestDist-Cpp-EUMM-EUCppGuess"><img src="https://badge.fury.io/pl/Acme-TestDist-Cpp-EUMM-EUCppGuess.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

    use Acme::TestDist::Cpp::EUMM::EUCppGuess qw(return_one);

    return_one(); # returns 1

=head1 DESCRIPTION

This distribution is useful for

=over

=item *

being a template to start your own CPAN XS/C++ distribution

=item *

test the tool chain of an individual environment

=item *

test the tool chains of CPAN infrastructure

=back

=head1 EXPORT

None by default, but the following functions are available:

=head2 return_one()

Returns the number 1. Useful for test.

=head2 returnOne()

Internal use.

=head1 VERSIONING

After reaching near perfect quality version numbers will be in the form
year.month.minor, i.e. YYYY.MM.99.

=head1 SEE ALSO

C<ExtUtils::CppGuess>
C<Extutils::MakeMaker>

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Acme-TestDist-Cpp-EUMM-EUCppGuess>

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2016 Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
