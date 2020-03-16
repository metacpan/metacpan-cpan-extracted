#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017, 2020 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib 'inc';
use MyMakeMakerExtras;
use MyMakeMakerGettext;

my %PREREQ_PM
  =(
    # for TGE.pm which is not working, and currently unused Float.pm
    # 'Archive::Zip' => 0,

    'Class::Singleton' => 1.4,   # 1.4 for has_instance()
    'Class::WeakSingleton' => 0, # think any ok
    'constant::defer' => 0,

    'Date::Calc' => '5.0',  # 5.0 for various Localtime() etc
    'Date::Parse' => 0,

    'DBI' => 0,
    'DBI::Const::GetInfoType' => 0, # in DBI 1.22 or higher

    # version 1.20 for fix resetting after an error like column not found
    # (RT ticket 30558 on version 1.14.  The debian 1.14-2 had a patch which
    # worked.)
    # version 1.27 for its incompatible change "sqlite_unicode"
    'DBD::SQLite' => 1.27,

    'Encode::Locale' => 0,

    # think 0.61 is good, to get undef for a non-existent $HOME
    'File::HomeDir' => 0.61,

    # builtin in perl 5.10, but also separately on CPAN, maybe
    'File::Spec' => 0,

    # FIXME: actually only for LME which is a bit broken, though also used
    # in Manual.t tests
    'File::Slurp' => 0,

    # builtin since perl 5.6 which is what Gtk2 needs anyway, but it's also
    # published separately (and newer) on CPAN; probably any version ok
    'File::Temp' => 0,

    # version 1.200 for Glib::strerror
    # version 1.220 for SOURCE_REMOVE constants, and callback ref leaks
    'Glib' => '1.220',
    'Glib::Object::Subclass' => 0,

    'Glib::Ex::ConnectProperties' => 18, # v.18 for textbuffer#not-empty

    # my Glib-Ex-ObjectBits
    'Glib::Ex::FreezeNotify' => 1,
    'Glib::Ex::SignalIds'    => 16, # v.16 for global destruction
    'Glib::Ex::SourceIds'    => 2, # new in v.2
    'Glib::Ex::SignalBits'   => 9, # new in v.9
    'Glib::Ex::ObjectBits'   => 12, # v.12 for set_property_maybe()

    # version 1.200 for auto-release Gtk2::GC, TreeModelFilter modify_func, ...
    # version 1.220 for EVENT_PROPAGATE constant, Gtk2::BindingSet, ...
    'Gtk2' => '1.220',
    'Gtk2::Pango' => 0,

    # my Gtk2-Ex-Xor
    'Gtk2::Ex::CrossHair' => 17, # v.17 for arrayref copy
    'Gtk2::Ex::Lasso' => 1,

    # my Gtk2-Ex-WidgetBits
    'Gtk2::Ex::WidgetBits'     => 10,
    'Gtk2::Ex::AdjustmentBits' => 47, # v.47 for set_empty()
    'Gtk2::Ex::ActionTooltips' => 10, # new in version 10
    'Gtk2::Ex::EntryBits'      => 11, # new in version 11
    'Gtk2::Ex::GdkBits'        => 23, # v.23 for window_clear_region
    'Gtk2::Ex::KeySnooper'     => 3,
    'Gtk2::Ex::MenuBits'       => 17,             # new in version 17
    'Gtk2::Ex::PixbufBits'     => 35,             # new in version 35
    'Gtk2::Ex::Statusbar::Message'         => 47, # new in version 47
    'Gtk2::Ex::Statusbar::MessageUntilKey' => 11, # new in version 11
    'Gtk2::Ex::TableBits'      => 47,             # new in version 47
    'Gtk2::Ex::TreeModelBits'  => 16,
    'Gtk2::Ex::TreeViewBits'   => 8,              # new in version 8
    'Gtk2::Ex::TextBufferBits' => 18,             # new in version 18
    'Gtk2::Ex::TreeModelFilter::Change' => 9,     # new in version 9
    'Gtk2::Ex::TreeModel::ImplBits'     => 17,    # new in version 17
    'Gtk2::Ex::Units'          => 13,             # new in version 13
    'Gtk2::Ex::WidgetEvents'   => 21,             # new in version 21

    'Gtk2::Ex::DateSpinner' => 2,
    'Gtk2::Ex::DateSpinner::CellRenderer' => 0, # in datespinner version 2
    'Gtk2::Ex::Dragger' => 2,  # version 2 for keyboard moves while dragging

    # my Gtk2-Ex-ErrorTextDialog
    # version 2 for warnings with compile errors
    'Gtk2::Ex::ErrorTextDialog' => 2,
    'Gtk2::Ex::ErrorTextDialog::Handler' => 2,
    'Gtk2::Ex::TextView::FollowAppend' => 1,

    'Gtk2::Ex::History' => 1,
    'Gtk2::Ex::History::Action' => 1,

    'Gtk2::Ex::ListModelConcat' => 1,
    'Gtk2::Ex::MenuView' => 1,
    'Gtk2::Ex::NoShrink' => 2,     # version 2 losing dubious "-1" bits
    'Gtk2::Ex::NumAxis' => 4,      # version 4 preferred for scrolling
    'Gtk2::Ex::TickerView' => 7,   # version 7 for bug fixes
    'Gtk2::Ex::TreeModelFilter::Draggable' => 0,
    'Gtk2::Ex::WidgetCursor' => 8, # version 8 to get SpinButton in Gtk 2.14

    # FIXME: version 2.10 has Gtk '-init' which tries to open the display ...
    'Gtk2::Ex::Datasheet::DBI' => 0,

    'HTML::LinkExtor' => 0, # part of HTML::Parser, only for RBA actually
    'HTML::TableExtract' => 0,
    'HTML::TreeBuilder' => 0,   # only for LME plastics hack actually

    'JSON' => 0,

    # anything Archive::Zip is happy with is enough, 1.07 looks likely
    'IO::String' => '1.07',

    # Perl-Lisp dist, only for the Emacs interface actually
    # think at least 0.04 to read nil as undef
    'Lisp::Reader'  => 0.04,
    'Lisp::Printer' => 0,
    'Lisp::Symbol'  => 0,

    # verison 0.13 apparently for memory leaks in subr args like after()
    # version 0.10 for minmax()
    # version 0.22 xsubs had some problems,
    #   - minmax() on one arg looks at the wrong bit of stack
    #   - apply() and part() don't cope with stack growth
    # The minmax() bit affected App::Chart::Gtk2::Graph.
    # 0.24 might be fixed.
    #
    'List::MoreUtils' => '0.24',

    # version 1.19 for N__() in scalar context
    # (Locale::Messages in 1.16 didn't declare a version, it was only in
    # Locale::TextDomain until 1.17 or 1.18 or something)
    'Locale::TextDomain' => '1.19',
    'Locale::Messages' => '1.19',

    'LWP' => '5.814',  # version 5.814 for new HTTP::Message::decodable()
    # parts of lwp used explicitly, some of which are separate now
    'LWP::UserAgent' => 0,
    'HTTP::Cookies' => 0,
    'HTTP::Message' => '5.814',
    'HTTP::Request' => 0,
    'HTML::Form'    => 0,

    'Math::Round' => 0,
    'Module::Find' => 0.06, # version 0.06 avoids duplicates
    'Module::Util' => 0,
    'Module::Pluggable' => 0,

    # version 1.60 for fixups to initializing in locales like de_DE with "."
    # as the monetary thousands sep
    'Number::Format' => '1.60',

    'PerlIO::via::EscStatus' => 2,  # version 2 fixing erase on close
    # parts of EscStatus used explicitly
    'PerlIO::via::EscStatus::Parser' => 0,
    'PerlIO::via::EscStatus::ShowAll' => 0,
    'PerlIO::via::EscStatus::ShowNone' => 0,

    'Proc::SyncExec' => 0,
    'POSIX::Wide' => 0,
    'Regexp::Common' => 0,
    'Regexp::Tr' => 0, # only for ATH.pm, but small, so get it always

    # 'Scope::Guard' => 0,
    'Set::IntSpan::Fast' => '1.10', # version 1.10 for new contains_all_range()
    # 'Set::Object' => 0,
    # 'String::ShellQuote' => '1.01', # 1.01 for croaking on error
    'Software::License::GPL_3' => '0.001', # new in 0.001

    'Spreadsheet::ParseExcel' => 0, # only LME and RBA actually
    # a component of Spreadsheet::ParseExcel, but used directly, so name it
    'Spreadsheet::ParseExcel::Utility' => 0,

    'Tie::Cache'  => 0,
    'Tie::IxHash' => 0,

    # my Tie-TZ
    'Tie::TZ'  => 1,
    'Time::TZ' => 6, # new in version 6

    'Time::Local' => 1.27,  # for timegm_modern()

    # builtin in perl 5.10 (and 5.8 up), but also separate on cpan;
    # think any version ok
    'Time::HiRes' => 0,

    # not used at the moment
    # builtin in perl 5.10 anyway
    # 'Time::Piece' => 0,

    # was for Yahoo, no longer used
    # 'Text::CSV_XS' => 0,

    'Text::Glob' => 0,

    # brought in by 'LWP' anyway, but used directly too, so name them here
    'URI::Escape' => 0,
    'URI::file' => 0,
   );

my %TEST_REQUIRES = (
                     'Test::More' => 0,
                     'Test::Weaken::Gtk2' => 17,  # new in WidgetBits version 17
                    );
unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
  # past ExtUtils::MakeMaker without separate TEST_REQUIRES
  %PREREQ_PM = (%PREREQ_PM, %TEST_REQUIRES);
}

WriteMakefile
  (NAME         => 'App::Chart',
   VERSION_FROM => 'lib/App/Chart.pm',
   ABSTRACT     => 'Stock and commodity charting program.',
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.010',

   # valid LICENSE values per Module::Build::Base::valid_licenses(), or at
   # least the ones there have urls to link
   LICENSE      => 'gpl_3',

   # ExtUtils::MM_Unix "fixin()" changes #!perl to #!/usr/bin/perl
   EXE_FILES    => [ 'chart' ],

   PREREQ_PM     => \%PREREQ_PM,
   TEST_REQUIRES => \%TEST_REQUIRES,

   clean     => { FILES => join(' ',
                                'doc/chart.dvi',
                                'doc/chart.ps',
                                'doc/chart.pdf',
                                'doc/*.dvi',
                                'doc/*.eps',
                                'doc/*.pdf',
                                'doc/*.ps',
                                'doc/chart.aux',
                                'doc/chart.cp',
                                'doc/chart.cps',
                                'doc/chart.fn',
                                'doc/chart.fns',
                                'doc/chart.ky',
                                'doc/chart.log',
                                'doc/chart.pg',
                                'doc/chart.toc',
                                'doc/chart.tp',
                                'doc/chart.tps',
                                'doc/chart.vr',
                                'App-Chart.tmp', # if bad xgettext
                                'doc/html-split',
                               ) },
   realclean => { FILES => 'TAGS' },

   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/chart/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },

     # Gtk2::Ex::Datasheet::DBI::CellRendererText not created, there's just
     # a GET_SIZE() workaround addition to it here
     #
     no_index => { directory => [ 'devel', 'misc', 'doc', 'po' ],
                   package => [ 'Gtk2::Ex::Datasheet::DBI::CellRendererText' ],
                 },

     prereqs =>
     { runtime =>
       { recommends =>
         {
          'Set::IntSpan::Fast::XS' => '0.05',
          'I18N::Langinfo::Wide' => 2, # version 2 for netbsd "646"

          # version 4.7 to avoid warnings about removal from the perl core dist
          # which was a ridiculous way to communicate to authors
          'Module::Pluggable' => '4.7',
         },
       },

       test =>
       { suggests =>
         { 'Test::Compile'       => '0.08',
           'Test::UseAllModules' => '0',

           # Test::Weaken '3' for "contents" support
           'Test::Weaken'        => '3',
           'Test::Weaken::ExtraBits' => 0,

           # Test::MockTime 0.03 for dates as strings, probably
           'Test::MockTime'           => '0.03',
           'Test::MockTime::DateCalc' => 0,

           # this is an author test in xt/1-Test-Synopsis.t only
           # 'Test::Synopsis'      => 0,
         },
       },

       # needed for "make dist"
       develop =>
       { requires => { 'Image::ExifTool' => 0 },
       },
     },

     optional_features =>
     { source_FQ =>
       { description => 'Finance::Quote data source.',
         prereqs =>
         { runtime =>
           { requires => { 'Finance::Quote' => 0 } } },
       },

       source_TSP =>
       { description => 'Thrift Savings Plan data source.',
         prereqs =>
         { runtime =>
           { requires => { 'Finance::Quote::TSP' => 0 } } },
       },

       # not sure anything with an ISIN is actually working currently
       check_isin =>
       { description => 'Validate downloaded ISIN values.',
         prereqs =>
         { runtime =>
           { requires => { 'Business::ISIN' => 0 } } },
       },

       maximum_sources =>
       { description => 'Have as many data sources available as possible.',
         prereqs =>
         { runtime =>
           { requires => { 'Finance::Quote' => 0,
                           'Finance::Quote::TSP' => 0 } } },
       },
       maximum_indicators =>
       { description => 'Have as many indicators available as possible.',
         prereqs =>
         { runtime =>
           { requires => { 'Finance::TA' => 0,
                           'GT::Indicators' => 0 } } },
       },

       maximum_error_info =>
       { description => 'Have as much information as possible in the Error dialog.',
         prereqs =>
         { runtime =>
           { requires => { 'Devel::StackTrace' => 0, },
             recommends => {
                            # Devel::StackTrace 1.19 catches bad utf8,
                            # which could be important for tracing.
                            # Though for flexibility the code in
                            # App::Chart::GUI doesn't demand it.
                            'Devel::StackTrace' => '1.19',
                           } } },
       },
       maximum_diagnostics =>
       { description => 'Have as much information as possible in the Help/Diagnostics dialog.',
         prereqs =>
         { runtime =>
           { requires => { 'BSD::Resource' => 0,
                           'Devel::FindBlessedRefs' => 0,
                           'Devel::Mallinfo' => 0,  # mine
                           'Devel::Peek' => 0,
                           'Devel::SawAmpersand' => 0,
                         },
             recommends => {
                            # Devel::Arena 0.23 might not work with perl
                            # 5.20, so have it only as recommends
                            'Devel::Arena' => 0,
                           },
           } },
       },
     },
   },
  );


# Maybe some of this would be under develop=>
# maximum_devel =>
# { description => 'Stuff used variously for development.',
#   requires => { 'Business::ISIN'     => 0,
#                 'Devel::FindRef'     => 0,
#                 'warnings::unused'   => 0,
#                 'Math::Polynomial'         => '1.00',
#                 'Math::Polynomial::Horner' => 0,
#                 'Devel::StackTrace'  => '1.19',
#                 'Module::Depends::Intrusive' => 0,
#                 'Module::ScanDeps'   => 0,
#                 'Module::ExtractUse' => 0,
#                 'Lisp::Reader'       => 0,
#                 'Parse::DebControl'  => 0,
#                 'lib::abs'           => 0,
#                 'File::chdir'        => 0,
#                 'Pod::Strip'         => 0,
#                 'Finance::Quote'     => 0,
#               } },

#------------------------------------------------------------------------------
package MY;
sub postamble {
  my ($makemaker) = @_;

  # FIXME: $(filter-out) is a GNU-ism ...
  $makemaker->{'MyMakeMakerExtras_LINT_FILES'}
    = '$(filter-out %/COPYING %.bash %.desktop %.html %.mo %.xpm, $(TO_INST_PM))'
      . ' chart t/*.t devel/*.pl examples/*.pl';

  $makemaker->{'PO_DOMAIN'} = 'App-Chart';

  my $ret = MyMakeMakerGettext::postamble($makemaker);

  $ret .= <<'HERE';

#------------------------------------------------------------------------------
# IndicatorModelGenerated.pm

lib/App/Chart/Gtk2/IndicatorModelGenerated.pm: devel/generate-indicator-model.pl lib/App/Chart/Series/Derived/*.pm
	$(PERL) -I lib devel/generate-indicator-model.pl \
	  >lib/App/Chart/Gtk2/IndicatorModelGenerated.pm \
	|| (rm -f lib/App/Chart/Gtk2/IndicatorModelGenerated.pm; false)

#------------------------------------------------------------------------------
# chart.desktop

# Just chucked under lib/App/Chart for now ...
# eg. /usr/share/applications, for .desktop files
# APPLICATIONSDIR = $(PREFIX)/share/applications
# doc_install :: chart.desktop
# 	install -d $(DESTDIR)$(APPLICATIONSDIR)
# 	install chart.desktop $(DESTDIR)$(APPLICATIONSDIR)


#------------------------------------------------------------------------------
# doc stuff
#
# doc/*.txt and doc/*.png are left in that directory so
# "M-x makeinfo-buffer" can be used during development.  They're excluded
# from the dist by MANIFEST.SKIP.  The *.png are copied to lib/App/Chart/doc
# for the dist.

# Depend only on the generator program doc/weights.pl since the .txt and
# .png are not in the doc directory of the dist.
HTML_TEXI_DEPS = \
  doc/chart.texi doc/version.texi doc/weights.pl

doc: lib/App/Chart/doc/chart.html doc/chart.omf

lib/App/Chart/doc/chart.html: $(HTML_TEXI_DEPS) doc/mung-html.pl
	make doc/chart-ema-weights.txt doc/chart-ema-weights.png # which builds others too
	cd doc && makeinfo --html --no-split chart.texi
	mkdir -p lib/App/Chart/doc
	mv doc/chart.html lib/App/Chart/doc/chart.html
	cp doc/*.png lib/App/Chart/doc
	cd lib/App/Chart/doc && $(PERL) ../../../../doc/mung-html.pl chart.html

doc/version.texi doc/chart.omf: doc/chart.texi
	echo '@c  Generated by top-level Makefile, DO NOT EDIT' >doc/version.texi
	echo '@set VERSION $(VERSION)' >>doc/version.texi
	echo '@set EDITION $(VERSION)' >>doc/version.texi
	echo '@set UPDATED '`date '+%d %B %Y'` >>doc/version.texi
	echo '@set UPDATED_MONTH '`date '+%B %Y'` >>doc/version.texi
	cd doc && perl -pi \
	  -e 's{version identifier="[^"]*"}{version identifier="$(VERSION)"};' \
	  -e 's{date="[^"]*"}{date="'`date +%Y-%m-%d`'"};' \
	  -e 's{<date>[^<]*</date>}{<date>'`date +%Y-%m-%d`'</date>};' \
	  chart.omf

info: doc/chart.info
doc/chart.info: doc/chart.texi doc/version.texi doc/chart-ema-weights.txt doc/chart-ema-weights.png
	cd doc && makeinfo chart.texi

TEXI2DVI = texi2dvi
dvi: doc/chart.dvi
doc/chart.dvi: doc/chart.texi doc/version.texi doc/chart-ema-weights.eps
	cd doc && $(TEXI2DVI) chart.texi

DVIPS = dvips
ps: doc/chart.ps
doc/chart.ps: doc/chart.dvi
	cd doc && $(DVIPS) -o chart.ps chart.dvi

TEXI2PDF = texi2pdf
pdf: doc/chart.pdf
doc/chart.pdf: doc/chart.texi doc/version.texi doc/chart-ema-weights.pdf
	cd doc && $(TEXI2PDF) chart.texi

WEIGHTS_SOURCES = \
  doc/weights.pl \
  lib/App/Chart/Series/Derived/DEMA.pm \
  lib/App/Chart/Series/Derived/EMA.pm \
  lib/App/Chart/Series/Derived/EPMA.pm \
  lib/App/Chart/Series/Derived/HullMA.pm \
  lib/App/Chart/Series/Derived/LaguerreFilter.pm \
  lib/App/Chart/Series/Derived/SMA.pm \
  lib/App/Chart/Series/Derived/REMA.pm \
  lib/App/Chart/Series/Derived/SineMA.pm \
  lib/App/Chart/Series/Derived/T3.pm \
  lib/App/Chart/Series/Derived/TMA.pm \
  lib/App/Chart/Series/Derived/TEMA.pm \
  lib/App/Chart/Series/Derived/WMA.pm \
  lib/App/Chart/Series/Derived/ZLEMA.pm

doc/chart-ema-weights.txt doc/chart-ema-weights.png: $(WEIGHTS_SOURCES)
	cd doc && $(PERL) -I ../lib weights.pl

doc/chart-ema-weights.eps: $(WEIGHTS_SOURCES)
	cd doc && $(PERL) -I ../lib weights.pl --eps
# "epstopdf" is from tetex or texlive
#   (debian package texlive-font-utils or previously texlive-extra-utils).
# "ps2pdf" is from ghostscript.
EPSTOPDF = epstopdf
PS2PDF = ps2pdf
doc/chart-ema-weights.pdf: doc/chart-ema-weights.eps
	#
	# NOTE: if you have $(PS2PDF) instead of $(EPSTOPDF) then messages like
	#     /bin/sh: $(EPSTOPDF): not found
	# are normal and harmless
	#
	cd doc; for i in chart-*-weights.eps; do \
	  $(EPSTOPDF) $$i || $(PS2PDF) $$i || exit 1; \
	done


html-split: doc/html-split/index.html
doc/html-split/index.html: $(HTML_TEXI_DEPS) doc/mung-html.pl
	rm -rf doc/html-split
	cd doc && makeinfo --html -o html-split chart.texi
	cp doc/*.png doc/html-split
	cd doc/html-split && $(PERL) ../mung-html.pl *.html

HERE
  return $ret;
}

#------------------------------------------------------------------------------
#
# cf
# Hurst.pdf
# Anis and Lloyd
# The expected value of the adjusted rescaled hurst range ...
# nBiometrika 63 1976 111-116
