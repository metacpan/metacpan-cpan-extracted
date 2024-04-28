package CPAN::Requirements::Dynamic;
$CPAN::Requirements::Dynamic::VERSION = '0.001';
use strict;
use warnings;

use Carp 'croak';
use Parse::CPAN::Meta;

sub _version_satisfies {
	my ($version, $range) = @_;
	require CPAN::Meta::Requirements::Range;
	return CPAN::Meta::Requirements::Range->with_string_requirement($range)->accepts($version);
}

sub _is_interactive {
	return -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));
}

sub _read_line {
	return undef if $ENV{PERL_MM_USE_DEFAULT} || !_is_interactive && eof STDIN;;

	my $answer = <STDIN>;
	chomp $answer if defined $answer;
	return $answer;
}

sub _prompt {
	my ($mess, $default) = @_;

	local $|=1;
	print "$mess [$default]";
	my $answer = _read_line;
	$answer = $default if !defined $answer or !length $answer;

	return $answer;
}

my %default_commands = (
	can_xs => sub {
		my ($self) = @_;
		require ExtUtils::HasCompiler;
		return ExtUtils::HasCompiler::can_compile_extension(config => $self->{config});
	},
	can_run => sub {
		my ($self, $command) = @_;
		require IPC::Cmd;
		return IPC::Cmd::can_run($command);
	},
	config_defined => sub {
		my ($self, $entry) = @_;
		return $self->{config}->get($entry) eq 'define';
	},
	has_env => sub {
		my ($self, $entry) = @_;
		return !!$ENV{$entry};
	},
	has_module => sub {
		my ($self, $module, $range) = @_;
		require Module::Metadata;
		my $data = Module::Metadata->new_from_module($module);
		return !!0 unless $data;
		return !!1 if not defined $range;
		return _version_satisfies($data->version($module), $range);
	},
	has_perl => sub {
		my ($self, $range) = @_;
		return _version_satisfies($], $range);
	},
	is_extended => sub {
		return !!$ENV{EXTENDED_TESTING};
	},
	is_interactive => sub {
		return _is_interactive;
	},
	is_os => sub {
		my ($self, @wanted) = @_;
		return !!grep { $_ eq $^O } @wanted
	},
	is_os_type => sub {
		my ($self, $wanted) = @_;
		require Perl::OSType;
		return Perl::OSType::is_os_type($wanted);
	},
	is_smoker => sub {
		return !!$ENV{AUTOMATED_TESTING};
	},
	prompt_default_yes => sub {
		my ($self, $message) = @_;
		return _prompt("$message [Y/n]", "y") =~ /^y/i;
	},
	prompt_default_no => sub {
		my ($self, $message) = @_;
		return _prompt("$message [y/N]", "n") =~ /^y/i;
	},
	want_pureperl => sub {
		my ($self) = @_;
		return !!$self->{pureperl_only};
	},
	want_xs => sub {
		my ($self) = @_;
		return !!0 if $self->{pureperl_only};
		require ExtUtils::HasCompiler;
		return ExtUtils::HasCompiler::can_compile_extension(config => $self->{config});
	},
	want_compiled => sub {
		my ($self) = @_;
		return defined $self->{pureperl_only} && $self->{pureperl_only} == 0;
	},
);

sub new {
	my ($class, %args) = @_;
	return bless {
		config        => $args{config}   || do { require ExtUtils::Config; ExtUtils::Config->new },
		prereqs       => $args{prereqs}  || do { require CPAN::Meta::Prereqs; CPAN::Meta::Prereqs->new },
		commands      => $args{commands} || \%default_commands,
		pureperl_only => $args{pureperl_only},
	}, $class;
}

sub _get_command {
	my ($self, $name) = @_;
	if ($name eq 'or') {
		return sub {
			my ($self, @each) = @_;
			for my $elem (@each) {
				return !!1 if $self->_run_condition($elem);
			}
			return !!0;
		};
	} elsif ($name eq 'and') {
		return sub {
			my ($self, @each) = @_;
			for my $elem (@each) {
				return !!0 if not $self->_run_condition($elem);
			}
			return !!1;
		};
	} else {
		return $self->{commands}{$name} || croak "No such command $name";
	}
}

sub _run_condition {
	my ($self, $condition) = @_;

	my $negate = !!0;
	my ($function, @arguments) = @{ $condition };
	while ($function eq 'not') {
		$function = shift @arguments;
		$negate = !$negate;
	}

	my $method = $self->_get_command($function);
	my $primary = $self->$method(@arguments);
	return $negate ? !$primary : $primary;
}

sub evaluate {
	my ($self, $argument) = @_;
	my $version = $argument->{version};
	croak "Dynamic prereqs spec version $version is not supported" if int $version > 1;
	my @prereqs;

	for my $entry (@{ $argument->{expressions} }) {
		if ($self->_run_condition($entry->{condition})) {
			if ($entry->{error}) {
				die "$entry->{error}\n";
			} elsif (my $prereqs = $entry->{prereqs}) {
				my $phase = $entry->{phase} || 'runtime';
				my $relation = $entry->{relation} || 'requires';
				my $prereqs = { $phase => { $relation => $entry->{prereqs} } };
				push @prereqs, CPAN::Meta::Prereqs->new($prereqs);
			}
		}
	}

	return $self->{prereqs}->with_merged_prereqs(\@prereqs);
}

sub evaluate_file {
	my ($self, $filename) = @_;
	my $structure = Parse::CPAN::Meta->load_file($filename);
	return $self->evaluate($structure);
}

1;

# ABSTRACT: Dynamic prerequisites in meta files

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Requirements::Dynamic - Dynamic prerequisites in meta files

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 my $result = $dynamic->evaluate({
   expressions => [
     {
       condition => [ 'has_perl' => 'v5.20.0' ],
       prereqs => { Bar => "1.3" },
     },
     {
       condition => [ is_os => 'linux' ],
       prereqs => { Baz => "1.4" },
     },
     {
       condition => [ config_defined => 'usethreads' ],
       prereqs => { Quz => "1.5" },
     },
     {
       condition => [ has_module => 'CPAN::Meta', '2' ],
       prereqs => { Wuz => "1.6" },
     },
     {
       condition => [ and =>
         [ config_defined => 'usethreads' ],
         [ is_os => 'openbsd' ],
       ],
       prereqs => { Euz => "1.7" },
     },
     {
       condition => [ not => is_os_type => 'Unix'],
       error => 'OS unsupported',
     },
   ],
 });

=head1 DESCRIPTION

This module implements a format for describing dynamic prerequisites of a distribution.

=head1 METHODS

=head2 new(%options)

This constructor takes two (optional but recommended) named arguments

=over 4

=item * config

This is an L<ExtUtils::Config|ExtUtils::Config> (compatible) object for reading configuration.

=item * pureperl_only

This should be the value of the C<pureperl-only> flag.

=back

=head2 evaluate(%options)

This takes a hash with two named arguments: C<version> and C<expressions>. The former is the version of the format, it currently defaults to 1. The latter is a list of hashes that can contain the following keys:

=over 4

=item * condition

The condition of the dynamic requirement. This is an array with a name as first values and zero or more arguments following it. The semantics are described below under L</Conditions>

=item * prereqs

The prereqs is a hash with modules for keys and the required version as values (e.g. C<< { Foo => '1.234' } >>).

=item * phase

The phase of the requirements. This defaults to C<'runtime'>. Other valid values include C<'build'> and C<'test'>.

=item * relation

The relation of the requirements. This defaults to C<'requires'>, but other valid values include C<'recommends'>, C<'suggests'> and C<'conflicts'>.

=item * error

It will die with this error if set. The two messages C<"No support for OS"> and C<"OS unsupported"> have special meaning to CPAN Testers and are generally encouraged for situations that indicate not a failed build but an impossibility to build.

=back

C<condition> and one of C<prereqs> or C<error> are mandatory.

=head2 evaluate_file($filename)

This takes a filename, that can be either a YAML file or a JSON file, and evaluates it.

=head2 Conditions

=head3 can_xs

This returns true if a compiler appears to be available.

=head3 can_run($command)

Returns true if a C<$command> can be run.

=head3 config_defined($variable)

This returns true if a specific configuration variable is defined.

=head3 has_env($variable)

This returns true if the environmental variable with the name in C<$variable> is true.

=head3 has_module($module, $version = 0)

Returns true if a module is installed on the system. If a C<$version> is given, it will also check if that version is provided. C<$version> is interpreted exactly as in the CPAN::Meta spec.

=head3 has_perl($version)

Returns true if the perl version satisfies C<$version>. C<$version> is interpreted exactly as in the CPAN::Meta spec (e.g. C<1.2> equals C<< '>= 1.2' >>).

=head3 is_extended

Returns true if extended testing is asked for.

=head3 is_interactive

Returns true if installed from a terminal that can answer prompts.

=head3 is_os(@systems)

Returns true if the OS name equals any of C<@systems>.

=head3 is_os_type($type)

Returns true if the OS type equals C<$type>. Typical values of C<$type> are C<'Unix'> or C<'Windows'>.

=head3 is_smoker

Returns true when running on a smoker.

=head3 has_env

This returns true if the given environmental variable is true.

=head3 prompt_default_no

This will ask a yes/no question to the user, defaulting to no.

=head3 prompt_default_yes

This will ask a yes/no question to the user, defaulting to yes.

=head3 want_pureperl

This returns true if the user has indicated they want a pure-perl build.

=head3 want_compiled

This returns true if the user has explicitly indicated they do not want a pure-perl build.

=head3 not

This takes an expression and negates its value.

=head3 or

This takes list of arrayrefs, each containing a condition expression. If at least one of the conditions is true this will also return true.

=head3 and

This takes a list of arrayrefs, each containing a condition expression. If all of the conditions are true this will also return true.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
