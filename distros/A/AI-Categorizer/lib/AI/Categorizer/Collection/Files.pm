package AI::Categorizer::Collection::Files;
use strict;

use AI::Categorizer::Collection;
use base qw(AI::Categorizer::Collection);

use Params::Validate qw(:types);
use File::Spec;

__PACKAGE__->valid_params
  (
   path => { type => SCALAR|ARRAYREF },
   recurse => { type => BOOLEAN, default => 0 },
  );

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  
  $self->{dir_fh} = do {local *FH; *FH};  # double *FH avoids a warning

  # Documents are contained in a directory, or list of directories
  $self->{path} = [$self->{path}] unless ref $self->{path};
  $self->{used} = [];

  $self->_next_path;
  return $self;
}

sub _next_path {
  my $self = shift;
  closedir $self->{dir_fh} if $self->{cur_dir};

  $self->{cur_dir} = shift @{$self->{path}};
  push @{$self->{used}}, $self->{cur_dir};
  opendir $self->{dir_fh}, $self->{cur_dir} or die "$self->{cur_dir}: $!";
}

sub next {
  my $self = shift;
  my $file = $self->_read_file;
  return unless defined $file;
  
  warn "No category information about '$file'" unless defined $self->{category_hash}{$file};
  my @cats = map AI::Categorizer::Category->by_name(name => $_), @{ $self->{category_hash}{$file} || [] };

  return $self->call_method('document', 'read', 
			    path => File::Spec->catfile($self->{cur_dir}, $file),
			    name => $file,
			    categories => \@cats,
			   );
}

sub _read_file {
  my ($self) = @_;
  
  my $file = readdir $self->{dir_fh};

  if (!defined $file) { # Directory has been exhausted
    return undef unless @{$self->{path}};
    $self->_next_path;
    return $self->_read_file;
  } elsif ($file eq '.' or $file eq '..') {
    return $self->_read_file;
  } elsif (-d (my $path = File::Spec->catdir($self->{cur_dir}, $file))) {
    push @{$self->{path}}, $path  # Add for later processing
      if $self->{recurse} and !grep {$_ eq $path} @{$self->{path}}, @{$self->{used}};
    return $self->_read_file;
  }
  return $file;
}

sub rewind {
  my $self = shift;
  push @{$self->{path}}, @{$self->{used}};
  @{$self->{used}} = ();
  $self->_next_path;
}

# This should share an iterator with next()
sub count_documents {
    my $self = shift;
    return $self->{document_count} if defined $self->{document_count};
    
    $self->rewind;
    
    my $count = 0;
    $count++ while defined $self->_read_file;

    $self->rewind;
    return $self->{document_count} = $count;
}

1;
__END__

=head1 NAME

AI::Categorizer::Collection::Files - One document per file

=head1 SYNOPSIS

  my $c = new AI::Categorizer::Collection::Files
    (path => '/tmp/docs/training',
     category_file => '/tmp/docs/cats.txt');
  print "Total number of docs: ", $c->count_documents, "\n";
  while (my $document = $c->next) {
    ...
  }
  $c->rewind; # For further operations
  
=head1 DESCRIPTION

This implements a Collection class in which each document exists as a
single file on a filesystem.  The documents can exist in a single
directory, or in several directories.

=head1 METHODS

This is a subclass of the abstract AI::Categorizer::Collection class,
so any methods mentioned in its documentation are available here.

=over 4

=item new()

Creates a new Collection object and returns it.  In addition to the
parameters accepted by the superclass, the following parameters are
accepted:

=over 4

=item path

Indicates a location on disk where the documents can be found.  The
path may be specified as a string giving the name of a directory, or
as a reference to an array of such strings if the documents are
located in more than one directory.

=item recurse

Indicates whether subdirectories of the directory (or directories) in
the C<path> parameter should be descended into.  If set to a true
value, they will be descended into.  If false, they will be ignored.
The default is false.

=back

=back

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 COPYRIGHT

Copyright 2002-2003 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

AI::Categorizer::Collection(3)

=cut
