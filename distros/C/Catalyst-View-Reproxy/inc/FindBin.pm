#line 1
# FindBin.pm
#
# Copyright (c) 1995 Graham Barr & Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

#line 90

package FindBin;
use Carp;
require 5.000;
require Exporter;
use Cwd qw(getcwd abs_path);
use Config;
use File::Basename;
use File::Spec;

@EXPORT_OK = qw($Bin $Script $RealBin $RealScript $Dir $RealDir);
%EXPORT_TAGS = (ALL => [qw($Bin $Script $RealBin $RealScript $Dir $RealDir)]);
@ISA = qw(Exporter);

$VERSION = "1.44";

sub init
{
 *Dir = \$Bin;
 *RealDir = \$RealBin;

 if($0 eq '-e' || $0 eq '-')
  {
   # perl invoked with -e or script is on C<STDIN>

   $Script = $RealScript = $0;
   $Bin    = $RealBin    = getcwd();
  }
 else
  {
   my $script = $0;

   if ($^O eq 'VMS')
    {
     ($Bin,$Script) = VMS::Filespec::rmsexpand($0) =~ /(.*\])(.*)/s;
     ($RealBin,$RealScript) = ($Bin,$Script);
    }
   else
    {
     my $dosish = ($^O eq 'MSWin32' or $^O eq 'os2');
     unless(($script =~ m#/# || ($dosish && $script =~ m#\\#))
            && -f $script)
      {
       my $dir;
       foreach $dir (File::Spec->path)
	{
        my $scr = File::Spec->catfile($dir, $script);
	if(-r $scr && (!$dosish || -x _))
         {
          $script = $scr;

	  if (-f $0)
           {
	    # $script has been found via PATH but perl could have
	    # been invoked as 'perl file'. Do a dumb check to see
	    # if $script is a perl program, if not then $script = $0
            #
            # well we actually only check that it is an ASCII file
            # we know its executable so it is probably a script
            # of some sort.

            $script = $0 unless(-T $script);
           }
          last;
         }
       }
     }

     croak("Cannot find current script '$0'") unless(-f $script);

     # Ensure $script contains the complete path incase we C<chdir>

     $script = File::Spec->catfile(getcwd(), $script)
       unless File::Spec->file_name_is_absolute($script);

     ($Script,$Bin) = fileparse($script);

     # Resolve $script if it is a link
     while(1)
      {
       my $linktext = readlink($script);

       ($RealScript,$RealBin) = fileparse($script);
       last unless defined $linktext;

       $script = (File::Spec->file_name_is_absolute($linktext))
                  ? $linktext
                  : File::Spec->catfile($RealBin, $linktext);
      }

     # Get absolute paths to directories
     $Bin     = abs_path($Bin)     if($Bin);
     $RealBin = abs_path($RealBin) if($RealBin);
    }
  }
}

BEGIN { init }

*again = \&init;

1; # Keep require happy

