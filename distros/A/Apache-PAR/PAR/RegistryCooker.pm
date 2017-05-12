package Apache::PAR::RegistryCooker;

use strict;
use warnings FATAL => 'all';

# we try to develop so we reload ourselves without die'ing on the warning
no warnings qw(redefine); # XXX, this should go away in production!

our $VERSION = '0.30';

our @ISA = qw(ModPerl::RegistryCooker);
use base qw(ModPerl::RegistryCooker);
use ModPerl::RegistryCooker;

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use File::Spec::Functions();
use Apache::Const -compile => qw(:common);
use Apache::Response ();
use Apache::RequestRec ();
use Apache::RequestUtil ();
use Apache::RequestIO ();
use Apache::Log ();
use Apache::Access ();

use APR::Table ();

use ModPerl::Util ();
use ModPerl::Global ();

sub handler : method {
	my $class = (@_ >= 2) ? shift : __PACKAGE__;
	my $r = shift;
	my $self = $class->new($r);
	$self->{PARDATA} = {
		MEMBER          => undef,
		ZIP             => undef,
		SCRIPT_PATH     => undef,
		EXTRA_PATH_INFO => undef
	}; # Adding on a new element at the end to store our data
	return $self->default_handler();
}

sub read_PAR_script {
	my $self = shift;

	my $contents = $self->{PARDATA}{MEMBER}->contents;
	$self->{CODE} = \$contents;
}

sub can_PAR_compile {
	my $self = shift;
	my $r = $self->{REQ};
	my $filename = $self->{FILENAME};
	my $path_info = $r->path_info;

	unless ($self->_find_file_parts()) {
		$self->log_error("$path_info not found or unable to stat inside $filename");
		return Apache::NOT_FOUND;
	}

	if(defined($self->{PARDATA}{MEMBER}) && $self->{PARDATA}{MEMBER}->isDirectory()) {
		$self->log_error("Unable to serve directory from PAR file");
		return Apache::FORBIDDEN;
	}

	$self->{MTIME} = $self->{PARDATA}{MEMBER}->lastModTime();

	return Apache::OK;

}

sub set_PAR_script_name {
	my $self = shift;
	my $r    = $self->{REQ};
	my @file_parts = split(/\//, $self->{PARDATA}{SCRIPT_PATH});
	my $filename   = $file_parts[-1];
	*0 = \$filename;

	# Additionally, we want to set the extra path info correctly
	# for use in a script
	my $path_info = $self->{PARDATA}{EXTRA_PATH_INFO} ? "/$self->{PARDATA}{EXTRA_PATH_INFO}" : '';
	$r->path_info($path_info);
	$ENV{PATH_INFO} = $path_info; # Is this the right thing to do in all cases?
	$r->filename($self->{PARDATA}{SCRIPT_PATH});
	$self->{FILENAME} = $self->{PARDATA}{SCRIPT_PATH};
}

sub namespace_from_PAR {
	my $self = shift;
	my $r = $self->{REQ};
	my $namespace_path = $r->path_info;
	my ($volume, $dirs, $file) =
		File::Spec::Functions::splitpath($namespace_path);
	my @dirs = File::Spec::Functions::splitdir($dirs);
	return join '_', grep { defined && length } $volume, @dirs, $file;
}

sub _find_file_parts {
	my $self        = shift;
	my $r           = $self->{REQ};
	my $path_info   = $r->path_info;
	my $filename    = $r->filename;

	$path_info      =~ s/^\///;
	my @path_broken = split(/\//, $path_info);
	my $path_name   = 'PARPerlRunPath';
	if($self->isa('Apache::PAR::Registry'))
	{
		$path_name = 'PARRegistryPath';
	}
	my $cur_path    = $r->dir_config->get($path_name);

	$cur_path     ||= 'script/';
	$cur_path       =~ s/\/$//;

	Archive::Zip::setErrorHandler(sub {});
	my $zip = Archive::Zip->new($filename);
	unless(defined($zip)) {
		$r->log_error("Unable to open file $filename");
		return undef;
	}

	# If starting path is /, start with next element
	$cur_path = shift(@path_broken) if $cur_path eq '';

	my $cur_member  = undef;
	while(defined(($cur_member = $zip->memberNamed($cur_path) || $zip->memberNamed("$cur_path/"))) && @path_broken) {
		last unless($cur_member->isDirectory());
		$cur_path .= '/' . shift(@path_broken);
	}
	$cur_member = $zip->memberNamed($cur_path);
	return undef unless (defined($cur_member));
	$self->{PARDATA}{ZIP}             = $zip;
	$self->{PARDATA}{MEMBER}          = $cur_member;
	$self->{PARDATA}{SCRIPT_PATH}     = $cur_path;
	$self->{PARDATA}{EXTRA_PATH_INFO} = join('/', @path_broken);
	return $cur_path;
}

1;
__END__

=head1 NAME

Apache::PAR::RegistryCooker - Internal base class used by Apache::PAR classes

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

This is an internal class used by Apache::PAR, and should not be used directly.

=head1 EXPORT

None by default.

=head1 AUTHOR

Nathan Byrd, E<lt>nathan@byrd.netE<gt>

=head1 SEE ALSO

L<Apache::PAR>

=head1 COPYRIGHT

Copyright 2002 by Nathan Byrd E<lt>nathan@byrd.netE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

