package AudioFile::Find;

use warnings;
use strict;

use File::Find::Rule;
use AudioFile::Info;
use List::MoreUtils qw( zip );
use YAML 'LoadFile';

=head1 NAME

AudioFile::Find - Finds audio files located on your system and maps them to L<AudioFile::Info> objects. 

=cut

our $VERSION = '0.03';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  use AudioFile::Find;

  my $finder = AudioFile::Find->new( 'some/dir' );
    
  # find everything
  my @audiofiles = $finder->search();
  
  # specify a search directory
  my @audiofiles = $finder->search( 'some/other/dir' );
  
  #same for genre, title, track, artist and album
  my @audiofiles = $finder->search( artist => 'Seeed' ); 
  
  #search using a regex
  my @audiofiles = $finder->search( 'some/other/dir', title => qr/Ding/ ); 
  
  # anonymous subroutine that returns true or false
  my @audiofiles = $finder->search( 'some/other/dir', track => sub { return shift > 10; } ); 

=head1 METHODS

=head2 new

Creates an object of this class. Takes an optional single argument which is the directory to search in.

=cut

sub new {
  my ($class, $dir) = @_;
  return bless { dir => $dir }, $class;
}

=head2 new

Sets and returns the directory to search.

=cut

sub dir {
  my ($self, $dir) = @_;
  $self->{dir} = $dir if defined $dir;
  return $self->{dir};
}

=head2 search 

Starts the search and returns a hash of filenames as keys and AudioFile::Info-Objects as values.
You may specify a search directory as the first argument 
and also pass a hash with search criteria. See the synopsis for details.

=cut

sub search {
  my $self = shift;
  my $dir  = @_ % 2 == 0 ? '' : shift;
  my $args = {@_};
  my %audio;
      
  my @patterns = map { "*.$_" } $self->extensions;
  for ( File::Find::Rule->file()->name( @patterns )->in( $dir || $self->dir || '.' ) )
  {
    my $info = AudioFile::Info->new($_);
    
    $audio{$_} = $info
      if $self->pass( $info, $args);
  }
  
  return %audio;
}

=head2 pass

Checks whether a given L<AudioFile::Info> object meets given criteria.
First argument is the L<AudioFile::Info> object, second argument is a reference to the criteria hash.

=cut

sub pass
{
  my ($self, $file, $criteria) = @_;
  
  while ( my ($key, $criterium) = each %$criteria ) 
  {
    my $value = $file->$key;
    
    if ( ref($criterium) eq "Regexp" )
    {
      return unless $value =~ $criterium;
    }
    elsif ( ref($criterium) eq "CODE" )
    {
      return unless $criterium->( $value );
    }
    else
    {
      return unless $value eq $criterium;
    }
  }
  
  return 1;
}

=head2 extensions

Discovers the extensions that are supported by the installed L<AudioFile::Info> plugins.

=cut

sub extensions {
  my ($self) = @_;
  my $path = $INC{'AudioFile/Info.pm'};
  $path =~ s/Info.pm$/plugins.yaml/;
  my $config = eval { LoadFile($path) } or return;
  my @ext = keys %{ $config->{default} };
  return @ext;
}

1;

=head1 AUTHORS

=over 

=item Markus, C<< <holli.holzer at googlemail.com> >>

=item Joel Berger C<joel.a.berger@gmail.com>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/AudioFile-Find>

=head1 BUGS

Bugs may be reported to:

=over

=item L<http://github.com/jberger/AudioFile-Find/issues>

=item L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AudioFile-Find>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008-2014 by Authors listed above, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

