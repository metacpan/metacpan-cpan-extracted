package Archive::Peek::External;
use Moose;
use Archive::Peek::External::Tar;
use Archive::Peek::External::Zip;
use MooseX::Types::Path::Class qw( File );
our $VERSION = '0.35';

has 'filename' => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
);

sub BUILD {
    my $self     = shift;
    my $filename = $self->filename;
    my $basename = $filename->basename;
    if ( $basename =~ /\.zip$/i ) {
        bless $self, 'Archive::Peek::External::Zip';
    } elsif ( $basename =~ /(\.tar|\.tar\.gz|\.tgz|\.bz2|\.bzip2)$/i ) {
        bless $self, 'Archive::Peek::External::Tar';
    } else {
        confess("Failed to open $filename");
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Archive::Peek::External - Peek into archives without extracting them (using external tools)

=head1 SYNOPSIS

  use Archive::Peek::External;
  my $peek = Archive::Peek::External->new( filename => 'archive.tgz' );
  my @files = $peek->files();
  my $contents = $peek->file('README.txt')
  
=head1 DESCRIPTION

This module lets you peek into archives without extracting them.
It currently supports tar files and zip files using external tools
such as 'tar' and 'unzip'.

=head1 METHODS

=head2 new

The constructor takes the filename of the archive to peek into:

  my $peek = Archive::Peek::External->new( filename => 'archive.tgz' );

=head2 files

Returns the files in the archive:

  my @files = $peek->files();

=head2 file

Returns the contents of a file in the archive:

  my $contents = $peek->file('README.txt')

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2011, Leon Brocard.

=head1 LICENSE

This module is free software; you can redistribute it or 
modify it under the same terms as Perl itself.
