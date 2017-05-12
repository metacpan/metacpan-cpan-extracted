#!/usr/bin/perl -w
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.

#This is the magical make maker.  It does even more complicated stuff than
#normal because I use TeXInfo and want it linked in.

use ExtUtils::MakeMaker;

#see lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Cwd;
my $dir = cwd();
$dir =~ s/^.*\/([^\/]+)$/$1/;

$ModName=$dir;
$VERSION="0.41";

my $Pfiles="lib/$ModName/". join(".pm lib/$ModName/",
        'TieRCService','Cfgfile', 'CfgArgs',
        'TieAliases', 'TieGeneric','TieGroup','TieHost', 'TieNamed', 'TieNet',
        'TiePh',      'TieProto',  'TieRsrc', 'TieServ', 'TieShadow','TieUser').
	'.pm lib/Secure/File.pm';

sub MY::postamble
{
   "\n#This assumes, of course, that you have these tools installed...\n".
   "$ModName"."_toc.html: $ModName.tex $Pfiles Intro.tex\n".
   "\ttxh2texi --pod --output-file=".$ModName."2.tex\n".
   "\ttxh2texi --rcs --up-node=Revisions --main-node-prefix=Files --output-file=$ModName-revs.tex\n".
   "\ttexi2html -glossary -split_node -menu $ModName.tex\n\n".
   "texi: $ModName"."_toc.html \n".
   "\ttexihtml_mod $ModName\n\n";
}


#My script files
opendir D, 'bin';
my ($A,$b,@_Scripts)=readdir D;
closedir D;
my @Scripts;
foreach my $I (@_Scripts)
{
   if ($I=~/makefile/i) {next;}
   if ($I =~/\.tex$/i) {next;}
   push @Scripts, "bin/$I";
}


WriteMakefile(
    'NAME'      => $ModName, #'-Tools',
    'dist'    => {COMPRESS=> 'gzip -9f', SUFFIX=>'gz', 
                  POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../'
                  },
    'linkext' => {LINKTYPE => '' }, 
    'clean'   => {FILES => "*% *.html *~ www-* .htp* .htg*"},
    VERSION => $VERSION,
    'VERSION_FROM' => '', # finds $VERSION
    'EXE_FILES' => [@Scripts],
    'MAN1PODS'  => {map {my $a=$_; s/^bin\//.\/blib\/man1\//; $a,"$_.\$(MAN1EXT)";} @Scripts},
);
