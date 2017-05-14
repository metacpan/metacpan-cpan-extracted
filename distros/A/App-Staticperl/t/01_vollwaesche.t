BEGIN { $| = 1; print "1..9\n"; }

#TODO: actually ask before doing this

$PFX="/tmp/staticperltest$$";
mkdir $PFX, 0700
   or die "$PFX: $!";

END {
   system "rm -rf $PFX";
}

# the default shell on solaris doesn't even have
# minimal bourne shell support :/
$ENV{PATH}="/usr/ucb/bin:$ENV{PATH}"
   if -d "/usr/ucb/bin";

{
   open my $fh, ">", "$PFX/staticperlrc"
      or die "$PFX/staticperlrc: $!";
   print $fh <<EOF;
PERL_VERSION=5.12.4
STATICPERL=$PFX
PERL_CCFLAGS=
PERL_OPTIMIZE=""
PERL_CONFIGURE="-Ucc= -Uccflags= -Uldflags= -Ulibs="
EOF
}

$ENV{STATICPERLRC} = "$PFX/staticperlrc";

sub tryrun {
   my ($test, $command) = @_;

   if (my $exit = system "exec >$PFX/output 2>&1; $command") {
      my $output = do { local *FH; open FH, "<$PFX/output" or die "$PFX/output: $!"; local $/; <FH> };
      $output = substr $output, -30000 if 30000 < length $output; # "output truncated after..." I wish they would document these things
      printf STDERR
             "\n\n# FAILED #%d exit status 0x%04x (%s)\n\n# OUTPUT:\n%s\n\n",
             $test, $exit, $command, $output;
      print "not ok $test\n";
   } else {
      print "ok $test\n";
   }
}

print qx<sh bin/staticperl version> =~ /staticperl version / ? "" : "not ", "ok 1\n";

tryrun 2, "sh bin/staticperl install";
tryrun 3, "sh bin/staticperl instcpan Games::Go::SimpleBoard";
tryrun 4, "sh bin/staticperl mkapp $PFX/perl.bin -MGames::Go::SimpleBoard";
tryrun 5, "$PFX/perl.bin -e0";
tryrun 6, "$PFX/perl.bin -MGames::Go::SimpleBoard -e0";
tryrun 7, "sh bin/staticperl mkapp $PFX/perl.bin -MGames::Go::SimpleBoard -MPOSIX";
tryrun 8, "$PFX/perl.bin -e0";
tryrun 9, "$PFX/perl.bin -MPOSIX -e0";


