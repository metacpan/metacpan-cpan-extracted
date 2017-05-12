#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use Pod::Usage;

use lib 'lib';

use Acme::Chef;

use vars qw/$VERSION/;
$VERSION = '0.05';

@ARGV or pod2usage(
  -msg     => "You need to specify a .chef file to compile.",
  -verbose => 2,   # Manual
);

my $program_file = shift @ARGV;
my $target_file  = shift @ARGV;

-f $program_file or pod2usage(
  -msg     => "You specified an invalid source filename.",
  -verbose => 0,   # Only synopsis
);

not defined $target_file and pod2usage(
  -msg     => "You specified an invalid target filename.",
  -verbose => 0,   # Only synopsis
);

open my $fh, '<', $program_file or pod2usage(
  -msg     => "You specified an invalid filename.",
  -verbose => 0,   # Only synopsis
);

local $/ = undef;

my $code = <$fh>;

close $fh;

my $compiled = Acme::Chef->compile($code);

my $module_code;
foreach my $module (
         qw(
            Acme::Chef::Ingredient Acme::Chef::Container
            Acme::Chef Acme::Chef::Recipe
           )
        ) {
   my $module_file = join '/', (split /::/, $module);

   my $full_path;
   foreach my $dir (@INC) {
      my $directory = $dir;
      $directory =~ s/\/$//;
      my $file = "$directory/$module_file.pm";
      if (-f $file) {
         $full_path = $file;
         last;
      }
   }

   die "Could not find $module in \@INC."
     if not defined $full_path;

   open my $fh, '<', $full_path or die "Could not find $module in \@INC. ($!)";

   # $module_code .= "\npackage $module;\n";

   local $/ = "\n";

   while(<$fh>) {
      last if /^__END__$/;
      last if /^__DATA__$/;
      s/^use Acme::Chef::\w+;.*//;
      $module_code .= $_;
   }

   $module_code .= "\n";

   close $fh;
}

my $dump = $compiled->dump('autorun');

open my $fileh, '>', $target_file or die "Could not open target file ($target_file): $!";

print $fileh "# Insert shebang here\nuse strict;\nuse warnings;\n";
print $fileh $module_code,"\n";
print $fileh "print ", $dump;

close $fileh or die "Could not complete writing to file ($target_file): $!";

__END__

=pod

=head1 NAME

compilechef - A compiler for the Chef language using Acme::Chef

=head1 SYNOPSIS

compilechef in.chef out.pl

=head1 DESCRIPTION

Experimental software.

This script tries to "compile" a chef program into a Perl program.
It includes the modules Acme::Chef::* into the generated code.
It does so by searching your @INC for the module files and inserting
the module code into the source code of the executable. Hence, the
generated executable should be somewhat more portable.

This script should run in any environment that can execute chef
programs using the chef.pl interpreter except maybe on VMS and MacOS.

Anything else: See L<Acme::Chef>.

=head1 AUTHOR

Steffen Mueller, chef-module at steffen-mueller dot net

Chef was designed by David Morgan-Mar.

=head1 COPYRIGHT

Copyright (c) 2002-2003 Steffen Mueller. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut


