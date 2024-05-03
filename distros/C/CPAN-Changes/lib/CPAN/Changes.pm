package CPAN::Changes;
use strict;
use warnings;

our $VERSION = '0.500004';
$VERSION =~ tr/_//d;

use Sub::Quote qw(qsub);
use Types::Standard qw(ArrayRef HashRef InstanceOf);
use CPAN::Changes::Release;

use Moo;

my $release_type = (InstanceOf['CPAN::Changes::Release'])->plus_coercions(
  HashRef ,=> qsub q{ CPAN::Changes::Release->new($_[0]) },
);
has _releases => (
  is => 'rw',
  init_arg => 'releases',
  isa => ArrayRef[$release_type],
  coerce => 1,
  default => qsub q{ [] },
);

has preamble => (
  is => 'rw',
  default => '',
);

sub clone {
  my $self = shift;
  my %attrs = %$self;
  $attrs{releases} = [ map $_->clone, @{delete $self->{_releases}} ];
  return (ref $self)->new(%attrs, @_);
}

# backcompat
sub releases {
  my ($self, @args) = @_;
  if (@args > 1 or @args == 1 && ref $args[0] ne 'ARRAY') {
    @args = [ @args ];
  }
  @{ $self->_releases(@args) };
}

sub _numify_version {
  my $version = shift;
  $version = _fix_version($version);
  $version =~ s/_//g;
  if ($version =~ s/^v//i || $version =~ tr/.// > 1) {
    my @parts = split /\./, $version;
    my $n = shift @parts;
    $version = sprintf(join('.', '%s', ('%03s' x @parts)), $n, @parts);
  }
  $version += 0;
  return $version;
}

sub _fix_version {
  my $version = shift;
  return 0 unless defined $version;
  my $v = ($version =~ s/^v//i);
  $version =~ s/[^\d\._].*//;
  $version =~ s/\.[._]+/./;
  $version =~ s/[._]*_[._]*/_/g;
  $version =~ s/\.{2,}/./g;
  $v ||= $version =~ tr/.// > 1;
  $version ||= 0;
  return (($v ? 'v' : '') . $version);
}

sub find_release {
  my ($self, $version) = @_;

  my ($release) = grep { $_->version eq $version } @{ $self->_releases };
  return $release
    if $release;
  $version = _numify_version($version) || return undef;
  ($release) = grep { _numify_version($_->version) == $version } @{ $self->_releases };
  return $release;
}

sub reversed {
  my ($self) = @_;
  return $self->clone(releases => [ reverse @{ $self->_releases } ]);
}

sub serialize {
  my ($self, %opts) = @_;

  if ($opts{reverse}) {
    $self = $self->reversed;
  }
  my $width = $opts{width} || 75;
  my @styles = @{ $opts{styles} || ['', '[]', '-', '*'] };
  my @indents = @{ $opts{indents} || ['', ' ', ''] };

  my $out = $self->preamble || '';
  $out .= "\n\n"
    if $out;

  for my $release (reverse @{$self->_releases}) {
    my $styles = \@styles;
    my $indents = \@indents;
    if (
      !$opts{styles}
      and (
        grep {
          length($styles->[1]) > 1
          && length($indents->[0] . $styles->[1] . $_->text) > $width
        }
          @{ $release->entries }
        or
        !grep { $_->has_entries }
          @{ $release->entries }
      )
    ) {
      $styles = [ '', '-', '*' ];
    }
    $out .= "\n"
      unless $out eq '' || $out =~ /\n\n\z/;
    $out .= $release->serialize(
      %opts,
      indents => $indents,
      styles => $styles,
      width => $width - length $indents->[0],
    );
  }
  return $out;
}

require CPAN::Changes::Parser;

# :( i know people use these
our $W3CDTF_REGEX = $CPAN::Changes::Parser::_ISO_8601_DATE;
our $UNKNOWN_VALS = $CPAN::Changes::Parser::_UNKNOWN_DATE;

sub load {
  my ($class, $filename, %args) = @_;
  $args{version_like} = $args{next_token}
    if exists $args{next_token};
  require CPAN::Changes::Parser;
  CPAN::Changes::Parser->new(%args)->parse_file($filename);
}

sub load_string {
  my ($class, $string, %args) = @_;
  $args{version_like} = $args{next_token}
    if exists $args{next_token};
  require CPAN::Changes::Parser;
  CPAN::Changes::Parser->new(%args)->parse_string($string);
}

sub add_release {
  my ($self, @new_releases) = @_;
  @new_releases = map { $release_type->coerce($_) } @new_releases;
  my @releases = @{ $self->_releases };
  for my $new_release (@new_releases) {
    my $version = _numify_version($new_release->version);
    for my $release (@releases) {
      if (_numify_version($release->version) == $version) {
        $release = $new_release;
        undef $new_release;
      }
    }
  }
  push @releases, grep { defined } @new_releases;
  $self->_releases(\@releases);
  return 1;
}

sub delete_release {
  my ($self, @versions) = @_;
  my @releases = @{ $self->_releases };
  for my $version (map { _numify_version($_) } @versions) {
    @releases = grep { _numify_version($_->version) != $version } @releases;
  }
  $self->_releases(\@releases);
}

sub release {
  my ($self, $version) = @_;
  $self->find_release($version);
}

sub delete_empty_groups {
  my ($self) = @_;
  for my $release ( @{ $self->_releases } ) {
    $release->delete_empty_groups;
  }
}

1;
__END__

=head1 NAME

CPAN::Changes - Parser for CPAN style change logs

=head1 SYNOPSIS

  use CPAN::Changes;
  my $changes = CPAN::Changes->load('Changes');
  $changes->release('0.01');

=head1 DESCRIPTION

It is standard practice to include a Changes file in your distribution. The
purpose the Changes file is to help a user figure out what has changed since
the last release.

People have devised many ways to write the Changes file. A preliminary
specification has been created (L<CPAN::Changes::Spec>) to encourage module
authors to write clear and concise Changes.

This module will help users programmatically read and write Changes files that
conform to the specification.

=head1 METHODS

=head2 new ( %args )

Creates a B<CPAN::Changes> object.

=head3 %args

=over 4

=item preamble

The preamble section of the changelog.

=item releases

An arrayref of L<CPAN::Changes::Release> objects.

=back

=head2 load ( $filename, %args )

Creates a new B<CPAN::Changes> object by parsing the given file via
L<CPAN::Changes::Parser>.

=head2 load_string ( $filename, %args )

Creates a new B<CPAN::Changes> object by parsing the given string via
L<CPAN::Changes::Parser>.

=head2 preamble ( [ $preamble ] )

Gets or sets the preamble section.

=head2 releases ( [ @releases ] )

Gets or sets the list of releases as L<CPAN::Changes::Release> objects.

=head2 add_release ( @releases )

Adds the given releases to the change log.  If a release of the same version
exists, it will be overwritten.

=head2 delete_release ( @versions )

Removes the given versions from change log.

=head2 find_release ( $version )

Finds a release with the given version.

=head2 reversed

Returns a new B<CPAN::Changes> object with the releases in the opposite order.

=head2 clone ( %attrs )

Returns a new C<CPAN::Changes> object with the given attributes changed.

=head2 serialize ( %options )

Returns the change log as a string suitable for saving as a F<Changes> file.

=over 4

=item width

The width to wrap lines at.  By default, lines will be wrapped at 75 characters.

=item styles

An array reference of styles to use when outputting the entries, one for each
level of change. The first entry is used for the release entry itself.

The styles can be either a single character to prefix change lines or two
characters to use as a prefix and suffix.

=item indents

An array reference of indent strings to use when outputting the entries.

=item reverse (legacy)

If true, releases will be output in reversed order.

=item group_sort (legacy)

A code reference used to sort the groups in the releases.

=back

=head1 LEGACY METHODS

=head2 delete_empty_groups

Removes empty groups.

=head2 release

An alias for find_release.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

Brian Cassidy <bricas@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2011-2015 the CPAN::Changes L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
