#!/usr/bin/env perl
#
# takes a list of xml data files and creates a module providing constants
#
# options:
#   -o output filename
#   -s sort order the constants
#   -t output raku (or use other language templates)

use v5.20;
use Carp;
use Data::Dumper;
use FindBin qw($Dir);
use Getopt::Long;
use Module::Util qw(is_valid_module_name module_path);
use Mojo::Template;
use XML::LibXML;

my $name = 'Astro::Constants';
my $template = 'perl';

GetOptions(
    'help|?'       => \my $help,
    'name|n=s'     => \$name,
    'output|o=s'   => \my $output,
    'sort|s'       => \my $sort,
    'template|t=s' => \$template,
    'verbose|s'    => \my $verbose,
);

if ($help) {
    print show_usage();
    exit;
}

die "No files given\n\t", show_usage() unless @ARGV;
die "Invalid module name $name" unless is_valid_module_name($name);

# TODO - implement options
warn "sort not in use" if $sort;
warn "verbose not in use" if $verbose;
$output ||= join '/', $Dir, qw(.. lib), module_path($name);

my %t = get_templates($template);
my $mt = Mojo::Template->new;

my (@constants, $tagname, %precision, $processed, );

for my $datafile ( @ARGV ) {
    unless (-e $datafile) {
        warn "File $datafile does not exist";
        next;
    }
    my $xml = XML::LibXML->load_xml(location => $datafile);

    for my $element ( $xml->getElementsByTagName('PhysicalConstant') ) {
        my $constant = extract_constant($element);
        next unless $constant->{name};

        push @constants, $constant;
	    push @{$tagname->{all}}, $constant->{name};

	    for my $category ( $constant->{categories}->@* ) {
		    push @{$tagname->{$category}}, $constant->{name};
		    push @{$tagname->{$category}}, $constant->{alternates}->@*
                if exists $constant->{alternates};
	    }
	}
}

#### output module templates
open my $fh, '>', $output or die "Couldn't write to $output: $!\n";
# TODO do the loops in the templates
say $fh $mt->render($t{module_header}, $name, '2018 CODATA');
for my $constant ( @constants ) {
    print $fh $mt->render($t{constant_code}, $constant);
}
say $fh $mt->render($t{module_middle}, %precision, %precision);
for my $constant ( @constants ) {
    print $fh $mt->render($t{constant_docs}, $constant);
}
# TODO add =cut to finish POD
print $fh $mt->render($t{module_footer}, $tagname );

=pod

TODO write precision values into module available for the precision() sub
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

	say $fh 'my %_precision = (';
	for my $name (sort keys %precision) {
		my ($value, $type) = @{$precision{$name}}{qw(value type)};
		say $fh "\t$name \t=> {value => $value, \ttype => '$type'},";
	}
	say $fh ');';
}

=cut

exit;

sub get_templates {
# TODO move templates to files in /templates and store filenames in %template
    my $style = shift;

    my %template = (
        perl => {
            module_header => <<'EOT',
% my ($name, $source) = @_;
package <%= $name %>;
# ABSTRACT: Perl library to provide physical constants for use in Physics and Astronomy based on values from <%= $source %>.
#
#  They are not constant but are changing still. - Cymbeline, Act II, Scene 5

use 5.006;
use strict;
use warnings;

use base qw(Exporter);

=encoding utf8

=head1 SYNOPSIS

    use strict;
    use Astro::Constants qw( :all );

    # to calculate the gravitational force of the Sun on the Earth
    # in Newtons, use GMm/r^2
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

The C<:all> tag imports all the constants in their long name forms
(i.e. GRAVITATIONAL).  Useful subsets can be imported with these tags:
C<:fundamental> C<:conversion> C<:mathematics> C<:cosmology>
C<:planetary> C<:electromagnetic> or C<:nuclear>.
Alternate names such as LIGHT_SPEED instead of SPEED_LIGHT or HBAR
instead of H_BAR are imported with C<:alternates>.  I'd like
to move away from their use, but they have been in the module for years.

Long name constants are constructed with the L<constant> pragma and
are not interpolated in double quotish situations because they are
really inlined functions.
Short name constants were constructed with the age-old idiom of fiddling
with the symbol table using typeglobs, e.g. C<*PI = \3.14159>,
and can be slower than the long name constants.

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
* C<:all>             (everything except :deprecated)
* C<:fundamental>
* C<:conversion>
* C<:mathematics>
* C<:cosmology>
* C<:planetary>
* C<:electromagnetic>
* C<:nuclear>
* C<:alternates>
* C<:deprecated>
=cut

EOT

            module_middle => <<'EOT',
% my %precision = @_;

my %_precision = (
% for my $name (sort keys %precision) {
  % my ($value, $type) = @{$precision{$name}}{qw(value type)};
    <%= $name %> => {value => <%= $value %>, type => '<%= $type %>'},
% }
);
EOT

            module_footer => <<'EOT',
% my $tags = shift;

=head1 FUNCTIONS

=head2 pretty

This is a helper function that rounds a value or list of values to 5 significant figures.

=head2 precision

Give this method the string of the constant and it returns the precision or uncertainty
listed.

  $rel_precision = precision('GRAVITATIONAL');
  $abs_precision = precision('MASS_EARTH');

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
* L<Astronomical Constants 2016|http://asa.usno.navy.mil/static/files/2016/Astronomical_Constants_2016.pdf>
* L<IAU recommendations concerning units|https://www.iau.org/publications/proceedings_rules/units>
* L<Re-definition of the Astronomical Unit|http://syrte.obspm.fr/IAU_resolutions/Res_IAU2012_B2.pdf>

=head1 REPOSITORY

* L<github|https://github.com/duffee/Astro-Constants>

=head1 ISSUES

Feel free to file bugs or suggestions in the
L<Issues|https://github.com/duffee/Astro-Constants/issues> section of the Github repository.

Using C<strict> is a must with this code.  Any constants you forgot to import will
evaluate to 0 and silently introduce errors in your code.  Caveat Programmer.

If you are using this module, drop me a line using any available means at your
disposal, including
*gasp* email (address in the Author section), to let me know how you're using it.
What new features would you like to see?

Current best method to contact me is via a Github Issue.

=head2 Extending the data set

If you want to add in your own constants or override the factory defaults,
run make, edit the F<PhysicalConstants.xml> file and then run C<dzil build> again.
If you have a pre-existing F<PhysicalConstants.xml> file, drop it in place
before running C<dzil build>.

=head2 Availability

the original astroconst sites have disappeared

=head1 ROADMAP

I have moved to a I<noun_adjective> format for long names.
LIGHT_SPEED and SOLAR_MASS become SPEED_LIGHT and MASS_SOLAR.
This principle should make the code easier to read with the most
important information coming at the beginning of the name.
See also L<Astro::Constants::Roadmap>

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

# some helper functions
sub pretty {
    if (@_ > 1) {
        return map { sprintf("%1.3e", $_) } @_;
    }
    return sprintf("%1.3e", shift);
}

sub precision {
    my ($name, $type) = @_;
    warn "precision() requires a string, not the constant value"
        unless exists $_precision{$name};

    return $_precision{$name}->{value};
}

our @EXPORT_OK = qw(
    <%= join q{ }, $tags->{all}->@*, $tags->{alternates}->@* %>
    pretty precision
);

our %EXPORT_TAGS = (
% for my $name (sort keys $tags->%* ) {
    <%= $name %> => [qw( <%= join q{ }, $tags->{$name}->@* %> )],
% }
);

1; # Perl is my Igor
EOT

            constant_code => <<'EOT',
% my $c = shift;
% if ($c->{deprecated}) {
sub <%= $c->{name} %> { warn "<%= $c->{name} %> deprecated"; return <%= $c->{value} %>; }
% } else {
use constant <%= uc $c->{name} %> => <%= $c->{value} %>;
  % if ($c->{alternates}) {
    % for my $alt_name ( $c->{alternates}->@* ) {
use constant <%= uc $alt_name %> => <%= $c->{value} %>;
    % }
  % }
% }
EOT

            constant_docs => <<'EOT',
% my $c = shift;
% my $unit;
=constant <%= uc $c->{name} %>

    <%= $c->{value} %><%= q{ } . $unit if $unit %>

<%= $c->{description} %>
<% if ($c->{alternates}) { %>
  % if ($c->{alternates}->@* > 1) {
This constant is also available using these alternate names (imported using the :alternate tag): <%= join ', ', $c->{alternates}->@* %>
  % } else {
This constant is also available using the alternate name C<<%= $c->{alternates}[0] %>>
(imported using the :alternate tag for backwards compatibility)
  % }
<% } %>
EOT
        },
    );

    unless (exists $template{$style}) {
        carp "No templates available for $style. Using default 'perl'\n";
        $style = 'perl';
    }

    return $template{$style}->%*;
}

sub show_usage {
    return "Usage: $0 [hnostv] xml_file(s)\n";
}

sub store_precision {
	my ($name, $precision, $type) = @_;

	if ($type eq 'defined') {
		$type = 'relative';
		$precision = 0;
	}
	$precision{$name}->{value} = $precision;
	$precision{$name}->{type} = $type;
}

sub extract_constant {
    my $element = shift;

	my $name        = $element->getChildrenByTagName('name')->shift()->textContent();
    my $description = $element->getChildrenByTagName('description')->shift()->textContent();
    chomp $description;

    my $constant = {
        name        => $name,
        value       => $element->getChildrenByTagName('value')->shift()->textContent(),
        description => $description,
    };

	# recognise that there can be more than one alternateName
	my $alternate = undef;
	my @alternates = ();
	if ( $element->getChildrenByTagName('alternateName') ) {
		for my $node ( $element->getChildrenByTagName('alternateName') ) {
			$alternate = $node->textContent();
			next unless $alternate =~ /\S/;

			push @{$tagname->{alternates}}, $alternate;
			if ($node->hasAttribute('type') && $node->getAttribute('type') eq 'deprecated') {
				push @{$tagname->{deprecated}}, $alternate;
			}
			else {
				push @{$tagname->{all}}, $alternate;
			}
			push @alternates, $alternate;
		}
	}
	$constant->{alternates} = \@alternates if @alternates;
	$constant->{deprecated} = 1 if $element->getChildrenByTagName('deprecated');

    my @categories;
    for my $cat_node ( $element->getElementsByTagName('category') ) {
		my $category =	$cat_node->textContent();
		next unless $category;
		push @categories, $category;
	}
    $constant->{categories} = \@categories if @categories;

	my $precision = $element->getChildrenByTagName('uncertainty')->shift();
	store_precision($name,
		$precision->textContent(),
		$precision->getAttribute('type'));

    return $constant;
}
