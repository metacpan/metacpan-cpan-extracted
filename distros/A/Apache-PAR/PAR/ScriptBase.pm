package Apache::PAR::ScriptBase;

use 5.005;
use strict;

# Exporter
require Exporter;
use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION);
@ISA = qw(Exporter);
%EXPORT_TAGS = ( 'all' => [ qw( ) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );

$VERSION = '0.30';

use Apache::Constants qw(OK NOT_FOUND FORBIDDEN);
use Archive::Zip ();

sub readscript {
	my $pr = shift;
	my $contents = $pr->{_member}->contents;
	$pr->{'code'} = \$contents;
}

sub set_script_name {
	my $pr = shift;
	my $r  = $pr->{r};

	my @file_parts = split(/\//, $pr->{_script_path});
	my $filename = $file_parts[-1];
	*0 = \$filename;
}

sub _can_compile {
	my $pr        = shift;
	my $r         = $pr->{r};
	my $filename  = $r->filename;
	my $path_info = $r->path_info;

	unless ($pr->_find_file_parts()) {
		my $msg = "$path_info not found or unable to stat inside $filename";
		$r->log_error($msg);
		$r->notes('error-notes', $msg);
		return NOT_FOUND;
	}

	if(defined($pr->{_member}) && $pr->{_member}->isDirectory()) {
		$r->log_reason("Unable to serve directory from PAR file", $filename);
		return FORBIDDEN;
	}

	$pr->{'mtime'} = $pr->{_member}->lastModTime();
	return wantarray ? (OK, $pr->{'mtime'}) : OK;
}

sub _find_file_parts {
	my $pr          = shift;
	my $r           = $pr->{r};
	my $path_info   = $r->path_info;
	my $filename    = $r->filename;

	$path_info      =~ s/^\///;
	my @path_broken = split(/\//, $path_info);

        my $path_name   = 'PARPerlRunPath';
        if($pr->isa('Apache::PAR::Registry'))
        {
                $path_name = 'PARRegistryPath';
        }

	my $cur_path    = $r->dir_config($path_name) || 'script/';
	$cur_path =~ s/\/$//;

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
	$pr->{_zip}             = $zip;
	$pr->{_member}          = $cur_member;
	$pr->{_script_path}     = $cur_path;
	$pr->{_extra_path_info} = join('/', @path_broken);
	return $cur_path;
}

sub _set_path_info {
	my $pr = shift;
	my $r  = $pr->{r};

	my $path_info = $pr->{_extra_path_info} ? "/$pr->{_extra_path_info}" : '';
	$r->path_info($path_info);
	$ENV{PATH_INFO} = $path_info;
	$r->filename($pr->{_script_path});
}

1;
__END__

=head1 NAME

Apache::PAR::ScriptBase - Internal base class used by Apache::PAR classes

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

