use strict;
use 5.005062;
use ExtUtils::MakeMaker;
use Config;
use ExtUtils::Embed qw(ccopts ldopts);

my $extracflags = '';
my $verbose = grep {$_ eq '-v' } @ARGV;
my $lddlflags = $Config{lddlflags};
if ($^O eq 'darwin') {
  $lddlflags =~ s/-flat_namespace/-twolevel_namespace/;
  $lddlflags =~ s/-undefined suppress/-undefined error/;
}
my $ccflags = $Config{ccflags};
$ccflags .= " $extracflags";
$ccflags .= ' -DPERL_CUSTOM_OPS -DPERL_CUSTOM_OPCODES' if $] >= 5.008;
my $obj = $Config{obj_ext};

sub checkexport {
  my $sym = shift;
  open C, ">", "test.c";
  print C << "EOF";
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "perlapi.h"
#include "XSUB.h"

int main (int argc, char **argv) {
  pTHXx;
  $sym;
}
EOF
  close C;

  my $cflags = ccopts;
  my $exe = $Config{exe_ext};
  my $redir = $^O eq 'MSWin32' ? "> NUL" : "2>/dev/null >/dev/null";
  my $psym = $sym; 
  @_ ? $psym = shift : $psym =~ s/\n/ /g;
  print "\nTesting libperl export for $psym\n";

  my $coredir = $ENV{PERL_SRC} || "$Config{installarchlib}/CORE";
  my $libdir  = "$Config{prefix}/lib";
  my $useshrplib = $Config{useshrplib};
  my $linkargs;
  if ($^O eq 'MSWin32' && $Config{cc} =~ m/^cl/i) {
    my $cmd = "$Config{cc} $cflags -c $redir";
    print "  $cmd\n" if $verbose;
    system($cmd);
    my $ok = ($? == 0) and -e "test.obj";
    return 0 unless $ok;

    $linkargs = ldopts("-std");
    $linkargs .= " perl5$Config{PERL_VERSION}.lib kernel32.lib msvcrt.lib";
    $cmd = "$Config{ld} test.obj $linkargs $redir";
    print "  $cmd\n" if $verbose;
    system $cmd;
  }
  else {
    if ( -e "$coredir/$Config{libperl}" and $Config{libperl} !~ /\.(dll|so)$/ ) {
      # prefer static linkage manually, without broken ExtUtils::Embed 
      $linkargs = sprintf("%s $coredir/$Config{libperl} %s",
			  @Config{qw(ldflags libs)});
    } elsif ( $useshrplib and -e "$libdir/$Config{libperl}") {
      # debian: /usr/lib/libperl.so.5.10.1 and broken ExtUtils::Embed::ldopts
      $linkargs = ExtUtils::Embed::ldopts('-std');
      $linkargs =~ s|-lperl |$libdir/$Config{libperl} |;
    } else {
      $linkargs = ExtUtils::Embed::ldopts('-std');
    }
    my $cmd = "$Config{cc} $ccflags -I$coredir test.c $linkargs $redir";
    print "  $cmd\n" if $verbose;
    system $cmd;
  }
  my $ok = $? == 0;
  print $ok ? "ok" : "not found";
  return $ok;
}

my $broken_plat = $^O =~ /MSWin32|AIX/;
unless ($broken_plat) {
  END { unlink "a.out", "a.exe", "test.exe", "test$obj", "test.c"; };
  $ccflags .= " -DHAVE_PAD_ALLOC"
    if checkexport("Perl_pad_alloc(aTHX_ 0, SVs_PADTMP)", "pad_alloc");
  $ccflags .= " -DHAVE_CV_CLONE"
    if checkexport("CV* cv;\nPerl_cv_clone(aTHX_ cv)", "cv_clone");
  print "\n";
} # else -DDISABLE_PERL_CORE_EXPORTED

WriteMakefile
  (
   'NAME'		=> 'B::Generate',
   'VERSION_FROM'	=> 'lib/B/Generate.pm',
   'PREREQ_PM'	=>
   {
    'B'                  => 0, # 1.09 for rt29257 re OP_LIST. tested down to 1.02 w/ perl5.8.4
    'ExtUtils::CBuilder' => 0,
    'ExtUtils::Embed'    => 0,
   },
   ABSTRACT_FROM => 'lib/B/Generate.pm',
   AUTHOR        => 'Simon Cozens',
   (($^O eq 'darwin') ?
     (LDDLFLAGS     => $lddlflags) : ()),
   CCFLAGS        => $ccflags,
   ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  =>
     {
      resources =>
      {
       repository  => 'http://github.com/rurban/b-generate',
       license     => 'http://dev.perl.org/licenses/',
      },
     }
    ) : ()),
    #SIGN => 1
  );


package MY;
use Config;

# sub const_config {
#   my $s = shift->SUPER::const_config(@_);
#   return $s unless $^O eq 'darwin';
#   my ($lddlflags) = $s =~ /^LDDLFLAGS (.*)$/m;
#   $lddlflags =~ s/-flat_namespace/-twolevel_namespace/;
#   $lddlflags =~ s/-undefined suppress/-undefined error/;
#   $lddlflags .= " $Config{archlibexp}/CORE/$Config{libperl}";
#   $s =~ s/^LDDLFLAGS (.*)$/LDDLFLAGS $lddlflags/;
#   return $s;
# }

# Modules using B::Generate should do the same
sub test {
  local $_ = shift->SUPER::test(@_);
  s/PERL_DL_NONLAZY=1 //g;
  return $_;
}

sub depend {
  "
README : \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README

README.md : \$(VERSION_FROM)
	pod2markdown \$(VERSION_FROM) > \$@

release : dist
	echo git commit -a -m\"release \$(VERSION)\"
	git tag \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags

test_cover :: pure_all
	\$(RM_RF) cover_db
	\$(PERLRUNINST) -S cover -test
test_coveralls :: pure_all
	\$(PERLRUNINST) -S cover -test -report coveralls

gcov : \$(BASEEXT).c.gcov \$(BASEEXT).gcov cover_db/\$(BASEEXT)-xs.html

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
