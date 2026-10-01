package CPAN::Maker::Bootstrapper::Role::DarkPANRequires;

use strict;
use warnings;

use Carp qw(croak);
use CLI::Simple::Constants qw(:booleans);
use Data::Dumper;
use English qw(-no_match_vars);
use HTTP::Tiny;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use JSON;
use Role::Tiny;

use Readonly;

Readonly::Scalar our $METACPAN_URL     => 'https://fastapi.metacpan.org/v1/download_url/';
Readonly::Scalar our $CPANFILE_DARKPAN => 'cpanfile.darkpan';
Readonly::Scalar our $CPANM_DARKPAN    => 'cpanm.darkpan';
Readonly::Scalar our $REQUIRES_FILE    => 'requires';

########################################################################
sub cmd_create_darkpan_requires {
########################################################################
  my ($self) = @_;

  open my $requires_fh, '<', $REQUIRES_FILE
    or croak sprintf 'Could not open %s: %s', $REQUIRES_FILE, $OS_ERROR;

  my $darkpan_index = $self->fetch_darkpan_index;

  my %darkpan_requires;

  while ( my $line = <$requires_fh> ) {
    chomp $line;

    next
      if $line =~ /^\s*$/;

    next
      if $line =~ /^\s*#/;

    my ( $module, $version ) = split /\s+/, $line, 2;

    next
      if !$module;

    next
      if !$self->is_on_darkpan( $module, $darkpan_index );

    my $distribution = $self->is_on_metacpan($module);

    if ($distribution) {
      $self->get_logger->warn( sprintf '%s is available from both CPAN and the configured DarkPAN; preferring DarkPAN',
        $module );
    }

    $version //= 0;

    $darkpan_requires{$module} = $version;
  }

  close $requires_fh
    or croak sprintf 'Could not close %s: %s',
    $REQUIRES_FILE,
    $OS_ERROR;

  $self->write_cpanfile_darkpan( \%darkpan_requires );

  $self->write_cpanm_darkpan( \%darkpan_requires );

  return $SUCCESS;
}

########################################################################
sub write_cpanfile_darkpan {
########################################################################
  my ( $self, $requires ) = @_;

  open my $fh, '>', $CPANFILE_DARKPAN
    or croak sprintf 'Could not write %s: %s',
    $CPANFILE_DARKPAN,
    $OS_ERROR;

  for my $module ( sort keys %{$requires} ) {
    my $version = $requires->{$module};

    printf {$fh}
      "requires '%s', '%s';\n",
      $module,
      $version;
  }

  close $fh
    or croak sprintf 'Could not close %s: %s',
    $CPANFILE_DARKPAN,
    $OS_ERROR;

  return;
}

########################################################################
sub write_cpanm_darkpan {
########################################################################
  my ( $self, $requires ) = @_;

  open my $fh, '>', $CPANM_DARKPAN
    or croak sprintf 'Could not write %s: %s',
    $CPANM_DARKPAN,
    $OS_ERROR;

  for my $module ( sort keys %{$requires} ) {
    my $version = $requires->{$module};

    if ( !$version || $version eq '0' ) {
      print {$fh} $module, "\n";
      next;
    }

    printf {$fh}
      "%s~%s\n",
      $module,
      $version;
  }

  close $fh
    or croak sprintf 'Could not close %s: %s',
    $CPANM_DARKPAN,
    $OS_ERROR;

  return;
}

########################################################################
sub fetch_darkpan_index {
########################################################################
  my ($self) = @_;

  my $darkpan_url = $ENV{DARKPAN_URL};

  croak 'DARKPAN_URL is not set'
    if !$darkpan_url;

  $darkpan_url =~ s{/\z}{};

  my $url = $darkpan_url . '/modules/02packages.details.txt.gz';

  my $listing = $self->fetch_02packages($url);

  $listing =~ s/\A.*?\n\n//s;

  my %modules;

  for my $line ( split /\n/, $listing ) {
    next
      if !$line;

    my ( $module, $version, $distribution ) = split /\s+/, $line, 3;

    next
      if !$module;

    $modules{$module} = {
      version      => $version,
      distribution => $distribution,
    };
  }

  return \%modules;
}

########################################################################
sub is_on_darkpan {
########################################################################
  my ( $self, $module, $darkpan_index ) = @_;

  $darkpan_index //= $self->fetch_darkpan_index;

  return q{}
    if !exists $darkpan_index->{$module};

  return $module;
}

########################################################################
sub is_on_metacpan {
########################################################################
  my ( $self, $module ) = @_;

  my $url = $METACPAN_URL . $module;

  my $rsp = HTTP::Tiny->new->get($url);

  return q{}
    if $rsp->{status} == 404;

  croak sprintf 'ERROR: could not fetch %s: %s', $url, $rsp->{reason}
    if !$rsp->{success};

  my $payload = decode_json( $rsp->{content} );

  return $payload->{distribution} // q{};
}

########################################################################
sub fetch_02packages {
########################################################################
  my ( $self, $url ) = @_;

  my $rsp = HTTP::Tiny->new->get($url);

  croak sprintf 'ERROR: could not fetch %s: %s', $url, $rsp->{reason}
    if !$rsp->{success};

  my $listing = q{};

  gunzip \$rsp->{content} => \$listing
    or croak sprintf 'ERROR: could not decompress %s: %s',
    $url,
    $GunzipError;

  return $listing;
}

1;
