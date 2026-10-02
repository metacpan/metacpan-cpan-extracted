package CPAN::Maker::Bootstrapper::Role::DepsFilter;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use Data::Dumper;
use Digest::SHA qw(sha1_hex);
use English qw(-no_match_vars);
use File::Spec;
use File::Path qw(make_path);
use HTTP::Tiny;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Storable qw(nstore retrieve);

use Role::Tiny;

########################################################################
sub cmd_deps_filter {
########################################################################
  my ($self) = @_;

  my @mirrors = ('https://cpan.metacpan.org');

  my ($requires) = $self->get_args;

  die "ERROR: usage: deps-filter requires\n"
    if !$requires;

  die "ERROR: $requires not found\n"
    if !-f $requires;

  if ( -e 'build-mirrors' ) {
    foreach my $mirror ( split /\n/xsm, slurp('build-mirrors') ) {
      next if !$mirror || $mirror =~ /^[#]/xsm;
      push @mirrors, $mirror;
    }
  }

  my $index = $self->fetch_index( \@mirrors );

  my $filtered_list = $self->_filter_packages( $index, $requires );

  if ( %{$filtered_list} ) {
    print {*STDOUT} join( "\n", sort values %{$filtered_list} ), "\n";
  }

  return $SUCCESS;
}

########################################################################
sub _create_index {
########################################################################
  my ( $self, $url_list ) = @_;

  my %index;

  # Later repositories take precedence over earlier repositories.
  foreach my $details ( @{$url_list} ) {
    my $listing;

    if ( $details =~ m{\Afile://(.+)\z}xsm ) {
      my $filename = $1;

      die "ERROR: $filename not found\n"
        if !-f $filename;

      gunzip $filename => \$listing
        or die "ERROR: could not read $filename - $GunzipError\n";
    }
    else {
      $listing = $self->fetch_02packages("$details/modules/02packages.details.txt.gz");
    }

    $listing =~ s/\A.*?\n\n//s;

    foreach my $package ( split /\n/, $listing ) {
      my ( $module, undef, $path ) = split /\s+/xsm, $package, 3;

      if ( $path =~ m{/([^/]+)(?:[.]tar[.]gz|[.]tgz)$}xsm ) {
        my $module_name = $1;
        $module_name =~ s/[-]v?[\d].*$//xsm;
        $module_name =~ s/[-]/::/xsmg;
        $index{$module} = $module_name;
      }
      else {
        $index{$module} = $path;
      }
    }
  }

  return \%index;
}

########################################################################
sub _filter_packages {
########################################################################
  my ( $self, $index, $package_list ) = @_;

  my $packages = slurp($package_list);

  my %found_index;
  my %not_found_index;
  my %requires;

  foreach my $p ( split /\n/xsm, $packages ) {
    next if !$p || $p =~ /^[#]/xsm;
    my ($module_name) = split /\s+/xsm, $p;
    $module_name =~ s/^[+\s]+//xsm;
    $requires{$module_name} = $p;

    if ( $index->{$module_name} && $module_name eq $index->{$module_name} ) {
      $found_index{$module_name} = $index->{$module_name};  # what distribution are you in?
    }
    else {
      $not_found_index{$module_name} = $index->{$module_name};
    }
  }

  my @found = keys %found_index;

  foreach my $m ( keys %not_found_index ) {
    next if $index->{$m} && $found_index{ $index->{$m} };

    push @found, $m;
  }

  return { map { $_ => $requires{$_} } @found };
}

########################################################################
sub fetch_index {
########################################################################
  my ( $self, $url_list ) = @_;

  my $cache_dir = $self->_deps_filter_cache_dir;
  my $sources   = $self->_refresh_02packages_cache( $cache_dir, $url_list );
  my $signature = $self->_index_signature($sources);

  my $index = $self->_load_cached_index( $cache_dir, $signature );

  return $index
    if $index;

  $index = $self->_create_index( [ map { $_->{file_url} } @{$sources} ] );

  $self->_store_cached_index( $cache_dir, $signature, $index, );

  return $index;
}

########################################################################
sub _deps_filter_cache_dir {
########################################################################
  my ($self) = @_;

  my $cache_home = $ENV{XDG_CACHE_HOME} // File::Spec->catdir( $ENV{HOME}, '.cache' );

  my $cache_dir = File::Spec->catdir( $cache_home, 'cpan-maker-bootstrapper', 'deps-filter', );

  make_path($cache_dir)
    if !-d $cache_dir;

  return $cache_dir;
}

########################################################################
sub _refresh_02packages_cache {
########################################################################
  my ( $self, $cache_dir, $url_list ) = @_;

  my @sources;

  foreach my $url ( @{$url_list} ) {
    push @sources, $self->_refresh_02packages( $cache_dir, $url, );
  }

  return \@sources;
}

########################################################################
sub _refresh_02packages {
########################################################################
  my ( $self, $cache_dir, $url ) = @_;

  my $cache_key = sha1_hex($url);

  my $repo_dir = File::Spec->catdir( $cache_dir, 'repositories', $cache_key, );

  make_path($repo_dir)
    if !-d $repo_dir;

  my $packages_file = File::Spec->catfile( $repo_dir, '02packages.details.txt.gz', );

  my $state_file = File::Spec->catfile( $repo_dir, 'state.storable', );

  my $state = {};

  if ( -f $state_file ) {
    $state = retrieve($state_file);
  }

  my %headers;

  if ( -f $packages_file ) {
    $headers{'If-None-Match'} = $state->{etag}
      if $state->{etag};

    $headers{'If-Modified-Since'} = $state->{last_modified}
      if $state->{last_modified};
  }

  my $packages_url = sprintf '%s/modules/02packages.details.txt.gz', $url =~ s{/$}{}xr;

  my $res = HTTP::Tiny->new->get( $packages_url, { headers => \%headers }, );

  if ( !$res->{success} && $res->{status} != 304 ) {
    die sprintf
      "ERROR: could not fetch %s - %s %s%s\n",
      $packages_url, $res->{status}, $res->{reason}, $res->{content} ? ": $res->{content}" : q{};
  }

  if ( $res->{status} == 304 && -f $packages_file ) {
    return {
      %{$state},
      url      => $url,
      file_url => "file://$packages_file",
    };
  }

  die sprintf "ERROR: could not fetch %s - %s %s\n", $packages_url, $res->{status}, $res->{reason}
    if !$res->{success};

  open my $fh, '>:raw', $packages_file
    or die "ERROR: could not write $packages_file\n$OS_ERROR";

  print {$fh} $res->{content};
  close $fh;

  $state = {
    url           => $url,
    etag          => $res->{headers}->{etag},
    last_modified => $res->{headers}->{'last-modified'},
    digest        => sha1_hex( $res->{content} ),
  };

  nstore $state, $state_file;

  return { %{$state}, file_url => "file://$packages_file", };
}

########################################################################
sub _index_signature {
########################################################################
  my ( $self, $sources ) = @_;

  my $signature = join "\n",
    map { join q{|}, $_->{url}, $_->{etag} // q{}, $_->{last_modified} // q{}, $_->{digest} // q{} } @{$sources};

  return sha1_hex($signature);
}

########################################################################
sub _load_cached_index {
########################################################################
  my ( $self, $cache_dir, $signature ) = @_;

  my $index_file = File::Spec->catfile( $cache_dir, 'index.storable', );

  my $state_file = File::Spec->catfile( $cache_dir, 'index.signature', );

  return
    if !-f $index_file || !-f $state_file;

  my $cached_signature = slurp($state_file);
  chomp $cached_signature;

  return
    if $cached_signature ne $signature;

  return retrieve($index_file);
}

########################################################################
sub _store_cached_index {
########################################################################
  my ( $self, $cache_dir, $signature, $index ) = @_;

  my $index_file = File::Spec->catfile( $cache_dir, 'index.storable', );

  my $state_file = File::Spec->catfile( $cache_dir, 'index.signature', );

  nstore $index, $index_file;

  open my $fh, '>', $state_file
    or die "ERROR: could not write $state_file\n$OS_ERROR";

  print {$fh} "$signature\n";
  close $fh;

  return $SUCCESS;
}

1;
