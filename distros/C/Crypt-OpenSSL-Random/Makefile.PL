use ExtUtils::MakeMaker;
use Config;
use Crypt::OpenSSL::Guess 0.11 qw(openssl_inc_paths openssl_lib_paths);
use 5.006;

my ($libdir, $incdir);
my $args = join(" ", @ARGV);
if ($args =~ /INCDIR[ =](\S+)/) {
  $incdir = $1;
}
if ($args =~ /LIBDIR[ =](\S+)/) {
  $libdir = $1;
}
my $libs = "-lssl -lcrypto";

WriteMakefile(
  'NAME'	    => 'Crypt::OpenSSL::Random',
  'VERSION_FROM'    => 'Random.pm',
  'LIBS'            => $libdir ? [ "-L$libdir $libs" ] : [ openssl_lib_paths() . " $libs" ],
  'INC'             => $incdir ? "-I$incdir" : openssl_inc_paths(),
  'AUTHOR'          => 'Ian Robertson',
   (eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 } ?
    ('CONFIGURE_REQUIRES' =>
     {
      'Crypt::OpenSSL::Guess' => '0.11',
     },
    ) : ()),
   (eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 } ?
    ('LICENSE'     => 'perl',
     'META_MERGE'  =>
     {
      resources =>
      {
       #homepage    => 'http://sourceforge.net/projects/perl-openssl/',
       repository  => 'https://github.com/rurban/Crypt-OpenSSL-Random',
       license     => 'http://dev.perl.org/licenses/',
       #MailingList => 'perl-openssl-users@lists.sourceforge.net',
      },
     }
    ) : ()),
    SIGN => 1
);

package MY;
use Config;

sub top_targets {
  local $_ = shift->SUPER::top_targets(@_);
  s/\$\(FIRST_MAKEFILE\) blibdirs/\$(FIRST_MAKEFILE\) blibdirs README/;
  $_
}

sub depend {
  "
README : \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README

release : dist
	-git commit -a -m\"release \$(VERSION)\"
	git tag \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags

gcov : \$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov cover_db/\$(BASEEXT)-xs.html

\$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov : \$(BASEEXT).xs
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -fprofile-arcs -ftest-coverage\" LDDLFLAGS=\"\$(LDDLFLAGS) -fprofile-arcs -ftest-coverage\"
	gcov \$(BASEEXT).c \$(BASEEXT).xs

cover_db/\$(BASEEXT)-xs.html : \$(BASEEXT).xs.gcov
	PERL5OPT=-MDevel::Cover make test
	-$^X -S gcov2perl \$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov
	$^X -S cover

gprof :
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -pg\" LDDLFLAGS=\"\$(LDDLFLAGS) -pg\"
"
}
