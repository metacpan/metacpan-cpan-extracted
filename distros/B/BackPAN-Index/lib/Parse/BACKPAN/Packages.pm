package Parse::BACKPAN::Packages;

use strict;
use warnings;

our $VERSION = '0.40';

use Mouse;
use BackPAN::Index::Types;

has no_cache =>
  is		=> 'ro',
  isa		=> 'Bool',
  default 	=> 0;

has only_authors =>
  is		=> 'ro',
  isa		=> 'Bool',
  default	=> 1
;

has _delegate =>
  is	=> 'rw',
  isa	=> 'BackPAN::Index';


sub BUILD {
    my $self = shift;
    my $args = shift;

    # Translate from PBP options to BackPAN::Index
    if( exists $args->{no_cache} ) {
	$args->{update} = $args->{no_cache};
    }

    if( exists $args->{only_authors} ) {
	$args->{releases_only_from_authors} = $args->{only_authors};
    }

    require BackPAN::Index;
    $self->_delegate( BackPAN::Index->new($args) );

    return $self;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my($method) = $AUTOLOAD =~ /:: ([^:]+) $/x;

    # Skip things like DESTROY
    return if uc $method eq $method;

    $self->_delegate->$method(@_);
}

sub files {
    my $self = shift;

    my %files;
    my $rs = $self->_delegate->files;
    while( my $file = $rs->next ) {
        $files{$file->path} = $file;
    }
    
    return \%files;
}

sub file {
    my ( $self, $path ) = @_;

    return $self->_delegate->files->single({ path => $path });
}

sub releases {
    my($self, $dist) = @_;

    return $self->_delegate->releases($dist)->all;
}


sub distributions {
    my $self = shift;

    # For backwards compatibilty when releases() was distributions()
    return $self->releases(shift) if @_;

    return [$self->_delegate->distributions->get_column("name")->all];
}

sub distributions_by {
    my ( $self, $author ) = @_;
    return unless $author;

    my $dists = $self->db->dbh->selectcol_arrayref(q[
             SELECT DISTINCT dist
             FROM   releases
             WHERE  cpanid = ?
             ORDER BY dist
        ],
        undef,
        $author
    );

    return @$dists;
}

sub authors {
    my $self     = shift;

    my $authors = $self->db->dbh->selectcol_arrayref(q[
        SELECT DISTINCT cpanid
        FROM     releases
        ORDER BY cpanid
    ]);

    return @$authors;
}

sub size {
    my $self = shift;

    my $size = $self->db->dbh->selectcol_arrayref(q[
        SELECT SUM(size) FROM files
    ]);

    return $size->[0];
}

1;

__END__

=head1 NAME

Parse::BACKPAN::Packages - Provide an index of BACKPAN

=head1 SYNOPSIS

  use Parse::BACKPAN::Packages;
  my $p = Parse::BACKPAN::Packages->new();
  print "BACKPAN is " . $p->size . " bytes\n";

  my @filenames = keys %$p->files;

  # see Parse::BACKPAN::Packages::File
  my $file = $p->file("authors/id/L/LB/LBROCARD/Acme-Colour-0.16.tar.gz");
  print "That's " . $file->size . " bytes\n";

  # see Parse::BACKPAN::Packages::Release
  my @acme_colours = $p->releases("Acme-Colour");
  
  my @authors = $p->authors;
  my @acmes = $p->distributions_by('LBROCARD');

=head1 DESCRIPTION

Parse::BackPAN::Packages has been B<DEPRECATED>.  Please use the
faster and more flexible L<BackPAN::Index>.

The Comprehensive Perl Archive Network (CPAN) is a very useful
collection of Perl code. However, in order to keep CPAN relatively
small, authors of modules can delete older versions of modules to only
let CPAN have the latest version of a module. BACKPAN is where these
deleted modules are backed up. It's more like a full CPAN mirror, only
without the deletions. This module provides an index of BACKPAN and
some handy functions.

The data is fetched from the net and cached for an hour.

=head1 METHODS

=head2 new

The constructor downloads a ~1M index file from the web and parses it,
so it might take a while to run:

  my $p = Parse::BACKPAN::Packages->new();

By default it caches the file locally for one hour. If you do not
want this caching then you can pass in:

  my $p = Parse::BACKPAN::Packages->new( { no_cache => 1 } );

=head2 authors

The authors method returns a list of all the authors. This is meant so
that you can pass them into the distributions_by method:

  my @authors = $p->authors;

=head2 distributions

  my $distributions = $p->distributions;

The distributions method returns an array ref of the names of all the
distributions in BackPAN.

=head2 releases

The releases method returns a list of objects representing all
the different releases of a distribution:

  # see Parse::BACKPAN::Packages::Release
  my @acme_colours = $p->releases("Acme-Colour");

=head2 distributions_by

The distributions_by method returns a list of distribution names
representing all the distributions that an author has uploaded:

  my @acmes = $p->distributions_by('LBROCARD');

=head2 file

The file method finds metadata relating to a file:

  # see Parse::BACKPAN::Packages::File
  my $file = $p->file("authors/id/L/LB/LBROCARD/Acme-Colour-0.16.tar.gz");
  print "That's " . $file->size . " bytes\n";

=head2 files

The files method returns a hash reference where the keys are the
filenames of the files on CPAN and the values are
Parse::BACKPAN::Packages::File objects:

  my @filenames = keys %$p->files;

=head2 size

The size method returns the sum of all the file sizes in BACKPAN:

  print "BACKPAN is " . $p->size . " bytes\n";

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2005-9, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<BackPAN::Index>, L<CPAN::DistInfoname>
