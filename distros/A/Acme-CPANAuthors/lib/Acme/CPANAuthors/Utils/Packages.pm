package Acme::CPANAuthors::Utils::Packages;

use strict;
use warnings;
use CPAN::DistnameInfo;
use version;
use base 'Acme::CPANAuthors::Utils::CPANIndex';

sub _preambles {qw(
  file url description columns intended_for
  written_by line_count last_updated
)}

sub _mappings {+{
  package             => 'packages',
  distribution        => 'dists',
  latest_distribution => 'latest_dists',
}}

sub _parse {
  my ($self, $file) = @_;

  my $handle = $self->_handle($file);

  my $done_preambles = 0;
  while (my $line = $handle->getline) {
    $line =~ s/\r?\n$//;
    unless ($done_preambles) {
      if ($line =~ /^\s*$/) {
        $done_preambles = 1;
      }
      elsif (my ($key, $value) = $line =~ /^([^:]+):\s*(.*)/) {
        $key =~ tr/A-Z\-/a-z_/;
        $self->{preambles}{$key} = $value;
      }
      next;
    }

    my ($package, $version, $path) = split ' ', $line;

    my $dist = $self->_dist_from_path($path);

    my $pkg = Acme::CPANAuthors::Utils::Packages::Package->new({
      package      => $package,
      version      => $version,
      distribution => $dist,
    });

    push @{ $dist->{packages} ||= [] }, $pkg;

    $self->{packages}{$package} = $pkg;
  }
}

sub _dist_from_path {
  my ($self, $path) = @_;

  my $dist = $self->{dists}{$path};
  return $dist if $dist;

  my $info = CPAN::DistnameInfo->new($path);
  $dist = Acme::CPANAuthors::Utils::Packages::Distribution->new({
    prefix    => $path,
    dist      => $info->dist,
    version   => $info->version,
    maturity  => $info->maturity,
    filename  => $info->filename,
    cpanid    => $info->cpanid,
    distvname => $info->distvname,
  });

  $self->{dists}{$path} = $dist;

  return unless defined $dist->version && $dist->dist;

  # see if it's latest
  my $distname = $info->dist;
  my $latest = $self->{latest_dists}{$distname};
  unless ($latest) {
    $self->{latest_dists}{$distname} = $dist;
    return $dist;
  }
  my ($distv, $latestv);
  eval {
    no warnings;
    $distv   = version->new( $dist->version   || 0 );
    $latestv = version->new( $latest->version || 0 );
  };
  if ($distv && $latestv) {
    if ($distv > $latestv) {
      $self->{latest_dists}{$distname} = $dist;
    }
  }
  else {
    no warnings;
    if ($dist->version > $latest->version) {
      $self->{latest_dists}{$distname} = $dist;
    }
  }

  $dist;
}

package #
  Acme::CPANAuthors::Utils::Packages::Distribution;

use strict;
use warnings;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_ro_accessors(qw/
  prefix
  dist
  version
  maturity
  filename
  cpanid
  distvname
  packages
/);

*path    = *prefix;
*name    = *dist;
*pauseid = *cpanid;

sub contains { @{ shift->{packages} || [] } }

package #
  Acme::CPANAuthors::Utils::Packages::Package;

use strict;
use warnings;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_ro_accessors(qw/
  package
  version
  distribution
/);

*name = *package;

1;

__END__

=head1 NAME

Acme::CPANAuthors::Utils::Packages

=head1 SYNOPSIS

  use Acme::CPANAuthors::Utils::Packages;

  # you can't pass the raw content of 02packages.details.txt(.gz)
  my $packages = Acme::CPANAuthors::Utils::Packages->new(
    'cpan/modules/02packages.details.txt.gz'
  );

  my $package = $packages->package('Acme::CPANAuthors');

  my $dist    = $packages->distribution('I/IS/ISHIGAKI/Acme-CPANAuthors-0.12.tar.gz');

  my $latest  = $packages->latest_distribution('Acme-CPANAuthors');

=head1 DESCRIPTION

This is a subset of L<Parse::CPAN::Packages>. The reading
methods are similar in general (accessors are marked as
read-only, though). Internals and data-parsing methods may
be different, but you usually don't need to care.

=head1 METHODS

=head2 new

always takes a file name (both raw C<.txt> file and C<.txt.gz>
file name are acceptable). Raw content of the file is not
acceptable.

=head2 package

takes a name of a package, and returns an object that represents it.

=head2 distribution

takes a file name of a distribution, and returns an object that
represents it.

=head2 latest_distribution

takes a name of a distribution, and returns an object that represents
the latest version of it.

=head2 packages, distributions, latest_distributions

returns a list of stored packages or (latest) distribution objects.

=head2 package_count, distribution_count, latest_distribution_count

returns the number of stored packages or (latest) distributions.

=head1 PREAMBLE ACCESSORS

=head2 file, url, description, columns, intended_for, written_by, line_count, last_updated

These are accessors to the preamble information of
C<02packages.details.txt>.

=head1 PACKAGE ACCESSORS

=head2 package (name), version

  my $package = $packages->package('Acme::CPANAuthors');
  print $package->package, "\n"; # Acme::CPANAuthors
  print $package->version, "\n"; # 0.12

=head2 distribution

returns an object that represents the distribution that the package
belongs to.

=head1 DISTRIBUTION ACCESSORS

=head2 prefix (path), dist (name), version, maturity, filename, cpanid (pauseid), distvname

  my $dist = $packages->distribution('I/IS/ISHIGAKI/Acme-CPANAuthors-0.12.tar.gz');
  print $dist->prefix,"\n";    # I/IS/ISHIGAKI/Acme-CPANAuthors-0.12.tar.gz
  print $dist->dist,"\n";      # Acme-CPANAuthors
  print $dist->version,"\n";   # 0.12
  print $dist->maturity,"\n";  # released
  print $dist->filename,"\n";  # Acme-CPANAuthors-0.12.tar.gz
  print $dist->cpanid,"\n";    # ISHIGAKI
  print $dist->distvname,"\n"; # Acme-CPANAuthors-0.12

=head2 packages (contains)

returns a list of objects that represent the packages the
distribution contains. C<packages> method returns it as an
array reference, C<contains> returns it as an array.

=head1 SEE ALSO

L<Parse::CPAN::Packages>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
