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
use HTTP::Request;
use IO::Scalar;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use LWP::UserAgent;
use List::Util qw(none);
use Log::Log4perl qw(:easy);
use Log::Log4perl::Level;
use Pod::Usage;

use Readonly;
Readonly our $BASE_URL => q{};

use parent qw(Class::Accessor::Validated);

our $VERSION = '0.02';

our @EXPORT_OK = qw(parse_distribution_path);

our %ATTRIBUTES = (
  logger        => 0,
  log_level     => 0,
  package       => 0,  # Archive::Tar of unzip packag
  module_index  => 0,  # distribution tarball indexed list of contents
  darkpan_index => 0,  # distribution list (raw)
  help          => 0,
  base_url      => 1,
  module        => 0,
);

__PACKAGE__->setup_accessors( keys %ATTRIBUTES );

caller or __PACKAGE__->main();

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  $options->{log_level} //= 'info';

  my $self = $class->SUPER::new($options);

  return $self;
}

########################################################################
sub parse_distribution_path {
########################################################################
  my ($path) = @_;

  my @distribution = ( $path =~ m{D/DU/DUMMY/(.*)-([v\d.]+)[.]tar[.]gz$}xsm );

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

  $package =~ s{D/DU/DUMMY/(.*)[.]tar[.]gz$}{$1}xsm;

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

  my $file = '02packages.details.txt.gz';

  my $index_url = sprintf '%s/modules/%s', $self->get_base_url, $file;

  my $ua  = LWP::UserAgent->new;
  my $req = HTTP::Request->new( GET => $index_url );
  my $rsp = $ua->request($req);

  my $index = q{};

  die Dumper( [ rsp => $rsp ] )
    if !$rsp->is_success;

  my $index_zipped = $rsp->content;

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

  my $ua  = LWP::UserAgent->new;
  my $req = HTTP::Request->new( GET => $package_url );
  my $rsp = $ua->request($req);

  die Dumper( [ rsp => $rsp ] )
    if !$rsp->is_success;

  my $package_zipped = $rsp->content;
  my $package        = q{};

  gunzip( \$package_zipped, \$package );

  my $tar = Archive::Tar->new;

  my $fh = IO::Scalar->new( \$package );

  $tar->read($fh);

  $self->set_package($tar);

  my ($package_basename) = $package_name =~ /^D\/DU\/DUMMY\/(.*?)[.]tar[.]gz$/xsm;

  $logger->debug(
    sub {
      return Dumper(
        [ package_basename => $package_basename,
          files            => $tar->list_files
        ]
      );
    }
  );

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

  foreach (@modules) {
    my ( $module, $version, $zip ) = split /\s+/xsm;

    if ( $module_versions{$module} && $version gt $module_versions{$module} ) {
      delete $module_index{$zip};
    }

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

DarkPAN::Utils - set of utilities for working with a DarkPAN

=head1 SYNOPSIS

 use DarkPAN::Utils qw(parse_distribution_path);

 use DarkPAN::Utils::Docs;

 my $dpu = DarkPAN::Utils->new(
   log_level => 'debug',
   base_url  => 'https://cpan.openbedrock.net/orepan2',
 );

 $dpu->fetch_darkpan_index;

 my $package = $dpu->find_module('SomeApp::Module');


 if ($package) {
   $dpu->fetch_package( $package->[0] );
 }


 my $file = $dpu->extract_module( $package->[0], 'SomeApp::Module');
 my $docs = DarkPAN::Utils::Docs->new( text => $file );

 $docs->parse_pod;

 print $docs->get_html();

=head1 DESCRIPTION

=head1 METHODS AND SUBROUTINES

=head2 new

=head2 parse_distribution_path

=head2 find_module

=head2 extract_file

=head2 extract_module

=head2 fetch_darkpan_index

=head2 fetch_package

=head2 init_logger

=head2 fetch_options

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=head1 SEE ALSO

L<OrePAN2>, L<OrePAN2::S3>

=cut
