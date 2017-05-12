package Apache::PAR::Static;

use 5.005;
use strict;

# for version detection
require mod_perl;

# constants
use vars qw($CACHE_FILE $CACHE_MEMORY $CACHE_SHARED);
$CACHE_FILE           = 'file';
$CACHE_MEMORY = 'memory';
$CACHE_SHARED   = 'shared';

# Exporter
require Exporter;
use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION);
@ISA = qw(Exporter);
%EXPORT_TAGS = ( 'all' => [ qw($CACHE_FILE $CACHE_MEMORY $CACHE_SHARED) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );

$VERSION = '0.30';

unless ($mod_perl::VERSION < 1.99) {
	require Apache::Const;
	import Apache::Const qw(OK NOT_FOUND FORBIDDEN);
	require Apache::Response;
	require Apache::RequestRec;
	require Apache::RequestIO;
	require Apache::RequestUtil;
	require APR::Table;
}
else {
	require Apache::Constants;
	import Apache::Constants qw(OK NOT_FOUND FORBIDDEN);
	require Apache::Log;
	require Apache::File;
}

use MIME::Types ();
use Archive::Zip ();

sub handler {
	my $r = shift;

	my $filename    = $r->filename;

	(my $path_info = $r->path_info) =~ s/^\///;

	my $file_path    = $r->dir_config->get('PARStaticFilesPath') || 'htdocs/';
	$file_path      .= '/' if ($file_path !~ /\/$/);
	$file_path      .= $path_info;

	$file_path =~ s/^\///;


	return NOT_FOUND() unless -r $filename;

	# Use the last modified time of the PAR archive
	# Can cause cache to reload more often than necessary
	# but much faster than opening the archive every time
	my $last_modified = (stat(_))[9];

	# Initialize the cache
	my $cache_obj = _init_cache($r);
	my $contents = _get_cache($r, $filename, $file_path, $last_modified, $cache_obj);

	unless (defined $contents) {
		Archive::Zip::setErrorHandler(sub {});
		my $zip = Archive::Zip->new($filename);
		return NOT_FOUND() unless(defined($zip));

		my $member = $zip->memberNamed($file_path) || $zip->memberNamed("$file_path/");
		return NOT_FOUND() unless(defined($member));

		if($member->isDirectory()) {
			my @index_list = $r->dir_config->get('PARStaticDirectoryIndex');
			unless (@index_list) {
				$r->log_error('Apache::PAR::Static: Cannot serve directory - set PARStaticDirectoryIndex to enable');
				return FORBIDDEN();
			}

			# save $file_path for later
			my $index_path = $file_path;
			$index_path =~ s/\/$//;
			foreach my $index_name (@index_list) {
				if(defined($member = $zip->memberNamed("$index_path/$index_name"))) {
					$index_path .= "/$index_name";
					last;
				}
			}
			if(!defined($member) || $member->isDirectory()) {
				$r->log_error('Apache::PAR::Static: Cannot serve directory - Index file does not exist.');
				return FORBIDDEN();
			}
		}

		$contents = $member->contents;
		return NOT_FOUND() unless defined($contents);

		# This uses the original file name (not index name)
		# Can cause a duplicate cache entry, but avoids
		# having to open the archive each time to see if request
		# is for a directory
		_set_cache($r, $filename, $file_path, $contents, $last_modified, $cache_obj);
	}

	$r->headers_out->set('Accept-Ranges' => 'bytes');

	$r->content_type(MIME::Types::by_suffix($file_path)->[0] || $r->dir_config->get('PARStaticDefaultMIME') || 'text/plain');
	(my $package = __PACKAGE__) =~ s/::/\//g;
	$r->update_mtime($last_modified);
	$r->update_mtime((stat $INC{"$package.pm"})[9]);
	$r->set_last_modified;

	$r->set_content_length(length($contents));


	if((my $status = $r->meets_conditions) eq OK()) {
		$r->send_http_header if ($mod_perl::VERSION < 1.99);
	}
	else {
		return $status;
	}
	return OK() if $r->header_only;

	my $range_request = ($mod_perl::VERSION < 1.99) ? $r->set_byterange : 0;

	if($range_request) {
		while(my($offset, $length) = $r->each_byterange) {
			$r->print(substr($contents, $offset, $length));
		}
	}
	else {
		$r->print($contents);
	}
	return OK();
}

# Caching subroutines

sub _init_cache {
	my $r = shift;
	my $cache_type     = lc($r->dir_config->get('PARStaticCacheType'));
	my $cache_expires  = lc($r->dir_config->get('PARStaticCacheExpires')) || 'never';
	my $cache_max_size = lc($r->dir_config->get('PARStaticCacheMaxSize'));

	my $cache_debug = $r->dir_config->get('PARStaticCacheDebug');
	
	$r->log->debug('Apache::PAR::Static: Initializing caching') if $cache_debug;
	
	my $cache_obj = undef;
	
	unless(defined $cache_type and $cache_type ne '') {
		$r->log->debug('Apache::PAR::Static: No cache type specified') if $cache_debug;
		return undef;
	}

	if($cache_type eq $CACHE_MEMORY)    { $cache_type = 'Memory'; }
	elsif($cache_type eq $CACHE_SHARED) { $cache_type = 'SharedMemory'; }
	elsif($cache_type eq $CACHE_FILE)   { $cache_type = 'File'; }

	# makes a module name like Cache::SizeAwareMemoryCache
	my $cache_module =
		'Cache::' .
		($cache_max_size ? 'SizeAware' : '') .
		$cache_type .
		'Cache';

	$r->log->debug("Apache::PAR::Static: Using cache module: $cache_module") if $cache_debug;
	eval "require $cache_module; \$cache_obj = $cache_module->new({
		namespace          => 'APACHE_PAR_STATIC',
		default_expires_in => \$cache_expires,
		max_size           => \$cache_max_size,
		});";

	unless (defined($cache_obj)) {
		$r->log->warn("Apache::PAR::Static: failed to initialize cache object - $@");
		return undef;
	}
	$r->log->debug("Apache::PAR::Static: Caching initialized sucessfully.") if $cache_debug;

	return $cache_obj;
}

sub _get_cache {
	my ($r, $filename, $location, $file_mtime, $cache_obj) = @_;

	return undef unless
		defined $filename and
		defined $location and
		defined $cache_obj;

	my $cache_debug = $r->dir_config->get('PARStaticCacheDebug');

	$r->log->debug('Apache::PAR::Static: Attempting to get cache results') if $cache_debug;
	
	my $cache_results = $cache_obj->get($filename . '!!' . $location);

	# Cache miss
	unless (defined $cache_results) {
		$r->log->debug("Apache::PAR::Static: Cache miss for $location in $filename") if $cache_debug;
		return undef;
	}

	# Check for updated file
	my $cache_mtime = $cache_results->[0];
	unless ($cache_mtime == $file_mtime) {
		$cache_obj->remove($location);
		$r->log->debug("Apache::PAR::Static: Cache time does not match file modified time for $location in $filename") if $cache_debug;
		return undef;
	}

	# Cache hit
	$r->log->debug("Apache::PAR::Static: Cache hit for $location in $filename") if $cache_debug;

	#FIXME pass by reference
	return $cache_results->[1];
}

sub _set_cache {
	#FIXME pass by reference
	my ($r, $filename, $location, $content, $file_mtime, $cache_obj) = @_;
	return unless 
		defined $filename and
		defined $location and 
		defined $content and 
		defined $file_mtime and
		defined $cache_obj;
	my $cache_debug = $r->dir_config->get('PARStaticCacheDebug');

	$r->log->debug("Apache::PAR::Static: Adding $location in $filename to cache") if $cache_debug;

	return $cache_obj->set($filename . '!!' . $location, [$file_mtime, $content]);
}


1;
__END__

=head1 NAME

Apache::PAR::Static - Serve static content to clients from within .par files.

=head1 SYNOPSIS

A sample configuration (within a web.conf) is below:

  Alias /myapp/static/ ##PARFILE##/
  <Location /myapp/static>
    SetHandler perl-script
    PerlHandler Apache::PAR::Static
    PerlSetVar PARStaticFilesPath htdocs/
    PerlSetVar PARStaticDirectoryIndex index.htm
    PerlAddVar PARStaticDirectoryIndex index.html
    PerlSetVar PARStaticDefaultMIME text/html
    PerlSetVar PARStaticCacheType memory
    PerlSetVar PARStaticCacheExpires "1 day"
    PerlSetVar PARStaticCacheMaxSize 1000
  </Location>

=head1 DESCRIPTION

The Apache::PAR::Static module allows a .par file creator to place any static content into a .par archive (under a configurable directory in the .par file) to be served directly to clients.

To use, add Apache::PAR::Static into the Apache configuration, either through an Apache configuration file, or through a web.conf file (discussed in more detail in L<Apache::PAR>.)

=head2 Some things to note:

Apache::PAR::Static does not currently use Apache defaults in mod_dir.  Therefore, it is necessary to specify variables for directory index files and the default mime type.  To specify files to use for directory indexes, use the following syntax in the configuration:

  PerlSetVar PARStaticDirectoryIndex index.htm
  PerlAddVar PARStaticDirectoryIndex index.html
  ...

To set the default MIME type for requests, use:
  PerlSetVar PARStaticDefaultMIME text/html

Currently, Apache::PAR::Static does not have the ability to generate directory indexes for directories inside .par files.  Also, other Apache module features, such as language priority, do not take effect for content inside .par archives.

The default directory to serve static content out of in a .par file is htdocs/ to override this, set the PARStaticFilesPath directive.  For example, to set this to serve files from a static/ directory within the .par file, use:

  PerlSetVar PARStaticFilesPath static/

B<TIP:> To serve the contents of a zip file as static content, this module can be used standalone (without the main Apache::PAR module).  Try something like the following (in an httpd.conf file):

  Alias /zipcontents/ /path/to/a/zip/file.zip/
  <Location /zipcontents>
    SetHandler perl-script
    PerlHandler Apache::PAR::Static
    PerlSetVar PARStaticFilesPath /
    PerlSetVar PARStaticDirectoryIndex index.htm
    PerlAddVar PARStaticDirectoryIndex index.html
    PerlSetVar PARStaticDefaultMIME text/html
  </Location>

B<NOTE:> Under mod_perl 1.x, byte range requests are supported, to facilitate the serving of PDF files, etc. For mod_perl 2.x users, use the appropriate Apache filter (currently untested.)

=head2 Caching static content

Apache::PAR::Static has the ability to cache static content for faster retrieval.
In order to take advantage of this facility, the Cache::Cache module (available from CPAN) must be installed.
Options available for caching:

  PerlSetVar PARStaticCacheType [memory|shared|file]
  PerlSetVar PARStaticCacheExpires "<expires string>"
  PerlSetVar PARStaticCacheMaxSize <maximum size in bytes>
  PerlSetVar PARStaticCacheMaxDebug 1

PARStaticCacheType must be set to either memory, shared or file depending on the type of cache desired.
PARStaticCacheExpires, if present, must be set to a valid string accepted by Cache::Cache.  The default value is "never".  If set to a value, this controls how often members of the cache are expired.
PARStaticCacheMaxSize, if present, must be set to a positive number representing the maximum size that the cache can grow to in bytes.  The default if this is not set is to allow caches of any size.  Setting this value may incur a performance penalty, see the documentation for Cache::Cache for more information.
PARStaticCacheDebug, if set to a true value, will cause caching information to be displayed in the Apache server log.  To see these messages, your LogLevel should be set to debug.

Caching can be very important, depending on performance requirements and hardware used.  On my machine (Pentium 733 running RH 8 Linux and an untuned Apache 1.3.27), the following benchmarks were gathered:

=over 4

=item * Static content served via Apache: 177 req/sec.

=item * Content served via Apache::PAR::Static without caching: 7 req/sec.

=item * Content served via Apache::PAR::Static with memory caching: 111 req/sec.

=back

You may want to play around with the various caching schemes to determing which one is best for your situation.  A quick comparison chart is below of the various caching schemes:

=over 4

=item * memory: Fastest access, most memory consumed

=item * file: Slowest access, least memory consumed

=item * shared: middle in both areas

=back

=head1 EXPORT

None by default.

=head1 AUTHOR

Nathan Byrd, E<lt>nathan@byrd.netE<gt>

=head1 SEE ALSO

L<perl>.

L<Apache::PAR>.

L<PAR>.

L<Cache::Cache>

=head1 COPYRIGHT

Copyright 2002 by Nathan Byrd E<lt>nathan@byrd.netE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
