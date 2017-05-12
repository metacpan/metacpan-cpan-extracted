package Bundle::Melody::extlib;

use v5.8.8;
use strict;

use vars qw($VERSION);
$VERSION = '0.9.29';

1;

__END__

=head1 NAME

Bundle::Melody::extlib - a bundle containing the CPAN
modules bundled with Melody E<lt>http://openmelody.org/E<gt>
and that is distributed in its extlib directory.

=head1 ABSTRACT

Bundle::Melody::extlib is a bundle containing the CPAN
modules bundled with Melody E<lt>http://openmelody.org/E<gt>
and that is distributed in its extlib directory. This bundle
only includes modules that do not require compilation in any
part of the depdency tree excluding modules in the core of
Perl 5.8.8 or later.

=head1 SYNOPSIS

C<perl -MCPAN -e "install Bundle::Melody::extlib">

=head1 CONTENTS

Algorithm::Diff 1.1902 [Required]

bignum 0.17 [1]

Cache 2.04 [Required]

CGI 3.45 [1] [Required]

Class::Accessor 0.22 [Required]

Class::Data::Inheritable 0.06 [Required]

Class::Trigger 0.1001 [Required]

Crypt::DH 0.06

Data::ObjectDriver 0.06 [Required]

File::Copy::Recursive 0.23 [Required]

Heap::Fibonacci 0.71 [Required]

HTML::Diff 0.561 [Required]

Image::Size 2.93 [Required]

IO::Scalar 2.110

Jcode 0.88 [Required]

JSON 2.12 [Required]

Locale::Maketext 1.13 [Required] [1]

Log::Dispatch 2.26 [Required]

Log::Log4perl 1.3 [Required]

Lucene::QueryParser 1.04 [Required]

LWP 5.831 [Required]

Mail::Sendmail

Math::BigInt 1.63 [1]

MIME::Charset 0.044

MIME::EncWords 0.040

Net::OpenID::Consumer 1.03

Params::Validate 0.73 [Required]

Path::Class 0.21

Sub::Install 0.925 [Required]

SOAP::Lite 0.710.08

TheSchwartz 1.07 [Required]

URI 1.36 [Required]

version 0.76 [2] [Required]

XML::NameSpaceSupport 1.09

XML::SAX 0.96

XML::Simple 2.14

YAML::Tiny 1.12 [Required]
 
=head1 DESCRIPTION

This bundle contains the prerequisite CPAN modules bundled
with Melody E<lt>http://openmelody.org/E<gt> and that is
distributed in its extlib directory. This bundle only
includes modules that do not require compilation in any part
of the depdency tree not incuding compiled modules that ship
with Perl 5.8.8 or later.

Packages requiring some type of compilation are as follows:

=over 4

=item Digest::SHA1 0.06 [Required]

=item HTML::Parser 3.66 [Required]

=item DBI 1.21 [Required]

=item Archive::Tar

=item Archive::Zip

=item Cache::Memcached

=item Crypt::DSA

=item Crypt::SSLeay

=item IO::Compress::Gzip

=item IO::Uncompress::Gunzip

=item XML::Atom

=item XML::LibXML

=item XML::Parser 2.23

=item XML::XPath

=back

=head2 Database Options

=over4

=item DBD::mysql

=item DBD::Pg 1.32

=item DBD::SQLite

=item DBD::SQLite2

=back

=head2 Graphic Manipulation Options

=over 4

=item Image::Magick

=item netpbm via IPC::Run

=item GD 

=back

[1] While a core module, the versions shipping with most perls are flawed.

[2] We force the pure perl version of the module in creating extlib.

=head1 SEE ALSO

E<lt>http://openmelody.org/E<gt>, L<Bundle::Melody::Test>

=head1 PARTICIPATION

The git repository for this bundle can found at:
L<http://github.com/tima/perl-bundle-melody-extlib/>

If you have something to push back to my repository, just
use the "pull request" button on the github site.

Participation in developing Melody is also welcome. If you
wish to contribute code, the git repository can be found at:
L<http://github.com/openmelody/melody/>. For more
information, resources and ways that you can participate
visit E<lt>http://openmelody.org/E<gt>.

=head1 LICENSE

The software is released under the Artistic License. The
terms of the Artistic License are described at
L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, Bundle::Melody::extlib is
Copyright 2009-2010, Timothy Appnel, tima@cpan.org. All
rights reserved.

=cut

=end
