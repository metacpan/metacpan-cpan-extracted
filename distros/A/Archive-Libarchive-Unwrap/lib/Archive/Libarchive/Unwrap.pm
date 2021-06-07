package Archive::Libarchive::Unwrap;

use strict;
use warnings;
use Archive::Libarchive qw( ARCHIVE_OK ARCHIVE_WARN ARCHIVE_EOF );
use Ref::Util qw( is_ref );
use 5.020;
use Carp ();
use experimental qw( signatures );

# ABSTRACT: Unwrap files with multiple compression / encoding formats
our $VERSION = '0.01'; # VERSION


sub new ($class, %options)
{
  Carp::croak("Required option: One of filename or memory")
    unless defined $options{filename} || defined $options{memory};

  Carp::croak("Missing or unreadable: $options{filename}")
    if defined $options{filename} && !-r $options{filename};

  my $self = bless {
    filename => delete $options{filename},
    memory   => delete $options{memory},
  }, $class;

  Carp::croak("Illegal options: @{[ sort keys %options ]}")
    if %options;

  return $self;
}


sub unwrap ($self)
{
  my $r = Archive::Libarchive::ArchiveRead->new;
  $r->support_filter_all;
  $r->support_format_raw;
  my $ret;
  if($self->{filename})
  {
    $ret = $r->open_filename($self->{filename});
  }
  elsif($self->{memory})
  {
    $ret = $r->open_memory(is_ref $self->{memory} ? $self->{memory} : \$self->{memory});
  }
  else
  {
    # this shouldn't happen if the constructor
    # is doing its job.
    die "internal error, no filename or memory";
  }

  $self->_diag($r, $ret);
  $ret = $r->next_header(Archive::Libarchive::Entry->new);
  $self->_diag($r, $ret);

  my $output = '';
  my $buffer;
  while(1)
  {
    $ret = $r->read_data(\$buffer);
    last if $ret == 0;
    $self->_diag($r, $ret);
    $output .= $buffer;
  }

  $ret = $r->close;
  $self->_diag($r, $ret);

  return $output;
}

sub _diag ($self, $r, $ret)
{
  if($ret == ARCHIVE_WARN)
  {
    Carp::carp($r->error_string);
  }
  elsif($ret < ARCHIVE_WARN)
  {
    Carp::croak($r->error_string);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::Libarchive::Unwrap - Unwrap files with multiple compression / encoding formats

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Archive::Libarchive::Unwrap;
 
 my $uw = Archive::Libarchive::Unwrap->new( filename => 'hello.txt.uu' );
 print $uw->unwrap;

=head1 DESCRIPTION

This module will unwrap one or more nested filter formats supported by L<Archive::Libarchive>.  The detection
logic for L<Archive::Libarchive> is such that you typically do not need to tell it which formats are a file
is stored using.  The filter formats include traditional compression formats like gzip, bzip2, but also includes
other encodings like uuencode.  The idea of this module is to just point it to a file and it will do its best
to decode it until you get to the inner file.

=head1 CONSTRUCTOR

=head2 new

 my $uw = Archive::Libarchive::Unwrap->new(%options);

This creates a new instance of the Unwrap class.  At least one of the C<filename> and C<memory> options are
required.

=over 4

=item filename

 my $uw = Archive::Libarchive::Unwrap->new( filename => $filename );

This will create an Unwrap instance that will read from the given C<$filename>.

=item memory

 my $uw = Archive::Libarchive::Unwrap->new( memory => $memory );
 my $uw = Archive::Libarchive::Unwrap->new( memory => \$memory );

This will create an Unwrap instance that will read from memory.  You may pass in either a scalar containing
the raw wrapped data, or a scalar reference to the same.

=back

=head1 METHODS

=head2 unwrap

 my $content = $uw->unwrap;

This will return the raw content of the unfiltered file.  This will decompress and/or filter multiple
filters, so if you had a text file that was gzipped and uuencoded C<hello.txt.gz.uu>, this method will
return the content of the inner text file C<hello.txt>.

=head1 SEE ALSO

=over 4

=item L<Archive::Libarchive::Peek>

An interface for peeking into archives without extracting them to the local filesystem.

=item L<Archive::Libarchive::Extract>

An interface for extracting files from an archive.

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
