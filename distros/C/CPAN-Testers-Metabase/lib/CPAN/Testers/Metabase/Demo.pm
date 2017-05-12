use strict;
use warnings;
package CPAN::Testers::Metabase::Demo;
# ABSTRACT: Demo Metabase backend
our $VERSION = '1.999002'; # VERSION

use Moose;
use Metabase::Archive::SQLite 1.000;
use Metabase::Index::FlatFile 1.000;
use Metabase::Librarian 1.000;
use Path::Class;
use File::Temp;
use namespace::autoclean;

with 'Metabase::Gateway';

has 'data_directory' => (
  is        => 'ro',
  isa       => 'Str',
  lazy      => 1,
  builder   => '_build_data_directory',
);

# keeps the tempdir alive until process exits
has '_cache' => (
  is        => 'ro',
  isa       => 'HashRef',
  default   => sub { {} },
);

sub _build_data_directory {
  my $self = shift;
  return q{} . ( $self->_cache->{tempdir} = File::Temp->newdir ); # stringify
}

sub _build_fact_classes { return [qw/CPAN::Testers::Report/] }

sub _build_public_librarian { return $_[0]->__build_librarian("public") }

sub _build_private_librarian { return $_[0]->__build_librarian("private") }

sub __build_librarian {
  my ($self, $subspace) = @_;

  my $data_dir = dir( $self->data_directory )->subdir($subspace);
  $data_dir->mkpath or die "coudln't make path to $data_dir";

  my $index = $data_dir->file('index.json');
  $index->touch;

  my $archive = $data_dir->file('archive.sqlite');

  return Metabase::Librarian->new(
    archive => Metabase::Archive::SQLite->new(
      filename => "$archive",
    ),
    index => Metabase::Index::FlatFile->new(
      index_file => "$index",
    ),
  );
}

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

CPAN::Testers::Metabase::Demo - Demo Metabase backend

=head1 VERSION

version 1.999002

=head1 SYNOPSIS

=head2 Direct usage

   use CPAN::Testers::Metabase::Demo;
 
   # defaults to directory on /tmp
   my $mb = CPAN::Testers::Metabase::Demo->new;
 
   $mb->public_librarian->search( %search spec );

=head2 Metabase::Web config

   ---
   Model::Metabase:
     class: CPAN::Testers::Metabase::Demo

=head1 DESCRIPTION

This is a demo Metabase backend that uses SQLite and a flat file in
a temporary directory.

=head1 USAGE

=head2 new

   my $mb = CPAN::Testers::Metabase::AWS->new( 
     data_directory => "/tmp/my-metabase"
   );

Arguments for C<<< new >>>:

=over

=item *

C<<< data_directory >>> -- optional -- directory path to store data files.  Defaults
to a L<File::Temp> temporary directory

=back

=head1 SEE ALSO

=over

=item *

L<CPAN::Testers::Metabase>

=item *

L<Metabase::Gateway>

=item *

L<Metabase::Web>

=back

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__END__

