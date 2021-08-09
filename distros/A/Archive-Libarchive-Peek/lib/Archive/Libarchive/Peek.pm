package Archive::Libarchive::Peek;

use strict;
use warnings;
use Archive::Libarchive 0.03 qw( ARCHIVE_OK ARCHIVE_WARN ARCHIVE_EOF );
use Ref::Util qw( is_plain_coderef is_plain_arrayref is_plain_scalarref is_ref );
use Carp ();
use Path::Tiny ();
use 5.022;
use experimental qw( signatures refaliasing postderef );

# ABSTRACT: Peek into archives without extracting them
our $VERSION = '0.04'; # VERSION


sub new ($class, %options)
{
  Carp::croak("Required option: one of filename or memory")
    unless defined $options{filename} || defined $options{memory};

  Carp::croak("Exactly one of filename or memory is required")
    if defined $options{filename} && defined $options{memory};

  if(defined $options{filename})
  {
    foreach my $filename (@{ is_plain_arrayref($options{filename}) ? $options{filename} : [$options{filename}] })
    {
      Carp::croak("Missing or unreadable: $filename")
        unless -r $filename;
    }
  }
  elsif(!(is_plain_scalarref $options{memory} && defined $options{memory}->$* && !is_ref $options{memory}->$*))
  {
    Carp::croak("Option memory must be a scalar reference to a plain non-reference scalar");
  }

  my $self = bless {
    filename   => delete $options{filename},
    passphrase => delete $options{passphrase},
    memory     => delete $options{memory},
  }, $class;

  Carp::croak("Illegal options: @{[ sort keys %options ]}")
    if %options;

  return $self;
}


sub filename ($self)
{
  return $self->{filename};
}


sub _archive ($self)
{
  my $r = Archive::Libarchive::ArchiveRead->new;
  my $e = Archive::Libarchive::Entry->new;

  $r->support_filter_all;
  $r->support_format_all;

  if($self->{passphrase})
  {
    if(is_plain_coderef $self->{passphrase})
    {
      $r->set_passphrase_callback($self->{passphrase});
    }
    else
    {
      $r->add_passphrase($self->{passphrase});
    }
  }

  my $ret;

  if(defined $self->{filename})
  {
    $ret = is_plain_arrayref($self->filename) ? $r->open_filenames($self->filename, 10240) : $r->open_filename($self->filename, 10240);
  }
  else
  {
    $ret = $r->open_memory($self->{memory});
  }

  if($ret == ARCHIVE_WARN)
  {
    Carp::carp($r->error_string);
  }
  elsif($ret < ARCHIVE_WARN)
  {
    Carp::croak($r->error_string);
  }

  return ($r,$e);
}

sub _entry ($self, $r, $e)
{
  my $ret = $r->next_header($e);
  return 0 if $ret == ARCHIVE_EOF;
  if($ret == ARCHIVE_WARN)
  {
    Carp::carp($r->error_string);
  }
  elsif($ret < ARCHIVE_WARN)
  {
    Carp::croak($r->error_string);
  }
  return 1;
}

sub files ($self)
{
  my($r, $e) = $self->_archive;

  my @files;

  while(1)
  {
    last unless $self->_entry($r,$e);
    push @files, $e->pathname;
    $r->read_data_skip;
  }

  $r->close;

  return @files;
}


sub _entry_data ($self, $r, $e, $content)
{
  $$content = '';

  if($e->size > 0)
  {
    while(1)
    {
      my $buffer;
      my $ret = $r->read_data(\$buffer);
      last if $ret == 0;
      if($ret == ARCHIVE_WARN)
      {
        Carp::carp($r->error_string);
      }
      elsif($ret < ARCHIVE_WARN)
      {
        Carp::croak($r->error_string);
      }
      $$content .= $buffer;
    }
  }
}

sub file ($self, $filename)
{
  my($r, $e) = $self->_archive;

  while(1)
  {
    last unless $self->_entry($r,$e);
    if($e->pathname eq $filename)
    {
      my $content;
      $self->_entry_data($r, $e, \$content);
      return $content;
    }
    else
    {
      $r->read_data_skip;
    }
  }

  $r->close;

  return undef;
}


sub iterate ($self, $callback)
{
  my($r, $e) = $self->_archive;

  while(1)
  {
    last unless $self->_entry($r,$e);
    my $content;
    $self->_entry_data($r, $e, \$content);
    $callback->($e->pathname, $content, $e);
  }
}


sub as_hash ($self)
{
  my %hash;
  my %links;
  $self->iterate(sub ($path, $content, $e) {
    if(my $target = $e->hardlink)
    {
      if(defined $hash{$target})
      {
        \$hash{$path} = \$hash{$target};
      }
      else
      {
        Carp::croak("found hardlink but no target");
      }
      return;
    }
    my $type = $e->filetype;
    if($type eq 'reg')
    {
      $hash{$path} = $content;
    }
    elsif($type eq 'lnk')
    {
      my $target = Path::Tiny->new($e->symlink)->absolute(Path::Tiny->new("/")->child($e->pathname)->parent)->relative('/');
      $links{$path} = $target;
    }
    else
    {
      $hash{$path} = [$type];
    }
  });

  foreach my $path (keys %links)
  {
    my $target = $links{$path};
    if($hash{$target})
    {
      $hash{$path} = \$hash{$target};
    }
    else
    {
      $hash{$path} = \undef;
    }
  }

  \%hash;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::Libarchive::Peek - Peek into archives without extracting them

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Archive::Libarchive::Peek;
 my $peek = Archive::Libarchive::Peek->new( filename => 'archive.tar' );
 my @files = $peek->files();
 my $contents = $peek->file('README.txt')

=head1 DESCRIPTION

This module lets you peek into archives without extracting them.  It is based on L<Archive::Peek>, but it uses L<Archive::Libarchive>,
and thus all of the many formats supported by C<libarchive>.  It also supports some unique features of the various classes that use
the "Peek" style interface:

=over 4

=item Many Many formats

compressed tar, Zip, RAR, ISO 9660 images, etc.

=item Zips with encrypted entries

You can specify the passphrase or a passphrase callback with the constructor

=item Multi-file RAR archives

If filename is an array reference it will be assumed to be a list of filenames
representing a single multi-file archive.

=back

=head1 CONSTRUCTOR

=head2 new

 my $peek = Archive::Libarchive::Peek->new(%options);

This creates a new instance of the Peek object.  One of the L</filename> or
L</memory> option

=over 4

=item filename

 my $peek = Archive::Libarchive::Peek->new( filename => $filename );

The filename of the archive to read from.

=item memory

[version 0.03]

 my $peek = Archive::Libarchive::Peek->new( memory => \$content );

A reference to the memory region containing the archive.  Passing in a plain
scalar will throw an exception.

=item passphrase

 my $peek = Archive::Libarchive::Peek->new( passphrase => $passphrase );
 my $peek = Archive::Libarchive::Peek->new( passphrase => sub {
   ...
   return $passphrase;
 });

This option is the passphrase for encrypted zip entries, or a
callback which will return the passphrase.

=back

=head1 PROPERTIES

=head2 filename

This is the archive filename for the Peek object.  This will be C<undef> for in-memory archives.

=head1 METHODS

=head2 files

 my @files = $peek->files;

This method returns the filenames of the entries in the archive.

=head2 file

 my $content = $peek->file($filename);

This method files the filename in the archive and returns its content.

=head2 iterate

 $peek->iterate(sub ($filename, $content, $e) {
   ...
 });

This method iterates over the entries in the archive and calls the callback for each
entry.  The arguments are:

=over 4

=item filename

The filename of the entry

=item content

The content of the entry, or C<''> for non-regular or zero-sized files

=item entry

This is a L<Archive::Libarchive::Entry> instance which has metadata about the
file, like the permissions, timestamps and file type.

=back

=head2 as_hash

[version 0.02]

 my $hashref = $peek->as_hash;

Returns a hash reference where the keys are entry pathnames and the values are the
entry content.  This method will attempt to resolve symbolic links as scalar references.
Hardlinks will be reference aliased.  Directory and other special types will be handled
as array reference, the exact format to be determined in the future, although the first
element in the array reference will be the file type.

=head1 SEE ALSO

=over 4

=item L<Archive::Peek>

The original!

=item L<Archive::Peek::External>

Another implementation that uses external commands to peek into archives

=item L<Archive::Peek::Libarchive>

Another implementation that also relies on C<libarchive>, but doesn't support
the file type in iterate mode, encrypted zip entries, or multi-file RAR archives.

=item L<Archive::Libarchive>

A lower-level interface to C<libarchive> which can be used to read/extract and create
archives of various formats.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
