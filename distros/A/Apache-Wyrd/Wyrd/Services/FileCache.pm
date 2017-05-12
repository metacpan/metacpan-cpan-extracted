use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Services::FileCache;
use strict;
use Apache::Wyrd::Services::SAK qw(slurp_file token_parse);
use Exporter;

our $VERSION = '0.98';
our @ISA = qw(Exporter);
our @EXPORT = qw(get_cached);

my %_file_cache_register = ();
my %_file_timestamp_register = ();
my $_previous_checktime_register = undef;
my $timeout = 30;

=pod

=head1 NAME

Apache::Wyrd::Services::FileCache - Cache service for frequently-accessed files

=head1 SYNOPSIS

	use Apache::Wyrd::Services::FileCache;
	$self->get_cached('/var/lib/www/document_template.html');

=head1 DESCRIPTION

The FileCache is designed to reduce the number of disk accesses required
for Wyrds to make use of frequently-used files.  It stores such files in
memory, checking every 30 seconds to see if they are changed.  As the
perl environment persists under mod_perl, the cache persists with it.

For areas where changes are very frequent (such as during development),
the caching behavior can be turned off within the apache config by
setting C<NoFileCache> to a true value:

	PerlSetVar NoFileCache 1

The time between checks is also confiruable using a PerlSetVar directive:

	PerlSetVar FileCacheTimeout x

Where x is a number of seconds.

=head1 FLAGS

=over

=item allow_nonexistent_files

Do not report a fatal error if the file can't be found.  Instead, return
undef for contents.

=back

=head1 METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<get_cached> (scalar)

Get the file contents.  If the file has never been read by this process,
it is read into memory.  The argument should be an absolute path to the
file.

=cut

sub get_cached {
	my ($self, $file) = @_;
	my $time = time;
	my @stats = (undef,undef,undef,undef,undef,undef,undef,undef,undef,$_file_timestamp_register{$file});
	my $new_timeout = 0;
	my $force_load = 0;
	if ($self->can('dbl')) {#we're in a Wyrd, so we can check the dir_config;
		if ($self->dbl->req->dir_config('NoFileCache')) {
			$force_load = 1;
		}
		$new_timeout = $self->dbl->req->dir_config('FileCacheTimeout')
	}
	#NB use or flip-flop for $new_timeout so that the dir-config value does not persist
	#across different directory boundaries.
	if ($force_load or ($_previous_checktime_register < ($time - ($new_timeout || $timeout)))) {
		#$self->_info("checking $file against file cache");
		@stats = stat($file);
		delete($_file_cache_register{$file}) if ($stats[9] > $_file_timestamp_register{$file});
		$_previous_checktime_register = $time;
	}
	return $_file_cache_register{$file} if (exists($_file_cache_register{$file}));
	unless (-r $file and -f _) {
		$self->_raise_exception("File $file cannot be read or is not a proper file.")
			unless ($self->_flags->allow_nonexistent_files);
	}
	$self->_info("reading $file for file cache") if ($self->can('_info'));
	$_file_cache_register{$file} =  ${slurp_file($file)};
	$_file_timestamp_register{$file} = $stats[9];
	return $_file_cache_register{$file};
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

reserves the private global variables: $_file_cache_register,
$_file_timestamp_register, and $_previous_checktime_register.

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;