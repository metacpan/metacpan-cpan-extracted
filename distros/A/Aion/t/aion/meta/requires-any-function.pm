use common::sense; use open qw/:std :utf8/;  use Carp qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN {     $SIG{__DIE__} = sub {         my ($s) = @_;         if(ref $s) {             $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s;             die $s;         } else {             die Carp::longmess defined($s)? $s: "undef"         }     };      my $t = File::Slurper::read_text(__FILE__);     my $s = '/tmp/.liveman/perl-aion/aion!meta!requires-any-function.pm';      File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $s), File::Path::rmtree($s) if -e $s;  	File::Path::mkpath($s);  	chdir $s or die "chdir $s: $!";  	push @INC, '/ext/__/@lib/perl-aion/lib', 'lib'; 	 	$ENV{PROJECT_DIR} = '/ext/__/@lib/perl-aion'; 	$ENV{TEST_DIR} = $s;      while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) {         my ($file, $code) = ($1, $2);         $code =~ s/^#>> //mg;         File::Path::mkpath(File::Basename::dirname($file));         File::Slurper::write_text($file, $code);     } } # package Aion::Meta::RequiresAnyFunction;
# 
# use common::sense;
# 
# use Aion::Meta::Util qw//;
# 
# Aion::Meta::Util::create_getters(qw/pkg name/);
# 
# sub new {
#     my $cls = shift;
#     bless {@_}, ref $cls || $cls;
# }
# 
# sub compare {
#     my ($self, $other) = @_;
# 
#    	die "$self->{name} requires!" unless ref $other eq 'CODE';
# }
# 
# 1;
# 
# __END__
# 
# =encoding utf-8
# 
# =head1 NAME
# 
# Aion::Meta::RequiresAnyFunction - defines any function that must be in the module
# 
# =head1 SYNOPSIS
# 
# 	use Aion::Meta::RequiresAnyFunction;
# 	
# 	my $any_function = Aion::Meta::RequiresAnyFunction->new(
# 		pkg => 'My::Package', name => 'my_function'
# 	);
# 
# =head1 DESCRIPTION
# 
# It is created in C<requires fn1, fn2...> and when initializing the class it is checked that such a function was declared in it using C<sub> or C<has>.
# 
# =head1 SUBROUTINES
# 
# =head2 new (%args)
# 
# Constructor.
# 
# =head2 compare (CodeRef|Undef $other)
# 
# Checks that C<$other> is a function.
# 
# 	my $any_function = Aion::Meta::AnyFunction->new;
# 	eval { $any_function->compare(undef) }; $@  # ~> .3
# 
# =head1 AUTHOR
# 
# Yaroslav O. Kosmina L<mailto:dart@cpan.org>
# 
# =head1 LICENSE
# 
# ⚖ B<GPLv3>
# 
# =head1 COPYRIGHT
# 
# The Aion::Meta::RequiresAnyFunction module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
# 

done_testing;
