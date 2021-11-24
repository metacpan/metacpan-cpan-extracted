package CAD::Mesh3D::FormatSTL;
$VERSION = v0.2.1.001; # patched version of CAD::Format::STL v0.2.1

use warnings;
use strict;
use Carp;

use CAD::Format::STL::part;

=head1 NAME

CAD::Mesh3D::FormatSTL - read/write 3D stereolithography files

=head1 DON'T USE

Please don't use this module.  CAD::Mesh3D::FormatSTL exists only for
L<CAD::Mesh3D::STL> to use during testing and to overcome limitations
in L<CAD::Format::STL>.  If you think you want to use this directly,
use L<CAD::Format::STL> instead, and encourage the author to implement
and release the known bug-fix that is in the existing issues, possibly
patching it per the instructions in the L<CAD::Mesh3D::STL/"Known Issues">.

=head1 SYNOPSIS

Reading:

  my $stl = CAD::Mesh3D::FormatSTL->new->load("foo.stl");
  # what about the part/multipart?
  my @facets = $stl->part->facets;

Writing:

  my $stl = CAD::Mesh3D::FormatSTL->new;
  my $part = $stl->add_part("my part");
  $part->add_facets(@faces);
  $stl->save("foo.stl");
  # or $stl->save(binary => "foo.stl");

Streaming read/write:

  my $reader = CAD::Mesh3D::FormatSTL->reader("foo.stl");
  my $writer = CAD::Mesh3D::FormatSTL->writer(binary => "bar.stl");
  while(my $part = $reader->next_part) {
    my $part_name = $part->name;
    $writer->start_solid($part_name);
    while(my @data = $part->facet) {
      my ($normal, @vertices) = @data;
      my @v1 = @{$vertices[0]};
      my @v2 = @{$vertices[0]};
      my @v3 = @{$vertices[0]};
      # that's just for illustration
      $writer->facet(\@v1, \@v2, \@v3);
      # note the omitted normal
    }
    $writer->end_solid;
  }

=begin design

The reader auto-detects whether it is binary (but assumes ascii when
seek can't go backwards.)

The reader and writer both take 1, 2, or {1,2}+2n arguments.

This package and/or the reader/writer are subclassable (though getting
$self->reader to instantiate a subclass implies that you have subclassed
$self.)

A cached_facet (or raw_facet) method is necessary to ensure uniform
tranformation of shared points (and optimize the computation.)  This
would return the normal and points as a list of scalars rather than
arrays, with a later call to unpack_point() or something.  The caller
needs to be able to handle the caching (or else there is a callback for
non-cached (or an override for unpack_point().)

Maybe $self->set_writer() and set_reader() immutable object methods?

=end design

=head1 ABOUT

This module provides object-oriented methods to read and write the STL
(Stereo Lithography) file format in both binary and ASCII forms.  The
STL format is a simple set of 3D triangles.

=cut

use Class::Accessor::Classy;
lo 'parts';
no  Class::Accessor::Classy;

=head1 Constructor

=head2 new

  my $stl = CAD::Mesh3D::FormatSTL->new;

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {parts => []};
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 add_part

Create a new part in the stl.

  my $part = $stl->add_part("name");

Optionally, add the faces directly:

  my $part = $stl->add_part("name", @faces);

=cut

sub add_part {
  my $self = shift;
  my ($name, @faces) = @_;

  my $part = CAD::Format::STL::part::->new($name, @faces);
  push(@{$self->{parts}}, $part);
  return($part);
} # end subroutine add_part definition
########################################################################

=head2 part

Get the part at $index.  Negative indices are valid.

  my $part = $stl->part($index);

Throws an error if there is no such part.

=cut

sub part {
  my $self = shift;
  my ($index) = @_;

  @{$self->{parts}} or croak("file has no parts");

  $index ||= 0;
  exists($self->{parts}[$index]) or croak("no part $index");
  return($self->{parts}[$index]);
} # end subroutine part definition
########################################################################

=head1 I/O Methods

=head2 load

Load an STL file (auto-detects binary/ascii)

  $stl = $stl->load("filename.stl");

Optionally, explicitly declare binary mode:

  $stl = $stl->load(binary => "filename.stl");

The $self object is returned to allow e.g. chaining to C<new()>.

The filename may also be a filehandle.

=cut

sub load {
  my $self = shift;
  my ($file, @and) = @_;

  my $mode;
  if(@and) {
    (@and > 1) and croak('too many arguments to load()');
    $mode = $file;
    ($file) = @and;
  }

  # allow filehandle
  unless((ref($file) || '') eq 'GLOB') {
    open(my $fh, '<', $file) or
      die "cannot open '$file' for reading $!";
    $file = $fh;
  }

  # detection
  unless($mode) {
    unless(seek($file, 0,0)) {
      croak('must have explicit mode for non-seekable filehandle');
    }
    # now, detection...
    $mode = sub {
      my $fh = shift;
      seek($fh, 80, 0);
      my $count = eval {
        my $buf; read($fh, $buf, 4) or die;
        unpack('L', $buf);
      };
      $@ and return 'ascii'; # if we hit eof, it can't be binary
      $count or die "detection failed - no facets?";
      my $size = (stat($fh))[7];
      # calculate the expected file size
      my $expect =
        + 80 # header
        +  4 # count
        + $count * (
          + 4 # normal, pt,pt,pt (vectors)
          * 4 # bytes per value
          * 3 # values per vector
          + 2 # the trailing 'short'
        );
      return ($size == $expect) ? 'binary' : 'ascii';
    }->($file);
    seek($file, 0, 0) or die "cannot reset filehandle";
  }

  my $method = '_read_' . lc($mode);
  $self->can($method) or croak("invalid read mode '$mode'");

  $self->$method($file);
  return($self);
} # end subroutine load definition
########################################################################

=head2 _read_ascii

  $self->_read_ascii($filehandle);

=cut

sub _read_ascii {
  my $self = shift;
  my ($fh) = @_;

  my $getline = sub {
    while(my $line = <$fh>) {
      $line =~ s/\s*$//; # allow any eol
      length($line) or next;
      return($line);
    }
    return;
  };
  my $p_re = qr/([^ ]+)\s+([^ ]+)\s+([^ ]+)$/;

  my $part;
  while(my $line = $getline->()) {

    if($line =~ m/^\s*solid (.*)/) {
      $part = $self->add_part($1);
    }
    elsif($line =~ m/^\s*endsolid (.*)/) {
      my $name = $1;
      $part or die "invalid 'endsolid' entry with no current part";
      ($name eq $part->name) or
        die "end of part '$name' should have been '",
          $part->name, "'";
      $part = undef;
    }
    elsif($part) {
      my @n = ($line =~ m/^\s*facet\s+normal\s+$p_re/) or
        die "how did that happen? ($line)";
      #warn "got ", join('|', @n);
      my @facet = (\@n);

      my $next = $getline->();
      unless($next and ($next =~ m/^\s*outer\s+loop$/)) {
        die "facet doesn't start with 'outer loop' ($next)";
      }
      push(@facet, do {
        my @got;
        while(my $line = $getline->()) {
          ($line =~ m/^\s*endloop$/) and last;
          if($line =~ m/^\s*vertex\s+$p_re/) {
            push(@got, [$1, $2, $3]);
          }
        }
        @got;
      });
      (scalar(@facet) == 4) or
        die "need three vertices per facet (not $#facet)";
      my $end = $getline->();
      ($end and ($end =~ m/^\s*endfacet/)) or
        die "bad endfacet $line";
      $part->add_facets([@facet]);
    }
    else {
      die "what? ($line)";
    }
  }
  $part and die "part '", $part->name, "' was left open";
} # end subroutine _read_ascii definition
########################################################################

=head2 get_<something>

These functions are currently only used internally.

=over

=item get_triangle

=item get_ulong

=item get_float32

=item get_short

=back

=cut

sub get_triangle {
  my ($fh) = @_;

  my ($n, $x, $y, $z) = map({[map({get_float32($fh)} 1..3)]} 1..4);
  my $scrap = get_short($fh);
  return($n, $x, $y, $z);
}

sub get_ulong {
  my ($fh) = @_;

  my $buf;
  read($fh, $buf, 4) or warn "EOF?";
  return(unpack('L', $buf));
}

sub get_float32 {
  my ($fh) = @_;

  my $buf;
  read($fh, $buf, 4) or warn "EOF?";
  return(unpack('f', $buf));
}

sub get_short {
  my ($fh) = @_;

  my $buf;
  read($fh, $buf, 2) or warn "EOF?";
  return(unpack('S', $buf));
}

=head2 _read_binary

  $self->_read_binary($filehandle);

=cut

sub _read_binary {
  my $self = shift;
  my ($fh) = @_;

  binmode $fh;

  $self->parts and die "binary STL files must have only one part";

  die "bigfloat" unless(length(pack("f", 1)) == 4);
  # TODO try to read part name from header (up to \0)
  my $name = 'a part';
  seek($fh, 80, 0);

  my $triangles = get_ulong($fh);
  my $part = $self->add_part($name);

  my $count = 0;
  while(1) {
    my @tr = get_triangle($fh);
    # TODO check that the unit normal is within a thousandth of a radian
    # (0.001 rad is ~0.06deg)
    $part->add_facets([@tr]);
    $count++;
    eof($fh) and last;
  }
  ($count == $triangles) or
    die "ERROR: got $count facets (expected $triangles)";
} # end subroutine _read_binary definition
########################################################################

=head2 save

  $stl->save("filename.stl");

  $stl->save(binary => "filename.stl");

=cut

sub save {
  my $self = shift;
  my ($file, @and) = @_;

  my $mode;
  if(@and) {
    (@and > 1) and croak('too many arguments to save()');
    $mode = $file;
    ($file) = @and;
  }

  # allow filehandle
  unless((ref($file) || '') eq 'GLOB') {
    open(my $fh, '>', $file) or
      die "cannot open '$file' for writing $!";
    $file = $fh;
  }

  $mode = 'ascii' unless($mode);

  my $method = '_write_' . lc($mode);
  $self->can($method) or croak("invalid write mode '$mode'");

  $self->$method($file);
} # end subroutine save definition
########################################################################

=head2 _write_binary

  $self->_write_binary($filehandle);

=cut

sub _write_binary {
  my $self = shift;
  my ($fh) = @_;

  my ($part, @and) = $self->parts;
  @and and die 'cannot write binary files with multiple parts';

  binmode $fh;

  my $name = $part->name; # utf8 is ok
  print $fh $name, "\0" x (80 - do {use bytes; length($name)});
  my @facets = $part->facets;
  print $fh pack('L', scalar(@facets));
  foreach my $facet (@facets) {
    print $fh map({map({pack('f', $_)} @$_)} @$facet);
    print $fh "\0" x 2;
  }

} # end subroutine _write_binary definition
########################################################################

=head2 _write_ascii

  $self->_write_ascii($filehandle);

=cut

sub _write_ascii {
  my $self = shift;
  my ($fh) = @_;

  my $spaces = '';
  my $print = sub {print $fh $spaces, @_, "\n"};
  my @parts = $self->parts or croak("no parts to write");
  foreach my $part (@parts) {
    $print->('solid ', $part->name);
    $spaces = ' 'x2;
    foreach my $facet ($part->facets) {
      my ($n, @pts) = @$facet;
      $print->(join(' ', 'facet normal', @$n));
      $spaces = ' 'x4;
      $print->('outer loop');
      $spaces = ' 'x6;
      (@pts == 3) or die "invalid facet";
      foreach my $pt (@pts) {
        $print->(join(' ', 'vertex', @$pt));
      }
      $spaces = ' 'x4;
      $print->('endloop');
      $spaces = ' 'x2;
      $print->('endfacet');
    }
    $spaces = '';
    print $fh 'endsolid ', $part->name, "\n";
  }
} # end subroutine _write_ascii definition
########################################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

CAD::Format::STL Copyright (C) 2007 Eric L. Wilhelm, All Rights Reserved.
CAD::Mesh3D::FormatSTL Copyright (C) 2021 Peter C. Jones, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 PATCHED BY CAD::Mesh3D

Per the LICENSE following the same terms as Perl, the
L<Artistic License|https://dev.perl.org/licenses/artistic.html>
allows publishing a modified or patched version under the same
name as long as it is made freely available or by allowing the
original copyright holder to include my modifications in the
standard version of the package.  As the core modifications
have been in CAD::Format::STL's
L<issue tracker|https://rt.cpan.org/Public/Bug/Display.html?id=83595>
since Feb 2013, the CAD::Mesh3D developer feels justified in providing
the patched version along with CAD::Mesh3D, which requires the patched
version to be used in Windows.  However, to avoid offense and confusion,
the file/module that includes the patch has been renamed to
CAD::Mesh3D::FormatSTL in this distribution.

If the original author of CAD::Format::STL ever publishes a newer version
that doesn't contain the bug, this patched version will not be used by
CAD::Mesh3D, and the official module will be used instead.

=cut

# vi:ts=2:sw=2:et:sta
1;
