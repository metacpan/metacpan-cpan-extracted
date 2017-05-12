#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 1995 - 2009 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;
use File::Spec;
use File::Copy;
use ExtUtils::MakeMaker;

BEGIN
{
    eval { require Config_m; }; # ExtUtils::FakeConfig (+ ActivePerl)
    eval { require Config;   }  # Everyone else
    if ($@);
}

my($good,$text,$answer,$default,$file,$orig,$PATCHLEVEL,$SUBVERSION);

my($CC,$EXE) = @Config::Config{'cc','_exe'}; # or @Config::Config{'cc','exe_ext'};

my(@PATH) = (File::Spec->path(), '.');

my $ORIG = 'src';
my $C_XS = 'C_XS';
my $Perl = 'Perl';

my $Patchlevel = 'patchlevel.h';

my(@C_XS) = qw(Pcalc.pm Pcalc.xs DatePcalc.c DatePcalc.h ToolBox.h typemap);
my(@Perl) = qw(Pcalc.pm);

my(@Clean) = (@C_XS, $Patchlevel, qw(Pcalc.c));

my %Parameters =
(
    'NAME'              => 'Date::Pcalc',
    'VERSION_FROM'      => 'Pcalc.pm',
    'PREREQ_PM'         =>
                              {
                                  'Carp::Clan'  => 5.3,
                                  'Bit::Vector' => 7.1
                              },
#   ($] >= 5.005 ?
#       ('ABSTRACT'     => 'Gregorian calendar date calculations',
#        'AUTHOR'       => 'Steffen Beyer <STBEY@cpan.org>') : ()),
#   ($] >= 5.005 && $^O eq 'MSWin32' && $Config::Config{'archname'} =~ /-object\b/i ?
#       ('CAPI'         => 'TRUE') : ()),
    'dist'              => { COMPRESS => "gzip -9", SUFFIX => "gz" },
    'clean'             => { FILES => join(' ', @Clean) }
);

sub Check_CC
{
    my($cmd) = $_[0];
    my($dir,$abs);
    return $cmd if (-x $cmd or MM->maybe_command($cmd));
    foreach $dir (@PATH)
    {
        $abs = File::Spec->catfile($dir, $cmd);
        return $cmd if (-x $abs or MM->maybe_command($abs));
    }
    return '';
}

sub Have_CC
{
    my($cmd) = $_[0];
    my(@chunks) = split(/ /, $cmd); # may contain args; try to find out the program part
    while (@chunks)
    {
        return $cmd if (($cmd = Check_CC(join(' ', @chunks      ))) ne '');
        return $cmd if (($cmd = Check_CC(join(' ', @chunks, $EXE))) ne '');
        pop(@chunks);
    }
    return '';
}

if (($good = Have_CC($CC)) ne '')
{
    $CC = $good;
    $text = 'located';
}
else
{
    $CC =~ s/\s+-.+$//;
    $CC .= $EXE;
    $text = 'cannot locate';
}

eval { require ExtUtils::CBuilder; };
unless ($@)
{
    print "Testing your C compiler...\n";
    if ( ExtUtils::CBuilder->new( quiet => 1 )->have_compiler() )
    {
        $good = $CC;
        $text = 'located and successfully tested';
    }
    else
    {
        $good = '';
        $text = 'could not successfully use';
    }
}

print <<"VERBATIM";

Config.pm indicates that your version of Perl was built with
this C compiler:

    $CC

VERBATIM

if ($good ne '')
{
    print <<"VERBATIM";
I have $text this compiler on your system.

You now have the option to either install the (fast) C/XS implementation of
this module (recommended), or a (somewhat slower) pure-Perl implementation.

VERBATIM
}
else
{
    print <<"VERBATIM";
I $text this compiler on your system.

Therefore you now have the option to install a (somewhat slower) pure-Perl
implementation of this module instead of the (fast) C/XS implementation.

If however the C compiler mentioned above really is installed on your system,
please make sure it can be found in the PATH and then try running this program
again. Or if you think I should have found this compiler, and if you are sure
it is available and functional, simply answer 'c' to the next question.

VERBATIM
}

$answer = '';
$default = ($good ne '') ? 'c' : 'p';
while (1)
{
    $answer = prompt(q{Install C/XS version (answer 'c') or pure-Perl version (answer 'p')?}, $default);
    last if $answer =~ /^[CcPp]$/;
}

foreach $file (@Clean)
{
    if (-e $file) { unless (unlink($file)) { warn "Can't unlink file <$file>: $!\n"; exit 0; } }
}

if ($answer =~ /^[Cc]$/)
{
    foreach $file (@C_XS)
    {
        $orig = File::Spec->catfile($ORIG,$C_XS,$file);
        unless (copy($orig,$file)) { warn "Can't copy file <$orig> to <$file>: $!\n"; exit 0; }
    }
    $Parameters{'OBJECT'} = '$(O_FILES)';
    WriteMakefile(%Parameters);

    $PATCHLEVEL = $Config::Config{'PATCHLEVEL'} || $Config::Config{'patchlevel'} || substr($],2,3);
    $SUBVERSION = $Config::Config{'SUBVERSION'} || $Config::Config{'subversion'} || substr($],5) || 0;

    unless
    (
        open(PATCHLEVEL, ">$Patchlevel")                          and
        print("Writing $Patchlevel for $^X ($])\n")               and
        printf(PATCHLEVEL "#define PATCHLEVEL %d\n", $PATCHLEVEL) and
        printf(PATCHLEVEL "#define SUBVERSION %d\n", $SUBVERSION) and
        close(PATCHLEVEL)
    )
    {
        warn "Oops: Could not write file <$Patchlevel>: $!\n";
        warn "However, you might succeed in building this module anyway;\n";
        warn "Just give it a try!\n";
        exit 0;
    }
}
else
{
    foreach $file (@Perl)
    {
        $orig = File::Spec->catfile($ORIG,$Perl,$file);
        unless (copy($orig,$file)) { warn "Can't copy file <$orig> to <$file>: $!\n"; exit 0; }
    }
    WriteMakefile(%Parameters);
}

__END__

