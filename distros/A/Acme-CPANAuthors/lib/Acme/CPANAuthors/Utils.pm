package Acme::CPANAuthors::Utils;

use strict;
use warnings;
use Carp;
use base qw( Exporter );
use File::Spec;

our $VERSION   = '0.25'; # see RT #43388
our @EXPORT_OK = qw( cpan_authors cpan_packages );

my $CPANFiles = {};

sub clear_cached_cpan_files () { $CPANFiles = {}; }

sub cpan_authors () {
  unless ( $CPANFiles->{authors} ) {
    require Acme::CPANAuthors::Utils::Authors;
    $CPANFiles->{authors} =
      Acme::CPANAuthors::Utils::Authors->new( _cpan_authors_file() );
  }
  return $CPANFiles->{authors};
}

sub cpan_packages () {
  unless ( $CPANFiles->{packages} ) {
    require Acme::CPANAuthors::Utils::Packages;
    $CPANFiles->{packages} =
      Acme::CPANAuthors::Utils::Packages->new( _cpan_packages_file() );
  }
  return $CPANFiles->{packages};
}

sub _cpan_authors_file () {
  _cpan_file( authors => '01mailrc.txt.gz' );
}

sub _cpan_packages_file () {
  _cpan_file( modules => '02packages.details.txt.gz' );
}

sub _cpan_file {
  my ($dir, $basename) = @_;

  my $file;
  if ($ENV{ACME_CPANAUTHORS_HOME}) {
    $file = _catfile($ENV{ACME_CPANAUTHORS_HOME}, $dir, $basename);
    return $file if $file && -r $file;
  }
  require File::Path;
  for my $parent (File::Spec->tmpdir, '.') {
    my $tmpdir = File::Spec->catdir($parent, '.acmecpanauthors', $dir);
    eval { File::Path::mkpath($tmpdir) };
    next unless -d $tmpdir && -r _;
    $file = _catfile($tmpdir, $basename);
    my $how_old = -M $file;
    if (!-r $file or !$how_old or $how_old > 1) {
      require HTTP::Tiny;
      my $ua = HTTP::Tiny->new(env_proxy => 1);
      my $res = $ua->mirror('http://www.cpan.org/'.$dir.'/'.$basename, $file);
      next unless $res->{success};
    }
    return $file if -r $file;
  }
  croak "$basename not found";
}

sub _catfile { File::Spec->canonpath( File::Spec->catfile( @_ ) ); }

1;

__END__

=head1 NAME

Acme::CPANAuthors::Utils

=head1 DESCRIPTION

This may export several utility functions to use internally.

=head1 FUNCTIONS

=head2 cpan_authors (exportable)

returns a (probably cached) Parse::CPAN::Authors object.

=head2 cpan_packages (exportable)

returns a (probably cached) Parse::CPAN::Packages object.

=head2 clear_cached_cpan_files

clears cached Parse::CPAN::Authors/Packages objects.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
