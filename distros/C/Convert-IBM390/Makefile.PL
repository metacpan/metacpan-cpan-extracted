use ExtUtils::MakeMaker;

$use_xs = (grep { $_ eq 'noxs' } @ARGV) == 0;

#--- Subroutine to find the internal name of 'undef'.  This is
#--- sv_undef in older releases, PL_sv_undef in more recent releases.
#--- Since many are still using the older releases, we take care of
#--- it here.  In the near future, this can be removed.
sub undef_flag {
 if ($] < 5.005) { return '-DOLD_INTERNAL'; }
 else            { return ''; }
}

if ($use_xs) {
  @perlonly = ();
  print "\n\n","*"x40,"\n";
  print "Using Perl/XS implementation\n";
  print "*"x40,"\n\n";
  $infile = 'IBM390_pm_xsver';
  $outfile = 'IBM390.pm';
} else {
  @perlonly = (
    XS => {},
    C => []
  );
  print "\n\n","*"x40,"\n";
  print "Using Perl-only implementation\n";
  print "*"x40,"\n\n";
  $infile = 'IBM390_pm_perlver';
  $outfile = 'IBM390.pm';
}

open(IN, "d/$infile") or die "Cannot open d/$infile: $!";
open(OUT,">lib/Convert/$outfile") or die "Cannot open $outfile: $!";
while(<IN>) {
   print OUT;
}
close(IN);

open(IN, "d/IBM390_pm_common") or die "Cannot open d/IBM390_pm_common: $!";
while(<IN>) {
   print OUT;
}
close(IN);
close(OUT);

$p_define = '';

#--- C code

if ($use_xs) {
  @c_code = qw(IBM390lib.ccc IBM390lib.hhh);
  foreach $file (@c_code) {
    ($outfile = $file) =~ s/(ccc|hhh)/substr($1,0,1)/e;
    open(IN, "d/$file") or die "Cannot open d/$infile: $!";
    open(OUT,">$outfile") or die "Cannot open $outfile: $!";
    while(<IN>) { print OUT; }
    close(IN);
    close(OUT);
  }
  $p_define .= undef_flag();
}

#--- WriteMakefile parameters
$p_obj = '$(O_FILES)' x $use_xs;

WriteMakefile(
    'NAME'	=> 'Convert::IBM390',
    'VERSION_FROM' => 'lib/Convert/IBM390.pm', # finds $VERSION
    'OBJECT'    => $p_obj,
    'DEFINE'	=> $p_define,
#    'DEFINE'	=> "$p_define -DDEBUG390",   # if debugging is desired
    'INC'	=> '',    # e.g., -I/usr/local/lib/.../CORE
    'clean'	=> { FILES => 'lib/Convert/IBM390.pm IBM390lib.c IBM390lib.h ' },
    'dist'	=> { PREOP => 'cp -p "d/IBM390_pm_dummy" "lib/Convert/IBM390.pm"' },
    @perlonly,
);
