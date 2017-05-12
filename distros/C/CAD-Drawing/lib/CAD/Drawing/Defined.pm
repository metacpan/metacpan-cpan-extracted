package CAD::Drawing::Defined;
our $VERSION = '0.62';

use warnings;
use strict;
use Carp;
use vars qw(
		@ISA
		@EXPORT
		$debug
		$linkdebug
		$loaddebug
		$colordebug
		%color_names
		%call_syntax
		%ac_storage_method
		%defaults
		@defaultkeys
		@std_opts_syntax
		$pi
		@aci2hex
		@aci2rgb
		);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
			$debug
			$linkdebug
			$loaddebug
			$colordebug
			%color_names
			%call_syntax
			%ac_storage_method
			%defaults
			@defaultkeys
			@std_opts_syntax
			$pi
			@aci2hex
			@aci2rgb
			check_select
			color_translate
			checkarcangs
			);
# @EXPORT_OK = qw(
# 			color_translate
# 			);
$debug = 0;
$linkdebug = 0;
$colordebug = 0;
$loaddebug = 0;

%defaults = (
	"layer" => "0",
	"color" => 256,
	"linetype" => "default",
	);

@defaultkeys = keys(%defaults);

########################################################################
=head1 NAME

CAD::Drawing::Defined - exported constants for CAD::Drawing::*

=head1 Description

Everything in this module is exported by default.  This module is not
intended to be used directly, but is required by each module in the
CAD::Drawing tree.

=head1 AUTHOR

Eric L. Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com

=head1 COPYRIGHT

This module is copyright (C) 2004-2006 by Eric L. Wilhelm.  Portions
copyright (C) 2003 by Eric L. Wilhelm and A. Zahner Co.

=head1 LICENSE

This module is distributed under the same terms as Perl.  See the Perl
source package for details.

You may use this software under one of the following licenses:

  (1) GNU General Public License
    (found at http://www.gnu.org/copyleft/gpl.html)
  (2) Artistic License
    (found at http://www.perl.com/pub/language/misc/Artistic.html)

=head1 NO WARRANTY

This software is distributed with ABSOLUTELY NO WARRANTY.  The author,
his former employer, and any other contributors will in no way be held
liable for any loss or damages resulting from its use.

=head1 Modifications

The source code of this module is made freely available and
distributable under the GPL or Artistic License.  Modifications to and
use of this software must adhere to one of these licenses.  Changes to
the code should be noted as such and this notification (as well as the
above copyright information) must remain intact on all copies of the
code.

Additionally, while the author is actively developing this code,
notification of any intended changes or extensions would be most helpful
in avoiding repeated work for all parties involved.  Please contact the
author with any such development plans.

=cut
########################################################################

=head1 Useful Functions

These were functions that didn't seem appropriate as object-oriented but
were needed in multiple places.  They are exported by default (as is
nearly everything in this package.

=cut
########################################################################

=head2 check_select

Provides a uniform interface to selection processing.

NOTE:  this is not an object method and is exported by default!

Direct calling should be for internal use only, but you may have been
sent to this documentation by one of the modules which uses this
function to process %option arguments.

%opts hash may contain  (alias)

  Inclusive lists:
  "select layers"      (sl)
  "select colors"      (sc)
  "select types"       (st)
  "select linetypes"   (slt)

  Exclusive lists:
  "not layers"         (nl)
  "not colors"         (nc)
  "not types"          (nt)
  "not linetypes"      (nlt)

The values must be list references.

The space-separated terms in the keys above may now be underscore ("_")
separated as well (this saves having to double-quote the item when using
it as a hash key in the %options argument.)

If an option is omitted, all of that category are selected.

  ($s, $n) = check_select(\%selection_options);

$s will be a hash reference to inclusive items
$n will be a hash reference to excluded items

Keys in the returned hash references are according to the above-listed
alias conventions ($s->{l} contains a set of true values for selected
layers (where the layer name is a string acting as the hash key.))

Note that the \%selection_options hash reference is a required argument
(at this level.)  Any functions which make it optional must declare a
hash before passing to this.

=cut
sub check_select {
	my ($opt) = @_;
	my %opts = %$opt;
	my %s = (
		"l" => undef(),
		"c" => undef(),
		"t" =>  undef(),
		"lt" => undef(),
		);
	my %n = (
		"l" => undef(),
		"c" => undef(),
		"t" =>  undef(),
		"lt" => undef(),
		);
	my %res = ( "s" => \%s, "n" => \%n);
	my @choices = keys(%res);
	my %mapch = (
		"s" => "select",
		"n" => "not",
		);
	my %mapit = (
		"l" => "layers",
		"c" => "colors",
		"t" => "types",
		"lt" => "linetypes",
		);
	# $opts{sl} && print "wanted @{$opts{sl}}\n";
	foreach my $ch (@choices) {
		my $g = $res{$ch};
		foreach my $it (keys(%{$g})) {
			foreach my $alias ($ch . $it, $mapch{$ch}."_".$mapit{$it}) {
				$opts{$alias} && 
					($opts{"$mapch{$ch} $mapit{$it}"} = $opts{$ch.$it});
				# print "option $alias: $opts{$alias}\n";
			}
			if($opts{"$mapch{$ch} $mapit{$it}"}) {
				# print "$mapch{$ch} $mapit{$it}\n";
				my @list = @{$opts{"$mapch{$ch} $mapit{$it}"}};
				($it eq "c") && (@list = color_translate(@list));
				# print "($it) list: @list\n";
				$g->{$it} = {map({$_ => 1} @list)};
			}
			else {
				$g->{$it} = undef;
			}
		}
	}
	return(\%s, \%n);

} # end subroutine check_select definition
########################################################################

=head2 checkarcangs

Performs in-place modification of arc angles in \@angs.

NOTE:  this is not an object method and is exported by default!

Internal use only.

  checkarcangs(\@angs);

=cut
sub checkarcangs {
	my($ang) = @_;
	foreach my $d (0,1) {
		# print "got $$ang[$d] for an angle\n";
		if($$ang[$d] =~ s/d$//) {  
			# allow spec of angle in degrees with $angle . "d";
			$$ang[$d] *= $pi / 180;
			}
		while($$ang[$d] > $pi) {
			$$ang[$d] -= $pi * 2;
			}
		while($$ang[$d] <= -$pi) {
			$$ang[$d] += $pi * 2;
			}
		}
	} # end subroutine checkarcangs definition
########################################################################

=head2 color_translate

Translates a list of colors into numbers.  Numbers will be passed
through (as will unrecognized names!)

  @colors = color_translate(@colors);

=cut
sub color_translate {
	my(@list) = @_;
	foreach my $item (@list) {
		$linkdebug && print "got color for $item: $color_names{$item}\n";
		( defined($color_names{$item}) ) && ($item = $color_names{$item} );
		($item == int($item) ) or carp("don't know what to do with color: $item\n");
		}
	$#list || return($list[0]);	
	return(@list);

} # end subroutine color_translate definition
########################################################################

=head1 Various definitions

=head2 %color_names

Useful for humans.  Currently, these have to be statically defined here.
A better system might allow more spellings and user-defined names (maybe
loadable from a file.)

=cut

%color_names = (
	"byblock" => 0,
	"by block" => 0,
	"bylayer" => 256,
	"by layer" => 256,
	"red" => 1,
	"yellow" => 2,
	"green" => 3,
	"cyan" => 4,
	"blue" => 5,
	"magenta" => 6,
	"black" => 7,
	"darkgray" => 8,
	"darkgrey" => 8,
	"lightgray" => 9,
	"lightgrey" => 9,
	"charcoal" => 250,
	"white" => 255,
	);
########################################################################
# call syntax for add functions
# list only the non-standard options (as keys per the data-structure syntax)
# FIXME: need to define what is required separately from what is in the hash?
=head2 %call_syntax

used to allow other functions to decide how to handle various entities

=cut
%call_syntax = (
	"plines" 	=> 	[\&CAD::Drawing::addpolygon, "pts"], 
	"lines" 	=>	[\&CAD::Drawing::addline, "pts"],
	"texts"	=>	[\&CAD::Drawing::addtext, "pt", "string"],
	"points"	=>	[\&CAD::Drawing::addpoint, "pt"],
	"circles"	=>	[\&CAD::Drawing::addcircle, "pt", "rad"],
	"arcs"	=>	[\&CAD::Drawing::addarc, "pt", "rad", "angs"],
	"images"	=>	[\&CAD::Drawing::addimage, "pt"],
	);
#"

%ac_storage_method = (
	plines => "ocs",
	lines => "wcs",
	texts => "ocs",
	circles => "ocs",
	arcs => "ocs",
	points => "wcs",
	);
#"
########################################################################
$pi = atan2(1,1) * 4;

########################################################################
=head1 Big Constant arrays

=head2 @aci2hex

256 value array which contains #RRGGBB photo-style hex codes for each
aci color.  This is mostly hand-mapped.

=cut

@aci2hex = (
                "#FFFFFF", "#ff0000", "#ffff00", "#00ff00", #   0 -   3
                "#00ffff", "#0000ff", "#ff00ff", "#ffffff", #   4 -   7
                "#b2b2b2", "#c0c0c0", "#ff0000", "#ff8080", #   8 -  11
                "#a60000", "#a65353", "#800000", "#804040", #  12 -  15
                "#4c0000", "#4c2626", "#260000", "#261313", #  16 -  19
                "#ff4000", "#ff9f80", "#a62900", "#a66853", #  20 -  23
                "#802000", "#805040", "#4c1300", "#4c3026", #  24 -  27
                "#260a00", "#261813", "#ff8000", "#ffbf80", #  28 -  31
                "#a65300", "#a67c53", "#804000", "#806040", #  32 -  35
                "#4c2600", "#4c3926", "#261300", "#261d13", #  36 -  39
                "#ffbf00", "#ffdf80", "#a67c00", "#a69153", #  40 -  43
                "#806000", "#807040", "#4c3900", "#4c4326", #  44 -  47
                "#261d00", "#262113", "#ffff00", "#ffff80", #  48 -  51
                "#a6a600", "#a6a653", "#808000", "#808040", #  52 -  55
                "#4c4c00", "#4c4c26", "#262600", "#262613", #  56 -  59
                "#bfff00", "#dfff80", "#7ca600", "#91a653", #  60 -  63
                "#608000", "#708040", "#394c00", "#434c26", #  64 -  67
                "#1d2600", "#212613", "#80ff00", "#bfff80", #  68 -  71
                "#53a600", "#7ca653", "#408000", "#608040", #  72 -  75
                "#264c00", "#394c26", "#132600", "#1d2613", #  76 -  79
                "#40ff00", "#9fff80", "#29a600", "#68a653", #  80 -  83
                "#208000", "#508040", "#134c00", "#304c26", #  84 -  87
                "#0a2600", "#182613", "#00ff00", "#80ff80", #  88 -  91
                "#00a600", "#53a653", "#008000", "#408040", #  92 -  95
                "#004c00", "#264c26", "#002600", "#132613", #  96 -  99
                "#00ff40", "#80ff9f", "#00a629", "#53a668", # 100 - 103
                "#008020", "#408050", "#004c13", "#264c30", # 104 - 107
                "#00260a", "#132618", "#00ff80", "#80ffbf", # 108 - 111
                "#00a653", "#53a67c", "#008040", "#408060", # 112 - 115
                "#004c26", "#264c39", "#002613", "#13261d", # 116 - 119
                "#00ffbf", "#80ffdf", "#00a67c", "#53a691", # 120 - 123
                "#008060", "#408070", "#004c39", "#264c43", # 124 - 127
                "#00261d", "#132621", "#00ffff", "#80ffff", # 128 - 131
                "#00a6a6", "#53a6a6", "#008080", "#408080", # 132 - 135
                "#004c4c", "#264c4c", "#002626", "#132626", # 136 - 139
                "#00bfff", "#80dfff", "#007ca6", "#5391a6", # 140 - 143
                "#006080", "#407080", "#00394c", "#26434c", # 144 - 147
                "#001d26", "#132126", "#0080ff", "#80bfff", # 148 - 151
                "#0053a6", "#537ca6", "#004080", "#406080", # 152 - 155
                "#00264c", "#26394c", "#001326", "#131d26", # 156 - 159
                "#0040ff", "#809fff", "#0029a6", "#5368a6", # 160 - 163
                "#002080", "#405080", "#00134c", "#26304c", # 164 - 167
                "#000a26", "#131826", "#0000ff", "#8080ff", # 168 - 171
                "#0000a6", "#5353a6", "#000080", "#404080", # 172 - 175
                "#00004c", "#26264c", "#000026", "#131326", # 176 - 179
                "#4000ff", "#9f80ff", "#2900a6", "#6853a6", # 180 - 183
                "#200080", "#504080", "#13004c", "#30264c", # 184 - 187
                "#0a0026", "#181326", "#8000ff", "#bf80ff", # 188 - 191
                "#5300a6", "#7c53a6", "#400080", "#604080", # 192 - 195
                "#26004c", "#39264c", "#130026", "#1d1326", # 196 - 199
                "#bf00ff", "#df80ff", "#7c00a6", "#9153a6", # 200 - 203
                "#600080", "#704080", "#39004c", "#43264c", # 204 - 207
                "#1d0026", "#211326", "#ff00ff", "#ff80ff", # 208 - 211
                "#a600a6", "#a653a6", "#800080", "#804080", # 212 - 215
                "#4c004c", "#4c264c", "#260026", "#261326", # 216 - 219
                "#ff00bf", "#ff80df", "#a6007c", "#a65391", # 220 - 223
                "#800060", "#804070", "#4c0039", "#4c2643", # 224 - 227
                "#26001d", "#261321", "#ff0080", "#ff80bf", # 228 - 231
                "#a60053", "#a6537c", "#800040", "#804060", # 232 - 235
                "#4c0026", "#4c2639", "#260013", "#26131d", # 236 - 239
                "#ff0040", "#ff809f", "#a60029", "#a65368", # 240 - 243
                "#800020", "#804050", "#4c0013", "#4c2630", # 244 - 247
                "#26000a", "#261318", "#545454", "#767676", # 248 - 251
                "#989898", "#bbbbbb", "#dddddd", "#000000", # 252 - 255
		"#000000" # FIXME:  By-Layer and By-Block colors have been set as white
                );
########################################################################

=head2 @aci2rgb

Generated from @aci2hex for use in postscript and other items.  The idea
here is that it is a fairly small set of values and may as well have
been generated and placed in this file, rather than constantly
loading-down the tight loop of saving values to postscript.

=cut
@aci2rgb = (
		[255, 255, 255], [255,   0,   0], [255, 255,   0], [  0, 255,   0],
		[  0, 255, 255], [  0,   0, 255], [255,   0, 255], [255, 255, 255],
		[178, 178, 178], [192, 192, 192], [255,   0,   0], [255, 128, 128],
		[166,   0,   0], [166,  83,  83], [128,   0,   0], [128,  64,  64],
		[ 76,   0,   0], [ 76,  38,  38], [ 38,   0,   0], [ 38,  19,  19],
		[255,  64,   0], [255, 159, 128], [166,  41,   0], [166, 104,  83],
		[128,  32,   0], [128,  80,  64], [ 76,  19,   0], [ 76,  48,  38],
		[ 38,  10,   0], [ 38,  24,  19], [255, 128,   0], [255, 191, 128],
		[166,  83,   0], [166, 124,  83], [128,  64,   0], [128,  96,  64],
		[ 76,  38,   0], [ 76,  57,  38], [ 38,  19,   0], [ 38,  29,  19],
		[255, 191,   0], [255, 223, 128], [166, 124,   0], [166, 145,  83],
		[128,  96,   0], [128, 112,  64], [ 76,  57,   0], [ 76,  67,  38],
		[ 38,  29,   0], [ 38,  33,  19], [255, 255,   0], [255, 255, 128],
		[166, 166,   0], [166, 166,  83], [128, 128,   0], [128, 128,  64],
		[ 76,  76,   0], [ 76,  76,  38], [ 38,  38,   0], [ 38,  38,  19],
		[191, 255,   0], [223, 255, 128], [124, 166,   0], [145, 166,  83],
		[ 96, 128,   0], [112, 128,  64], [ 57,  76,   0], [ 67,  76,  38],
		[ 29,  38,   0], [ 33,  38,  19], [128, 255,   0], [191, 255, 128],
		[ 83, 166,   0], [124, 166,  83], [ 64, 128,   0], [ 96, 128,  64],
		[ 38,  76,   0], [ 57,  76,  38], [ 19,  38,   0], [ 29,  38,  19],
		[ 64, 255,   0], [159, 255, 128], [ 41, 166,   0], [104, 166,  83],
		[ 32, 128,   0], [ 80, 128,  64], [ 19,  76,   0], [ 48,  76,  38],
		[ 10,  38,   0], [ 24,  38,  19], [  0, 255,   0], [128, 255, 128],
		[  0, 166,   0], [ 83, 166,  83], [  0, 128,   0], [ 64, 128,  64],
		[  0,  76,   0], [ 38,  76,  38], [  0,  38,   0], [ 19,  38,  19],
		[  0, 255,  64], [128, 255, 159], [  0, 166,  41], [ 83, 166, 104],
		[  0, 128,  32], [ 64, 128,  80], [  0,  76,  19], [ 38,  76,  48],
		[  0,  38,  10], [ 19,  38,  24], [  0, 255, 128], [128, 255, 191],
		[  0, 166,  83], [ 83, 166, 124], [  0, 128,  64], [ 64, 128,  96],
		[  0,  76,  38], [ 38,  76,  57], [  0,  38,  19], [ 19,  38,  29],
		[  0, 255, 191], [128, 255, 223], [  0, 166, 124], [ 83, 166, 145],
		[  0, 128,  96], [ 64, 128, 112], [  0,  76,  57], [ 38,  76,  67],
		[  0,  38,  29], [ 19,  38,  33], [  0, 255, 255], [128, 255, 255],
		[  0, 166, 166], [ 83, 166, 166], [  0, 128, 128], [ 64, 128, 128],
		[  0,  76,  76], [ 38,  76,  76], [  0,  38,  38], [ 19,  38,  38],
		[  0, 191, 255], [128, 223, 255], [  0, 124, 166], [ 83, 145, 166],
		[  0,  96, 128], [ 64, 112, 128], [  0,  57,  76], [ 38,  67,  76],
		[  0,  29,  38], [ 19,  33,  38], [  0, 128, 255], [128, 191, 255],
		[  0,  83, 166], [ 83, 124, 166], [  0,  64, 128], [ 64,  96, 128],
		[  0,  38,  76], [ 38,  57,  76], [  0,  19,  38], [ 19,  29,  38],
		[  0,  64, 255], [128, 159, 255], [  0,  41, 166], [ 83, 104, 166],
		[  0,  32, 128], [ 64,  80, 128], [  0,  19,  76], [ 38,  48,  76],
		[  0,  10,  38], [ 19,  24,  38], [  0,   0, 255], [128, 128, 255],
		[  0,   0, 166], [ 83,  83, 166], [  0,   0, 128], [ 64,  64, 128],
		[  0,   0,  76], [ 38,  38,  76], [  0,   0,  38], [ 19,  19,  38],
		[ 64,   0, 255], [159, 128, 255], [ 41,   0, 166], [104,  83, 166],
		[ 32,   0, 128], [ 80,  64, 128], [ 19,   0,  76], [ 48,  38,  76],
		[ 10,   0,  38], [ 24,  19,  38], [128,   0, 255], [191, 128, 255],
		[ 83,   0, 166], [124,  83, 166], [ 64,   0, 128], [ 96,  64, 128],
		[ 38,   0,  76], [ 57,  38,  76], [ 19,   0,  38], [ 29,  19,  38],
		[191,   0, 255], [223, 128, 255], [124,   0, 166], [145,  83, 166],
		[ 96,   0, 128], [112,  64, 128], [ 57,   0,  76], [ 67,  38,  76],
		[ 29,   0,  38], [ 33,  19,  38], [255,   0, 255], [255, 128, 255],
		[166,   0, 166], [166,  83, 166], [128,   0, 128], [128,  64, 128],
		[ 76,   0,  76], [ 76,  38,  76], [ 38,   0,  38], [ 38,  19,  38],
		[255,   0, 191], [255, 128, 223], [166,   0, 124], [166,  83, 145],
		[128,   0,  96], [128,  64, 112], [ 76,   0,  57], [ 76,  38,  67],
		[ 38,   0,  29], [ 38,  19,  33], [255,   0, 128], [255, 128, 191],
		[166,   0,  83], [166,  83, 124], [128,   0,  64], [128,  64,  96],
		[ 76,   0,  38], [ 76,  38,  57], [ 38,   0,  19], [ 38,  19,  29],
		[255,   0,  64], [255, 128, 159], [166,   0,  41], [166,  83, 104],
		[128,   0,  32], [128,  64,  80], [ 76,   0,  19], [ 76,  38,  48],
		[ 38,   0,  10], [ 38,  19,  24], [ 84,  84,  84], [118, 118, 118],
		[152, 152, 152], [187, 187, 187], [221, 221, 221], [  0,   0,   0],
		[255, 255, 255],
		);
########################################################################

=head2 regen_aci2rgb

Fairly self-explanatory.  Saved here only so I don't lose it.

=cut
# FIXME:  really should put this elsewhere (a BEGIN block!)
sub regen_aci2rgb {
	my $count = 0;
  my $per = 4;
	my $ts = 1;
	print "\@aci2rgb = (\n";
	for(my $i = 0; $i < @aci2hex; $i++) {
		my $hex = $aci2hex[$i];
		$hex =~ s/#(..)(..)(..)//;
		my ($red, $green, $blue) = ($1, $2, $3);
		($count % $per) || print "\t"x$ts;
		$count++;
		print "[" , 
				join(", ", map( { sprintf("%3d", hex($_)) } 
														$red, $green, $blue)), "]";
		if($count % $per) {
			print ", ";
			}
		else {
			print ",\n";
			}
		}
	print "\n", "\t"x$ts, ");\n";
} # end subroutine regen_aci2rgb definition
########################################################################





########################################################################

1;
