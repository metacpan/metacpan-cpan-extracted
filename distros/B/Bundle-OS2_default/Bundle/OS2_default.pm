package Bundle::OS2_default;

$VERSION = '1.07';

1;

=head1 NAME

Bundle::OS2_default - Modules to install last for OS/2 binary distribution

=head1 SYNOPSIS

  perl -MCPAN -e "install Bundle::OS2_default"

  perl_ -MCPAN -e "force 'install', Bundle::OS2_default1"
  perl_ -MCPAN -e "force 'install', Bundle::OS2_default2"
  perl_ -MCPAN -e "force 'install', Bundle::OS2_default3"
  ...

=head1 CONTENTS

Bundle::OS2_default1_2

Bundle::OS2_default3

Bundle::OS2_default4

Bundle::OS2_default5

Bundle::OS2_default6

Bundle::OS2_default7

Bundle::OS2_default8

=head1 KNOWN PROBLEMS with version 5.8.2 and CPAN of 2003/12/04

Most of the mentioned patches are sent to the respected authors; see also the
subdirectory F<patches> of this distribution.  With patched-enough
CPAN.pm (as in binary distribution), one can put patches to
F<$CPANHOME/.cpan/patches/> subdirectory, and they will be auto-applied.

For general installation instructions see L<perlos2/"Building a binary distribution">.

=head2 Tests failing on other systems too

=over

=item DBD-CSV-0.1030

   not ok 7 -
   FAILED Test 7 -
   Test 7: DBI error 0,
   Use of uninitialized value in array dereference at t/40blobs.t line 141.
   Use of uninitialized value in numeric eq (==) at t/40blobs.t line 141.
   not ok 8 -
   FAILED Test 8 -
   00000000 000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
   00000020 202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f
   00000040 404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f
   00000060 606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f
   00000080 808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f
   000000a0 a0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebf
   000000c0 c0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedf
   000000e0 e0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff
   00000000
   00000020
   00000040
   00000060
   00000080
   000000a0
   000000c0
   000000e0

  Failed 2/14 test scripts, 85.71% okay. 4/245 subtests failed, 98.37% okay.
  Failed Test Stat Wstat Total Fail  Failed  List of Failed
  -------------------------------------------------------------------------------
  t/40blobs.t               11    3  27.27%  4 7-8
  t/ak-dbd.t                49    1   2.04%  27


=item GD-2.07

Text mode during patching (F<patch_GD_pm_2.041_gif_021110.gz> for GIF
compatibility) of test files; this leads to failure of C<t/GD.t:11>.

=item libxml-perl-0.07

    Failed 1/6 test scripts, 83.33% okay. 1/45 subtests failed, 97.78% okay.
    Failed Test Stat Wstat Total Fail  Failed  List of Failed
    ---------------------------------------------------------
    t/stream.t                11    1   9.09%  11

is not translated from latin-1 to utf...

=head2 Suspected to be unrelated to problems with OS/2 port

=over

=item C<XML-Grove-0.46alpha>

produces some junk looking as Unicode-related.

   Failed 1/2 test scripts, 50.00% okay. 2/10 subtests failed, 80.00% okay.
   Failed Test Stat Wstat Total Fail  Failed  List of Failed
   -------------------------------------------------------------------------------
   t/grove.t                  5    2  40.00%  3-4

=item C<XML-Simple-2.09>

  t/3_Storable......Document requires an element [Ln: 1, Col: 0]

  Failed 1/10 test scripts, 90.00% okay. 8/418 subtests failed, 98.09% okay.
  Failed Test    Stat Wstat Total Fail  Failed  List of Failed
  -------------------------------------------------------------------------------
  t/3_Storable.t  255 65280    21   16  76.19%  14-21


=item C<XML-XSLT-Wrapper-0.32>

  t/libxslt......# Test 1 got: '1' (t/libxslt.t at line 28)
  #   Expected: ''
  #  t/libxslt.t line 28 is: skip($missing, defined(1), defined($result));
  runtime error
  Evaluating user parameter COMEIN failed
  # Test 2 got: '' (t/libxslt.t at line 40)
  #   Expected: <UNDEF>
  #  t/libxslt.t line 40 is: skip($missing, '', $result);

  Failed 1/8 test scripts, 87.50% okay. 2/9 subtests failed, 77.78% okay.
  Failed Test Stat Wstat Total Fail  Failed  List of Failed
  -------------------------------------------------------------------------------
  t/libxslt.t                2    2 100.00%  1-2
  3 subtests skipped.


=head2 (Suspected to be) related to problems with OS/2 port

=over

=item Net::SNPP

  Failed 1/2 test scripts, 50.00% okay. 1/16 subtests failed, 93.75% okay.
  Failed Test Stat Wstat Total Fail  Failed  List of Failed
  ------------------------------------------------------------------------
  t/server.t     1   256    15    1   6.67%  6

=item     File-chdir-0.06

Tries to catdir starting with rootdir... Temporary plug installed...

=item IPC-Run-0.75

Would trap the OS without new kernel (Nov 2003) or patches to 5.8.2 which
avoid dup() at C<max_fh+1>.  Has no code to support OS/2...

=item Module-Build-0.20

Has no code to support OS/2 build of XS modules.

=item Net_SSLeay.pm-1.25

Server-client communication failing during tests.  The test leaves two server
processes running; these processes need to be killed manually for the C<CPAN>
session to end.

=item CPANPLUS

fails backend test...

=head2 No tests defined for these extensions

    Curses
    XML::Sablotron::DOM
    XML::Sablotron::Situation
    XML::Sablotron::SXP
    XML::Sablotron::Processor
    XML::Registry
    XML::miniXQL::Parser
    File::NCopy


=head2 Some porting issues remain, but are not caught by the test suite

C<SQLite> relies on st_inode for file locking.  This part of code will not
work under EMX.

=head1 Build quirks

Sometimes the C<CPAN> process gets stuck and needs to be killed manually.  This
is not reproducible...  Sometime C<mkdir> produces the error C<disk full>;
again not reproducible.

Some modules need to be installed by hand; these are all the modules with build
failures, and their dependencies (such as C<DBD-RAM-0.072> depending on
C<DBD::CSV>).  Additionally:

=over

=item CPANPLUS

Will not work with redirection C<< <nul >>.

Can be build/installed with (with failing dependency on IPC::Run):

  perl5.8.2 -wle "$ENV{PERL5OPT} .= join q( -Mblib=), '', grep -f qq($_/.cpantok), <../*>; print $ENV{PERL5OPT}; exec @ARGV" perl5.8.2 Makefile.PL

etc.  It fails backend test...  Should be manually installed.

=item LWP

succeeds when tested as

  perl5.8.2 -MCwd=cwd -wle "$c = cwd; $ENV{PERL5OPT} .= join q( -Mblib=), '', grep -f qq($_/.cpantok), <$c/../*>; print $ENV{PERL5OPT}; exec @ARGV" make test

Then may be manually installed.

??? To be continued...

=head1 AOUT Build quirks

Fortunately, only C<XML::LibXLT> is a dependence of Makefile.PL on another
XSUB module.  So the fact that we installed modules with F<perl.exe> makes
all other prerequisites available with F<perl_.exe> too.

Observed problems:

=over

=item F<pm_to_blib> need to be removed

otherwise F<.pm> files will not be copied to F<../blib>.


=item Some modules expect to find F<blib> in the current directory

???

=item Some modules will not build with FIRST_MAKEFILE redefined


???

=item Some modules will not work with static build

???

=item Some modules will not work from a subdirectory of toplevel F<Makefile.PL>

C<PAR>, C<Mailtools>, and C<libwww>, C<XML::SAX>.

=item Net_SSLeay

resets C<FIRST_MAKEFILE> from F<Makefile.aout> to F<Makefile>?!

=item SQLite


       'OPTIMIZE'      => "-O6 -DNDEBUG=1 -DSQLITE_PTR_SZ=$Config{ptrsize}",

is extremely wrong (kid Makefiles is run with parent's OPTIMIZE).

=item C<CPANPLUS::Shell::Curses>

I needed to manually run C<force install> to get C<Test::Pod> installed...

via

  env PERL_RL=0 perl5.8.2 -MCPAN -eshell |& tee 000cpan-5.8.2-newindex-install-sh-cur

).  To test for this, one may need to create a Makefile.PL in the build
directory, and `make -j4 test <nul'.

=back

??? To be continued...
