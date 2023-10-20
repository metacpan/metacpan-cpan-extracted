package App::LXC::Container::Data::Debian;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container::Data::Debian - define Debian-specific configuration data

=head1 SYNOPSIS

    # This module should only be used by OS-specific classes deriving from
    # it or by App::LXC::Container::Data.

=head1 ABSTRACT

This module provides configuration data specific for Debian.

=head1 DESCRIPTION

see L<App::LXC::Container::Data>

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.29';

use App::LXC::Container::Data::common;
use App::LXC::Container::Texts;

#########################################################################

=head1 EXPORT

Nothing is exported as access should only be done using the singleton
object.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require Exporter;
our @ISA = qw(App::LXC::Container::Data::common);
our @EXPORT_OK = qw();

#########################################################################
#########################################################################

=head1 METHODS

=cut

#########################################################################

=head2 B<content_default_mounts> - return default mount configuration

    Internal Object-oriented implementation of the function
    L<App::LXC::Container::Data::content_default_mounts>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_default_mounts($$@)
{
    local $_ = shift;
    my @output =
	($_->SUPER::content_default_mounts(@_),
	 '',
	 '# Debian:',
	 '/etc/debian_version');
    return @output
}

########################################################################

=head2 depends_on - find package of file

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::depends_on>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub depends_on($$$)
{
    my ($self, $package, $include) = @_;
    $self->SUPER::depends_on($package, $include);

    return ()  unless  $self->_dpkg_status($package);
    my @packages = ();
    local $_;
    # outer loop over all possible dependencies:
    my @check = ('pre-depends', 'depends');
    $include > 0  and  push @check, 'recommends';
    $include > 1  and  push @check, 'suggests';
    foreach (@check)
    {
	# inner loop over all possible dependencies:
	foreach ($self->_dpkg_status($package, $_))
	{
	    # only add installed dependencies:
	    push @packages, $_  if  $self->_dpkg_status($_);
	}
    }
    return @packages;
}

########################################################################

=head2 package_of - find package of file

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::package_of>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
use constant SEARCH => 'dpkg-query --search ';
sub package_of($$)
{
    my ($self, $file) = @_;
    $self->SUPER::package_of($file);
    local $_;
    # TODO: looks like pipe with redirection in shell never fails:
    # uncoverable branch true
    open my $dpkg, '-|', SEARCH . $file . ' 2>/dev/null'
	or  fatal('internal_error__1',
		  'error calling ' . SEARCH . $file . ': '. $!);
    my $package = undef;
    while (<$dpkg>)
    {
	if (m/^([^ ]+): $file$/)
	{
	    $package = $1;
	    last;
	}
    }
    close $dpkg;
    return $package;
}

########################################################################

=head2 paths_of - find package of file

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::paths_of>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
use constant LISTFILES => 'dpkg-query --listfiles ';
sub paths_of($$)
{
    my ($self, $package) = @_;
    $self->SUPER::paths_of($package);
    local $_;
    # TODO: Better approach to get main architecture?
    foreach ('', ':amd64', ':i386')
    {
	my $pa = $package . $_;
	# TODO: as above:
	# uncoverable branch true
	open my $dpkg, '-|', LISTFILES . $pa . ' 2>/dev/null'
	    or  fatal('internal_error__1',
		      'error calling ' . LISTFILES . $pa . ': '. $!);
	# dpkg returns absolute paths, so we don't have to unify them here:
	my @paths = ();
	foreach (<$dpkg>)
	{
	    s/\r?\n//;
	    # ignore non-existing "package diverts others to:"
	    if (s/^package diverts others to: //)
	    {   next unless -e $_;   }
	    # ignore non-existing "diverted by ... to:"
	    elsif (s/^diverted by [-\w]+ to: //)
	    {   next unless -e $_;   }
	    elsif (m/: /)
	    {
		fatal('internal_error__1',
		      'unexpected content in ' . LISTFILES . $pa . ': '. $_);
	    }
	    push @paths, $_;
	}
	# try explicit architectures if close returns non-null:
	close $dpkg  and  return @paths;
    }
    fatal('internal_error__1',
	  LISTFILES . 'failed to find anything for ' . $package);
}

#########################################################################
#########################################################################

=head1 INTRNAL METHODS

The following methods may only be used internally:

=cut

#########################################################################

=head2 B<_dpkg_status> - read and cache dpkg status information

    my $boolean = $self->_dpkg_status($package);
        or
    my @values = $self->_dpkg_status($package, $key);

=head3 example:

    if ($self->_dpkg_status($package))
    {
        my @depends = $self->_dpkg_status($package, 'depends');
        my @recommends = $self->_dpkg_status($package, 'recommends');
        my @suggests = $self->_dpkg_status($package, 'suggests');
    }

=head3 parameters:

    $self               should be reference to singleton
    $package            name of package
    $key                information to be returned

=head3 description:

Read and cache dependency information from the dpkg status file.  A call
without key can be used to check if a package is installed, otherwise the
allowed keys are C<depends>, C<recommends> and C<suggests>.

=head3 returns:

    requested information

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# List of installed packages, their dependencies and other information; this
# is only variable for the unit tests:
our $_dpkg_status = '/var/lib/dpkg/status';

sub _dpkg_status($$;$)
{
    my ($self, $package, $key) = @_;

    # parse and cache file if called for 1st time:
    unless (defined $self->{STATUS})
    {
	my ($pkg, $stat) = ('');
	open $stat, '<', $_dpkg_status
	    or  fatal('can_t_open__1__2', $_dpkg_status, $!);
	$self->{STATUS} = {};
	local $_;
	while (<$stat>)
	{
	    if (m/^Package: (\S+)$/)
	    {
		$pkg = $1;
		defined $self->{STATUS}{$pkg}
		    or  $self->{STATUS}{$pkg} = {};
	    }
	    elsif (m/^Architecture: (\S+)$/)
	    {
		$pkg  or
		    fatal('can_t_determine_package_in__1__2', $_dpkg_status, $.);
		defined $self->{STATUS}{$pkg}{arch}
		    or  $self->{STATUS}{$pkg}{arch} = [];
		push @{$self->{STATUS}{$pkg}{arch}}, lc($1);
	    }
	    elsif (m/^$/)
	    {	$pkg = '';   }
	    elsif (m/^(Depends|Pre-Depends|Recommends|Suggests): (.*)$/)
	    {
		$pkg  or
		    fatal('can_t_determine_package_in__1__2', $_dpkg_status, $.);
		my $key = lc($1);
		my @dependencies =
		    map { s/ \([<=>]+ [^)]+\)$//; $_ }
		    split m/(?:, | \| )/, $2;
		$self->{STATUS}{$pkg}{$key} = \@dependencies;
	    }
	}
	close $stat;
    }

    return undef	unless  defined $self->{STATUS}{$package};
    return 1		unless  defined $key;
    return ()		unless  defined $self->{STATUS}{$package}{$key};
    return @{$self->{STATUS}{$package}{$key}};
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

C<L<App::LXC::Container::Data>>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
