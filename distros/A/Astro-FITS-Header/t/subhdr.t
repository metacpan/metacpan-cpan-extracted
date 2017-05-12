#!perl

# Test that sub-headers work correctly
# Needs a better suite of tests.
use strict;
use Test::More tests => 28;

require_ok( "Astro::FITS::Header" );
require_ok( "Astro::FITS::Header::Item");


# Force numify to return the actual object reference.
# This allows us to verify that a header stored through
# a tie does not get reblessed or stringified.
package Astro::FITS::Header;
use overload '0+' => 'fudge', fallback => 1;
sub fudge { return $_[0] }
package main;

# build a test card
my $int_card = new Astro::FITS::Header::Item(
                               Keyword => 'LIFE',
                               Value   => 42,
                               Comment => 'Life the Universe and everything',
                               Type    => 'INT' );

# build another
my $string_card = new Astro::FITS::Header::Item(
                               Keyword => 'STUFF',
                               Value   => 'Blah Blah Blah',
                               Comment => 'So long and thanks for all the fish',
			       Type    => 'STRING' );

# and another
my $another_card = new Astro::FITS::Header::Item(
                               Keyword => 'VALUE',
                               Value   => 34.5678,
                               Comment => 'A floating point number',
                               Type    => 'FLOAT' );

# and another for the array
my $x = "AA";
my @h1 = map { $x++; new Astro::FITS::Header::Item( 
						   Keyword => "H1$x",
						   Value   => $x,
						   Comment => "$x th header",
						   Type    => "STRING",
						  )} (0..5);
my @h2 = map { $x++; new Astro::FITS::Header::Item( 
						   Keyword => "H2$x",
						   Value   => $x,
						   Comment => "$x th header",
						   Type    => "STRING",
						  )} (0..5);


# Form a header
my $hdr = new Astro::FITS::Header( Cards => [ $int_card, $string_card ]);

# and another header
my $subhdr = new Astro::FITS::Header( Cards => [ $another_card ]);
print "# Subhdr: $subhdr\n";

# now create an item pointing to that subhdr
my $subitem = new Astro::FITS::Header::Item(
					    Keyword => 'EXTEND',
					    Value => $subhdr,
					   );

# Add the item
$hdr->insert(0,$subitem);

# Now use the alternate array based interface
my $h1 = new Astro::FITS::Header( Cards => \@h1);
my $h2 = new Astro::FITS::Header( Cards => \@h2);
$hdr->subhdrs( $h1, $h2);

my @ret = $hdr->subhdrs;
is( scalar(@ret), 2, "Count number of subheaders");

#tie
my %header;
tie %header, ref($hdr), $hdr;

# Add another item
$header{EXTEND2} = $subhdr;
is($header{EXTEND2}{VALUE},34.5678 );

# test that we have the correct type
# This should be a hash
is( ref($header{EXTEND}), "HASH");

# And this should be an Astro::FITS::Header
isa_ok( $hdr->value("EXTEND"), "Astro::FITS::Header");

# Now store a hash
$header{NEWHASH} = { A => 2, B => 3};
is( $header{NEWHASH}->{A}, 2);
is( $header{NEWHASH}->{B}, 3);

# Now store a tied hash
my %sub;
tie %sub, ref($subhdr), $subhdr;
$header{NEWTIE} = \%sub;
my $newtie = $header{NEWTIE};
my $tieobj = tied %$newtie;

# Check class
isa_ok( $tieobj, "Astro::FITS::Header");

# Make sure we have a long numification
my $tienum = 0 + $tieobj;
my $hdrnum = 0 + $subhdr;
ok( $tienum > 0);
ok( $hdrnum > 0);

# Compare memory addresses
is( $tienum, $hdrnum, "cf memory addresses" );

printf "# The tied object is: %s\n",0+$tienum;
printf "# The original object is:: %s\n",$hdrnum;

# test values
is($header{NEWTIE}->{VALUE}, $another_card->value);

# Test autovivification
# Note that $hdr{BLAH}->{YYY} = 5 does not work
my $void = $header{BLAH}->{XXX};
printf "# VOID is %s\n", defined $void ? $void : '(undef)';
is(ref($header{BLAH}), 'HASH');
$header{BLAH}->{XXX} = 5;
is($header{BLAH}->{XXX}, 5);

# Test tied array subheader
ok(exists $header{SUBHEADERS}, "Does the subheader exist?");
my $subh = $header{SUBHEADERS};
is( ref($subh), "ARRAY", "Do we have a tie?");
is(@$subh, 2, "Got correct number of array subheaders");
is($subh->[1]->{H2AM}, "AM", "array to tied hash");

# make sure we get SUBHEADERS as a valid key
my $got;
for my $k (keys %header) {
  $got = 1 if $k eq 'SUBHEADERS';
}
ok( $got, "SUBHEADERS appeared in foreach");

my $p = pop( @$subh );
is($p->{H2AM}, "AM", "pop?");

# push it back on the front
unshift( @$subh, $p);
is($subh->[0]->{H2AM}, "AM", "unshift?");

# shift it off
my $s = shift( @$subh );
is($s->{H2AM}, "AM", "shift?");

# and push it on the end
push(@$subh, $s);
is($subh->[1]->{H2AM}, "AM", "push?");

# Now remove the subhdrs using the tie
@$subh = ();

# store the subheader from the earlier item
$subh->[2] = $header{BLAH};
is($subh->[2]->{XXX}, 5);

# Store a hash
$subh->[3] = { AAA => "22"};
is($subh->[3]->{AAA}, 22);

# Clear using the objecy
@{ $hdr->subhdrs } = ();

ok(!exists $header{SUBHEADERS}, "Subheader should not exist");

# make sure we do not get SUBHEADERS as a valid key
$got = 0;
for my $k (keys %header) {
  $got = 1 if $k eq 'SUBHEADERS';
}
ok( !$got, "SUBHEADERS should not appear in foreach");

