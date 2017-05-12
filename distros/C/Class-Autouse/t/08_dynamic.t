#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

my $test_the_test = 0;

use Test::More tests => (768 * ($test_the_test ? 2 : 1));
use File::Temp;
use IO::File;
use Class::Autouse;

use Carp;
$SIG{__WARN__} = \&Carp::cluck;

#
# write a temp directory of modules for testing
#

my $temp_dir;
BEGIN {
	$temp_dir = File::Temp::tempdir(CLEANUP => 1);
	#$temp_dir = $ENV{PWD} . "/dd";
	#print $temp_dir,"\n";
}
use lib $temp_dir;

sub class_isa_ok {
	my ($class,$parent,$msg) = @_;
	$msg ||= "$class isa $parent"; 
	local $^W = 0; 
	ok($class->isa($parent),$msg);
}

sub main::class_is_being_used {
	# this is a no-op, but is useful for debugging
	# all real/autogen classes call it in their definition source
	
	# print "using @_\n";
}

sub failed_test {
	# this is a no-op, but is useful for debugging
	# it is called after any test fails
	
	# Carp::confess();
}

# Try all possible combinations of use cases.
# Number the use case.  
# Make a fresh set of classes for each case using the case number in the names.
my $retval;
my $n          = 0;
my @file_types = qw/ use_file autouse_file autouse_callback autouse_regex /;
my @uses       = qw/ can isa regular_method autoload_method /; 
my @targets    = qw/ self parent grandparent /;
my %statistics = ();
for my $class_type ( @file_types ) {
	for my $parent_class_type ( @file_types ) {
		for my $grandparent_class_type ( @file_types ) {
			for my $first_use ( @uses ) {
				for my $first_use_target ( @targets ) {
					$n++;
					my $cname = "C$n"; # child
					my $pname = "P$n"; # parent
					my $gname = "G$n"; # grandparent

					my $msg = "test $n: $cname ($class_type) isa $pname ($parent_class_type) isa $gname ($grandparent_class_type): first use $first_use on $first_use_target";
					
					if ($test_the_test) {
						#diag $msg;
						mkfile(class_name => $gname);
						mkfile(class_name => $pname, parent_class_name => $gname);
						mkfile(class_name => $cname, parent_class_name => $pname);
						eval "use $gname; use $pname; use $cname;";
						die $@ if $@;
						class_isa_ok($pname,$gname);         
						class_isa_ok($cname,$pname);
						next;
					}

					eval {

						# write class modules as needed
						# where a class is to be dynamically loaded, setup an autouse callback instead. 
						for my $data (
							[$gname, undef,     $grandparent_class_type,    undef,                      ($first_use_target eq 'grandparent' ? 1 : 0)], 
							[$pname, $gname,    $parent_class_type,         $grandparent_class_type,    ($first_use_target eq 'parent' ? 1 : 0) ], 
							[$cname, $pname,    $class_type,                $parent_class_type,         ($first_use_target eq 'self' ? 1 : 0)  ]
						) {
							my ($class_name, $parent_class_name, $type, $parent_type, $might_have_autoload) = @$data;
							my $has_autoload = ( (($first_use eq 'autoload_method') && $might_have_autoload) ? 1 : 0 );
							
							$n+=0;
							if ($type eq 'autouse_callback') {
								Class::Autouse->autouse(
									sub { 
										my ($class,$method,@args) = @_; 
										my ($n2) = ($class =~ /^\D(\d\d)/);
										if ($class eq $class_name) {
											#print "autogen $class\n";
											my $src = class_src(
												class_name => $class_name, 
												parent_class_name => $parent_class_name, 
												parent_class_type => $parent_type, 
												has_autoload => $has_autoload,
											);
											local $^W = 0;
											eval $src;
											if ($@) {
												Carp::confess("Error in test code.  Failed to make module source for $class_name (isa $parent_class_name): $@");
											}
											return 1;
										}
									}
								);
							}
							else {
								mkfile(class_name => $class_name, parent_class_name => $parent_class_name, parent_class_type => $parent_type, has_autoload => $has_autoload);
								if ($type eq 'autouse_file') {
									Class::Autouse->autouse($class_name);
								}
								elsif ($type eq 'autouse_regex') {
									Class::Autouse->autouse(qr/$class_name/);
								}
								elsif ($type eq 'use_file') {
									$^W = 0; 
									eval "use $class_name";
									die $@ if $@;
								}
								else {
									die "unknown type $type?";
								}
							}
						}

						# Target one of the levels of the inheritance hierarchy
						# some test will try each of these
						my $target_class_name;
						if ($first_use_target eq 'self') {
							$target_class_name = $cname;
						}
						elsif ($first_use_target eq 'parent') {
							$target_class_name = $pname;
						}
						elsif ($first_use_target eq 'grandparent') {
							$target_class_name = $gname;
						}
						else {
							die "unknown first use target $first_use_target";
						}

						# Attempt the given use case
						if ($first_use eq 'isa') {
							unless ( class_isa_ok($cname,$target_class_name,"$cname isa $target_class_name for $msg") ) {
								failed_test();
								$statistics{all}++;
								$statistics{$class_type}++;
								$statistics{$parent_class_type}++;
								$statistics{$grandparent_class_type}++;
								$statistics{"isa.$class_type"}++;
								$statistics{"isa.$parent_class_type"}++;
								$statistics{"isa.$grandparent_class_type"}++;
								$statistics{"isa.class.$class_type"}++;
								$statistics{"isa.parent.$parent_class_type"}++;
								$statistics{"isa.grand.$grandparent_class_type"}++;
							}
						}
						else {
							if ($first_use eq 'can') {
								my $target_method_name = $target_class_name . '_method';
								$^W = 0; 
								my $code = $cname->can($target_method_name);
								$^W = 1;
								if ($code) {
									no strict 'refs';
									no strict 'subs';
									is(
										$code->(),
										$cname->$target_method_name(),
										"values match for $msg",
									) or failed_test();
								}   
								else {
									fail("got method $target_method_name for $msg");
									failed_test();
									$statistics{all}++;
									$statistics{$class_type}++;
									$statistics{$parent_class_type}++;
									$statistics{$grandparent_class_type}++;
									$statistics{"can.$class_type"}++;
									$statistics{"can.$parent_class_type"}++;
									$statistics{"can.$grandparent_class_type"}++;
									$statistics{"can.class.$class_type"}++;
									$statistics{"can.parent.$parent_class_type"}++;
									$statistics{"can.grand.$grandparent_class_type"}++;
								}
							}
							elsif ($first_use eq 'regular_method' or $first_use eq 'autoload_method') {
								my $target_method_name;
								if ($first_use eq 'autoload_method') {
									$target_method_name = 'missing_method';
									no strict 'refs';
								}
								else {
									$target_method_name = $target_class_name . '_method';
								}
								$retval = undef;
								$^W = 0; 
								eval "\$retval = $cname->$target_method_name();";
								if ($@) {
									fail("failed to try $target_method_name on $cname! $msg\n $@");
									failed_test();
								}
								elsif ($first_use eq 'autoload_method') {
									is(
										$retval,
										"autoload result from $target_class_name", 
										"return value ($retval) is as expected ($target_class_name $target_method_name) for $msg"
									) or failed_test();
	
								}
								else {
									is(
										$retval,
										"$target_class_name $target_method_name", 
										"return value ($retval) is as expected ($target_class_name $target_method_name) for $msg"
									) or failed_test();
								}
							}
							else {
								die "unknown first use $first_use???";
							}
						}
					};

					if ($@) {
						fail("error on $msg\n$@");
						failed_test();
					}
				}
			}
		}
	}
}

sub mkfile {
	my (%args) = @_;
	my $cname = $args{'class_name'};
	my $n1 = "$temp_dir/${cname}.pm";
	my $m1 = IO::File->new(">$n1");
	die "failed to create file $n1: $!" unless $m1;
	my $src = class_src(@_);
	$m1->print($src);
	$m1->close;
}

sub class_src {
	my (%args) = @_;
	my ($cname, $pname, $ptype, $has_autoload) = @args{'class_name','parent_class_name', 'parent_class_type', 'has_autoload'};

	my $isa_src = ($pname ? "use vars '\@ISA';\n\@ISA = ('$pname');\n" : "\n");
	#my $isa_src = ($pname ? "use base '$pname';\n" : "\n");
	if (!defined($ptype)) {
		$isa_src .= "#no parent class\n";
	}
	elsif ($ptype eq 'use_file') {
		$isa_src .= "use $pname;\n";
	}
	elsif ($ptype eq 'autouse_file') {
		$isa_src .= "use Class::Autouse '$pname';\n"; 
	}
	elsif ($ptype eq 'autouse_callback' or $ptype eq 'autouse_regex') {
		$isa_src .= "#use Class::Autouse sub {...} is in the test\n";
	}
	else {
		Carp::confess("Odd parent class type $ptype!");
	}

	my $autoload_src = (!$has_autoload ? "" : <<EOS );
# handles all missing methods
sub AUTOLOAD { return "autoload result from $cname" }
EOS

	my $src = <<EOS;
package $cname;

# turn off warnings since we may not want to load the parent class 
# until we're actually using can/isa or failing to find a method
local \$^W = 0;
$isa_src

# this is a no-op, and is primarily for debugging
main::class_is_being_used(__PACKAGE__);

# methods w/o overrides
sub ${cname}_method { "$cname ${cname}_method" }

# methods w/ override
sub mymethod { "$cname mymethod" }

$autoload_src
1;
EOS
	#print "####\n$src\n###\n";
	return $src;
}


