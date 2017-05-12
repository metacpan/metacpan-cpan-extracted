package Apache::PAR::Registry;
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
	@ISA = qw(Exporter Apache::PAR::ScriptBase Apache::RegistryNG);
	require Apache::RegistryNG;
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
	is_cached       => 'is_cached',
	should_compile  => 'should_compile_if_modified',
	flush_namespace => 'NOP',
	cache_table     => 'cache_table_common',
	cache_it        => 'cache_it',
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
	shift->{_script_path};
}

sub run {
	my $pr = shift;
	$pr->_set_path_info();
	return $pr->SUPER::run();
}

1;
__END__

=head1 NAME

Apache::PAR::Registry - Apache::Registry subclass which serves Apache::Registry scripts to clients from within .par files.

=head1 SYNOPSIS

A sample configuration (within a web.conf) is below:

  Alias /myapp/cgi-perl/ ##PARFILE##/
  <Location /myapp/cgi-perl>
    Options +ExecCGI
    SetHandler perl-script
    PerlHandler Apache::PAR::Registry
    PerlSetVar PARRegistryPath registry/
  </Location>

=head1 DESCRIPTION

Subclass of Apache::Registry (or ModPerl::Registry) to serve Apache::Registry scripts to clients from within .par files.  Registry scripts should continue to operate as they did before when inside a .par archive.

To use, add Apache::PAR::Registry into the Apache configuration, either through an Apache configuration file, or through a web.conf file (discussed in more detail in the Apache::PAR manpage.)


=head2 Some things to note:

Options +ExecCGI B<must> be turned on in the configuration in order to serve Registry scripts.

.par files must be executable by the web server user in order to serve Registry scripts.

File modification testing is performed on the script itself.  Otherwise modifying the surrounding package should not cause mod_perl to reload the module.

Modules can be loaded from within the .par archive as if they were physically on the filesystem.  However, because of the way PAR.pm works, your scripts can also load modules within other .par packages, as well as modules from your @INC.

By default, scripts are served under the script/ directory within a .par archive.  This value can be changed using the PARRegistryPath variable, for instance:

PerlSetVar PARRegistryPath registry/

B<NOTE:> The default location has changed with Apache::PAR 0.20.  Previously, the default location for Registry scripts was the scripts/ directory.  To continue to use the old path in an archive, set the following in a web.conf:

PerlSetVar PARRegistryPath scripts/

=head1 EXPORT

None by default.

=head1 AUTHOR

Nathan Byrd, E<lt>nathan@byrd.netE<gt>

=head1 SEE ALSO

L<perl>.

L<PAR>, L<Apache::PAR>, and L<Apache::Registry> or L<ModPerl::Registry>.

=head1 COPYRIGHT

Copyright 2002 by Nathan Byrd E<lt>nathan@byrd.netE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
