use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion-spirit!aion!spirit/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Spirit - functions for controlling the program execution process
# 
# # VERSION
# 
# 0.0.1
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Spirit;

package A {
    sub x_1() { 1 }
    sub x_2() { 2 }
    sub y_1($) { 1+shift }
    sub y_2($) { 2+shift }
}

aroundsub "A", qr/_2$/, sub { shift->(@_[1..$#_]) + .03 };

::is scalar do {A::x_1}, scalar do{1}, 'A::x_1     # -> 1';

# Perl cached subroutines with prototype "()" in main:: as constant. aroundsub should be applied in a BEGIN block to avoid this:
::is scalar do {A::x_2}, scalar do{2}, 'A::x_2         # -> 2';
::is scalar do {(\&A::x_2)->()}, scalar do{2.03}, '(\&A::x_2)->() # -> 2.03';

# Functions with parameters not cached:
::is scalar do {A::y_1 .5}, scalar do{1.5}, 'A::y_1 .5  # -> 1.5';
::is scalar do {A::y_2 .5}, scalar do{2.53}, 'A::y_2 .5  # -> 2.53';

# 
# # DESCRIPTION
# 
# A Perl program consists of packages, globals, subroutines, lists, and scalars. That is, it is simply data that, unlike a C program, can be “changed on the fly.”
# 
# Thus, this module provides convenient functions for transforming all these entities, as well as maintaining their integrity.
# 
# # SUBROUTINES
# 
# ## aroundsub ($pkg, $re, $around)
# 
# Wraps the functions in the package in the specified regular sequence.
# 
# The package may not be specified for the current:
# 
# File N.pm:
#@> N.pm
#>> package N;
#>> 
#>> use Aion::Spirit qw/aroundsub/;
#>> 
#>> use constant z_2 => 10;
#>> 
#>> aroundsub qr/_2$/, sub { shift->(@_[1..$#_]) + .03 };
#>> 
#>> sub x_1() { 1 }
#>> sub x_2() { 2 }
#>> sub y_1($) { 1+shift }
#>> sub y_2($) { 2+shift }
#>> 
#>> 1;
#@< EOF
# 
done_testing; }; subtest 'aroundsub ($pkg, $re, $around)' => sub { 
use lib ".";
use N;

::is scalar do {N::x_1}, scalar do{1}, 'N::x_1          # -> 1';
::is scalar do {N::x_2}, scalar do{2.03}, 'N::x_2          # -> 2.03';
::is scalar do {N::y_1 0.5}, scalar do{1.5}, 'N::y_1 0.5      # -> 1.5';
::is scalar do {N::y_2 0.5}, scalar do{2.53}, 'N::y_2 0.5      # -> 2.53';

# 
# ## wrapsub ($sub, $around)
# 
# Wraps a function in the specified.
# 
done_testing; }; subtest 'wrapsub ($sub, $around)' => sub { 
sub sum(@) { my $x = 0; $x += $_ for @_; $x }

BEGIN {
    *avg = wrapsub \&sum, sub { my $x = shift; $x->(@_) / @_ };
}

::is scalar do {avg 1,2,5}, scalar do{(1+2+5) / 3}, 'avg 1,2,5  # -> (1+2+5) / 3';

::is scalar do {Sub::Util::subname \&avg}, "main::sum__AROUND", 'Sub::Util::subname \&avg   # => main::sum__AROUND';

# 
# ## ASSERT ($ok, $message)
# 
# This is assert. This is checker scalar by nullable.
# 
done_testing; }; subtest 'ASSERT ($ok, $message)' => sub { 
my $ok = 0;
ASSERT $ok == 0, "Ok";

::like scalar do {eval { ASSERT $ok, "Ok not equal 0!" }; $@}, qr!Ok not equal 0\!!, 'eval { ASSERT $ok, "Ok not equal 0!" }; $@  # ~> Ok not equal 0!';

my $ten = 11;

::like scalar do {eval { ASSERT $ten == 10, sub { "Ten maybe 10, but ten = $ten!" } }; $@}, qr!Ten maybe 10, but ten = 11\!!, 'eval { ASSERT $ten == 10, sub { "Ten maybe 10, but ten = $ten!" } }; $@  # ~> Ten maybe 10, but ten = 11!';

# 
# ## firstidx (&sub, @list)
# 
# Searches the list for the first match and returns the index of the found element.
# 
done_testing; }; subtest 'firstidx (&sub, @list)' => sub { 
::is scalar do {firstidx { /3/ } 1,2,3}, scalar do{2}, 'firstidx { /3/ } 1,2,3  # -> 2';
::is scalar do {firstidx { /4/ } 1,2,3}, scalar do{undef}, 'firstidx { /4/ } 1,2,3  # -> undef';

# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)
# 
# # LICENSE
# 
# This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Spirit module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
