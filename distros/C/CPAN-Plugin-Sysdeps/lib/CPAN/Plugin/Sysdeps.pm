package CPAN::Plugin::Sysdeps;

use strict;
use warnings;

our $VERSION = '0.39';

use Hash::Util 'lock_keys';
use List::Util 'first';

our $TRAVERSE_ONLY; # only for testing

sub new {
    my($class, @args) = @_;

    my $installer;
    my $batch = 0;
    my $dryrun = 0;
    my $debug = 0;
    my @additional_mappings;
    my @args_errors;
    my $options;
    for my $arg (@args) {
	if (ref $arg eq 'HASH') {
	    if ($options) {
		die "Cannot handle multiple option hashes";
	    } else {
		$options = $arg;
	    }
	} elsif ($arg =~ m{^(apt-get|aptitude|pkg|yum|chocolatey|homebrew)$}) { # XXX are there more package installers?
	    $installer = $1;
	} elsif ($arg eq 'batch') {
	    $batch = 1;
	} elsif ($arg eq 'interactive') {
	    $batch = 0;
	} elsif ($arg eq 'dryrun') {
	    $dryrun = 1;
	} elsif ($arg =~ m{^mapping=(.*)$}) {
	    push @additional_mappings, $1;
	} elsif ($arg =~ m{^debug(?:=(\d+))?$}) {
	    $debug = defined $1 ? $1 : 1;
	} else {
	    push @args_errors, $arg;
	}
    }
    if (@args_errors) {
	die 'Unrecognized ' . __PACKAGE__ . ' argument' . (@args_errors != 1 ? 's' : '') . ": @args_errors\n";
    }

    if (exists $ENV{CPAN_PLUGIN_SYSDEPS_DEBUG}) {
	$debug = $ENV{CPAN_PLUGIN_SYSDEPS_DEBUG};
    }
    if ($debug) {
	require Data::Dumper; # we'll need it
    }

    my $os                  = $options->{os} || $^O;
    my $osvers              = '';
    my $linuxdistro         = '';
    my $linuxdistroversion  = 0;
    my $linuxdistrocodename = '';
    if ($os eq 'linux') {
	my $linux_info;
	my $get_linux_info = sub {
	    return $linux_info if $linux_info;
	    return $linux_info = _detect_linux_distribution();
	};
	if (defined $options->{linuxdistro}) {
	    $linuxdistro = $options->{linuxdistro};
	} else {
	    $linuxdistro = lc $get_linux_info->()->{linuxdistro};
	}

	if (defined $options->{linuxdistroversion}) {
	    $linuxdistroversion = $options->{linuxdistroversion};
	} else {
	    $linuxdistroversion = $get_linux_info->()->{linuxdistroversion}; # XXX make it a version object? or make sure it's just X.Y?
	}

	if (defined $options->{linuxdistrocodename}) {
	    $linuxdistrocodename = $options->{linuxdistrocodename};
	} else {
	    $linuxdistrocodename = $get_linux_info->()->{linuxdistrocodename};
	}
    } elsif ($os eq 'freebsd') {
	# Note: don't use $Config{osvers}, as this is just the OS
	# version of the system which built the current perl, not the
	# actually running OS version.
	if (defined $options->{osvers}) {
	    $osvers = $options->{osvers};
	} else {
	    chomp($osvers = `/sbin/sysctl -n kern.osrelease`);
	}
    }

    if (!$installer) {
	if      ($os eq 'freebsd') {
	    $installer = 'pkg';
	} elsif ($os eq 'gnukfreebsd') {
	    $installer = 'apt-get';
	} elsif ($os eq 'linux') {
	    if      (__PACKAGE__->_is_linux_debian_like($linuxdistro)) {
		$installer = 'apt-get';
	    } elsif (__PACKAGE__->_is_linux_fedora_like($linuxdistro)) {
		$installer = 'yum';
	    } else {
		die __PACKAGE__ . " has no support for linux distribution $linuxdistro $linuxdistroversion\n";
	    }
	} elsif( $os eq 'MSWin32' ) {
	    $installer = 'chocolatey';
	} elsif ($os eq 'darwin') {
	    $installer = 'homebrew';
	} else {
	    die __PACKAGE__ . " has no support for operating system $os\n";
	}
    }

    my @mapping;
    for my $mapping (@additional_mappings, 'CPAN::Plugin::Sysdeps::Mapping') {
	if (-r $mapping) {
	    open my $fh, '<', $mapping
		or die "Can't load $mapping: $!";
	    local $/;
	    my $buf = <$fh>;
	    push @mapping, eval $buf;
	    die "Error while loading $mapping: $@" if $@;
	} else {
	    eval "require $mapping"; die "Can't load $mapping: $@" if $@;
	    push @mapping, $mapping->mapping;
	}
    }

    my %config =
	(
	 installer           => $installer,
	 batch               => $batch,
	 dryrun              => $dryrun,
	 debug               => $debug,
	 os                  => $os,
	 osvers              => $osvers,
	 linuxdistro         => $linuxdistro,
	 linuxdistroversion  => $linuxdistroversion,
	 linuxdistrocodename => $linuxdistrocodename,
	 mapping             => \@mapping,
	);
    my $self = bless \%config, $class;
    lock_keys %$self;
    $self;
}

# CPAN.pm plugin hook method
sub post_get {
    my($self, $dist) = @_;

    my @packages = $self->_map_cpandist($dist);
    if (@packages) {
	my @uninstalled_packages = $self->_filter_uninstalled_packages(@packages);
	if (@uninstalled_packages) {
	    my @cmds = $self->_install_packages_commands(@uninstalled_packages);
	    for my $cmd (@cmds) {
		if ($self->{dryrun}) {
		    warn "DRYRUN: @$cmd\n";
		} else {
		    warn "INFO: run @$cmd...\n";

		    system @$cmd;
		    if ($? != 0) {
		    	die "@$cmd failed, stop installation";
		    }
		}
	    }
	}
    }
}

# Helpers/Internal functions/methods
sub _detect_linux_distribution {
    if (-x '/usr/bin/lsb_release') {
	_detect_linux_distribution_lsb_release();
    } else {
	_detect_linux_distribution_fallback();
    }
}

sub _detect_linux_distribution_lsb_release {
    my %info;
    my @cmd = ('lsb_release', '-irc');
    open my $fh, '-|', @cmd
	or die "Error while running '@cmd': $!";
    while(<$fh>) {
	chomp;
	if      (m{^Distributor ID:\s+(.*)}) {
	    $info{linuxdistro} = $1;
	} elsif (m{^Release:\s+(.*)}) {
	    $info{linuxdistroversion} = $1;
	} elsif (m{^Codename:\s+(.*)}) {
	    $info{linuxdistrocodename} = $1;
	} else {
	    warn "WARNING: unexpected '@cmd' output '$_'";
	}
    }
    close $fh
	or die "Error while running '@cmd': $!";
    \%info;
}

sub _detect_linux_distribution_fallback {
    if (open my $fh, '<', '/etc/redhat-release') {
	my $contents = <$fh>;
	if ($contents =~ m{^(CentOS|RedHat) (Linux )?release (\d+)\S* \((.*?)\)}) {
	    return {linuxdistro => $1, linuxdistroversion => $2, linuxdistrocodename => $3};
	}
    }
    if (open my $fh, '<', '/etc/issue') {
	chomp(my $line = <$fh>);
	if      ($line =~ m{^Linux Mint (\d+) (\S+)}) {
	    return {linuxdistro => 'LinuxMint', linuxdistroversion => $1, linuxdistrocodename => $2};
	} elsif ($line =~ m{^(Debian) GNU/Linux (\d+)}) {
	    my %info = (linuxdistro => $1, linuxdistroversion => $2);
	    $info{linuxdistrocodename} =
		{
		 6 => 'squeeze',
		 7 => 'wheezy',
		 8 => 'jessie',
		 9 => 'stretch',
		}->{$info{linuxdistroversion}};
	    return \%info;
	} else {
	    warn "WARNING: don't know how to handle '$line'";
	}
    } else {
	warn "WARNING: no /etc/issue available";
    }
    return {};
}

sub _is_linux_debian_like {
    my(undef, $linuxdistro) = @_;
    $linuxdistro =~ m{^(debian|ubuntu|linuxmint)$};
}

sub _is_linux_fedora_like {
    my(undef, $linuxdistro) = @_;
    $linuxdistro =~ m{^(fedora|redhat|centos)$};
}

sub _is_apt_installer { shift->{installer} =~m{^(apt-get|aptitude)$} }

# Run a process in an elevated window, wait for its exit
sub _win32_run_elevated {
    my($exe, @args) = @_;
    
    my $args = join " ", map { if(/[ "]/) { s!"!\\"!g; qq{"$_"} } else { $_ }} @args;

    my $ps1 = sprintf q{powershell -NonInteractive -NoProfile -Command "$process = Start-Process '%s' -PassThru -ErrorAction Stop -ArgumentList '%s' -Verb RunAs -Wait; Exit $process.ExitCode"},
        $exe, $args;

    $ps1;
}

sub _debug {
    my $self = shift;
    if ($self->{debug}) {
	print STDERR 'DEBUG: ';
	print STDERR join('', map {
	    if (ref $_) {
		Data::Dumper->new([$_])->Terse(1)->Indent(0)->Dump;
	    } else {
		$_;
	    }
	} @_);
	print STDERR "\n";
    }
}

sub _map_cpandist {
    my($self, $dist) = @_;

    # compat for older CPAN.pm (1.76)
    if (!$dist->can('base_id')) {
	no warnings 'once';
	*CPAN::Distribution::base_id = sub {
	    my $self = shift;
	    my $id = $self->id();
	    my $base_id = File::Basename::basename($id);
	    $base_id =~ s{\.(?:tar\.(bz2|gz|Z)|t(?:gz|bz)|zip)$}{}i;
	    return $base_id;
	};
    }

    # smartmatch for regexp/string/array without ~~, 5.8.x compat!
    my $smartmatch = sub ($$) {
	my($left, $right) = @_;
	if (ref $right eq 'Regexp') {
	    return 1 if $left =~ $right;
	} elsif (ref $right eq 'ARRAY') {
	    return 1 if first { $_ eq $left } @$right;
	} else {
	    return 1 if $left eq $right;
	}
    };

    my $handle_mapping_entry; $handle_mapping_entry = sub {
	my($entry, $level) = @_;
	for(my $map_i=0; $map_i <= $#$entry; $map_i++) {
	    my $key_or_subentry = $entry->[$map_i];
	    if (ref $key_or_subentry eq 'ARRAY') {
		$self->_debug(' ' x $level . ' traverse another tree level');
		my $res = $handle_mapping_entry->($key_or_subentry, $level+1);
		return $res if $res && !$TRAVERSE_ONLY;
	    } elsif (ref $key_or_subentry eq 'CODE') {
		my $res = $key_or_subentry->($self, $dist);
		return $res if $res && !$TRAVERSE_ONLY;
	    } else {
		my $key = $key_or_subentry;
		my $match = $entry->[++$map_i];
		$self->_debug(' ' x $level . " match '$key' against '", $match, "'");
		if ($key eq 'cpandist') {
		    return 0 if !$smartmatch->($dist->base_id, $match) && !$TRAVERSE_ONLY;
		} elsif ($key eq 'cpanmod') {
		    my $found = 0;
		    for my $mod ($dist->containsmods) {
			$self->_debug(' ' x $level . "  found module '$mod' in dist, check now against '", $match, "'");
			if ($smartmatch->($mod, $match)) {
			    $found = 1;
			    last;
			}
		    }
		    return 0 if !$found && !$TRAVERSE_ONLY;
		} elsif ($key eq 'os') {
		    return 0 if !$smartmatch->($self->{os}, $match) && !$TRAVERSE_ONLY;
		} elsif ($key eq 'osvers') {
		    return 0 if !$smartmatch->($self->{osvers}, $match) && !$TRAVERSE_ONLY; # XXX should also be able to do numerical comparisons
		} elsif ($key eq 'linuxdistro') {
		    if ($match =~ m{^~(debian|fedora)}) {
			my $method = "_is_linux_$1_like";
			$self->_debug(' ' x $level . " translate $match to $method");
			return 0 if !$self->$method($self->{linuxdistro}) && !$TRAVERSE_ONLY;
		    } elsif ($match =~ m{^~}) {
			die "'like' matches only for debian and fedora";
		    } else {
			return 0 if !$smartmatch->($self->{linuxdistro}, $match) && !$TRAVERSE_ONLY;
		    }
		} elsif ($key eq 'linuxdistroversion') {
		    return 0 if !$smartmatch->($self->{linuxdistroversion}, $match) && !$TRAVERSE_ONLY; # XXX should do a numerical comparison instead!
		} elsif ($key eq 'linuxdistrocodename') {
		    return 0 if !$smartmatch->($self->{linuxdistrocodename}, $match) && !$TRAVERSE_ONLY; # XXX should also do a smart codename comparison additionally!
		} elsif ($key eq 'package') {
		    $self->_debug(' ' x $level . " found $match"); # XXX array?
		    return { package => $match };
		} else {
		    die "Invalid key '$key'"; # XXX context/position?
		}
	    }
	}
    };

    for my $entry (@{ $self->{mapping} || [] }) {
	my $res = $handle_mapping_entry->($entry, 0);
	if ($res && !$TRAVERSE_ONLY) {
	    return ref $res->{package} eq 'ARRAY' ? @{ $res->{package} } : $res->{package};
	}
    }

    ();
}

sub _find_missing_deb_packages {
    my($self, @packages) = @_;
    return () if !@packages;

    # taken from ~/devel/deb-install.pl
    my %seen_packages;
    my @missing_packages;

    my @cmd = ('dpkg-query', '-W', '-f=${Package} ${Status}\n', @packages);
    require IPC::Open3;
    require Symbol;
    my $err = Symbol::gensym();
    my $fh;
    my $pid = IPC::Open3::open3(undef, $fh, $err, @cmd)
	or die "Error running '@cmd': $!";
    while(<$fh>) {
	chomp;
	if (m{^(\S+) (.*)}) {
	    if ($2 ne 'install ok installed') {
		push @missing_packages, $1;
	    }
	    $seen_packages{$1} = 1;
	} else {
	    warn "ERROR: cannot parse $_, ignore line...\n";
	}
    }
    waitpid $pid, 0;
    for my $package (@packages) {
	if (!$seen_packages{$package}) {
	    push @missing_packages, $package;
	}
    }
    @missing_packages;
}

sub _find_missing_rpm_packages {
    my($self, @packages) = @_;
    return () if !@packages;

    my @missing_packages;

    {
	my %packages = map{($_,1)} @packages;

	local $ENV{LC_ALL} = 'C';
	my @cmd = ('rpm', '-q', @packages);
	open my $fh, '-|', @cmd
	    or die "Error running '@cmd': $!";
	while(<$fh>) {
	    if (m{^package (\S+) is not installed}) {
		my $package = $1;
		if (!exists $packages{$package}) {
		    die "Unexpected: package $package listed as non-installed, but not queries in '@cmd'?!";
		}
		push @missing_packages, $package;
	    }
	}
    }

    @missing_packages;
}

sub _find_missing_freebsd_pkg_packages {
    my($self, @packages) = @_;
    return () if !@packages;

    my @missing_packages;
    for my $package (@packages) {
	my @cmd = ('pkg', 'info', '--exists', $package);
	system @cmd;
	if ($? != 0) {
	    push @missing_packages, $package;
	}
    }

    @missing_packages;
}

sub _find_missing_homebrew_packages {
    my($self, @packages) = @_;
    return () if !@packages;

    my @missing_packages;
    for my $package (@packages) {
	my @cmd = ('brew', 'ls', '--versions', $package);
	open my $fh, '-|', @cmd
	    or die "Error running @cmd: $!";
	my $has_package;
	while(<$fh>) {
	    $has_package = 1;
	    last;
	}
	close $fh; # earlier homebrew versions returned always 0,
                   # newer (since Oct 2016) return 1 if the package is
                   # missing
	if (!$has_package) {
	    push @missing_packages, $package;
	}
    }
    @missing_packages;
}

sub _find_missing_chocolatey_packages {
    my($self, @packages) = @_;
    return () if !@packages;

    my %installed_packages = map {
	    /^(.*)\|(.*)$/
		or next;
	    $1 => $2
	} grep {
	    /^(.*)\|(.*)$/
	} `$self->{installer} list --localonly --limit-output`;
    my @missing_packages = grep { ! $installed_packages{ $_ }} @packages;
    @missing_packages;
}

sub _filter_uninstalled_packages {
    my($self, @packages) = @_;
    my $find_missing_packages;
    if      ($self->_is_apt_installer) {
	$find_missing_packages = '_find_missing_deb_packages';
    } elsif ($self->{installer} eq 'yum') {
	$find_missing_packages = '_find_missing_rpm_packages';
    } elsif ($self->{os} eq 'freebsd') {
	$find_missing_packages = '_find_missing_freebsd_pkg_packages';
    } elsif ($self->{os} eq 'MSWin32') {
	$find_missing_packages = '_find_missing_chocolatey_packages';
    } elsif ($self->{installer} eq 'homebrew') {
	$find_missing_packages = '_find_missing_homebrew_packages';
    } else {
	warn "check for installed packages is NYI for $self->{os}/$self->{linuxdistro}";
    }
    if ($find_missing_packages) {
	my @plain_packages;
	my @missing_packages;
	for my $package_spec (@packages) {
	    if ($package_spec =~ m{\|}) { # has alternatives
		my @single_packages = split /\s*\|\s*/, $package_spec;
		my @missing_in_packages_spec = $self->$find_missing_packages(@single_packages);
		if (@missing_in_packages_spec == @single_packages) {
		    push @missing_packages, $single_packages[0];
		}
	    } else {
		push @plain_packages, $package_spec;
	    }
	}
	push @missing_packages, $self->$find_missing_packages(@plain_packages);
	@packages = @missing_packages;
    } 
    @packages;
}

sub _install_packages_commands {
    my($self, @packages) = @_;
    my @pre_cmd;
    my @install_cmd;

    # sudo or not?
    if ($self->{installer} eq 'homebrew') {
	# may run as unprivileged user
    } elsif ($self->{installer} eq 'chocolatey') {
	# no sudo on Windows systems?
    } else {
	if ($< != 0) {
	    push @install_cmd, 'sudo';
	}
    }

    # the installer executable
    if ($self->{installer} eq 'homebrew') {
	push @install_cmd, 'brew';
    } else {
	push @install_cmd, $self->{installer};
    }

    # batch, default or interactive
    if ($self->{batch}) {
	if ($self->_is_apt_installer) {
	    push @install_cmd, '-y';
	} elsif ($self->{installer} eq 'yum') {
	    push @install_cmd, '-y';
	} elsif ($self->{installer} eq 'pkg') { # FreeBSD's pkg
	    # see below
	} elsif ($self->{installer} eq 'homebrew') {
	    # batch by default
	} else {
	    warn "batch=1 NYI for $self->{installer}";
	}
    } else {
	if ($self->_is_apt_installer) {
	    @pre_cmd = ('sh', '-c', 'echo -n "Install package(s) '."@packages".'? (y/N) "; read yn; [ "$yn" = "y" ]');
	} elsif ($self->{installer} eq 'yum') {
	    # interactive by default
	} elsif ($self->{installer} eq 'pkg') { # FreeBSD's pkg
	    # see below
	} elsif ($self->{installer} =~ m{^(chocolatey)$}) {
	    # Nothing to do here
	} elsif ($self->{installer} eq 'homebrew') {
	    # the sh builtin echo does not understand -n -> use printf
	    @pre_cmd = ('sh', '-c', 'printf %s "Install package(s) '."@packages".'? (y/N) "; read yn; [ "$yn" = "y" ]');
	} else {
	    warn "batch=0 NYI for $self->{installer}";
	}
    }

    # special options
    if ($self->{installer} eq 'pkg') { # FreeBSD's pkg
	push @install_cmd, '--option', 'LOCK_RETRIES=86400'; # wait quite long in case there are concurrent pkg runs
    }

    # the installer subcommand
    push @install_cmd, 'install'; # XXX is this universal?

    # post options
    if ($self->{batch} && $self->{installer} eq 'pkg') {
	push @install_cmd, '-y';
    }
    if ($self->{batch} && $self->{installer} eq 'chocolatey') {
	push @install_cmd, '-y';
    }

    push @install_cmd, @packages;
    
    if ($self->{os} eq 'MSWin32') {
        # Wrap the thing in our small powershell program
        @install_cmd = _win32_run_elevated(@install_cmd);
    };

    ((@pre_cmd ? \@pre_cmd : ()), \@install_cmd);
}

1;

__END__

=head1 NAME

CPAN::Plugin::Sysdeps - a CPAN.pm plugin for installing system dependencies

=head1 SYNOPSIS

In the CPAN.pm shell:

    o conf plugin_list push CPAN::Plugin::Sysdeps
    o conf commit

=head1 DESCRIPTION

B<CPAN::Plugin::Sysdeps> is a plugin for L<CPAN.pm|CPAN> (version >=
2.07) to install non-CPAN dependencies automatically. Currently, the
list of required system dependencies is maintained in a static data
structure in L<CPAN::Plugin::Sysdeps::Mapping>. Supported operations
systems and distributions are FreeBSD and Debian-like Linux
distributions. There are also some module rules for Fedora-like Linux
distributions, Windows through chocolatey, and Mac OS X through
homebrew.

The plugin may be configured like this:

    o conf plugin_list CPAN::Plugin::Sysdeps=arg1,arg2,...

Possible arguments are:

=over

=item C<apt-get>, C<aptitude>, C<pkg>, C<yum>, C<homebrew>

Force a particular installer for system packages. If not set, then the
plugin find a default for the current operating system or linux
distributions:

=over

=item Debian-like distributions: C<apt-get>

=item Fedora-like distributions: C<yum>

=item FreeBSD: C<pkg>

=item Windows: C<chocolatey>

=item Mac OS X: C<homebrew>

=back

Additionally, L<sudo(1)> is prepended before the installer programm if
the current user is not a privileged one, and the installer requires
elevated privileges.

=item C<batch>

Don't ask any questions.

=item C<interactive>

Be interactive, especially ask for confirmation before installing a
system package.

=item C<dryrun>

Only log installation actions.

=item C<debug>

Turn debugging on. Alternatively the environment variable
C<CPAN_PLUGIN_SYSDEPS_DEBUG> may be set to a true value.

=item C<mapping=I<perlmod|file>>

Prepend another static mapping from cpan modules or distributions to
system packages. This should be specified as a perl module
(I<Foo::Bar>) or an absolute file name. The mapping file is supposed
to just return the mapping data structure as described below.

=back

=head2 MAPPING

!This implementation is subject to change!

A mapping is tree-like data structure expressed as nested arrays. The
top-level nodes usually specify a cpan module or distribution to
match, and a leaf should specify the dependent system packages.

A sample mapping may look like this:

    (
     [cpanmod => ['BerkeleyDB', 'DB_File'],
      [os => 'freebsd',
       [package => 'db48']],
      [linuxdistro => '~debian',
       [linuxdistrocodename => 'squeeze',
	[package => 'libdb4.8-dev']],
       [linuxdistrocodename => 'wheezy',
	[package => 'libdb5.1-dev']],
       [package => 'libdb5.3-dev']]],
    );

The nodes are key-value pairs. The values may be strings, arrays of
strings (meaning that any of the strings may match), or compiled
regular expressions.

Supported keywords are:

=over

=item cpanmod => I<$value>

Match a CPAN module name (e.g. C<Foo::Bar>).

=item cpandist => I<$value>

Match a CPAN distribution name (e.g. C<Foo-Bar-1.23>). Note that
currently only the base_id is matched; this may change!

=item os => I<$value>

Match a operating system (perl's C<$^O> value).

=item linuxdistro => I<$value>

Match a linux distribution name, as returned by C<lsb_release -is>.
The distribution name is lowercased.

There are special values C<~debian> to match Debian-like distributions
(Ubuntu and LinuxMint) and C<~fedora> to match Fedora-like
distributions (RedHat and CentOS).

=item linuxdistrocodename => I<$value>

Match a linux distribution version using its code name (e.g.
C<jessie>).

TODO: it should be possible to express comparisons with code names,
e.g. '>=squeeze'.

=item linuxdistroversion => I<$value>

Match a linux distribution versions. Comparisons like '>=8.0' are
possible.

=item package => I<$value>

Specify the dependent system packages.

For some distributions (currently: debian-like ones) it is possible to
specify alternatives in the form C<package1 | package2 | ...>.

=back

=head2 PLUGIN HOOKS

The module implements the following CPAN plugin hooks:

=over

=item new

=item post_get

=back

=head1 USE CASES

=head2 CPAN TESTERS

Install system packages automatically while testing CPAN modules. If
the smoke system runs under an unprivileged user, then a sudoers rule
has to be added. For such a user named C<cpansand> on a Debian-like
system this could look like this (two rules for batch and non-batch
mode):

    cpansand ALL=(ALL) NOPASSWD: /usr/bin/apt-get -y install *
    cpansand ALL=(ALL) NOPASSWD: /usr/bin/apt-get install *

=head2 USE WITHOUT CPAN.PM

It's possible to use this module also without CPAN.pm through the
L<cpan-sysdeps> script.

For example, just list the system prereqs for L<Imager> on a FreeBSD
system:

    $ cpan-sysdeps --cpanmod Imager
    freetype2
    giflib-nox11
    png
    tiff
    jpeg

On a Debian system the output will look like:

    libfreetype6-dev
    libgif-dev
    libpng12-dev
    libjpeg-dev
    libtiff5-dev

Just show the packages which are yet uninstalled:

    $ cpan-sysdeps --cpanmod Imager --uninstalled

Show what L<CPAN::Plugin::Sysdeps> would execute if it was run:

    $ cpan-sysdeps --cpanmod Imager --dryrun

And actually run and install the missing packages:

    $ cpan-sysdeps --cpanmod Imager --run

=head2 USE WITH CPAN_SMOKE_MODULES

C<cpan_smoke_modules> is another C<CPAN.pm> wrapper specially designed
for CPAN Testing (to be found at
L<https://github.com/eserte/srezic-misc>. If C<CPAN.pm> is already
configured to use the plugin, then C<cpan_smoke_modules> will also use
this configuration. But it's also possible to use
C<cpan_smoke_modules> without changes to C<CPAN/MyConfig.pm>, and even
with an uninstalled C<CPAN::Plugin::Sysdeps>. This is especially
interesting when testing changes in the Mapping.pm file. A sample
run:

    cd .../path/to/CPAN-Plugin-Sysdeps
    perl Makefile.PL && make all test
    env PERL5OPT="-Mblib=$(pwd)" cpan_smoke_modules -perl /path/to/perl --sysdeps Imager

Or alternatively without any interactive questions:

    env PERL5OPT="-Mblib=$(pwd)" cpan_smoke_modules -perl /path/to/perl --sysdeps-batch Imager

=head1 NOTES, LIMITATIONS, BUGS, TODO

=over

=item * Minimal requirements

CPAN.pm supports the plugin system since 2.07. If the CPAN.pm is
older, then still the C<cpan-sysdeps> script can be used.

It is assumed that some system dependencies are still installed: a
C<make>, a suitable C compiler, maybe C<sudo>, C<patch> (e.g. if there
are distroprefs using patch files) and of course C<perl>. On linux
systems, C<lsb-release> is usually required (there's limited support
for lsb-release-less operation on some Debian-like distributions). On
Mac OS X systems C<homebrew> has to be installed.

=item * Batch mode

Make sure to configure the plugin with the C<batch> keyword (but read
also L</Conflicting packages>). In F<CPAN/MyConfig.pm>:

  'plugin_list' => [q[CPAN::Plugin::Sysdeps=batch]],

Installation of system packages requires root priviliges. Therefore
the installer is run using L<sudo(1)> if the executing user is not
root. To avoid the need to enter a password either make sure that
running the installer program (C<apt-get> or so) is made password-less
in the F<sudoers> file, or run a wrapper like
L<sudo_keeper|https://github.com/eserte/srezic-misc/blob/master/scripts/sudo_keeper>.

=item * Error handling

Failing things in the plugin are causing C<die()> calls. This can
happen if packages cannot be installed (e.g. because of a bad network
connection, the package not existing for the current os or
distribution, package exists only in a "non-free" repository which
needs to be added to F</etc/apt/sources.list>, another installer
process having the exclusive lock...).

=item * Conflicting packages

System prerequisites specified in the mapping may conflict with
already installed packages. Please note that with the "batch"
configuration already installed conflicting packages are actually
removed, at least on Debian systems.

=item * Support for more OS and Linux distributions

Best supported systems are FreeBSD and Debian-like systems (but
details may be missing for distributions like Ubuntu or Mint). Support
for Fedora-like systems and Mac OS X systems is fair, for Windows
quite limited and for other systems missing.

=item * Support for cpanm

To my knowledge there's no hook support in cpanm. Maybe things will
change in cpanm 2.0. But it's always possible to use the
L<cpan-sysdeps> script.

=item * Should gnukfreebsd be handled like debian?

Maybe gnukfreebsd should be included in the "like_debian" condition?

=back

=head1 CREDITS

This module was developed at the Perl QA Hackathon 2016
L<http://act.qa-hackathon.org/qa2016/>
which was made possible by the generosity of many sponsors:
 
L<https://www.fastmail.com> FastMail,
L<https://www.ziprecruiter.com> ZipRecruiter,
L<http://www.activestate.com> ActiveState,
L<http://www.opusvl.com> OpusVL,
L<https://www.strato.com> Strato,
L<http://www.surevoip.co.uk> SureVoIP,
L<http://www.cv-library.co.uk> CV-Library,
L<https://www.iinteractive.com/> Infinity,
L<https://opensource.careers/perl-careers/> Perl Careers,
L<https://www.mongodb.com> MongoDB,
L<https://www.thinkproject.com> thinkproject!,
L<https://www.dreamhost.com/> Dreamhost,
L<http://www.perl6.org/> Perl 6,
L<http://www.perl-services.de/> Perl Services,
L<https://www.evozon.com/> Evozon,
L<http://www.booking.com> Booking,
L<http://eligo.co.uk> Eligo,
L<http://www.oetiker.ch/> Oetiker+Partner,
L<http://capside.com/en/> CAPSiDE,
L<https://www.procura.nl/> Procura,
L<https://constructor.io/> Constructor.io,
L<https://metacpan.org/author/BABF> Robbie Bow,
L<https://metacpan.org/author/RSAVAGE> Ron Savage,
L<https://metacpan.org/author/ITCHARLIE> Charlie Gonzalez,
L<https://twitter.com/jscook2345> Justin Cook.

=head1 CONTRIBUTORS

Max Maischein (CORION) - Windows/chocolatey support

=head1 AUTHOR

Slaven Rezic

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016,2017 by Slaven ReziE<x0107>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<cpan-sysdeps>, L<CPAN>, L<apt-get(1)>, L<aptitude(1)>, L<pkg(8)>, L<yum(1)>.

=cut
