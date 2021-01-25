#
# Copyright (c) 2004-2012 by the cairo perl team (see the file README)
#
# Licensed under the LGPL, see LICENSE file for more information.
#
# $Id$
#

BEGIN { require 5.006; }

use strict;
use warnings;
use ExtUtils::MakeMaker;

require './inc/MakeHelper.pm';

my %extreqs = (
	'cairo' => '1.0.0',
);

# Unfortunately we already need these prereqs for writing the Makefile ...
my %prereqs = (
	'ExtUtils::Depends'   => 0.2,
	'ExtUtils::PkgConfig' => 1.0,
);

my %meta_merge = (
        q(meta-spec)          => {
            version => '2',
            url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
        },
        author              =>
            ['Cairo Perl Team <gtk-perl-list at gnome dot org>'],
        release_status      => 'stable',
        # valid values: https://metacpan.org/module/CPAN::Meta::Spec#license
        license             => 'lgpl_2_1',
        resources => {
            license     => 'http://www.gnu.org/licenses/lgpl-2.1.html',
            homepage    => 'http://gtk2-perl.sourceforge.net',
            x_MailingList =>
                'https://mail.gnome.org/mailman/listinfo/gtk-perl-list',
            bugtracker  => {
                    web     =>
                    'http://rt.cpan.org/Public/Dist/Display.html?Name=Cairo',
                    mailto  => 'bug-Cairo [at] rt.cpan.org',
            },
            repository  => {
                    url     => 'https://gitlab.gnome.org/GNOME/perl-cairo.git',
                    type    => 'git',
                    web     => 'https://gitlab.gnome.org/GNOME/perl-cairo',
            },
        },
        prereqs => {
          configure => {
            requires => {%prereqs}, # no direct ref for 5.14 compatibility
          },
          test => {
            recommends => {
              'Test::Number::Delta' => 1.0,
            },
          },
        },
        no_index            => {
            file => [qw(inc/MakeHelper.pm)],
        },
);

# ... thus we have to make sure they are installed.
while ((my $module, my $version) = each(%prereqs)) {
	unless (eval "use $module $version; 1" ) {
		print "This module requires $module to install itself.\n";
		my $yn = ExtUtils::MakeMaker::prompt("  Install $module from CPAN?", 'n');

		unless ($yn =~ /^y/i) {
			die " *** Cannot install without $module.  Exiting ...\n";
		}

		require Cwd;
		require File::Spec;
		require CPAN;

		# Save this 'cause CPAN will chdir all over the place.
		my $cwd = Cwd::cwd();
		my $makefile = File::Spec->rel2abs($0);

		CPAN::Shell->install($module);

		chdir $cwd
			or die "Cannot chdir() back to $cwd: $!";
	}
	eval "use $module $version; 1" or die $@;
}

my $autogen_dir = 'build';
mkdir $autogen_dir unless (-d $autogen_dir);
$MakeHelper::autogen_dir = $autogen_dir;

my %cairo_cfg;
eval { %cairo_cfg = ExtUtils::PkgConfig->find ("cairo >= $extreqs{cairo}"); };
if ($@ ne '') {
	warn $@;
	exit 0;
}

my %objects = (
	'cairo_t *'             => 'Cairo::Context',
	'cairo_font_face_t *'   => 'Cairo::FontFace',
	'cairo_pattern_t *'     => 'Cairo::Pattern',
	'cairo_region_t *'      => 'Cairo::Region',
	'cairo_scaled_font_t *' => 'Cairo::ScaledFont',
	'cairo_surface_t *'     => 'Cairo::Surface',
);

my %structs = (
	'cairo_font_options_t *'  => 'Cairo::FontOptions',
	'cairo_matrix_t *'        => 'Cairo::Matrix',
	'cairo_rectangle_t *'     => 'Cairo::Rectangle',
	'cairo_rectangle_int_t *' => 'Cairo::RectangleInt',
);

my %enums = (
	cairo_antialias_t => [qw/
		CAIRO_ANTIALIAS_
		CAIRO_ANTIALIAS_DEFAULT
		CAIRO_ANTIALIAS_NONE
		CAIRO_ANTIALIAS_GRAY
		CAIRO_ANTIALIAS_SUBPIXEL
	/],
	cairo_content_t => [qw/
		CAIRO_CONTENT_
		CAIRO_CONTENT_COLOR
		CAIRO_CONTENT_ALPHA
		CAIRO_CONTENT_COLOR_ALPHA
	/],
	cairo_extend_t => [qw/
		CAIRO_EXTEND_
		CAIRO_EXTEND_NONE
		CAIRO_EXTEND_REPEAT
		CAIRO_EXTEND_REFLECT
	/],
	cairo_fill_rule_t => [qw/
		CAIRO_FILL_RULE_
		CAIRO_FILL_RULE_WINDING
		CAIRO_FILL_RULE_EVEN_ODD
	/],
	cairo_filter_t => [qw/
		CAIRO_FILTER_
		CAIRO_FILTER_FAST
		CAIRO_FILTER_GOOD
		CAIRO_FILTER_BEST
		CAIRO_FILTER_NEAREST
		CAIRO_FILTER_BILINEAR
		CAIRO_FILTER_GAUSSIAN
	/],
	cairo_font_slant_t => [qw/
		CAIRO_FONT_SLANT_
		CAIRO_FONT_SLANT_NORMAL
		CAIRO_FONT_SLANT_ITALIC
		CAIRO_FONT_SLANT_OBLIQUE
	/],
	cairo_font_weight_t => [qw/
		CAIRO_FONT_WEIGHT_
		CAIRO_FONT_WEIGHT_NORMAL
		CAIRO_FONT_WEIGHT_BOLD
	/],
	cairo_format_t => [qw/
		CAIRO_FORMAT_
		CAIRO_FORMAT_ARGB32
		CAIRO_FORMAT_RGB24
		CAIRO_FORMAT_A8
		CAIRO_FORMAT_A1
	/],
	cairo_hint_metrics_t => [qw/
		CAIRO_HINT_METRICS_
		CAIRO_HINT_METRICS_DEFAULT
		CAIRO_HINT_METRICS_OFF
		CAIRO_HINT_METRICS_ON
	/],
	cairo_hint_style_t => [qw/
		CAIRO_HINT_STYLE_
		CAIRO_HINT_STYLE_DEFAULT
		CAIRO_HINT_STYLE_NONE
		CAIRO_HINT_STYLE_SLIGHT
		CAIRO_HINT_STYLE_MEDIUM
		CAIRO_HINT_STYLE_FULL
	/],
	cairo_line_cap_t => [qw/
		CAIRO_LINE_CAP_
		CAIRO_LINE_CAP_BUTT
		CAIRO_LINE_CAP_ROUND
		CAIRO_LINE_CAP_SQUARE
	/],
	cairo_line_join_t => [qw/
		CAIRO_LINE_JOIN_
		CAIRO_LINE_JOIN_MITER
		CAIRO_LINE_JOIN_ROUND
		CAIRO_LINE_JOIN_BEVEL
	/],
	cairo_operator_t => [qw/
		CAIRO_OPERATOR_
		CAIRO_OPERATOR_CLEAR
		CAIRO_OPERATOR_SOURCE
		CAIRO_OPERATOR_OVER
		CAIRO_OPERATOR_IN
		CAIRO_OPERATOR_OUT
		CAIRO_OPERATOR_ATOP
		CAIRO_OPERATOR_DEST
		CAIRO_OPERATOR_DEST_OVER
		CAIRO_OPERATOR_DEST_IN
		CAIRO_OPERATOR_DEST_OUT
		CAIRO_OPERATOR_DEST_ATOP
		CAIRO_OPERATOR_XOR
		CAIRO_OPERATOR_ADD
		CAIRO_OPERATOR_SATURATE
	/],
	cairo_path_data_type_t => [qw/
		CAIRO_PATH_
		CAIRO_PATH_MOVE_TO
		CAIRO_PATH_LINE_TO
		CAIRO_PATH_CURVE_TO
		CAIRO_PATH_CLOSE_PATH
	/],
	cairo_status_t => [qw/
		CAIRO_STATUS_
		CAIRO_STATUS_SUCCESS
		CAIRO_STATUS_NO_MEMORY
		CAIRO_STATUS_INVALID_RESTORE
		CAIRO_STATUS_INVALID_POP_GROUP
		CAIRO_STATUS_NO_CURRENT_POINT
		CAIRO_STATUS_INVALID_MATRIX
		CAIRO_STATUS_INVALID_STATUS
		CAIRO_STATUS_NULL_POINTER
		CAIRO_STATUS_INVALID_STRING
		CAIRO_STATUS_INVALID_PATH_DATA
		CAIRO_STATUS_READ_ERROR
		CAIRO_STATUS_WRITE_ERROR
		CAIRO_STATUS_SURFACE_FINISHED
		CAIRO_STATUS_SURFACE_TYPE_MISMATCH
		CAIRO_STATUS_PATTERN_TYPE_MISMATCH
		CAIRO_STATUS_INVALID_CONTENT
		CAIRO_STATUS_INVALID_FORMAT
		CAIRO_STATUS_INVALID_VISUAL
		CAIRO_STATUS_FILE_NOT_FOUND
		CAIRO_STATUS_INVALID_DASH
	/],
	cairo_subpixel_order_t => [qw/
		CAIRO_SUBPIXEL_ORDER_
		CAIRO_SUBPIXEL_ORDER_DEFAULT
		CAIRO_SUBPIXEL_ORDER_RGB
		CAIRO_SUBPIXEL_ORDER_BGR
		CAIRO_SUBPIXEL_ORDER_VRGB
		CAIRO_SUBPIXEL_ORDER_VBGR
	/],
);

my %flags = ();

# --------------------------------------------------------------------------- #

my @exports = qw(
	cairo_font_face_to_sv
	cairo_font_type_from_sv
	cairo_font_type_to_sv
	cairo_object_from_sv
	cairo_object_to_sv
	cairo_pattern_to_sv
	cairo_struct_from_sv
	cairo_struct_to_sv
	cairo_surface_to_sv

	newSVCairoGlyph
	SvCairoGlyph
	newSVCairoPath
	SvCairoPath
	newSVCairoFontExtents
	newSVCairoTextExtents

	cairo_antialias_from_sv
	cairo_antialias_to_sv
	cairo_content_from_sv
	cairo_content_to_sv
	cairo_extend_from_sv
	cairo_extend_to_sv
	cairo_fill_rule_from_sv
	cairo_fill_rule_to_sv
	cairo_filter_from_sv
	cairo_filter_to_sv
	cairo_font_slant_from_sv
	cairo_font_slant_to_sv
	cairo_font_weight_from_sv
	cairo_font_weight_to_sv
	cairo_format_from_sv
	cairo_format_to_sv
	cairo_hint_metrics_from_sv
	cairo_hint_metrics_to_sv
	cairo_hint_style_from_sv
	cairo_hint_style_to_sv
	cairo_line_cap_from_sv
	cairo_line_cap_to_sv
	cairo_line_join_from_sv
	cairo_line_join_to_sv
	cairo_operator_from_sv
	cairo_operator_to_sv
	cairo_path_data_type_from_sv
	cairo_path_data_type_to_sv
	cairo_status_from_sv
	cairo_status_to_sv
	cairo_subpixel_order_from_sv
	cairo_subpixel_order_to_sv
);

# --------------------------------------------------------------------------- #

sub add_new_enum_values {
	my (%new) = @_;
	foreach my $enum (keys %new) {
		foreach my $value (@{$new{$enum}}) {
			push @{$enums{$enum}}, $value;
		}
	}
}

my $have_cairo_1_2 = ExtUtils::PkgConfig->atleast_version("cairo", "1.2.0");
my $have_cairo_1_4 = ExtUtils::PkgConfig->atleast_version("cairo", "1.4.0");
my $have_cairo_1_6 = ExtUtils::PkgConfig->atleast_version("cairo", "1.6.0");
my $have_cairo_1_8 = ExtUtils::PkgConfig->atleast_version("cairo", "1.8.0");
my $have_cairo_1_10 = ExtUtils::PkgConfig->atleast_version("cairo", "1.10.0");
my $have_cairo_1_12 = ExtUtils::PkgConfig->atleast_version("cairo", "1.12.0");
my $have_cairo_1_14 = ExtUtils::PkgConfig->atleast_version("cairo", "1.14.0");
my $have_cairo_1_16 = ExtUtils::PkgConfig->atleast_version("cairo", "1.16.0");

if ($have_cairo_1_2) {
	add_new_enum_values(
		cairo_extend_t => [qw/CAIRO_EXTEND_PAD/],
		cairo_format_t => [qw/CAIRO_FORMAT_RGB16_565/],
		cairo_status_t => [qw/CAIRO_STATUS_INVALID_DSC_COMMENT/],
	);

	$enums{cairo_font_type_t} = [qw/
		CAIRO_FONT_TYPE_
		CAIRO_FONT_TYPE_TOY
		CAIRO_FONT_TYPE_FT
		CAIRO_FONT_TYPE_WIN32
		CAIRO_FONT_TYPE_ATSUI
	/];

	$enums{cairo_pattern_type_t} = [qw/
		CAIRO_PATTERN_TYPE_
		CAIRO_PATTERN_TYPE_SOLID
		CAIRO_PATTERN_TYPE_SURFACE
		CAIRO_PATTERN_TYPE_LINEAR
		CAIRO_PATTERN_TYPE_RADIAL
	/];

	$enums{cairo_surface_type_t} = [qw/
		CAIRO_SURFACE_TYPE_
		CAIRO_SURFACE_TYPE_IMAGE
		CAIRO_SURFACE_TYPE_PDF
		CAIRO_SURFACE_TYPE_PS
		CAIRO_SURFACE_TYPE_XLIB
		CAIRO_SURFACE_TYPE_XCB
		CAIRO_SURFACE_TYPE_GLITZ
		CAIRO_SURFACE_TYPE_QUARTZ
		CAIRO_SURFACE_TYPE_WIN32
		CAIRO_SURFACE_TYPE_BEOS
		CAIRO_SURFACE_TYPE_DIRECTFB
		CAIRO_SURFACE_TYPE_SVG
	/];

	$enums{cairo_svg_version_t} = [qw/
		CAIRO_SVG_VERSION_
		CAIRO_SVG_VERSION_1_1
		CAIRO_SVG_VERSION_1_2
	/];

	push @exports, qw/cairo_font_type_from_sv
	                  cairo_font_type_to_sv
	                  cairo_pattern_type_from_sv
	                  cairo_pattern_type_to_sv
	                  cairo_surface_type_from_sv
	                  cairo_surface_type_to_sv
	                  cairo_svg_version_from_sv
	                  cairo_svg_version_to_sv/;
} else {
	# We need to create empty enum entries for new types so that typemaps
	# are generated for them.  xsubpp demands typemaps even if the code is
	# #if'd out.
	$enums{cairo_font_type_t} = [];
	$enums{cairo_pattern_type_t} = [];
	$enums{cairo_surface_type_t} = [];
	$enums{cairo_svg_version_t} = [];
}

if ($have_cairo_1_4) {
	add_new_enum_values(
		cairo_status_t => [qw/CAIRO_STATUS_INVALID_INDEX
		                      CAIRO_STATUS_CLIP_NOT_REPRESENTABLE/],
		cairo_surface_type_t => [qw/CAIRO_SURFACE_TYPE_OS2/],
	);

	push @exports, qw/newSVCairoRectangle
	                  SvCairoRectangle/;
}

if ($have_cairo_1_6) {
	add_new_enum_values(
		cairo_font_type_t => [qw/CAIRO_FONT_TYPE_QUARTZ/],
		cairo_status_t => [qw/CAIRO_STATUS_TEMP_FILE_ERROR
				      CAIRO_STATUS_INVALID_STRIDE/],
		cairo_surface_type_t => [qw/CAIRO_SURFACE_TYPE_WIN32_PRINTING
					    CAIRO_SURFACE_TYPE_QUARTZ_IMAGE/],
	);

	$enums{cairo_ps_level_t} = [qw/
		CAIRO_PS_LEVEL_
		CAIRO_PS_LEVEL_2
		CAIRO_PS_LEVEL_3
	/];

	push @exports, qw/cairo_ps_level_from_sv
	                  cairo_ps_level_to_sv/;
} else {
	$enums{cairo_ps_level_t} = [];
}

if ($have_cairo_1_8) {
	add_new_enum_values(
		cairo_status_t => [qw/CAIRO_STATUS_FONT_TYPE_MISMATCH
				      CAIRO_STATUS_USER_FONT_IMMUTABLE
				      CAIRO_STATUS_USER_FONT_ERROR
				      CAIRO_STATUS_NEGATIVE_COUNT
				      CAIRO_STATUS_INVALID_CLUSTERS
				      CAIRO_STATUS_INVALID_SLANT
				      CAIRO_STATUS_INVALID_WEIGHT/],
                cairo_font_type_t => [qw/CAIRO_FONT_TYPE_USER/],
	);

	$flags{cairo_text_cluster_flags_t} = [qw/
		CAIRO_TEXT_CLUSTER_FLAG_
		CAIRO_TEXT_CLUSTER_FLAG_BACKWARD
	/];

	push @exports, qw/newSVCairoTextCluster
	                  SvCairoTextCluster
	                  cairo_text_cluster_flags_from_sv
	                  cairo_text_cluster_flags_to_sv/;
} else {
	$flags{cairo_text_cluster_flags_t} = [];
}

if ($have_cairo_1_10) {
	add_new_enum_values(
		cairo_status_t => [qw/CAIRO_STATUS_INVALID_SIZE
				      CAIRO_STATUS_USER_FONT_NOT_IMPLEMENTED
				      CAIRO_STATUS_DEVICE_TYPE_MISMATCH
				      CAIRO_STATUS_DEVICE_ERROR/],
		cairo_surface_type_t => [
			qw/CAIRO_SURFACE_TYPE_SCRIPT
			   CAIRO_SURFACE_TYPE_QT
			   CAIRO_SURFACE_TYPE_RECORDING
			   CAIRO_SURFACE_TYPE_VG
			   CAIRO_SURFACE_TYPE_GL
			   CAIRO_SURFACE_TYPE_DRM
			   CAIRO_SURFACE_TYPE_TEE
			   CAIRO_SURFACE_TYPE_XML
			   CAIRO_SURFACE_TYPE_SKIA
			   CAIRO_SURFACE_TYPE_SUBSURFACE/],
		cairo_operator_t => [
			qw/CAIRO_OPERATOR_MULTIPLY
			   CAIRO_OPERATOR_SCREEN
			   CAIRO_OPERATOR_OVERLAY
			   CAIRO_OPERATOR_DARKEN
			   CAIRO_OPERATOR_LIGHTEN
			   CAIRO_OPERATOR_COLOR_DODGE
			   CAIRO_OPERATOR_COLOR_BURN
			   CAIRO_OPERATOR_HARD_LIGHT
			   CAIRO_OPERATOR_SOFT_LIGHT
			   CAIRO_OPERATOR_DIFFERENCE
			   CAIRO_OPERATOR_EXCLUSION
			   CAIRO_OPERATOR_HSL_HUE
			   CAIRO_OPERATOR_HSL_SATURATION
			   CAIRO_OPERATOR_HSL_COLOR
			   CAIRO_OPERATOR_HSL_LUMINOSITY/],
	);

	$enums{cairo_pdf_version_t} = [qw/
		CAIRO_PDF_VERSION_
		CAIRO_PDF_VERSION_1_4
		CAIRO_PDF_VERSION_1_5
	/];

	$enums{cairo_region_overlap_t} = [qw/
		CAIRO_REGION_OVERLAP_
		CAIRO_REGION_OVERLAP_IN
		CAIRO_REGION_OVERLAP_OUT
		CAIRO_REGION_OVERLAP_PART
	/];

	push @exports, qw/newSVCairoRectangleInt
	                  SvCairoRectangleInt
	                  cairo_pdf_version_from_sv
	                  cairo_pdf_version_to_sv
	                  cairo_region_overlap_from_sv
	                  cairo_region_overlap_to_sv/;
} else {
	$enums{cairo_pdf_version_t} = [];
	$enums{cairo_region_overlap_t} = [];
}

if ($have_cairo_1_12) {
	add_new_enum_values(
		cairo_status_t => [qw/CAIRO_STATUS_INVALID_MESH_CONSTRUCTION
				      CAIRO_STATUS_DEVICE_FINISHED/],
	);
} else {
}

if ($have_cairo_1_14) {
	add_new_enum_values(
		cairo_status_t => [qw/CAIRO_STATUS_JBIG2_GLOBAL_MISSING/],
	);
} else {
}

if ($have_cairo_1_16) {
	add_new_enum_values(
		cairo_status_t => [qw/CAIRO_STATUS_PNG_ERROR
				      CAIRO_STATUS_FREETYPE_ERROR
				      CAIRO_STATUS_WIN32_GDI_ERROR
				      CAIRO_STATUS_TAG_ERROR/],
	);
	$enums{cairo_pdf_metadata_t} = [qw/
		CAIRO_PDF_METADATA_
		CAIRO_PDF_METADATA_TITLE
		CAIRO_PDF_METADATA_AUTHOR
		CAIRO_PDF_METADATA_SUBJECT
		CAIRO_PDF_METADATA_KEYWORDS
		CAIRO_PDF_METADATA_CREATOR
		CAIRO_PDF_METADATA_CREATE_DATE
		CAIRO_PDF_METADATA_MOD_DATE
	/];

	$flags{cairo_pdf_outline_flags_t} = [qw/
		CAIRO_PDF_OUTLINE_FLAG_
		CAIRO_PDF_OUTLINE_FLAG_OPEN
		CAIRO_PDF_OUTLINE_FLAG_BOLD
		CAIRO_PDF_OUTLINE_FLAG_ITALIC
	/];

	 push @exports, qw/
			cairo_pdf_outline_flags_from_sv
			cairo_pdf_outline_flags_to_sv/;
} else {
	$enums{cairo_pdf_metadata_t} = [];
	$flags{cairo_pdf_outline_flags_t} = [];
}

# --------------------------------------------------------------------------- #

my %object_guards = (
	cairo_region_t => '#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 10, 0)',
);

my %struct_guards = (
	cairo_rectangle_t     => '#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 4, 0)',
	cairo_rectangle_int_t => '#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 10, 0)',
);

my %enum_guards = (
	cairo_ps_level_t    => '#ifdef CAIRO_HAS_PS_SURFACE',
	cairo_svg_version_t => '#ifdef CAIRO_HAS_SVG_SURFACE',
);

my %flag_guards = ();

MakeHelper::do_enums (\%enums, \%enum_guards);

MakeHelper::do_flags (\%flags, \%flag_guards);

my @xs_files = qw(
	Cairo.xs
	CairoFont.xs
	CairoMatrix.xs
	CairoPath.xs
	CairoPattern.xs
	CairoSurface.xs
);

if ($have_cairo_1_10) {
	push @xs_files, 'CairoRegion.xs';
}

my $have_cairo_ft = !system qw(pkg-config --exists --silence-errors cairo-ft);
if ($have_cairo_ft) {
	print "Compiling Cairo with FreeType support\n";
	push @xs_files, 'CairoFt.xs';
	my %ft_cfg = ExtUtils::PkgConfig->find ('cairo-ft');
	$cairo_cfg{cflags} .= ' '.$ft_cfg{cflags};
	$cairo_cfg{libs} .= ' '.$ft_cfg{libs};
}

MakeHelper::write_boot (
	xs_files => \@xs_files,
	ignore => '^Cairo$',
);

my @typemaps = MakeHelper::do_typemaps (\%objects, \%structs, \%enums, \%flags,
                                        \%object_guards,
                                        \%struct_guards,
                                        \%enum_guards,
                                        \%flag_guards);
push @typemaps, 'cairo-perl.typemap';

my $dep = ExtUtils::Depends->new ('Cairo');
$dep->set_inc ('-I. -I'.$autogen_dir.' '.$cairo_cfg{cflags});
$dep->set_libs ($cairo_cfg{libs});
$dep->add_xs (@xs_files);
$dep->add_c (qw/cairo-perl-enums.c cairo-perl-flags.c/);
$dep->add_pm ('lib/Cairo.pm' => '$(INST_LIBDIR)/Cairo.pm');
$dep->add_typemaps (@typemaps);

$dep->install (qw(cairo-perl.h
                  cairo-perl.typemap
                  doctypes
                  build/cairo-perl-auto.h
                  build/cairo-perl-auto.typemap));
$dep->save_config ('build/IFiles.pm');

# On OpenBSD/NetBSD, any program that directly or indirectly wants to load
# libpthread.so must do so from the start.  But when perl is built without
# ithreads, it will also most likely not be compiled with "-pthread".  When
# libcairo then goes and tries to load libpthread.so, the loader will error
# out.
my @bsd_compat_flags = ();
if (($^O eq 'openbsd' || $^O eq 'netbsd') && $Config::Config{ldflags} !~ m/-pthread\b/) {
  warn " ***\n *** on OpenBSD/NetBSD, we either need perl linked with '-pthread',\n",
       " ***   or we need to set LD_PRELOAD=libpthread.so; doing the latter now...\n ***\n";
  @bsd_compat_flags = (
    macro => {FULLPERLRUN => 'LD_PRELOAD=libpthread.so $(FULLPERL)'},
  );
}

WriteMakefile (
    NAME          => 'Cairo',
    #AUTHOR, LICENSE are now part of %meta_merge
    VERSION_FROM  => 'lib/Cairo.pm',
    ABSTRACT_FROM => 'lib/Cairo.pm',
    PREREQ_PM     => \%prereqs,
    XSPROTOARG    => '-noprototypes',
    FUNCLIST      => \@exports,
    DL_FUNCS      => { Cairo=> [] },
    META_MERGE    => \%meta_merge,
    $dep->get_makefile_vars,
    @bsd_compat_flags,
);

sub MY::postamble
{
	my $autogen_dir = $MakeHelper::autogen_dir;

	"realclean ::
	-\$(RM_RF) $autogen_dir cairo-perl-enums.*";
}
