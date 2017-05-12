package Archive::Heritrix;

use 5.008005;
use strict;
use warnings;
use Compress::Zlib;
use File::Find;
use HTTP::Response;

our $VERSION = 0.02;

sub new {
  my ( $class, %arg ) = @_;
  my $self = bless {}, $class;

  if ( $arg{ 'file' } && $arg{ 'directory' } ) {
    die "file or directory, not both";
  }

  my @files = ();

  if ( $arg{ 'file' } ) {
    if ( ! -f $arg{ 'file' } ) {
      die "no such file";
    }
    @files = ( $arg{ 'file' } );
  }
  if ( $arg{ 'directory' } ) {
    if ( ! -d $arg{ 'directory' } ) {
      die "no such directory";
    }
    find( sub { push @files, $File::Find::name if $File::Find::name =~ /\.arc\.gz$/ },  $arg{ 'directory' } );
  }

  $self->{ 'files' } = \@files;
  $self->next_file();
  return $self;
}

sub next_file {
  my $self = shift;
  my $f = shift @{ $self->{ 'files' } };
  if ( ! $f ) {
    $self->{ '_fh' } = undef;
    return undef;
  }
  my $gz = gzopen( $f, 'rb' );
  return undef unless $gz;
  $self->{ '_fh' } = $gz;
}

sub next_record {
  my $self = shift;
  my $fh = $self->_fh();

  if ( ! $fh ) {
    if ( $self->next_file() ) {
      $fh = $self->_fh();
    }
    else {
      return undef;
    }
  }

  my $head;
  $fh->gzreadline( $head );
  chomp $head;
  my ($url,$ip,$stamp,$type,$length) = $head =~ m/^(.+?) ([\d\.]+) (\d+) (\S+) (\d+)$/;
  if ( ! $url ) {
    $self->next_file();
    $fh = $self->_fh();
    return undef unless $fh;
    $fh->gzreadline( $head );
    chomp $head;
    ($url,$ip,$stamp,$type,$length) = $head =~ m/^(.+?) ([\d\.]+) (\d+) (\S+) (\d+)$/;
  }
  return undef unless $url;

  my $buf = undef;
  my $read = 0;
  my $l0 = undef;
  while ( $read <= $length ) {
    my $bbuf;
    $fh->gzreadline( $bbuf );
    $l0 ||= $bbuf;
    my $got = length( $bbuf );
    $buf .= $bbuf;
    $read += $got;
  }
  my ( $code, $msg ) = $l0 =~ m#(\d{3})\s+(.+?)[\r\n]*$#;
  my $res = HTTP::Response->parse( $buf );
  $res->{'_headers'}->content_length($length);
  $res->{'_headers'}->referer($url);
  $res->code( $code );
  $res->message( $msg );

  return $res;
}

sub _fh {
  return shift->{ '_fh' };
}

1;
__END__
=head1 NAME

Archive::Heritrix - Perl extension for processing Heritrix archive (.arc) files

=head1 SYNOPSIS

  use Archive::Heritrix;
  my $arc;

  #open a single .arc.gz archive
  $arc = Archive::Heritrix->new( file => 'a.arc.gz' );
  while ( my $rec = $arc->next_record() ) {
    #it's a HTTP::Response object
  }

  #open a directory of .arc.gz archives.  matches recursively on file extension
  $arc = Archive::Heritrix->new( directory => 'eg' );
  while ( my $rec = $arc->next_record() ) {
    #it's a HTTP::Response object
  }

=head1 DESCRIPTION

Process Heritrix archive (arc) files as a stream of HTTP::Response objects.

Heritrix is the archival-grade crawler used by the Internet Archive.

=head1 SEE ALSO

  Heritrix project homepage, http://crawler.archive.org

=head1 AUTHOR

Allen Day, E<lt>allenday@ucla.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Allen Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
