########################################################################
package DarkPAN::Utils;
########################################################################

use strict;
use warnings;

use Archive::Tar;
use Data::Dumper;
use English qw(no_match_vars);
use File::Basename qw(fileparse);
use Getopt::Long qw(:config no_ignore_case);
use HTTP::Tiny;
use IO::Scalar;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use List::Util qw(none);
use Log::Log4perl qw(:easy);
use Log::Log4perl::Level;
use Pod::Usage;

use Readonly;
Readonly::Scalar our $BASE_URL         => q{};
Readonly::Scalar our $PACKAGES_DETAILS => '02packages.details.txt.gz';

Readonly::Scalar our $TRUE  => 1;
Readonly::Scalar our $FALSE => 0;

use parent qw(Class::Accessor::Validated);

our $VERSION = '1.0.0';

our @EXPORT_OK = qw(parse_distribution_path);

our %ATTRIBUTES = (
  logger        => $FALSE,
  log_level     => $FALSE,
  package       => $FALSE,  # Archive::Tar of unzip packag
  module_index  => $FALSE,  # distribution tarball indexed list of contents
  darkpan_index => $FALSE,  # distribution list (raw)
  help          => $FALSE,
  base_url      => $TRUE,
  module        => $FALSE,
);

__PACKAGE__->setup_accessors( keys %ATTRIBUTES );

caller or __PACKAGE__->main();

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  $options->{log_level} //= 'info';

  # base_url only required when not constructing from a local package
  local $ATTRIBUTES{base_url} = !$options->{package};

  my $self = $class->SUPER::new($options);

  return $self;
}

########################################################################
sub parse_distribution_path {
########################################################################
  my ($path) = @_;

  my @distribution = ( $path =~ m{(?:.*/)?([^/]*?)-([v\d.]+)[.]tar[.]gz$}xsm );

  return @distribution;
}

########################################################################
sub find_module {
########################################################################
  my ( $self, $module ) = @_;

  my $module_index = $self->get_module_index;

  my @found;

  foreach my $p ( keys %{$module_index} ) {

    my ($distribution) = parse_distribution_path($p);

    if ( $distribution eq $module ) {
      push @found, $p;
      next;
    }

    next if none { $_ eq $module } @{ $module_index->{$p} };

    push @found, $p;
  }

  return
    if !@found;

  return \@found;
}

########################################################################
sub extract_file {
########################################################################
  my ( $self, $file ) = @_;

  my $package = $self->get_package;

  my @list = $package->list_files;

  return
    if none { $file eq $_ } @list;

  return $package->get_content($file);
}

########################################################################
sub extract_module {
########################################################################
  my ( $self, $package, $module ) = @_;

  $package =~ s{(?:.*\/)?([^\/]+)[.]tar[.]gz$}{$1}xsm;

  my $file = $module;

  $file =~ s/::/\//xsmg;

  return $self->extract_file( sprintf '%s/lib/%s.pm', $package, $file );
}

########################################################################
sub fetch_darkpan_index {
########################################################################
  my ($self) = @_;

  return $self
    if $self->get_darkpan_index;

  my $file = $PACKAGES_DETAILS;

  my $index_url = sprintf '%s/modules/%s', $self->get_base_url, $file;

  my $rsp = HTTP::Tiny->new->get($index_url);

  my $index = q{};

  die Dumper( [ rsp => $rsp ] )
    if !$rsp->{success};

  my $index_zipped = $rsp->{content};

  gunzip( \$index_zipped, \$index )
    or die "unzip failed: $GunzipError\n";

  $self->set_darkpan_index($index);

  $self->_create_module_index;

  return $self;
}

########################################################################
sub fetch_package {
########################################################################
  my ( $self, $package_name ) = @_;

  my $logger = $self->get_logger;

  my $package_url = sprintf '%s/authors/id/%s', $self->get_base_url, $package_name;

  my $rsp = HTTP::Tiny->new->get($package_url);

  die Dumper( [ rsp => $rsp ] )
    if !$rsp->{success};

  my $package_zipped = $rsp->{content};
  my $package        = q{};

  gunzip( \$package_zipped, \$package );

  my $tar = Archive::Tar->new;

  my $fh = IO::Scalar->new( \$package );

  $tar->read($fh);

  $self->set_package($tar);

  if ($logger) {
    $logger->debug(
      sub {
        return Dumper( [ files => $tar->list_files ] );
      }
    );
  }

  return $self;
}

########################################################################
sub _create_module_index {
########################################################################
  my ($self) = @_;

  my $index = $self->get_darkpan_index;

  $index =~ s/^(?:.*)?\n\n//xsm;

  my @modules = split /\n/xsm, $index;

  my %module_index;
  my %module_versions;
  my %module_zip;  # tracks the zip currently representing each module

  foreach (@modules) {
    my ( $module, $version, $zip ) = split /\s+/xsm;

    if ( $module_versions{$module} && $version gt $module_versions{$module} ) {
      delete $module_index{ $module_zip{$module} };  # delete the OLD zip
    }

    $module_versions{$module} = $version;
    $module_zip{$module}      = $zip;  # update the tracker
    $module_index{$zip} //= [];
    push @{ $module_index{$zip} }, $module;
  }

  $self->set_module_index( \%module_index );

  return $self;
}

########################################################################
sub init_logger {
########################################################################
  my ($self) = @_;

  my $level = $self->get_log_level // 'info';

  $level = {
    'trace' => $TRACE,
    'debug' => $DEBUG,
    'info'  => $INFO,
    'warn'  => $WARN,
    'error' => $ERROR,
    'trace' => $TRACE,
  }->{$level} // $INFO;

  Log::Log4perl->easy_init($level);

  $self->set_logger( Log::Log4perl->get_logger );

  return $self;
}

########################################################################
sub fetch_options {
########################################################################

  my %options = (
    'log-level' => 'info',
    'base-url'  => $BASE_URL,
  );

  my @option_specs = qw(
    help|h
    package|p=s
    module|m=s
    log-level|l=s
    base-url|u=s
  );

  my $retval = GetOptions( \%options, @option_specs );

  if ( !$retval || $options{help} ) {
    pod2usage( -exitval => 1, -verbose => 1 );
  }

  foreach my $o ( keys %options ) {
    next if $o !~ /[-]/xsm;

    my $value = delete $options{$o};
    $o =~ s/[-]/_/xsm;
    $options{$o} = $value;
  }

  return \%options;
}

########################################################################
sub main {
########################################################################

  my $options = fetch_options();

  my $self = DarkPAN::Utils->new($options);

  $self->init_logger;

  my $logger = $self->get_logger;

  $self->fetch_darkpan_index;

  $logger->trace(
    Dumper(
      [ packages     => [ sort keys %{ $self->get_module_index } ],
        module_index => $self->get_module_index,
      ]
    )
  );

  my $module = $self->get_module;

  if ($module) {
    my $package = $self->find_module($module);

    die sprintf "could not find %s\n", $module
      if !$package;

    $logger->info( sprintf 'fetching package: %s', $package );

    $self->fetch_package($package);

    my $file = $self->extract_module( $package, $module );

    my $docs = DarkPAN::Module::Docs->new($file);

    print {*STDOUT} $docs->{html};
  }

  return 0;
}

1;

__END__

=pod

=head1 NAME

DarkPAN::Utils - utilities for working with a DarkPAN repository

=head1 SYNOPSIS

 use DarkPAN::Utils qw(parse_distribution_path);
 use DarkPAN::Utils::Docs;

 # Fetch and search the remote index
 my $dpu = DarkPAN::Utils->new(
   base_url  => 'https://cpan.openbedrock.net/orepan2',
   log_level => 'debug',
 );

 $dpu->init_logger;
 $dpu->fetch_darkpan_index;

 my $packages = $dpu->find_module('Amazon::Lambda::Runtime');

 if ($packages) {
   $dpu->fetch_package( $packages->[0] );

   my $source = $dpu->extract_module(
     $packages->[0],
     'Amazon::Lambda::Runtime',
   );

   my $docs = DarkPAN::Utils::Docs->new( text => $source );
   print $docs->get_html;
 }

 # Work with a local tarball directly (no base_url required)
 use Archive::Tar;

 my $tar = Archive::Tar->new;
 $tar->read('Amazon-Lambda-Runtime-2.1.0.tar.gz');

 my $dpu = DarkPAN::Utils->new( package => $tar );

 my $source = $dpu->extract_module(
   'Amazon-Lambda-Runtime-2.1.0.tar.gz',
   'Amazon::Lambda::Runtime',
 );

 # Parse a distribution path directly
 my ($name, $version) = parse_distribution_path(
   'D/DU/DUMMY/Amazon-Lambda-Runtime-2.1.0.tar.gz'
 );
 # $name    => 'Amazon-Lambda-Runtime'
 # $version => '2.1.0'

=head1 DESCRIPTION

C<DarkPAN::Utils> provides utilities for interacting with a private CPAN
mirror (DarkPAN) hosted on Amazon S3 and served via CloudFront. It can
download and parse the standard CPAN package index
(F<02packages.details.txt.gz>), fetch and unpack distribution tarballs,
and extract individual module source files for documentation generation.

The module may also be used with a local L<Archive::Tar> object to avoid
any network access, which is the preferred approach when the tarball has
just been uploaded and the CDN cache may not yet reflect the new content.

When invoked directly as a script (C<perl -MDarkPAN::Utils -e 1> or
C<darkpan-utils>), it parses command-line options and fetches and
displays documentation for a named module.

=head1 CONSTRUCTOR

=head2 new

 my $dpu = DarkPAN::Utils->new( base_url => $url );

 my $dpu = DarkPAN::Utils->new( base_url => $url, log_level => 'debug' );

 my $dpu = DarkPAN::Utils->new( package => $archive_tar_object );

Creates a new C<DarkPAN::Utils> instance. Arguments may be passed as a
flat list of key/value pairs or as a hashref.

=head3 Attributes

=over 4

=item base_url (required unless C<package> is provided)

The root URL of the DarkPAN repository, e.g.
C<https://cpan.openbedrock.net/orepan2>. Required when fetching the
package index or tarballs from the network. Not required when a local
L<Archive::Tar> object is supplied via C<package>.

=item package

An L<Archive::Tar> object representing a pre-loaded distribution
tarball. When provided, C<base_url> is not required and no network
access is performed by C<extract_file> or C<extract_module>.

=item log_level

Logging verbosity. One of C<trace>, C<debug>, C<info>, C<warn>,
or C<error>. Defaults to C<info>. Has no effect until C<init_logger>
is called.

=item module

The name of a Perl module (e.g. C<Amazon::Lambda::Runtime>). Used by
the command-line interface to identify the target module.

=item logger

A L<Log::Log4perl> logger instance. Populated by C<init_logger>; not
normally set directly.

=back

=head1 METHODS AND SUBROUTINES

=head2 parse_distribution_path

 use DarkPAN::Utils qw(parse_distribution_path);

 my ($name, $version) = parse_distribution_path($path);

Exported function (not a method). Parses a distribution path in any of
the following formats and returns the distribution name and version as a
two-element list:

=over 4

=item * Bare filename: C<Amazon-Lambda-Runtime-2.1.0.tar.gz>

=item * CPAN author path: C<D/DU/DUMMY/Amazon-Lambda-Runtime-2.1.0.tar.gz>

=item * Absolute local path: C</home/user/Amazon-Lambda-Runtime-2.1.0.tar.gz>

=back

Returns an empty list if the path does not match the expected
C<Name-Version.tar.gz> pattern.

=head2 find_module

 my $packages = $dpu->find_module('Amazon::Lambda::Runtime');

 if ($packages) {
   for my $path ( @{$packages} ) {
     print "$path\n";
   }
 }

Searches the in-memory module index (populated by C<fetch_darkpan_index>)
for distributions that contain the named module. The search matches both
by distribution name (the hyphenated form) and by the module names listed
in the package index.

Returns an arrayref of matching distribution paths in
C<D/DU/DUMMY/Name-Version.tar.gz> form, or C<undef> if no match is found.

C<fetch_darkpan_index> must be called before C<find_module>.

=head2 extract_file

 my $content = $dpu->extract_file('Amazon-Lambda-Runtime-2.1.0/README.md');

Retrieves the raw content of a named file from the loaded distribution
tarball. The C<package> attribute must be set, either by calling
C<fetch_package> or by passing an L<Archive::Tar> object to C<new>.

The file name must exactly match an entry in the tarball (including the
leading C<Distribution-Version/> directory prefix).

Returns the file content as a string, or C<undef> if the file is not
found in the tarball.

=head2 extract_module

 my $source = $dpu->extract_module(
   'D/DU/DUMMY/Amazon-Lambda-Runtime-2.1.0.tar.gz',
   'Amazon::Lambda::Runtime',
 );

Extracts the source of a Perl module from the loaded distribution
tarball. The first argument is the distribution path in any format
accepted by C<parse_distribution_path>; the version and path prefix are
stripped automatically. The second argument is the module name in
C<::>-separated form.

The module is expected to reside at C<lib/Module/Name.pm> within the
distribution directory.

Returns the module source as a string, or C<undef> if the file is not
found.

=head2 fetch_darkpan_index

 $dpu->fetch_darkpan_index;

Downloads F<02packages.details.txt.gz> from the DarkPAN repository and
parses it into an internal module index. If the index has already been
fetched, this method returns immediately without making another request.

C<base_url> must be set. Dies on HTTP failure or decompression error.
Returns C<$self>.

=head2 fetch_package

 $dpu->fetch_package('D/DU/DUMMY/Amazon-Lambda-Runtime-2.1.0.tar.gz');

Downloads a distribution tarball from the DarkPAN repository, decompresses
it, and stores the resulting L<Archive::Tar> object in the C<package>
attribute, making its contents available to C<extract_file> and
C<extract_module>.

C<base_url> must be set. Dies on HTTP failure. Returns C<$self>.

=head2 init_logger

 $dpu->init_logger;

Initialises a L<Log::Log4perl> logger at the level specified by the
C<log_level> attribute (default C<info>). Must be called before any
logging output is expected from C<fetch_package> or related methods.

Returns C<$self>.

=head2 fetch_options

 my $options = DarkPAN::Utils::fetch_options();

Parses command-line arguments for use when the module is run as a
script. Returns a hashref of options with hyphenated keys converted to
underscores.

Recognised options:

=over 4

=item --base-url, -u

URL of the DarkPAN repository.

=item --module, -m

Name of the Perl module to retrieve and display.

=item --log-level, -l

Logging level (C<trace>, C<debug>, C<info>, C<warn>, C<error>).
Default: C<info>.

=item --package, -p

Name of a specific distribution tarball.

=item --help, -h

Display usage information and exit.

=back

=head1 AUTHOR

Rob Lauer - E<lt>rlauer@treasurersbriefcase.comE<gt>

=head1 SEE ALSO

L<DarkPAN::Utils::Docs>, L<OrePAN2>, L<OrePAN2::S3>, L<HTTP::Tiny>,
L<Archive::Tar>, L<Log::Log4perl>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
