#! /usr/bin/perl -w
##
##  Makefile.PL
##
##  Copyright (c) 1994-2000  William Setzer
##
##  You may distribute under the terms of either the Artistic License
##  or the GNU General Public License, as specified in the README file.

require 5.005;
use strict;
#use warnings;   Can't use; new since Perl 5.005; use perl -w instead
use ExtUtils::MakeMaker;
use English;
use Config;

#  Here are the arguments defined for this file:
#
#    PANELS   -- enable panel functions
#    MENUS    -- enable menus functions
#    FORMS    -- enable forms functions
#    GEN      -- add generation function to Makefile (developers only!)
#
#  Ex:  "perl Makefile.PL PANELS MENUS GEN"

#  Environment variables tell us how one accesses the Curses library
#  on this system.
#
#    CURSES_LIBTYPE
#                'bsd', 'ncurses', or 'ncursesw' on most systems.
#                In some environments, there are other possibilities.
#
#    CURSES_CFLAGS
#    CURSES_PANEL_CFLAGS
#    CURSES_MENUS_CFLAGS
#    CURSES_FORMS_CFLAGS
#                contains any includes or defines (-I or -D) that are
#                needed to compile libcurses applications
#
#    CURSES_LDFLAGS
#    CURSES_PANEL_LDFLAGS
#    CURSES_MENUS_LDFLAGS
#    CURSES_FORMS_LDFLAGS
#                contains any libraries or library paths (-l or -L) that are
#                needed to compile libcurses applications.  This must be
#                -l and -L options only -- we parse it.  Note that if you
#                specify something that doesn't result in MakeMaker finding
#                a library, your value just gets silently ignored -- it
#                won't show up in the make file.


#  If these environment variables aren't set, we try in a fairly
#  stupid fashion to pick them for you, along with a "c-config.h" file.

my $libType = $ENV{'CURSES_LIBTYPE'};

my $inc = $ENV{'CURSES_CFLAGS'};
my $libs = $ENV{'CURSES_LDFLAGS'};

my $panel_inc = $ENV{'CURSES_PANEL_CFLAGS'} || '';
my $panel_libs = $ENV{'CURSES_PANEL_LDFLAGS'} || '';

my $menu_inc = $ENV{'CURSES_MENU_CFLAGS'} || '';
my $menu_libs = $ENV{'CURSES_MENU_LDFLAGS'} || '';

my $form_inc = $ENV{'CURSES_FORM_CFLAGS'} || '';
my $form_libs = $ENV{'CURSES_FORM_LDFLAGS'} || '';

#  If you want to see examples of what needs to go in the $inc and
#  $libs variables, check out the `guess_cfg' tables of values below.
#  In fact, one way to set the variables would be to add or modify an
#  entry for your 'osname'.  If you're not sure what the osname is for
#  your machine, you can use the following at your command line to
#  print it out:
#
#    perl -MConfig -le 'print $^O'
#
#  Some lines have multiple versions (such as `freebsd' and `linux'),
#  representing different versions of curses that an OS might have.
#  You can pick the version you want by setting the `default' entry.

#  Here are some notes provided by the hint providers for certain of the
#  OSes.  You should scan them first to see if they apply to you.
#
#  Notes for FreeBSD ncurses:
#    [Courtesy of "Andrew V. Stesin" <stesin@elvisti.kiev.ua>]
#    FreeBSD-2.0.5 ncurses + mytinfo    NOTE! Straight curses works much
#                                       better for me!
#
#  Notes for Solaris:
#    Under 2.3, it was reported that to get the module to compile properly
#    with gcc, you must add `-DSYSV=1' to $inc.  This will disable the
#    redefinition of memcpy to bcopy that is present in /usr/include/curses.h.
#    [Courtesy of Dave Blaszyk <dvb@ycc.Kodak.COM>]
#
#    $inc also contained "-I/usr/include", but this seems to cause a great
#    deal of trouble for gcc under perl5.002, so I removed it by default.
#    I have tested Curses-a9 with perl5.002 and gcc263 and Sun's unbundled
#    cc on Solaris 2.4 with an empty $inc and had no problems, but your
#    mileage may vary.
#
#    If you are having trouble compiling under Solaris, try various
#    combinations of "-I/usr/include" and "-DSYSV=1" in $inc to see if
#    it fixes things.
#
#    David Nelson reports in July 2014 that Solaris 11 no longer needs
#    -L /usr/ccs/lib and also has Ncurses installed; in particular, it
#    has a /usr/include/ncurses/ncurses.h.  (So generic Ncurses compile
#    (options are fine on Solaris 11).

##   OS            default guess for $inc      default guess for $libs
#
my $guess_cfg = {
  'aix'       => [ ''                       , '-lcurses -ltermcap'        ],
  'bsd386'    => [ ''                       , '-lcurses -ltermcap'        ],
  'bsdos'     => [ ''                       , '-lcurses -ltermcap'        ],
  'cygwin'    => [ '-I/usr/include/ncurses' , '-lncurses'                 ],
  'darwin'    => [ ''                       , '-lcurses'                  ],
  'dec_osf'   => [ ''                       , '-lcurses -ltermcap'        ],
  'dgux'      => [ ''                       , '-lcurses -ltermcap'        ],
  'dynixptx'  => [ ''                       , '-lcurses -lc'              ],
  'freebsd'   => {
    'bsd'     => [ ''                       , '-lcurses -ltermcap'        ],
    'ncurses' => [ ''                       , '-lncurses'                 ],
    'default' =>   'bsd'
  },
  'dragonfly' => {
    'bsd'     => [ ''                       => '-lcurses -ltermcap'        ],
    'ncurses' => [ ''                       => '-lncurses'                 ],
    'default' =>   'bsd'
  },

  'gnu'       => [ ''                       , '-lncurses'                 ],
  'hpux'      => [ ''                       , '-lcurses -ltermcap'        ],
# See INSTALL file for information about a different Curses library on HPUX.
  'irix'      => {
    'bsd'     => [ ''                       , '-lcurses -ltermcap'        ],
    'ncurses' => [ ''                       , '-lncurses'                 ],
    'default' =>   'bsd'
  },
  'isc'       => [ ''                       , '-lcurses -ltermcap'        ],
  'linux'     => {
    'bsd'     => [ ''                       ,  '-lcurses -ltermcap'       ],
    'ncurses' => [ '-I/usr/include/ncurses' ,  '-lncurses'                ],
    'default' =>   'ncurses'
  },
  'netbsd'   => {
    'bsd'     => [ ''                       => '-lcurses -ltermcap'        ],
    'ncurses' => [ ''                       => '-lncurses'                 ],
    'default' =>   'ncurses'
  },
  'next'      => [ ''                       , '-lcurses -ltermcap'        ],
  'openbsd'   => [ ''                       , '-lcurses -ltermcap'        ],
  'os2'       => {
    'bsd'     => [ ''                       , '-lcurses -ltermcap'        ],
    'ncurses' => [ ''                       , '-lncurses'                 ],
    'default' =>   'ncurses'
  },
  'sco'       => [ ''                       , '-lcurses -ltermcap'        ],
  'solaris'   => [ ''                       , '-L/usr/ccs/lib -lcurses'   ],
  'sunos'     => {
    'bsd'     => [ ''                       , '-lcurses -ltermcap'        ],
    'sysv'    => [ '-I/usr/5include'        , '-L/usr/5lib -lcurses'      ],
    'ncurses' => [ ''                       , '-lncurses'                 ],
    'default' =>   'sysv'
  },
  'VMS'       => [ ''                       , 'sys$library:vaxccurse.olb' ],
  'svr4'      => [ ''                       , '-lcurses'                  ],
  'MSWin32'   => {
    'borland' => [ '-w- -Id:\bc5\include'   , '-Ld:\bc5\lib pdcurses.lib' ],
    'visualc' => [ ''                       , 'pdcurses'                  ],
    'default' =>   'visualc'
  },
  ''          =>   undef
};

###
## You shouldn't need to change anything below
#

my $TRUE = 1; my $FALSE = 0;


sub nCursesIsInstalled() {

    if (-f('/usr/include/ncurses/ncurses.h')) {
        return $TRUE;
    } elsif (-f('/usr/include/ncurses.h')) {
        return $TRUE;
    } else {
        return $FALSE;
    }
}


sub bsdIsInstalled() {

    if (-f('/usr/include/curses/curses.h')) {
        return $TRUE;
    } elsif (-f('/usr/include/curses.h')) {
        return $TRUE;
    } else {
        return $FALSE;
    }
}



sub chooseLibraryType($$) {
    my ($typeList, $libtypR) = @_;
#-----------------------------------------------------------------------------
#  Assuming this is a platform on which there may be multiple versions of
#  Curses, choose one.
#
#  Return the choice as $$libtypR.
#
#  We prefer Ncurses, so choose that if it appears to be installed.
#  If it doesn't, but BSD appears to be installed, we choose that.  If
#  we don't see either, we choose $libtypDefault.
#-----------------------------------------------------------------------------
    if (0) {
    } elsif ($typeList->{'ncurses'} && nCursesIsInstalled()) {
        $$libtypR = 'ncurses';
    } elsif ($typeList->{'bsd'} && bsdIsInstalled()) {
        $$libtypR = 'bsd';
    } else {
        $$libtypR = $typeList->{'default'};
    }
}



sub guessAtCursesLocation($$$) {
    my ($libtypR, $incR, $libsR) = @_;
#-----------------------------------------------------------------------------
#  Return as $$libtypR the type of Curses library we should use, e.g.
#  'ncurses', 'ncursesw' or 'bsd'.  May be undefined if we don't think
#  we have to choose between those on this system.
#
#  Return as $$incR the -I option we think is appropriate to get the
#  Curses interface header files.
#
#  Return as $$libsR the -L and -l options we think are needed to link
#  the main Curses library (doesn't cover panels/menus/forms).
#-----------------------------------------------------------------------------
    print qq{Making a guess for -I and -L/-l options...\n};

    # We need to move away from the inflexible $guess_cfg thing.  For
    # starters, we don't use it when the system looks like one with
    # wide-character Ncurses.  Next, we make a similar special case out of
    # ncurses (14.07.09) but leave the $guess_cfg code otherwise undisturbed
    # (so there is dead ncurses-related code in the $guess-cfg code).

    if (-f('/usr/include/ncursesw/ncurses.h')) {
        $$incR = '-I/usr/include/ncursesw';
        $$libsR = '-lncursesw';
        $$libtypR = 'ncursesw';
    } elsif (-f('/usr/include/ncurses/ncurses.h')) {
        # This tests only for a particular form of Ncurses installation.
        # There are, unfortunately, some systems (most Linux, I believe)
        # that put Ncurses in the default search directories, so e.g. they
        # have /usr/include/ncurses.h.  Such systems are handled by code
        # below.
        $$incR = '-I/usr/include/ncurses';
        $$libsR = '-lncurses';
        $$libtypR = 'ncurses';
    } else {
        my $guess1 = $guess_cfg->{$OSNAME};
        my $libtyp;
            # typically 'bsd' or 'ncurses'.  Undefined if we think
            # there's no choice of Curses version on this platform.

        my $guess;
        if (ref $guess1 eq 'HASH') {
            # For this platform, we have a choice of Curses library.

            chooseLibraryType($guess1, \$libtyp);
            $guess = $guess1->{$libtyp};
        } else {
            $guess = $guess1;
        }
        if (not defined $guess) {
            print STDERR <<"EOW";

I'm sorry, but I could not make a good guess for the includes and
libraries that are needed.  You'll need to set the CURSES_
environment variables as described in the INSTALL file.
OSNAME=$OSNAME
EOW
            exit 1;
        }
        if (ref $guess ne 'ARRAY') {
            die "FATAL: internal error: guess_cfg is bad";
        }

        if (!defined($libtyp)) {
            if (0) {
            } elsif (-f('/usr/include/ncurses/ncurses.h')) {
                $inc = '-I/usr/include/ncurses';
            } elsif (-f('/usr/include/curses/curses.h')) {
                $inc = '-I/usr/include/curses';
            } elsif (-f('/usr/include/ncurses.h')) {
                $inc = '';
            } elsif (-f('/usr/include/curses.h')) {
                $inc = '';
            } else {
                $inc  = $guess->[0];
            }
        } else {
            if ($libtyp eq 'ncurses') {
                if (-f('/usr/include/ncurses/ncurses.h')) {
                    $inc = '-I/usr/include/ncurses';
                } elsif (-f('/usr/include/ncurses.h')) {
                    $inc = '';
                } else {
                    $inc  = $guess->[0];
                }
            } else {
                if (-f('/usr/include/curses/curses.h')) {
                    $inc = '-I/usr/include/curses';
                } elsif (-f('/usr/include/curses.h')) {
                    $inc = '';
                } else {
                    $inc  = $guess->[0];
                }
            }
        }
        $libs = $guess->[1];

        $$libtypR   = $libtyp;
        $$incR      = $inc;
        $$libsR     = $libs;
    }
    print("Guesses:\n");
    print("  includes:    '$$incR'\n");
    print("  libs:        '$$libsR'\n");
    if (defined($$libtypR)) {
        print("  Curses type: $$libtypR");
    } else {
        print("  Curses type: irrelevant");
    }
    print("\n");
}



sub defaultLibTypeForOs($) {
    my ($osname) = @_;
#-----------------------------------------------------------------------------
#  Return the default library type for OS named '$osname'; if we don't think
#  there is a choice of library type on this OS, return undef.
#-----------------------------------------------------------------------------
    my $libType;

    my $guess  = $guess_cfg->{$OSNAME};

    if (ref $guess eq 'HASH') {
        # For this platform, we have a choice of Curses library.

        $libType = $guess->{'default'};
    }
    return $libType;
}


# A "library class" is a more abstract categorization than a "library type."
# The difference between two library types is just compiler and linker
# options to choose the right library, but different library classes
# have bigger differences and can have different hints files.  The
# library class is part of the hint file name.

my %libClass = (
                'bsd'      => 'bsd',
                'ncurses'  => 'ncurses',
                'ncursesw' => 'ncurses',
                'sysv'     => 'sysv',
                'visualc'  => 'visualc',
                'borland'  => 'borland',
);



sub makeCConfigH($) {
    my ($libType) = @_;
#-----------------------------------------------------------------------------
#  $libType is the kind of Curses library we are using - e.g. 'bsd',
#  'ncurses', or 'ncursesw'.  It may be undefined if there is no
#  choice on this system.
#-----------------------------------------------------------------------------
    print qq{Making a guess for "c-config.h"...\n};

    my $libClass;

    if (defined($libType)) {
        $libClass = $libClass{$libType};

        if (!defined($libClass)) {
            print STDERR ("Internal error: invalid library type '$libType' " .
                          "in makeCConfigH()\n");
            exit 1;
        }
    }
    my $hintsfile;
    if (defined($libType) && -f("hints/c-$OSNAME.$libType.h")) {
        $hintsfile = "hints/c-$OSNAME.$libType.h";
    } elsif (defined($libClass) && -f("hints/c-$OSNAME.$libClass.h")) {
        $hintsfile = "hints/c-$OSNAME.$libClass.h";
    } else {
        my $candidate = "hints/c-$OSNAME.h";
        if (-f($candidate)) {
            $hintsfile = $candidate;
        } else {
            print STDERR <<"EOW";

I'm sorry, but I couldn't find a hints file that was configured for
your OS (named $candidate).  You will need to create and configure a
"c-config.h" file for yourself.  Please see the "INSTALL" directions
for pointers on how to do this.
EOW
            exit 1;
        }
    }

    print("Choosing hints file '$hintsfile'\n");

    eval "require File::Copy;";
    if (! $@) {
        &File::Copy::copy($hintsfile, "c-config.h");
    } else {
        my $cp;

        if    ($OSNAME eq 'MSWin32') { $cp = "perl -MExtUtils::Command -e cp" }
        elsif ($OSNAME eq 'VMS')     { $cp = "copy/log"                       }
        else                         { $cp = "cp"                             }

        my $sys = "$cp $hintsfile c-config.h";
        if ($sys =~ m!([^\\:\w/. -])!) {
            print STDERR <<"EOW";

I'm sorry.  I was going to try to create a "c-config.h" for you, but it
looks like there are some non-standard characters in the exec string.
I'm feeling rather paranoid, so I'll let you look at the line and do
it by hand if it looks OK.  I wanted to execute a copy and thought I
might be able to use:

   $sys

but it has the (possibly) naughty character '$1' in it.      '
EOW
            exit 1;
        } else {
            system($sys);
        }
    }
}




sub guessPanelMenuFormLibs($$$$$) {

    my ($ncursesLibSearch, $libType, $panelLibsR, $menuLibsR, $formLibsR) = @_;

    my ($panelLibGuess, $menuLibGuess, $formLibGuess);

    if (defined($libType) && $libType eq "ncursesw") {
        $panelLibGuess = -lpanelw;
        $menuLibGuess  = -lmenuw;
        $formLibGuess  = -lformw;
    } else {
        $panelLibGuess = -lpanel;
        $menuLibGuess  = -lmenu;
        $formLibGuess  = -lform;
    }
    $$panelLibsR = "$ncursesLibSearch $panelLibGuess";
    $$menuLibsR  = "$ncursesLibSearch $menuLibGuess";
    $$formLibsR  = "$ncursesLibSearch $formLibGuess";
}



my $gen;
my $panels;
my $menus;
my $forms;

my @argv;
while (@ARGV) {
    my $arg = shift;

    if    ($arg eq 'GEN')    { $gen    = $arg   }
    elsif ($arg eq 'PANELS') { $panels = $arg   }
    elsif ($arg eq 'MENUS')  { $menus  = $arg   }
    elsif ($arg eq 'FORMS')  { $forms  = $arg   }
    else                     { push @argv, $arg }
}
@ARGV = @argv;   # pass non-Curses arguments to MakeMaker

print "GEN    function:  ", ($gen    ? "enabled" : "not applicable"), "\n";
print "PANELS functions: ", ($panels ? "enabled" : "not enabled"), "\n";
print "MENUS  functions: ", ($menus  ? "enabled" : "not enabled"), "\n";
print "FORMS  functions: ", ($forms  ? "enabled" : "not enabled"), "\n";
print "\n";

if (defined($inc) && defined($libs)) {
    # We have the info we need
    if (!defined($libType)) {
        $libType = defaultLibTypeForOs($OSNAME);
    }
} elsif (defined($inc) || defined($libs)) {
    die("You must specify both CURSES_LDFLAGS and CURSES_CFLAGS " .
        "environment variables or neither.  ");
} elsif (defined($libType)) {
    die("If you specify CURSES_LIBTYPE, you must also specify " .
        "CURSES_LDFLAGS and CURSES_CFLAGS");
} else {
    guessAtCursesLocation(\$libType, \$inc, \$libs);
}

if (not -e "c-config.h") {
    makeCConfigH($libType);
}

#  Major cheese alert.  Any -L for the curses library is probably
#  also needed for the panels library.
#

my $ncursesLibSearch;

$ncursesLibSearch = '';  # initial value

while ($libs =~ m{(-L\S+)}g) {
    $ncursesLibSearch .= $1 . ' ';
}

guessPanelMenuFormLibs($ncursesLibSearch, $libType,
                       \my $panelGuess, \my $menuGuess, \my $formGuess);


if ($panels and not $panel_libs) {
    $panel_libs = $panelGuess;
}

if ($menus and not $menu_libs) {
    $menu_libs = $menuGuess;
}

if ($forms and not $form_libs) {
    $form_libs = $formGuess;
}
# Both Perl and Ncurses have a form.h.  We have to include the Perl
# header files in our search path, but don't need form.h itself.
# Because the Curses form library header directory comes before the
# perl header directory in our search path, that isn't normally a
# problem.  EXCEPT: when there is no specific Curses form library
# directory, and the Curses form.h is instead in the general system
# search path, e.g.  /usr/include/form.h.  The system directories come
# after the Perl directory in the search.  There used to be a
# workaround here where we would simply add /usr/include to the front
# of the search path, but that is not only gross, but ineffective with
# some compilers, which ignore a -I option that adds a directory that
# is a system directory (e.g. gcc 3).

# To deal with this, we make a rough check for the problem, and if it
# appears to exist, we tell the user to fix it.

if ($forms and $form_inc !~ m{-I} and -f('/usr/include/form.h')) {
    print("WARNING: Your Curses form.h file appears to be in the default\n");
    print("system search path, which will not work for us because of\n");
    print("the conflicting Perl form.h file.  This means your 'make' will\n");
    print("probably fail unless you fix this, as described in the INSTALL\n");
    print("file.\n");
}

my $clean =
    'config.h CursesDef.h c-config.h cdemo testsym testint testtyp *.i *.s';
my $realc = $gen
    ? 'list.syms Curses.pm ' .
      'CursesFun.c CursesVar.c CursesCon.c CursesTyp.h CursesBoot.c'
    : "";

my $components =
    ($panels ? " PANELS " : "") .
    ($menus  ? " MENUS "  : "") .
    ($forms  ? " FORMS "  : "");

WriteMakefile(NAME         => 'Curses',
              INC          => "$panel_inc $menu_inc $form_inc $inc",
              LIBS         => [ "$panel_libs $menu_libs $form_libs $libs" ],
              H            => [ 'CursesDef.h'                   ],
              clean        => { FILES      => $clean              },
              realclean    => { FILES      => $realc              },
              dist         => { COMPRESS   => 'gzip -9f'          },
              postamble    => { COMPONENTS => $components         },
              VERSION_FROM => 'Curses.pm',
);

sub MY::postamble {

    my ($this, %args) = @_;

    my $echo = $OSNAME eq 'VMS' ? 'write sys$output' : 'echo';
    my $objext = $OSNAME eq 'MSWin32' ? 'obj' : 'o';
    my $mf   = <<EOM;

config.h:
	./makeConfig $args{COMPONENTS} >\$@

CursesDef.h: c-config.h Makefile.PL list.syms config.h
	CC='\$(CC)' \\
	INC='\$(INC)' \\
	CCFLAGS='\$(CCFLAGS)' \\
	LDLOADLIBS='\$(LDLOADLIBS)' \\
	LDDLFLAGS='\$(LDDLFLAGS)' \\
	\$(PERL) testsyms \$(TESTSYMS_OPTS)

c-config.h:
	@ $echo "You need to make a c-config.h.  See the INSTALL document.";
	@ exit 1
cdemo: cdemo.c c-config.h
EOM

    if ($OSNAME eq 'VMS') {
        $mf .= <<EOM;
	\$(CC) \$(INC) cdemo.c
	\$(LD) cdemo\$(OBJ_EXT), \$(LDLOADLIBS), CURSES2.OPT/opt
EOM
    }
    else {
        $mf .= <<EOM;
	\$(CC) \$(INC) -o cdemo cdemo.c \$(LDLOADLIBS)
EOM
    }

    if ($gen) {
        $mf .= <<EOM;

Curses.c    :: \\
  CursesWide.c \\
  CursesFun.c \\
  CursesFunWide.c \\
  CursesVar.c \\
  CursesCon.c \\
  CursesTyp.h \\
  CursesBoot.c
	@\$(NOOP)

config      :: \\
  list.syms \\
  Curses.pm \\
  CursesFun.c \\
  CursesFunWide.c \\
  CursesVar.c \\
  CursesCon.c \\
  CursesTyp.h \\
  CursesBoot.c

list.syms    : gen/make.list.syms gen/list.fun gen/list.var gen/list.typ
	\$(PERL) gen/make.list.syms

Curses.pm    : gen/make.Curses.pm gen/list.fun gen/list.var gen/list.con
	\$(PERL) gen/make.Curses.pm

CursesFun.c  : gen/make.CursesFun.c gen/list.fun
	\$(PERL) gen/make.CursesFun.c

CursesVar.c  : gen/make.CursesVar.c gen/list.var
	\$(PERL) gen/make.CursesVar.c

CursesCon.c  : gen/make.CursesCon.c gen/list.con
	\$(PERL) gen/make.CursesCon.c

CursesTyp.h : gen/make.CursesTyp.h gen/list.typ
	\$(PERL) gen/make.CursesTyp.h

CursesBoot.c : gen/make.CursesBoot.c gen/list.fun gen/list.var gen/list.con
	\$(PERL) gen/make.CursesBoot.c

EOM
    }

    return $mf;
}
__END__
