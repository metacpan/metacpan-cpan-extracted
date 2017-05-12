package Basset::Test;

#Basset::Test, copyright and (c) 2004, 2005, 2006 James A Thomason III

=pod

Inline testing for Basset modules. Or anyone else that wants it, for that matter. Built off of Test::More.

=cut

$VERSION = '1.01';

use Basset::Object;
our @ISA = Basset::Object->pkg_for_type('object');

use Test::Builder;

use strict;
use warnings;

__PACKAGE__->add_class_attr('singleton');

=pod

=head1 METHODS

=over

=item test

->test is the bread and butter of Basset testing. Takes one, or optionally two arguments.
The first argument is always the class to test. The second argument is an optional boolean flag.
If true, then the test will also test all super classes B<in the current package>.

For more information on tests, read up on Test::More and Test::Builder. 

To embed a test:

 =pod
 
 =begin btest(NAMEOFTEST)
 
 $test->ok('true value', "Testing for true value");
 $test->is(1, 1, "1 = 1");
 #etc.
 
 =end btest(NAMEOFTEST)
 
 =cut

Note that you must specify the same NAMEOFTEST on both the begin and end lines (otherwise it's a pod formatting bug), and
it cannot contain any spaces.

If you append "__only" to the name of the test, then it will only be run within the test that contains it, never in a superclass.
For example, this is useful if you have a dummy method in a super class that always dies with the intention of having the subclass
populate it. You never want to run the superclass's tests from a subclass.

You do have access to Test::More style SKIP: blocks and the $TODO variable (declare it as our $TODO up at the
top if you use todos).

=end btest

=cut

__PACKAGE__->add_class_attr('_plan', 0);

sub plan {
	my $self = shift;
	if (@_ == 1) {
		$self->_plan(shift);
	};
	return $self->_plan;
}

__PACKAGE__->add_class_attr('_output', []);

__PACKAGE__->add_class_attr('silently');

sub test {

	my $self = shift;
	my $class = shift or return $self->error("Cannot test w/o class", "XXX");
	my $superclasses = shift || 0;
	
	$self->singleton(Test::Builder->new);
	
	$self->_output([]);

	$self->singleton->no_header(1);
	$self->singleton->no_ending(1);
	
	my @t = $self->get_all_tests($class, $superclasses) or return;

	my $tested = {};

	$self->announce('1..' . $self->plan . "\n");

	while (@t) {
		my $n = shift @t;
		my $t = '{' . (shift(@t) || '') . '};';
		$t = "package $class;\n$t";
		$t =~ s/\$test\b/$self/g;

		my @num = ($t =~ /$self->/g);
		$t =~ s/__PACKAGE__/$class/g;

		next if $tested->{$n};

		if ($n =~ s/__only//) {
			next if $tested->{$n}++;
		};


		my $num = @num; 

		if ($num) {
			$self->announce("# 1..$num testing $n\n");
			local $@ = undef;
			eval $t;
			if ($@) {
				$self->singleton->diag("failure ($@) during test suite :\n----\n$t\n----\n");
			}

		} else {
			$self->singleton->diag("no tests for $n\n");
		};
	};
	
	my @results = $self->singleton->summary;
	my ($successes, $failures) = (0,0);
	foreach my $r (@results) {
		$r ? $successes++ : $failures++;
	}
	
	my $total = $successes + $failures;
	
	$self->announce("# \n");
	$self->announce("# " . $successes . " tests passed\n");
	$self->announce("# " . $failures . " tests failed\n");
	
	$self->singleton->diag("Looks like you failed $failures tests of $total")
		if $failures;

	if ($total > $self->plan) {
		$self->singleton->diag("Looks like you planned " . $self->plan
			. " tests but ran " . ($total - $self->plan) . " extra.");
	}
	elsif ($total < $self->plan) {
		$self->singleton->diag("Looks like you planned " . $self->plan
			. " tests but only ran $total.");
	}

	my $laststream = undef;
	
	return 1 if $self->silently;
	
	if ($self->proving) {
		print <<"		eTESTOUTPUT";
			select((select(\\*STDOUT), \$| = 1)[0]);
			select((select(\\*STDERR), \$| = 1)[0]);
			use Test::Builder;
			my \$builder = Test::Builder->new();
			\$builder->plan('tests' => $total);
			
		eTESTOUTPUT
	}
	
	my $test_idx = 0;
	
	foreach my $item (@{$self->_output}) {
		my ($stream, $msg) = @$item;
		$test_idx++ if $msg =~ /^(not )?ok/;
		if (defined $laststream && $laststream eq $stream) {
			print $msg;
		} else {
			if ($self->proving) {
				if ($laststream) {
					print "eTESTOUTPUT\n";
				}
				if ($stream eq 'error' ) {
					print "\$builder->current_test($test_idx);\n";
					print "print STDERR <<'eTESTOUTPUT';\n";
				} else {
					print "print STDOUT <<'eTESTOUTPUT';\n";
				}
			}
			print $msg;
			$laststream = $stream;
		}
	}
	
	if ($laststream && $self->proving) {
		print "eTESTOUTPUT\n";
	}

	return 1;
}

sub get_all_tests {

	my $self = shift;
	my $class = shift;
	my $superclasses = shift || 0;
	local $@ = undef;

	eval "use $class";
	if ($@) {
		return $self->error("Catastrophe - could not use $class : $@", "BT-01");
	};
	
	$class->exceptions(0) if $class->can('exceptions');
		
	my $classes = $superclasses ? Basset::Object::isa_path($class) : [$class];

	my @modules = ();
	foreach my $class (@$classes) {
		local $@ = undef;
		eval "use $class";
		if ($@) {
			return $self->error("Catastrophe - could not use $class : $@", "BT-02");
		};
		my $module = $self->module_for_class($class);
		push @modules, $module;
	};

	my @t = ();
	
	foreach my $module (reverse @modules) {
		push @t, $self->extract_tests($INC{$module});
	};
	
	my $handleclass = 'Basset::Test::_Handle';
	
	tie *OUT, $handleclass, $self, 'output';
	tie *ERR, $handleclass, $self, 'error';
	tie *TODO, $handleclass, $self, 'todo';
	
	my $numtests = $self->count_tests(@t);
	
	$self->singleton->output(\*OUT);
	$self->singleton->failure_output(\*ERR);
	$self->singleton->todo_output(\*TODO);

	$self->singleton->exported_to($self->pkg);

	unless ($self->plan) {
		$self->singleton->plan('tests' => $numtests);
		$self->plan($numtests);
	}
	
	return @t ? @t : ($class);
}


sub count_tests {
	my $class = shift;
	my @tests = @_;
	my @num = ();
	
	my $skips = {};
	
	my $test_name = '';
	
	foreach my $test (@tests) {

		if ($test =~ /^\s*\$test->(?!announce)/m) {
			next if $skips->{$test_name};
			push @num, $test =~ /^\s*\$test->(?!announce)/gm;
			
			if ($test_name =~ s/__only$//) {
				$skips->{$test_name}++;
			}
		} else {
			$test_name = $test;

		}
		
	}

	return scalar @num;
}

sub extract_tests {
	my $self = shift;
	my $class = $self->pkg;
	my $file = shift;
	
	my $data = undef;
	
	open (my $fh, $file);
	{
		local $/ = undef;
		$data = <$fh>;
	};
	close $file;
		
	$self->line_counter(1);

	if ($data =~ /^\s*\$test->plan\(([^)]+)\);\s*\n/m) {
		my @plan = ();
		my $plan = $1;
		if ($1 =~ /,/) {
			@plan = split(/,/, $plan);
		} elsif ($1 =~ /=>/) {
			@plan = split(/\s*=>\s*/, $plan);
		} else {
			@plan = ($plan);
		}
		$plan[0] =~ s/['"\s]//g if defined $plan[0];
		$plan[1] =~ s/['"\s]//g if defined $plan[1];

		$plan[1] += 2;

		$self->singleton->plan(@plan);
		$self->plan($plan[1]);

	} else {
		$self->plan(0);
	}

	my @tests = ();
	if ($data =~ /^\s*=begin btest\(/m) {
		$data =~ s/(\n|^\s*=begin btest\(([^)]+)\)\s*\n)/$self->numberer($1, $2)/gem;
		@tests = $data =~ /^\s*=begin btest\(([^)]+)\)\s*\n(.+?)^\s*=end btest\(\1\)\s*\n/sgm;
	} else {
		$data =~ s/(\n|^\s*=begin btest( +([^\n]+))?\n)/$self->numberer($1, $2)/gem;
		@tests = $data =~ /^\s*=begin btest( +[^\n]+)?\n(.+?)^\s*=end btest\s*\n/sgm;
	}

	$self->test_for_strict($class, $file, \$data, \@tests);

	return @tests;
};

__PACKAGE__->add_class_attr('line_counter');
__PACKAGE__->add_class_attr('proving');

sub numberer {
	my $self = shift;
	my $val = shift;

	$self->line_counter($self->line_counter + 1);
	if ($val ne "\n") {
		my $name = shift || '';
		$val .= "\n#line " . $self->line_counter . " $name\n";
	}
	return $val;
};

sub test_for_strict {
	my $self = shift;
	my $class = shift;
	my $file = shift;
	my $data = shift;
	my $tests = shift;
	
	my $uses_strict = $$data =~ /^\s*use\s*strict\s*;/m ? 1 : 0;
	my $uses_warnings = $$data =~ /^\s*use\s*warnings\s*;/m ? 1 : 0;
	
	unshift @$tests, ("strict and warnings checks", <<"	eoT");
		\$test->ok($uses_strict, "uses strict");
		\$test->ok($uses_warnings, "uses warnings");
	eoT
	
	return 1;
}

sub skip {
	my $self = shift;
	my $reason = shift or return $self->error("Cannot skip w/o reason", "XXX");
	my $num = shift || 1;
	
	foreach (1..$num) {
		$self->singleton->skip($reason);
	}
	
	#cheat and bail out of the loop.
	no warnings;
	
	last SKIP;
}

__PACKAGE__->add_attr('todo');

sub AUTOLOAD {
	my $self = shift;
	(my $method = $Basset::Test::AUTOLOAD) =~ s/^(.+):://;
	
	my $method_map = {
		$method => $method,
		'is' => 'is_eq',
		'isnt' => 'isnt_eq',
	};
	
	my $imethod = $method_map->{$method};
	
	if ($method ne 'DESTROY') {

		if (defined $self->singleton) {
			no strict 'refs';
			my $pkg = $self->pkg;
			
			*{$pkg . "::$method"}  = sub {
				my $self	= shift;
				if (my $singleton = $self->singleton) {
					$self->singleton->$imethod(@_);
				} else {
					return $self->error("Cannot call method ($method) : no singleton", "XXX");
				}
			};

			return $self->$method(@_);
		} else {
			return $self->error("Cannot do anything without singleton", "XXX");
		};
	}
};

sub announce {
	my $self = shift;
	my @msgs = @_;
	
	foreach my $msg (@msgs) {
		push @{$self->_output}, ['output', $msg];
	};
}

1;

package Basset::Test::_Handle;

use Basset::Test;
our @ISA = qw(Basset::Test);

sub PRINT {
	my $self = shift;
	my ($test, $stream) = @$self;
	my @args = @_;

	foreach my $arg (@args) {
		push @{$test->_output}, [$stream, $arg];
	};
}

sub TIEHANDLE {
	my $class	= shift;
	my $test	= shift;
	my $stream	= shift;

	return bless [$test, $stream], $class;
}

1;
