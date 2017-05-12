#!/usr/bin/perl
# 07_a.t (was border.t). Test Border stuff.

use strict;
use Acme::EyeDrops qw(sightly get_eye_string);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d or die "write '$f': $!"; close(F);
}

# --------------------------------------------------

print "1..16\n";

my $hellostr = <<'HELLO';
print "hello world\n";
HELLO
my $camelstr  = get_eye_string('camel');
my $camel2str = $camelstr . "\n\n\n" . $camelstr;
my $tmpf = 'bill.tmp';

# Test bailing out via InformHandler when presented with a
# diabolical shape which sends sightly() into an infinite loop.
my $max_shapes = 5;
my $exp_throw_str = "bailing out after " . ($max_shapes+1) . " shapes.\n";
sub throw_inform {
   $_[0] =~ /^(\d+) / or die "oops, invalid ihandler string";
   $1 > $max_shapes and die "bailing out after $1 shapes.\n";
}

# Simple test of InformHandler.
my $inform_string;
sub test_inform { $inform_string .= $_[0] }

# -------------------------------------------------

my $itest = 0;
my $prog;

# -------------------------------------------------

eval {
   sightly( { ShapeString    => "#\n#\n#\n#\n#\n",
              SourceString   => "# Example nasty shape\n;1;\n",
              InformHandler  => \&throw_inform,
              Regex          => 1 } );
};
$@ or print "not ";
++$itest; print "ok $itest - InformHandler throw\n";
$@ eq $exp_throw_str or print "not ";
++$itest; print "ok $itest - InformHandler throw string\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  BorderWidth   => 2,
                  BorderGap     => 1,
                  InformHandler => \&test_inform,
                  Regex         => 1 } );
build_file($tmpf, $prog);
my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest\n";
$outstr eq "hello world\n" or print "not ";
++$itest; print "ok $itest\n";
$prog =~ tr/!-~/#/;
my @lines = split(/^/, $prog, -1);
scalar(@lines) > 6 or print "not ";
++$itest; print "ok $itest\n";
pop(@lines);pop(@lines);pop(@lines);
shift(@lines);shift(@lines);shift(@lines);
$prog = join("", @lines);
$prog =~ s/^.+\n// if $] >= 5.017;   # remove leading use re 'eval' line
$prog =~ s/^## //mg; $prog =~ s/ ##$//mg; $prog =~ s/ +$//mg;
$prog eq $camelstr or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------
# Same again, but exercise Left/Right/Top/Bottom

$prog = sightly({ Shape              => 'camel',
                  SourceString       => $hellostr,
                  BorderWidthLeft    => 2,
                  BorderWidthRight   => 2,
                  BorderWidthTop     => 2,
                  BorderWidthBottom  => 2,
                  BorderGapLeft      => 1,
                  BorderGapRight     => 1,
                  BorderGapTop       => 1,
                  BorderGapBottom    => 1,
                  InformHandler      => \&test_inform,
                  Regex              => 1 } );
build_file($tmpf, $prog);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest\n";
$outstr eq "hello world\n" or print "not ";
++$itest; print "ok $itest\n";
$prog =~ tr/!-~/#/;
@lines = split(/^/, $prog, -1);
scalar(@lines) > 6 or print "not ";
++$itest; print "ok $itest\n";
pop(@lines);pop(@lines);pop(@lines);
shift(@lines);shift(@lines);shift(@lines);
$prog = join("", @lines);
$prog =~ s/^.+\n// if $] >= 5.017;   # remove leading use re 'eval' line
$prog =~ s/^## //mg; $prog =~ s/ ##$//mg; $prog =~ s/ +$//mg;
$prog eq $camelstr or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------
# This test failed prior to EyeDrops.pm version 1.41.

$prog = sightly({ Shape         => 'camel,camel',
                  SourceString  => $hellostr,
                  BorderWidth   => 2,
                  BorderGap     => 1,
                  Gap           => 3,
                  InformHandler => \&test_inform,
                  Regex         => 1 } );
build_file($tmpf, $prog);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest\n";
$outstr eq "hello world\n" or print "not ";
++$itest; print "ok $itest\n";
$prog =~ tr/!-~/#/;
@lines = split(/^/, $prog, -1);
scalar(@lines) > 6 or print "not ";
++$itest; print "ok $itest\n";
pop(@lines);pop(@lines);pop(@lines);
shift(@lines);shift(@lines);shift(@lines);
$prog = join("", @lines);
$prog =~ s/^.+\n// if $] >= 5.017;   # remove leading use re 'eval' line
$prog =~ s/^## //mg; $prog =~ s/ ##$//mg; $prog =~ s/ +$//mg;
$prog eq $camel2str or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------

$inform_string eq "1 shapes completed.\n" x 3 or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------
# ShapeString join v Shape/Gap multiple shapes

sightly( { ShapeString   => join("\n",
                            get_eye_string('camel'),
                            get_eye_string('mongers')),
           SourceString  => $hellostr,
           Gap           => 0,
           InformHandler => sub {},
           Regex         => 1 } )
eq
sightly( { Shape         => 'camel,mongers',
           SourceString  => $hellostr,
           Gap           => 1,
           InformHandler => sub {},
           Regex         => 1 } ) or print "not ";
++$itest; print "ok $itest - join v gap the same\n";

# -------------------------------------------------

unlink($tmpf) or die "error: unlink '$tmpf': $!";
