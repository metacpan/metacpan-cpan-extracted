#!/usr/bin/perl
use strict; use warnings  FATAL => 'all'; use feature qw(state say); use utf8;
srand(42);  # so reproducible
#use open IO => ':locale';
use open ':std', ':encoding(UTF-8)';
select STDERR; $|=1; select STDOUT; $|=1;
use Carp;

use Test::More;

use Data::Dumper::Interp;
my $pkgname = "Data::Dumper::Interp";

sub getPkgVar($) {
  my ($varname) = @_;
  no strict 'refs'; my $r = eval "\$${pkgname}::$varname"; die $@ if $@;
  $r
}
sub setPkgVar($$) {
  my ($varname, $value) = @_;
  no strict 'refs'; eval "\$${pkgname}::$varname = \$value"; die $@ if $@;
}
sub callPkgNew(@) {
  no strict 'refs'; my $r; eval "\$r = ${pkgname}->new(\@_)"; die $@ if $@;
  $r
}

# ---------- Check stuff other than formatting or interpolation --------

sub unix_compatible_os() {
  state $result //=
    # There must be a better way...
    (($^O !~ /win|dos/i && $^O =~ /ix$|ux$|bsd|svr|uni|osf|sv$/)
     || $^O eq 'darwin'
     || $^O eq 'cygwin'
    )
    && -w "/dev/null";
  $result;
}

my $unicode_str = join "", map { chr($_) } (0x263A .. 0x2650);

# Certain combinations of Math::Big* are incompatible (undefined BigInt::_register_callback):
#   Math::BigInt 1.999829
#   Math::BigFloat 1.999829
#   Math::BigRat 0.2614
#
# In an attempt to avoid these troubles, require known-good versions
use Math::BigInt 1.999837 ();
use Math::BigFloat 1.999837 ();
use Math::BigRat 0.2624 ();

require Data::Dumper;
require bigint;
#require bigfloat;
require bigrat;

diag "Perl ",u($^V),"\n\n";

for my $modname ( qw/bigint bigfloat bigrat bignum 
                     bogon
                     Data::Dumper Math::BigInt Math::BigFloat Math::BigRat/) {
  # Not all these modules are explicitly used (e.g. bigfloat) 
  # but if present, show their verions.
  eval "require $modname;";
  my $modpath = "${modname}.pm" =~ s/::/\//gr;
  if ($INC{$modpath}) {
    no strict 'refs';
    diag sprintf "%-24s %s\n", 
                 $modname . '@' . u(${"${modname}::VERSION"}),
                 ($INC{$modpath} =~ s#^$ENV{HOME}/#\$HOME/#r);
  } else {
    diag "(Module '$modname' is not available)\n";
  }
}
diag "";

# Has Data::Dumper::Useqq('utf8') been fixed?
{ my $s = Data::Dumper->new([$unicode_str],['unicode_str'])->Terse(1)->Useqq('utf8')->Dump;
  chomp $s;
  $s =~ s/^"(.*)"$/$1/s or die "bug";
  if ($s =~ tr/\0-\377//c) {
    diag "!!! Useqq('utf8') seems to have been fixed in Data::Dumper !!! \n";
    diag "!!! and is now passing through wide characters as themselves.\n";
    diag "!!! Consider changing $pkgname to not bother parsing hex escapes?";
  } else {
    diag "Useqq('utf8') is still broken in Data::Dumper.\n"
  }
}

diag "Loaded ", $INC{"${pkgname}.pm" =~ s/::/\//gr},
     " VERSION=", (getPkgVar("VERSION") // "undef"),"\n";

# Check default Foldwidth
{
  # 1/3/23: CPAN smoke tests failing because Term::ReadKey::GetTerminalSize
  #   returns something different than `tput`; so we no longer try to check
  #   that the "correct" value is returned, but only that COLUMNS overrides
  #   what the terminal says, etc.

  die "Expected initial ${pkgname}::Foldwidth to be undef"
    if defined getPkgVar("Foldwidth");
  ivis("abc");
  my $expected = getPkgVar("Foldwidth") // die "Foldwidth remained undef";

  # COLUMNS should over-ride the actual terminal width
  setPkgVar("Foldwidth", undef); # re-enable auto-detect
  { local $ENV{COLUMNS} = $expected + 13;
    ivis("abc");
    die "${pkgname}::Foldwidth ",u(getPkgVar('Foldwidth'))," does not honor ENV{COLUMS}=$ENV{COLUMNS}"
      unless u(getPkgVar("Foldwidth")) == $expected + 13;
  }

  # Verify auto-detect works more than once
  setPkgVar("Foldwidth", undef); # re-enable auto-detect
  if (unix_compatible_os()) {
    delete local $ENV{COLUMNS};
    ivis("abc");
    die "${pkgname}::Foldwidth ",u(getPkgVar('Foldwidth'))," not defaulted correctly, expecting $expected" unless getPkgVar('Foldwidth') == $expected;
  }

  # Should defauilt to 80 if there is no terminal and COLUMNS is unset
  setPkgVar("Foldwidth", undef); # re-enable auto-detect
  if (unix_compatible_os()) {
    delete local $ENV{COLUMNS};
    my $pid = fork();
    if ($pid==0) {
      require POSIX;
      die "bug" unless POSIX::setsid()==$$; # Loose controlling tty
      #for (*STDIN,*STDOUT,*STDERR) { close $_ or die "Can not close $_:$!" }
      POSIX::close $_ for (0,1,2);
      ivis("abc");
      exit(getPkgVar('Foldwidth') // 253);
    }
    waitpid($pid,0);
    die "With no tty, ${pkgname}::Foldwidth defaulted to ", ($? >> 8)|($? & !0xFF), " (not 80 as expected)"
      unless $? == (80 << 8);
    $? = 0;
  }
}
ok(1, "Foldwidth default initialization");

# Basic check of printable unicode pass-thru
{ my $vis_outstr = vis($unicode_str);
  print "                unicode_str=\"$unicode_str\"\n";
  print "${pkgname} output=$vis_outstr\n";
  if (substr($vis_outstr,1,length($vis_outstr)-2) ne $unicode_str) {
    die "Unicode does not come through unmolested!";
  }
}
ok(1, "Unicode wide char pass-thru");

{ # Check that we recognize a Config arg of 'undef' as false, rather than
  # acting like not args are present.  The result should be the object ref.
  if (! ref callPkgNew()->Useqq(undef)) {
    diag "WARNING: Data::Dumper methods do not recognize undef boolean args as 'false'.\n";
  }
}
ok(1, "Configmethod(undef) recognized as (false)");

done_testing();


