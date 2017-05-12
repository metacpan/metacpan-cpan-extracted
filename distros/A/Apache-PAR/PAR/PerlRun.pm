package Apache::PAR::PerlRun;

use strict;

# for version detection
require mod_perl;

# Exporter
require Exporter;
use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION);
%EXPORT_TAGS = ( 'all' => [ qw( ) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );
@ISA = qw(Exporter);

$VERSION = '0.30';

unless ($mod_perl::VERSION < 1.99) {
	@ISA = qw(Exporter Apache::PAR::RegistryCooker);
	require Apache::PAR::RegistryCooker;
	require Apache::Const;
	import Apache::Const qw(OK);
}
else {
	@ISA = qw(Exporter Apache::PAR::ScriptBase Apache::PerlRun);
	require Apache::PerlRun;
	require Apache::PAR::ScriptBase;
	require Apache::Constants;
	import Apache::Constants qw(OK);
}

my $parent = 'Apache::PAR::RegistryCooker';

my %aliases = (
	new             => 'new',
	init            => 'init',
	default_handler => 'default_handler',
	run             => 'run',
	make_namespace  => 'make_namespace',
	namespace_root  => 'namespace_root',
	is_cached       => 'FALSE',
	should_compile  => 'TRUE',
	flush_namespace => 'flush_namespace_normal',
	cache_it        => 'NOP',
	rewrite_shebang => 'rewrite_shebang',
	chdir_file      => 'chdir_file_normal',
	get_mark_line   => 'get_mark_line',
	compile         => 'compile',
	error_check     => 'error_check',
	strip_end_data_segment             => 'strip_end_data_segment',
	convert_script_to_compiled_handler => 'convert_script_to_compiled_handler',
	can_compile     => $parent . '::can_PAR_compile',
	read_script     => $parent . '::read_PAR_script',
	set_script_name => $parent . '::set_PAR_script_name',
	namespace_from  => $parent . '::namespace_from_PAR',
);

unless ($mod_perl::VERSION < 1.99) {
	__PACKAGE__->install_aliases(\%aliases);
}

sub can_compile {
	my $pr = shift;

	my $status = $pr->SUPER::can_compile();
	return $status unless $status eq OK();
	return $pr->_can_compile();
}

sub namespace_from {
	my $pr = shift;
	my $r  = $pr->{r};

	my $uri = $r->uri;

	my $path_info = $pr->{_extra_path_info};
	my $script_name = $path_info && $uri =~ /$path_info$/ ?
		substr($uri, 0, length($uri)-length($path_info)) :
		$uri;

	if($Apache::Registry::NameWithVirtualHost && $r->server->is_virtual) {
		my $name = $r->get_server_name;
		$script_name = join "", $name, $script_name if $name;
	}
	$script_name =~ s:/+$:/__INDEX__:;

	return $script_name;
}

sub compile {
	my ($pr, $eval) = @_;
	$pr->_set_path_info();
	return $pr->SUPER::compile($eval);
}

1;
__END__

=head1 NAME

Apache::PAR::PerlRun - Apache::PerlRun (or ModPerl::PerlRun) subclass which serves PerlRun scripts to clients from within .par files.

=head1 SYNOPSIS

A sample configuration (within a web.conf) is below:

  Alias /myapp/cgi-run/ ##PARFILE##/
  <Location /myapp/cgi-run>
    Options +ExecCGI
    SetHandler perl-script
    PerlHandler Apache::PAR::PerlRun
    PerlSetVar PARPerlRunPath perlrun/
  </Location>

=head1 DESCRIPTION

Subclass of Apache::PerlRun (or ModPerl::PerlRun) to serve PerlRun scripts to clients from within .par files.  PerlRun scripts should continue to operate as they did before when inside a .par archive.

To use, add Apache::PAR::PerlRun into the Apache configuration, either through an Apache configuration file, or through a web.conf file (discussed in more detail in the Apache::PAR manpage.)


=head2 Some things to note:

Options +ExecCGI B<must> be turned on in the configuration in order to serve PerlRun scripts.

.par files must be executable by the web server user in order to serve PerlRun scripts.

File modification testing is performed on the script itself.  Otherwise modifying the surrounding package should not cause mod_perl to reload the module.

Modules can be loaded from within the .par archive as if they were physically on the filesystem.  However, because of the way PAR.pm works, your scripts can also load modules within other .par packages, as well as modules from your @INC.

By default, scripts are served under the script/ directory within a .par archive.  This value can be changed using the PARPerlRunPath variable, for instance:

PerlSetVar PARPerlRunPath perlrun/

B<NOTE:> The default location has changed with Apache::PAR 0.20.  Previously, the default location for PerlRun scripts was the scripts/ directory.  To continue to use the old path in an archive, set the following in a web.conf:

PerlSetVar PARPerlRunPath scripts/

=head1 EXPORT

None by default.

=head1 AUTHOR

Nathan Byrd, E<lt>nathan@byrd.netE<gt>

=head1 SEE ALSO

L<perl>.

L<PAR>, L<Apache::PAR>, and L<Apache::PerlRun> or L<ModPerl::PerlRun>.

=head1 COPYRIGHT

Copyright 2002 by Nathan Byrd E<lt>nathan@byrd.netE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
