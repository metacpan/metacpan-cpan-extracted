#!/usr/bin/perl

use strict;
use warnings;
use 5.014;  # s///r

use blib;

use Getopt::Long;
GetOptions( 'n|no-output' => \my $NO_OUT ) or exit 1;

use App::MatrixTool;

my $helpcmd = App::MatrixTool::Command::help->new;

my $SCRIPT = "bin/matrixtool";
open my $in, "<", $SCRIPT or
   die "Cannot open $SCRIPT for reading - $!";
$NO_OUT or open STDOUT, ">", "$SCRIPT.new" or
   die "Cannot open $SCRIPT.new for writing - $!";

while( <$in> ) {
   print;
   last if $_ =~ m/^=head1 COMMANDS/;
}

print "\n";

foreach my $cmd ( $helpcmd->commands ) {
   my $cmdname = $cmd->name;

   print <<"EOF" =~ s/^ {6}//mgr;
      =head2 $cmdname

      ${\ $cmd->description }
EOF

   my @argspecs = @{ $cmd->argspecs };
   print <<"EOF";

   \$ matrixtool $cmdname ${\ join ' ', map $helpcmd->_argdesc($_), @argspecs }

EOF

   my $optspecs;
   if( $optspecs = $cmd->optspecs and @$optspecs ) {

      print <<"EOF" =~ s/^ {9}//mgr;
         Options:

         =over 4

EOF

      foreach my $optspec ( sort { $a->name cmp $b->name } @$optspecs ) {
         my $name = "--".$optspec->print_name;
         $name .= " (-".$optspec->shortname.")" if defined $optspec->shortname;

         print <<"EOF" =~ s/^ {12}//mgr;
            =item * $name

            ${\ $optspec->description }

EOF
      }

      print <<"EOF" =~ s/^ {9}//mgr;
         =back

EOF
   }

   print <<"EOF" =~ s/^ {6}//mgr;
      See also L<${\ $cmd->package }>.

EOF
}

# Consume the previous content
while( <$in> ) {
   print, last if m/^=(?:head1|cut)/;
}

print while <$in>;

exit if $NO_OUT;

close STDOUT;
close $in;

rename "$SCRIPT", "$SCRIPT.old" or die "Cannot rename to $SCRIPT.old - $!";
rename "$SCRIPT.new", "$SCRIPT" or die "Cannot rename to $SCRIPT - $!";
