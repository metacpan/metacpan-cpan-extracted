#! perl -w

use strict ;
require 5.006 ;

use lib '.';
use private::MakeUtil;
use ExtUtils::MakeMaker 5.16 ;

my $WALL= '';
$WALL = ' -Wall -Wno-comment ' if $Config{'cc'} =~ /gcc/ ;

my $LIBLZMA_LIB ;
my $LIBLZMA_INCLUDE ;
my $LIBS = '-llzma';

ParseCONFIG() ;

UpDowngrade(getPerlFiles('MANIFEST'))
    unless $ENV{PERL_CORE};

WriteMakefile(
    NAME         => 'Compress::Raw::Lzma',
    VERSION_FROM => 'lib/Compress/Raw/Lzma.pm',
    INC          => "-I$LIBLZMA_INCLUDE" ,
    LIBS          => ["-L${LIBLZMA_LIB} $LIBS"],

    DEFINE       => "$WALL " ,
    XS           => { 'Lzma.xs' => 'Lzma.c'},
    'depend'     => { 'Makefile'   => 'config.in' },
    'dist'       => { COMPRESS     => 'gzip',
                      TARFLAGS     => '-chvf',
                      SUFFIX       => 'gz',
                      DIST_DEFAULT => 'MyTrebleCheck tardist',
                    },

    (
      $ENV{SKIP_FOR_CORE}
        ? (MAN3PODS    => {})
        : ()
    ),

    (
      $] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Compress/Raw/Lzma.pm',
            AUTHOR       => 'Paul Marquess <pmqs@cpan.org>')
        : ()
    ),

     ( eval { ExtUtils::MakeMaker->VERSION(6.46) }
        ? ( META_MERGE  => {

                "meta-spec" => { version => 2 },

                no_index => {
                    directory => [ 't', 'private' ],
                },

                resources   => {

                    bugtracker  => {
                        web     => 'https://github.com/pmqs/Compress-Raw-Lzma/issues'
                    },

                    homepage    => 'https://github.com/pmqs/Compress-Raw-Lzma',

                    repository  => {
                        type    => 'git',
                        url     => 'git://github.com/pmqs/Compress-Raw-Lzma.git',
                        web     => 'https://github.com/pmqs/Compress-Raw-Lzma',
                    },
                },
              }
            )
        : ()
    ),

    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),

) ;

my @names;
while (<DATA>)
{
    chomp;
    s/^\s*//;
    s/\s*$//;
    next if /^[^A-Z]/i || /^$/;
    my ($name, $type) = split /\s+/, $_;

    if (defined $type && $type =~ /enum/i)
	  { push @names, { name => $name, macro => ["#if 1\n", "#endif\n"] } }
    elsif (defined $type && $type =~ /string/i)
	  { push @names, { name => $name, type => "PV", macro => ["#ifdef $name \n", "#endif\n"] } }
    elsif (defined $type && $type =~ /int/i)
	  { push @names, { name => $name, type => "IV", macro => ["#if 1\n", "#endif\n"] } }
    else
      { push @names, { name => $name                  } }

}

if (eval {require ExtUtils::Constant; 1}) {
    # Check the constants above all appear in @EXPORT in Lzma.pm
    my %names = map { $_ => 1    }
                map { $_->{name} }
                @names ;
    open F, "<lib/Compress/Raw/Lzma.pm" or die "Cannot open Lzma.pm: $!\n";
    while (<F>)
    {
        last if /^\s*\@EXPORT\s+=\s+qw\(/ ;
    }

    while (<F>)
    {
        last if /^\s*\)/ ;
        /(\S+)/ ;
        delete $names{$1} if defined $1 ;
    }
    close F ;

    if ( keys %names )
    {
        my $missing = join ("\n\t", sort keys %names) ;
        die "The following names are missing from \@EXPORT in Lzma.pm\n" .
            "\t$missing\n" ;
    }

    ExtUtils::Constant::WriteConstants(
                                     NAME     => 'Lzma',
                                     NAMES    => \@names,
                                     C_FILE   => 'constants.h',
                                     XS_FILE  => 'constants.xs',

                                    );
}
else {
    foreach my $name (qw( constants.h constants.xs ))
    {
        my $from = catfile('fallback', $name);
        copy ($from, $name)
          or die "Can't copy $from to $name: $!";
    }
}

sub ParseCONFIG
{
    my ($k, $v) ;
    my @badkey = () ;
    my %Info = () ;
    my @Options = qw( INCLUDE LIB ) ;
    my %ValidOption = map {$_, 1} @Options ;
    my %Parsed = %ValidOption ;
    my $CONFIG = 'config.in' ;

    print "Parsing $CONFIG...\n" ;

    open(F, "<$CONFIG") or die "Cannot open file $CONFIG: $!\n" ;
    while (<F>) {
	s/^\s*|\s*$//g ;
	next if /^\s*$/ or /^\s*#/ ;
	s/\s*#\s*$// ;

	($k, $v) = split(/\s+=\s+/, $_, 2) ;
	$k = uc $k ;
	if ($ValidOption{$k}) {
	    delete $Parsed{$k} ;
	    $Info{$k} = $v ;
	}
	else {
	    push(@badkey, $k) ;
	}
    }
    close F ;

    print "Unknown keys in $CONFIG ignored [@badkey]\n"
	if @badkey ;

    # check parsed values
    my @missing = () ;
    die "The following keys are missing from $CONFIG  [@missing]\n"
        if @missing = keys %Parsed ;

    $LIBLZMA_INCLUDE = defined $ENV{'LIBLZMA_INCLUDE'}
                            ? $ENV{'LIBLZMA_INCLUDE'}
                            : $Info{'INCLUDE'} ;
    $LIBLZMA_LIB = defined $ENV{'LIBLZMA_LIB'}
                            ? $ENV{'LIBLZMA_LIB'}
                            : $Info{'LIB'} ;

    if ($^O eq 'VMS') {
        $LIBLZMA_INCLUDE = VMS::Filespec::vmspath($LIBLZMA_INCLUDE);
        $LIBLZMA_LIB = VMS::Filespec::vmspath($LIBLZMA_LIB);
    }


    print <<EOM if 0 ;
    INCLUDE         [$LIBLZMA_INCLUDE]
    LIB             [$LIBLZMA_LIB]

EOM

    print "Looks Good.\n" ;

}
__DATA__

# base.h
########
# lzma-ret Return values used by several functions in liblzma
LZMA_OK                 enum
LZMA_STREAM_END         enum
LZMA_NO_CHECK       	enum
LZMA_UNSUPPORTED_CHECK  enum
LZMA_GET_CHECK          enum
LZMA_MEM_ERROR          enum
LZMA_MEMLIMIT_ERROR     enum
LZMA_FORMAT_ERROR       enum
LZMA_OPTIONS_ERROR      enum
LZMA_DATA_ERROR         enum
LZMA_BUF_ERROR          enum
LZMA_PROG_ERROR         enum

# lzma_action: The `action' argument for lzma_code()
LZMA_RUN                enum
LZMA_SYNC_FLUSH         enum
LZMA_FULL_FLUSH         enum
LZMA_FINISH             enum

# bcj.h
#########
LZMA_FILTER_X86
LZMA_FILTER_POWERPC
LZMA_FILTER_IA64
LZMA_FILTER_ARM
LZMA_FILTER_ARMTHUMB
LZMA_FILTER_SPARC


# block.h
#########
LZMA_BLOCK_HEADER_SIZE_MIN
LZMA_BLOCK_HEADER_SIZE_MAX

# check.h

# lzma_check_typ: Type of the Check
LZMA_CHECK_NONE                 enum
LZMA_CHECK_CRC32                enum
LZMA_CHECK_CRC64                enum
LZMA_CHECK_SHA256               enum

LZMA_CHECK_ID_MAX
LZMA_CHECK_SIZE_MAX

# container.h
#############
LZMA_PRESET_DEFAULT
LZMA_PRESET_LEVEL_MASK
LZMA_PRESET_EXTREME

LZMA_TELL_NO_CHECK
LZMA_TELL_UNSUPPORTED_CHECK
LZMA_TELL_ANY_CHECK
LZMA_CONCATENATED


# delta.h
#########
LZMA_FILTER_DELTA
LZMA_DELTA_DIST_MIN
LZMA_DELTA_DIST_MAX
LZMA_DELTA_TYPE_BYTE enum

# filter.h
##########
LZMA_FILTERS_MAX


# index.h
##########
# Below supported from 5.0.0 onwards
#LZMA_INDEX_ITER_ANY enum
#LZMA_INDEX_ITER_STREAM enum
#LZMA_INDEX_ITER_BLOCK enum
#LZMA_INDEX_ITER_NONEMPTY_BLOCK enum


# index_hash.h
##############

# lzma.h
#########
#LZMA_FILTER_LZMA1
LZMA_FILTER_LZMA2

# lzma_match_finder: Match finders
LZMA_MF_HC3             enum
LZMA_MF_HC4             enum
LZMA_MF_BT2             enum
LZMA_MF_BT3             enum
LZMA_MF_BT4             enum

# lzma_mode: LZMA compression modes
LZMA_MODE_FAST          enum
LZMA_MODE_NORMAL        enum

LZMA_DICT_SIZE_MIN
LZMA_DICT_SIZE_DEFAULT

LZMA_LCLP_MIN
LZMA_LCLP_MAX
LZMA_LC_DEFAULT

LZMA_LP_DEFAULT

LZMA_PB_MIN
LZMA_PB_MAX
LZMA_PB_DEFAULT

# stream_flags.h
################

LZMA_STREAM_HEADER_SIZE

LZMA_BACKWARD_SIZE_MIN
#LZMA_BACKWARD_SIZE_MAX

# version.h
###########
LZMA_VERSION
LZMA_VERSION_MAJOR
LZMA_VERSION_MINOR
LZMA_VERSION_PATCH
LZMA_VERSION_STABILITY

LZMA_VERSION_STABILITY_STRING   string
LZMA_VERSION_STRING             string

#lzma_version_number		int
#lzma_version_string		string

# vli.h
#######
#LZMA_VLI_MAX
#LZMA_VLI_UNKNOWN
#LZMA_VLI_BYTES_MAX

# End of file
