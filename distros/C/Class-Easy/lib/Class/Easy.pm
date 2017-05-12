package Class::Easy;

# PORTIONS FROM Sub::Identify and common::sense

BEGIN {
	our $VERSION = '0.18';
	our @ISA;

	use Class::Easy::Import;
	
	my $loaded;
	unless ($ENV{PERL_SUB_IDENTIFY_PP}) {
		local $@;
		eval {
			require XSLoader;
			XSLoader::load(__PACKAGE__, $VERSION);
		};
		
		die $@ if $@ && $@ !~ /object version|loadable object/;
		
		$loaded = 1 unless $@;
	}
	
	our $is_pure_perl = !$loaded;
	
	if ($is_pure_perl) {
		require Class::Easy::PP;
	}

}

require Class::Easy::Timer;

sub stash_name   ($) { (get_coderef_info($_[0]))[0] }
sub sub_name     ($) { (get_coderef_info($_[0]))[1] }
sub sub_fullname ($) { join '::', get_coderef_info($_[0]) }


our @EXPORT = qw(has try_to_use try_to_use_quiet try_to_use_inc try_to_use_inc_quiet make_accessor timer);
our @EXPORT_OK = qw(sub_name stash_name sub_fullname get_coderef_info);

our %EXPORT_FOREIGN = (
	'Class::Easy::Log' => [qw(debug critical debug_depth logger catch_stderr release_stderr)],
#	'Class::Easy::Timer' => [qw(timer)],
);

our $LOG = '';

sub timer {
	return Class::Easy::Timer->new (@_);
}

sub import {
	my $mypkg   = shift;
	my $callpkg = caller;
	
	my %params = @_;
	
	# use warnings
	${^WARNING_BITS} = $Class::Easy::Import::WARN;
	
	# use strict, use utf8;
	$^H |= $Class::Easy::Import::H;
	
	# use feature
	$^H{feature_switch} = $^H{feature_say} = $^H{feature_state} = 1;
	
	# probably check for try_to_use is enough
	return
		if defined *{"$callpkg\::try_to_use"}{CODE}
			and sub_fullname (*{"$callpkg\::try_to_use"}{CODE}) eq __PACKAGE__.'::__ANON__';
	
	# export subs
	*{"$callpkg\::$_"} = \&{"$mypkg\::$_"} foreach @EXPORT;
	foreach my $p (keys %EXPORT_FOREIGN) {
		*{"$callpkg\::$_"} = \&{"$p\::$_"} foreach @{$EXPORT_FOREIGN{$p}};
	}
}

sub has ($;%) {
	
	my ($caller) = caller;
	my $accessor = shift;
	
	return make_accessor ($caller, $accessor, _unless_exists => 1, @_);
}

sub make_accessor ($;$;$;%) {
	my $caller = shift;
	my $name   = shift;

	my $full_ref = "${caller}::$name";
	
	my $default;
	$default = pop
		if @_ == 1 or @_ == 3; # _from_has support
	
	die 'bad call from: ' . join (', ', caller)
		if scalar @_ % 2;
	my %config = @_;
	
	my $isa     = $config{isa};
	my $is      = $config{is} || 'ro';
	$default    = $config{default}
		if exists $config{default};
	
	$config{global} = 1
		if defined $default and $is eq 'ro';
	
	# when make_accessor called from has, we must check for already created
	# accessor and redefine only if redefined flag supplied
	if (delete $config{_unless_exists} and defined *{$full_ref}{CODE}) {
		return;
	}
	
	my $mode;
	$mode = 1 if $is eq 'ro';
	$mode = 2 if $is eq 'rw';
	
	die "unknown accessor type: $is"
		unless $is =~ /^r[ow]$/;
	
	if (ref $default eq 'CODE') {
		
		*{$full_ref} = $default;
	
	} elsif ($config{global}) {
		
		*{$full_ref} = sub {
			
			my $c = @_;
			
			# return &$default if $c == 1 and ref $default eq 'CODE';
			return $default if $c == 1;
			_has_error ($caller, $name, $c - 1) if $c ^ $mode;
			
			make_accessor (ref $_[0] || $_[0], $name, %config, default => $_[1]);
		};
		
	} else {
		*{$full_ref} = sub {
			
			my $c = @_;
			
			return $_[0]->{$name} if $c == 1;
			_has_error ($caller, $name, $c - 1) if $c ^ $mode;
			
			$_[0]->{$name} = $_[1];

		};
		
	}
}

sub _has_error {
	my $caller = shift;
	my $name   = shift;
	my $argc   = shift;
	
	my ($acc_caller, $line) = (caller(1))[0, 2];
	die "too many parameters ($argc) for accessor $caller\->$name at $acc_caller line $line.\n";
}

sub _try_to_use {
	my $use_lib = shift;
	my $quiet   = shift;
	my @chunks  = @_;

	my $package = join  '::', @chunks;
	@chunks     = split '::', $package;
	my $path    = join ('/', @chunks) . '.pm';
	
	$@ = '';
	
	if ($use_lib) {
		return "exists in \%INC"
			if exists $INC{$path};
	} else {
		# OLD: we removed "or ! exists $INC{$path}" statement because
		# "used" package always available via symbol table
		if (eval ("scalar grep {!/\\w+\:\:/} keys \%$package\::;") > 0) {
			return "exists in symbol table";
		}
	}
	
	eval "use $package";
	
	if ($@) {
		Class::Easy::Log::debug ("i can't load module ($path): $@")
			unless $quiet;
		return;
	}
	
	return 1;
}

sub try_to_use {
	return _try_to_use (0, 0, @_);
}

sub try_to_use_quiet {
	return _try_to_use (0, 1, @_);
}

sub try_to_use_inc {
	return _try_to_use (1, 0, @_);
}

sub try_to_use_inc_quiet {
	return _try_to_use (1, 1, @_);
}

sub list_local_subs_for {
	my $module = shift;
	my $enum_imported = shift || 0;
	
	my $namespace = \%{$module . '::'};
	
	my @sub_list = grep {
		defined *{"$module\::$_"}{CODE}
	} keys %{$namespace};
	
	my $sub_by_type = {
		method   => {},
		imported => {},
		runtime  => {}
	};
	
	foreach my $sub (@sub_list) {
		my ($real_package, $real_sub) = (get_coderef_info (*{"$module\::$sub"}{CODE}));

		if ($real_package eq $module) {
			$sub_by_type->{method}->{$sub} = 1;
		} elsif ($real_sub eq '__ANON__') {
			$sub_by_type->{runtime}->{$sub} = 1;
		} else {
			$sub_by_type->{imported}->{$real_package}->{$real_sub} = $sub; # who needs $real_sub ?
		}
	}
	
	wantarray
		? (keys %{$sub_by_type->{method}}, keys %{$sub_by_type->{runtime}})
		: $sub_by_type;
}

sub list_all_subs_for {
	my $module = shift || (caller)[0];
	my $filter = shift || '';
	
	$module = ref $module
		if ref $module;
	
	my $namespace = \%{$module . '::'};
	
	my $linear_isa;
	
	if ($] < 5.009_005) {
		require Class::Easy::MRO;
		$linear_isa = __get_linear_isa ($module);
	} else {
		require mro;
		$linear_isa = mro::get_linear_isa ($module);
	}
	
	my $sub_by_type = list_local_subs_for ($module);
	$sub_by_type->{inherited}->{$_} = [list_local_subs_for ($_)]
		foreach grep {$_ ne $module} @$linear_isa;
	
	wantarray
		? (
			keys %{$sub_by_type->{method}}, 
			keys %{$sub_by_type->{runtime}},
			map {@{$sub_by_type->{inherited}->{$_}}} keys %{$sub_by_type->{inherited}})
		: $sub_by_type;
}

1;

=head1 NAME

Class::Easy - make class routine easy

=head1 ABSTRACT

This module is a functionality compilation of some good modules from CPAN.
Ideas are taken from Class::Data::Inheritable, Class::Accessor, Modern::Perl
and Moose at least.

Instead of building monstrous alternatives to Moose or making thousand modules
for every function I need, I decide to write small and efficient libraries for
everyday use. Class::Easy::Base is a base component for classes.

=head1 SYNOPSIS

SYNOPSIS

	# automatic loading of strict, warnings and utf8, like common::sense
	use Class::Easy::Import;
	# or same as above + functions like 'has', 'try_to_use', 'timer' and 'logger'
	use Class::Easy;
	
	# try to load package IO::Easy, return 1 when success
	try_to_use ('IO::Easy');
	
	# try to load package IO::Easy, but search for package existence
	# within %INC instead of symbolic table
	try_to_use_inc ('IO::Easy');
	
	# for current package
	has "property_ro"; # make readonly object accessor
	has "property_rw", is => 'rw'; # make readwrite object accessor
	
	has global25 => 25; # make readonly static accessor with value 25
	has "global", global => 1, is => 'rw'; # make readwrite static accessor

	# make subroutine in package main
	make_accessor ('main', 'initialize', default => sub {
		$::initialized = 1;
		return "initialized!";
	});
	
	# see documentation for Class::Easy::Log
	
	# string "[PID] [PACKAGE(STRING)] [DBG] something" logged
	debug "something";

	# see documentation for Class::Easy::Timer

	my $t = timer ('long operation');
	# … long operation

	my $time = $t->lap ('another long op');
	# …

	$time = $t->end;
	# $time contains time between last 'lap' or 'timer'
	# and 'end' call

	$time = $t->total;
	# now $time contains total time between timer init
	# and end call

=head1 FUNCTIONS

=head2 has ($name [, is => 'ro' | 'rw'] [, default => $default], [, global => 1])

create accessor named $name in current scope

=cut

=head2 make_accessor ($scope, $name)

create accessor in selected scope

=cut

=head2 try_to_use, try_to_use_quiet

tries to use specified package with printing error message to STDERR
or "_quiet" version.

return true value in case of successful operation or existing non-package
references in symbol table. correctly works with virtual packages.

takes package name or package name chunks, for example:

	try_to_use ('IO::Easy');
	# or equivalent
	try_to_use (qw(IO Easy));

if you want to separate io errors from syntax errors you may want to
check $! variable;

for example: 

	use Errno qw(:POSIX);
	
	if (!try_to_use ('IO::Easy')) {
		die 'file not found for package IO::Easy'
			if $!{ENOENT};
	}

=cut

=head2 try_to_use_inc, try_to_use_inc_quiet

similar to the try_to_use, but check for module presence in %INC
instead of symbol table lookup.

=cut

=head2 timer

create new L<Class::Easy::Timer> object

=cut

=head2 get_coderef_info, stash_name, sub_name, sub_fullname

retrieve real name for coderef. useful for anonymous or imported functions

	get_coderef_info (*{Class::Easy::timer}{CODE}); # ('Class::Easy', 'timer')
	stash_name (*{Class::Easy::timer}{CODE}); # 'Class::Easy'
	sub_name (*{Class::Easy::timer}{CODE}); # 'timer'
	sub_fullname (*{Class::Easy::timer}{CODE}); # 'Class::Easy::timer'

=cut

=head2 list_all_subs_for, list_local_subs_for

in scalar context return hashref with complete coderef info for class.
 - key 'inherited' contains all inherited methods, separated by class name,
 - key 'runtime' contains all code references in current package which point
to anonymous method,
 - key 'method' contains all local methods,
 - key 'imported' contains all imported subs, separated by class name

	{
		'inherited' => {
			'My::Circle' => [
				'new',
				'global_hash',
				'global_hash_rw',
				'new_default',
				'global_hash_rw_default',
				'dim_x',
				'id',
				'dim_y'
			]
		},
		'runtime' => {
			'global_ro' => 1,
			'global_one' => 1,
			'global_one_defined' => 1,
			'dim_z' => 1,
			'accessor' => 1
		},
		'method' => {
			'sub_z' => 1
		},
		'imported' => {
			'Class::Easy' => {
				'make_accessor' => 'make_accessor',
				'try_to_use' => 'try_to_use',
				'try_to_use_inc' => 'try_to_use_inc',
				'try_to_use_quiet' => 'try_to_use_quiet',
				'has' => 'has',
				'timer' => 'timer',
				'try_to_use_inc_quiet' => 'try_to_use_inc_quiet'
			},
			'Class::Easy::Log' => {
				'critical' => 'critical',
				'release_stderr' => 'release_stderr',
				'catch_stderr' => 'catch_stderr',
				'debug' => 'debug',
				'debug_depth' => 'debug_depth',
				'logger' => 'logger'
			}
		}
	};

'local' version of subroutine doesn't contains any inherited methods


=cut



=head1 AUTHOR

Ivan Baktsheev, C<< <apla at the-singlers.us> >>

=head1 BUGS

Please report any bugs or feature requests to my email address,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Easy>. 
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT



=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Ivan Baktsheev

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
