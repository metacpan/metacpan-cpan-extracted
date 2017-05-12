=== What is it? ===

This is a Perl interface to libsndfile C library, which provides
common interface for handling various sound formats. With this
module, you will be able to handle supported sound formats in Perl also.

In addition to usual I/O interface, it also provides additional
interface to handle PDL (Perl Data Language) object directly, so
sound data manipulation can be done much efficiently compared to
manipulation using standard Perl scalar.

=== Requirements ===

To compile/install this module, following packages are required:

  - libsndfile library (from http://www.mega-nerd.com/libsndfile/)
  - PDL.pm             (Perl Data Language module, available from CPAN)

=== Installation ===

Standard procedure of

  perl Makefile.PL
  make
  make test
  make install

should work fine. You might also want to check out code in bin/ folder.

=== Known Bugs ===

I have been experiencing strange behavior of bseek/fseek method,
which does seeks, but returns unreliable value for some reason.
I'm looking into libsndfile right now on this issue.

=== Environment ===

I have developed/tested the code on Debian GNU/Linux (lenny/amd64).

=== Contact Address ===

Please send bug reports/comments to: Taisuke Yamada <tai atmark rakugaki.org>
