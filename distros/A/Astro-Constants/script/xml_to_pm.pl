#!/usr/bin/perl -w
#
# builds the Astro::Constants modules from an xml definition file
# Boyd Duffee, Dec 2015
#
# hard coded to run from top directory and uses only data/PhysicalConstants.xml

use strict;
use autodie;
use Modern::Perl;
use XML::LibXML;

#die "Usage: $0 infile outfile" unless @ARGV == 1;

my ($tagname, );
my $dzil_methodtag = q{=method};

my $xml = XML::LibXML->load_xml(location => 'data/PhysicalConstants.xml');

my $lib = 'lib';	# where is the lib directory
mkdir "$lib/Astro/Constants" unless -d "$lib/Astro/Constants";
open my $ac_fh, '>:utf8', "$lib/Astro/Constants.pm";
open my $mks_fh, '>:utf8', "$lib/Astro/Constants/MKS.pm";
open my $cgs_fh, '>:utf8', "$lib/Astro/Constants/CGS.pm";

write_module_header($ac_fh, 'Astro::Constants');
write_module_header($mks_fh, 'Astro::Constants::MKS');
write_module_header($cgs_fh, 'Astro::Constants::CGS');

write_pod_synopsis($ac_fh);

for my $constant ( $xml->getElementsByTagName('PhysicalConstant') ) {
	my ($short_name, $long_name, $mks_value, $cgs_value, $values, $options, ) = undef;

	for my $name ( $constant->getChildrenByTagName('name') ) {
		$short_name = $name->textContent() if $name->getAttribute('type') eq 'short';
		$long_name = $name->textContent() if $name->getAttribute('type') eq 'long';
	}

	my $description = $constant->getChildrenByTagName('description')->shift()->textContent();
	for my $value ( $constant->getChildrenByTagName('value') ) {
		if ( $value->hasAttribute('system') ) {
			$values->{mks} = $value->textContent() if $value->getAttribute('system') eq 'MKS';
			$values->{cgs} = $value->textContent() if $value->getAttribute('system') eq 'CGS';
		}
		else {
			$values->{value} = $value->textContent();
			next;
		}
	}

	# recognise that there can be more than one alternateName
	my $alternate = undef;
	my @alternates = ();
	if ( $constant->getChildrenByTagName('alternateName') ) {
		for my $node ( $constant->getChildrenByTagName('alternateName') ) {
			$alternate = $node->textContent();
			next unless $alternate =~ /\S/;

			push @{$tagname->{alternates}}, $alternate;
			if ($node->hasAttribute('type') && $node->getAttribute('type') eq 'deprecated') {
				push @{$tagname->{deprecated}}, $alternate;
			}
			else {
				push @{$tagname->{long}}, $alternate;
			}
			push @alternates, $alternate;

			write_constant($mks_fh, ($values->{mks} || $values->{value}), $alternate) 
				if $values->{mks} || $values->{value};
			write_constant($cgs_fh, ($values->{cgs} || $values->{value}), $alternate) 
				if $values->{cgs} || $values->{value};
		}
	}
	$options->{deprecated} = 1 if $constant->getChildrenByTagName('deprecated');

	#### write to the module files
	write_method_pod($ac_fh, $long_name, $short_name, $description, $values, \@alternates);
	write_constant($mks_fh, ($values->{mks} || $values->{value}), $long_name, $short_name, $options) 
			if $values->{mks} || $values->{value};
	write_constant($cgs_fh, ($values->{cgs} || $values->{value}), $long_name, $short_name) 
			if $values->{cgs} || $values->{value};

	push @{$tagname->{long}}, $long_name if $long_name;
	push @{$tagname->{short}}, '$' . $short_name if $short_name;
		

	for my $cat_node ( $constant->getElementsByTagName('category') ) {
		my $category =	$cat_node->textContent();
		next unless $category;
		push @{$tagname->{$category}}, $long_name;
		push @{$tagname->{$category}}, $alternate if $alternate;
	}

	my $precision = $constant->getChildrenByTagName('uncertainty')->shift();
	store_precision($long_name, 
		$precision->textContent(), 
		$precision->getAttribute('type'));
}

write_pod_footer($ac_fh);
write_module_footer($mks_fh, $tagname);
write_module_footer($cgs_fh, $tagname);

exit;

####

sub write_module_header {
	my ($fh, $name) = @_;

	print $fh <<HEADER;
package $name;
# ABSTRACT: This library provides physical constants for use in Physics and Astronomy based on values from 2018 CODATA.

use 5.006;
use strict;
use warnings;
HEADER
	if ($name eq 'Astro::Constants') {
		print $fh "\n  'They are not constant but are changing still. - Cymbeline, Act II, Scene 5';\n\n";
	}
	else {
		print $fh "use base qw/Exporter/;\n\n";
	}
	if ($name eq 'Astro::Constants::CGS') {
		print $fh <<"NOTICE";
warn "use of $name is deprecated and will be removed from the package in version 0.15";
warn "write new code to use Astro::Constants::MKS instead";

=head1 NOTICE OF DEPRECATION

This module is now deprecated and will be removed from the package in version 0.15.
Write new code to use L<Astro::Constants> or check the documentation.
The IAU stopped using cgs units last century, so it's about time this module was archived.

=cut


NOTICE
	}
}

sub write_module_footer {
	my ($fh, $tags) = @_;

	write_precision($fh);

	print $fh <<FOOT;

# some helper functions
sub pretty {
	if (\@_ > 1) {
		return map { sprintf("\%1.3e", \$_) } \@_;
	}
	return sprintf("\%1.3e", shift);
}

sub precision {
	my (\$name, \$type) = \@_;
	warn "precision() requires a string, not the constant value" 
		unless exists \$_precision{\$name};

	return \$_precision{\$name}->{value};
}

our \@EXPORT_OK = qw( 
	@{$tags->{long}}
	@{$tags->{short}}
	@{$tags->{alternates}}
	pretty precision
);

our \%EXPORT_TAGS = (
FOOT

	for my $name (sort keys %{$tags}) {
		print $fh "\t$name => [qw/ @{$tags->{$name}} /],\n";
	}

	print $fh ");\n";
	print $fh "push \@EXPORT_OK, qw/@{$tags->{deprecated}}/;\n" 
		if exists $tags->{deprecated} && @{$tags->{deprecated}};
	print $fh <<FOOT;

'Perl is my Igor';
FOOT

}

sub write_method_pod {
	my ($fh, $long_name, $short_name, $description, $values, $alt_ref, ) = @_;

	my $display;
	$display .= "    $values->{mks}\tMKS\n" if $values->{mks};
	$display ||= "    $values->{value}\n";

	say $fh <<"POD";	# writing for Dist::Zilla enhanced Pod

$dzil_methodtag $long_name

$display
$description

POD
	say $fh "This constant is also available using the short name C<\$$short_name>" if $short_name;
	if ($short_name && @$alt_ref > 1) {
		say $fh 'as well as these alternate names (imported using the :alternate tag): ', join ', ', @$alt_ref;
	}
	elsif ($short_name && @$alt_ref) {
		say $fh 'as well as the alternate name C<', $alt_ref->[0], 
				"> (imported using the :alternate tag for backwards compatibility)";
	}
	elsif (@$alt_ref > 1) {
		say $fh "This constant is also available using these alternate names (imported using the :alternate tag): ", 
				join ', ', @$alt_ref;
	}
	elsif (@$alt_ref) {
		say $fh "This constant is also available using the alternate name C<", $alt_ref->[0], 
                "> (imported using the :alternate tag for backwards compatibility)";
	}
	print $fh "\n";
}

sub write_pod_synopsis {
	my ($fh, ) = @_;

	say $fh <<'POD';
=head1 SYNOPSIS

    use strict;		# important!
    use Astro::Constants::MKS qw/:long/;

    # to calculate the gravitational force of the Sun on the Earth in Newtons, use GMm/r^2
    my $force_sun_earth = GRAVITATIONAL * MASS_SOLAR * MASS_EARTH / ASTRONOMICAL_UNIT**2;

=head1 DESCRIPTION

This module provides physical and mathematical constants for use
in Astronomy and Astrophysics.

The values are stored in F<Physical_Constants.xml> in the B<data> directory
and are mostly based on the 2018 CODATA values from NIST.

B<NOTE:> Other popular languages are still using I<2014> CODATA values
for their constants and may produce different results in comparison.
On the roadmap is a set of modules to allow you to specify the year or
data set for the values of constants, defaulting to the most recent.

The C<:long> tag imports all the constants in their long name forms
(i.e. GRAVITATIONAL).  Useful subsets can be imported with these tags:
C<:fundamental> C<:conversion> C<:mathematics> C<:cosmology> 
C<:planetary> C<:electromagnetic> or C<:nuclear>.
Alternate names such as LIGHT_SPEED instead of SPEED_LIGHT or HBAR
instead of H_BAR are imported with C<:alternates>.  I'd like
to move away from their use, but they have been in the module for years.
Short forms of the constant names are included to provide backwards
compatibility with older versions based on Jeremy Bailin's Astroconst
library and are available through the import tag C<:short>.

Long name constants are constructed with the L<constant> pragma and
are not interpolated in double quotish situations because they are 
really inlined functions.
Short name constants are constructed with the age-old idiom of fiddling
with the symbol table using typeglobs, e.g. C<*PI = \3.14159>,
and may be slower than the long name constants.

=head2 Why use this module

You are tired of typing in all those numbers and having to make sure that they are
all correct.  How many significant figures is enough or too much?  Where's the
definitive source, Wikipedia?  And which mass does "$m1" refer to, solar or lunar?

The constant values in this module are protected against accidental re-assignment
in your code.  The test suite protects them against accidental finger trouble in my code. 
Other people are using this module, so more eyeballs are looking for errors
and we all benefit.  The constant names are a little longer than you might like,
but you gain in the long run from readable, sharable code that is clear in meaning.
Your programming errors are a little easier to find when you can see that the units 
don't match.  Isn't it reassuring that you can verify how a number is produced
and which meeting of which standards body is responsible for its value?

Trusting someone else's code does carry some risk, which you I<should> consider, 
but have you also considered the risk of doing it yourself with no one else 
to check your work?  And, are you going to check for the latest values from NIST
every 4 years?

=head3 And plus, it's B<FASTER>

Benchmarking has shown that the imported constants can be more than 3 times
faster than using variables or other constant modules because of the way
the compiler optimizes your code.  So, if you've got a lot of calculating to do,
this is the module to do it with.

=head1 EXPORT

Nothing is exported by default, so the module doesn't clobber any of your variables.  
Select from the following tags:

=for :list
* C<:long>                (use this one to get the most constants)
* C<:short>
* C<:fundamental>
* C<:conversion>
* C<:mathematics>
* C<:cosmology>
* C<:planetary>
* C<:electromagnetic>
* C<:nuclear>
* C<:alternates>

POD
}

sub write_pod_footer {
	my ($fh, ) = @_;

	say $fh <<POD;
$dzil_methodtag pretty

This is a helper function that rounds a value or list of values to 5 significant figures.

$dzil_methodtag precision

Give this method the string of the constant and it returns the precision or uncertainty
listed.

  \$rel_precision = precision('GRAVITATIONAL');
  \$abs_precision = precision('MASS_EARTH');

At the moment you need to know whether the uncertainty is relative or absolute.
Looking to fix this in future versions.

=head2 Deprecated functions

I've gotten rid of C<list_constants> and C<describe_constants> because they are now in
the documentation.  Use C<perldoc Astro::Constants> for that information.

=head1 SEE ALSO

=for :list
* L<Astro::Cosmology>
* L<Perl Data Language|PDL>
* L<NIST|http://physics.nist.gov>
* L<Astronomical Almanac|http://asa.usno.navy.mil>
* L<IAU 2015 Resolution B3|http://iopscience.iop.org/article/10.3847/0004-6256/152/2/41/meta>
* L<Neil Bower's review on providing read-only values|http://neilb.org/reviews/constants.html>
* L<Test::Number::Delta>
* L<Test::Deep::NumberTolerant> for testing values within objects

Reference Documents:

=for :list
* L<IAU 2009 system of astronomical constants|http://aa.usno.navy.mil/publications/reports/Luzumetal2011.pdf>
* L<Astronomical Constants 2016.pdf|http://asa.usno.navy.mil/static/files/2016/Astronomical_Constants_2016.pdf>
* L<IAU recommendations concerning units|https://www.iau.org/publications/proceedings_rules/units>
* L<Re-definition of the Astronomical Unit|http://syrte.obspm.fr/IAU_resolutions/Res_IAU2012_B2.pdf>

=head1 REPOSITORY

* L<https://github.com/duffee/Astro-Constants>

=head1 ISSUES

File issues/suggestions at the Github repository L<https://github.com/duffee/Astro-Constants>.
The venerable L<RT|https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=Astro-Constants>
is the canonical bug tracker that is clocked by L<meta::cpan|https://metacpan.org/pod/Astro::Constants>.

Using C<strict> is a must with this code.  Any constants you forgot to import will
evaluate to 0 and silently introduce errors in your code.  Caveat Programmer.

If you are using this module, drop me a line using any available means at your 
disposal, including
*gasp* email (address in the Author section), to let me know how you're using it. 
What new features would you like to see?
If you've had an experience with using the module, let other people know what you
think, good or bad, by rating it at
L<cpanratings|http://cpanratings.perl.org/rate/?distribution=Astro-Constants>.

=head2 Extending the data set

If you want to add in your own constants or override the factory defaults,
run make, edit the F<PhysicalConstants.xml> file and then run C<dzil build> again.
If you have a pre-existing F<PhysicalConstants.xml> file, drop it in place
before running C<dzil build>.

=head2 Availability

the original astroconst sites have disappeared

=head1 ROADMAP

I plan to deprecate the short names and change the order in which
long names are constructed, moving to a I<noun_adjective> format.
LIGHT_SPEED and SOLAR_MASS become SPEED_LIGHT and MASS_SOLAR.
This principle should make the code easier to read with the most
important information coming at the beginning of the name.

=head1 ASTROCONST  X<ASTROCONST>

(Gleaned from the Astroconst home page -
L<astroconst.org|http://web.astroconst.org> )

Astroconst is a set of header files in various languages (currently C,
Fortran, Perl, Java, IDL and Gnuplot) that provide a variety of useful
astrophysical constants without constantly needing to look them up.

The generation of the header files from one data file is automated, so you
can add new constants to the data file and generate new header files in all
the appropriate languages without needing to fiddle with each header file
individually.

This package was created and is maintained by Jeremy Bailin.  It's license
states that it I<is completely free, both as in speech and as in beer>.

=head1 DISCLAIMER

No warranty expressed or implied.  This is free software.  If you
want someone to assume the risk of an incorrect value, you better
be paying them.

(What would you want me to test in order for you to depend on this module?)

I<from Jeremy Bailin's astroconst header files>

The Astroconst values have been gleaned from a variety of sources,
and have quite different precisions depending both on the known
precision of the value in question, and in some cases on the
precision of the source I found it from. These values are not
guaranteed to be correct. Astroconst is not certified for any use
whatsoever. If your rocket crashes because the precision of the
lunar orbital eccentricity isn't high enough, that's too bad.

=head1 ACKNOWLEDGMENTS

Jeremy Balin, for writing the astroconst package and helping
test and develop this module.

Doug Burke, for giving me the idea to write this module in the
first place, tidying up Makefile.PL, testing and improving the
documentation.

=cut

POD
}

sub write_constant {
	my ($fh, $value, $long_name, $short_name, $options) = @_;

	if ($options && $options->{deprecated}) {
		print $fh <<"WARNING";
sub $long_name { warn "$long_name deprecated"; return $value; }
WARNING
	}
	else {
		say $fh "use constant $long_name => $value;";
		say $fh "\*$short_name = \\$value;" if $short_name;
	}
}

my %precision;
sub store_precision {
	my ($name, $precision, $type) = @_;

	if ($type eq 'defined') {
		$type = 'relative';
		$precision = 0;
	}
	$precision{$name}->{value} = $precision;
	$precision{$name}->{type} = $type;
}

sub write_precision {
	my ($fh) = @_;

	say $fh "\n", 'my %_precision = (';
	for my $name (sort keys %precision) {
		my ($value, $type) = @{$precision{$name}}{qw/value type/};
		say $fh "\t$name \t=> {value => $value, \ttype => '$type'},"; 
	}
	say $fh ');';
}
