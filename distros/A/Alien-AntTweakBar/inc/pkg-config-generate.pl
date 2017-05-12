#!/usr/bin/env perl

my ($output, $prefix, $version) = @ARGV;

my $data = <<TEMPLATE;
prefix=$prefix
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: anttweakbar
Description: small OpenGL GUI library
Version: $version
URL: http://anttweakbar.sourceforge.net
Libs: -L\${libdir} -lanttweakbar
Cflags: -I\${includedir}
TEMPLATE

open my $out, ">", $output or die("can't open output: $!");
print $out $data;
