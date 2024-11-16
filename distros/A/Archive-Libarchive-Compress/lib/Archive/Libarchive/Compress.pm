use warnings;
use 5.020;
use experimental qw( postderef signatures );

package Archive::Libarchive::Compress 0.01 {

  use Carp ();
  use Path::Tiny ();
  use File::chdir;
  use Ref::Util qw( is_ref is_plain_scalarref is_plain_coderef );
  use Archive::Libarchive 0.04 qw( ARCHIVE_OK ARCHIVE_WARN );
  use FFI::C::Stat;

  # ABSTRACT: Recursively archive a directory (using libarchive)


  sub new ($class, %options) {
      Carp::croak("Required option: one of filename or memory")
        unless defined($options{filename} // $options{memory});
      Carp::croak("Exactly one of filename or memory is required")
        if defined($options{filename}) && defined($options{memory});

      if(defined $options{memory} && !(is_plain_scalarref $options{memory} && defined $options{memory}->$* && !is_ref $options{memory}->$*)) {
        Carp::croak("Option memory must be a scalar reference to a plain non-reference scalar");
      }

      Carp::croak("Entry is not a code reference")
        if defined $options{entry} && !is_plain_coderef $options{entry};

      my $self = bless {
        filename   => delete $options{filename},
        entry      => delete($options{entry}) // sub ($e) { return 1 },
        memory     => delete $options{memory},
        prep       => delete($options{prep}) // sub ($ar) { $ar->set_format_pax_restricted },
      }, $class;

      Carp::croak("Illegal options: @{[ sort keys %options ]}")
        if %options;

      return $self;
  }


  sub filename   ($self) { return $self->{filename}       }
  sub from       ($self) { return $self->{from}           }

  sub _archive ($self) {
    my $w = Archive::Libarchive::ArchiveWrite->new;
    my $e = Archive::Libarchive::Entry->new;

    $self->{prep}->($w);

    my $ret;

    if($self->filename) {
      $ret = $w->open_filename($self->filename);
    } else {
      $ret = $w->open_memory($self->{memory});
    }

    if($ret == ARCHIVE_WARN) {
      Carp::carp($w->error_string);
    } elsif($ret < ARCHIVE_WARN) {
      Carp::croak($w->error_string);
    }

    return($w,$e);
  }

  sub _iterate ($self, $w, $e, $path) {

    if(-d $path) {
      foreach my $child (sort { $a->basename cmp $b->basename } $path->children) {
        $self->_iterate($w, $e, $child);
      }
    } elsif(-f $path) {
      $e->clear;
      $e->set_pathname("$path");
      $e->set_filetype('reg');
      my $stat = FFI::C::Stat->new("$path");
      $e->copy_stat($stat);

      if($self->{entry}->($e)) {
        my $ret = $w->write_header($e);

        if($ret == ARCHIVE_WARN) {
          Carp::carp($w->error_string);
        } elsif($ret < ARCHIVE_WARN) {
          Carp::croak($w->error_string);
        }

        $ret = $w->write_data(\$path->slurp_raw);

        if($ret == ARCHIVE_WARN) {
          Carp::carp($w->error_string);
        } elsif($ret < ARCHIVE_WARN) {
          Carp::croak($w->error_string);
        }
      }
    }
  }


  sub compress ($self, %options) {
    Carp::croak("Already compressed") if defined $self->from;

    my $from = Path::Tiny->new($options{from} // $CWD);

    my($w, $e) = $self->_archive;

    local $CWD = $from;

    $self->_iterate($w, $e, Path::Tiny->new("."));

    $w->close;

  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::Libarchive::Compress - Recursively archive a directory (using libarchive)

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Archive::Libarchive::Compress;

 my $w = Archive::Libarchive::Compress->new( filename => 'foo.tar' );
 $w->compress( from => '.' );

=head1 DESCRIPTION

This module recursively archives a directory to either a file or
to memory.  This module does not store directory structure, just
the files, so an empty directory will not be represented in the
resulting archive.

=head1 CONSTRUCTOR

=head2 new

 my $w = Archive::Libarchive::Compress->new(%args);

Exactly one of C<filename> and C<memory> are required.  All other
arguments are optional.

=over 4

=item entry

Callback function called for each entry before it is written to
the archive.  The entry is passed in as an instance of
L<Archive::Libarchive::Entry>.  If this callback returns a false
value, then the entry will not be written to the archive.

 my $w = Archive::Libarchive::Compress->new(
   filename => 'foo.tar',
   entry => sub ($e) {
     # skip "hidden" files
     return $e->pathname !~ /^\./;
   },
 )

You may also modify the entry, before it gets written.  This can
be useful for modifying stored file properties like the owner,
group or permissions that you may not want in the archive.

=item filename

The name of the archive filename to create.

=item memory

Scalar reference which will be used as a buffer to write the archive
to memory.  This scalar does not have to be pre-allocated, so this
will work:

 my $out = '';
 my $w = Archive::Libarchive::Compress->new( memory => \$out );

=item prep

Callback function called before the archive has been opened.
An instance of L<Archive::Libarchive::ArchiveWrite> will be passed
in.  This is useful for specifying a format for the archive.
If not provided, then pax restricted format will be used.
(This is uncompressed and widely supported).  If you wanted
to for example use GNU tar format compressed with bzip2:

 my $w = Archive::Libarchive::Compress->new(
   filename => 'foo.tar.bz2',
   prep => sub ($archive) {
     $archive->set_format_gnutar;
     $archive->add_filter_bzip2;
   },
 );

See L<Archive::Libarchive::ArchiveWrite> for more details.

=back

=head1 METHODS

=head2 filename

 my $filename = $w->filename;

Returns the Archive filename.

=head2 from

 my $from = $w->from;

Returns the directory that was archived.  If L</compress> hasn't been called yet,
then it will return C<undef>.

=head2 compress

 $w->compress( from => $dir );
 $w->compress;

Recursively archives the directory.  If C<$dir> is not provided, then
the current directory will be used.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
