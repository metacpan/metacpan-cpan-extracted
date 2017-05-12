package Catalyst::Model::File;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';


use MRO::Compat;
use Carp;
use MooseX::Types::Path::Class qw/ Dir /;
use MooseX::Types::Moose qw/ Str /;
use IO::Dir;
use Path::Class ();
use IO::File;

our $VERSION = '0.10';

=head1 NAME

Catalyst::Model::File - File based storage model for Catalyst.

=head1 SYNOPSIS

# use the helper to create a model
    myapp_create.pl model File File

# configure in lib/MyApp.pm

    MyApp->config(
        name          => 'MyApp',
        root          => MyApp->path_to('root'),
        'Model::File' => {
            root_dir => MyApp->path_to('file_store')
        },
    );

Simple file based storage model for Catalyst.

  @file_names = $c->model('File')->list;

=head1 METHODS

=cut

has root_dir => (
    isa => Dir,
    is => 'ro',
    coerce => 1,
    required => 1,
);

has _dir => (
    isa => Dir,
    is => 'rw',
    lazy => 1,
    default => sub { shift()->root_dir },
    clearer => '_clear_dir',
);

has dir_create_mask => (
    isa => Str,
    is => 'ro',
    default => '0775',
);

has _directory => (
    isa => Dir,
    is => 'rw',
    default => sub { Path::Class::dir('/') },
);

sub BUILD {
    my $self = shift;
    mkdir($self->root_dir, oct($self->dir_create_mask));
}

sub build_per_context_instance {
  my ($self, $c) = @_;

  $self->cd('/');

  return $self;
}

=head2 list

Returns a list of files (and/or directories) found under the current working 
dir. Default will return files (including those found under sub-directories)
but not directories.

To change this behaviour specify a C<mode> param of C<files> (default), 
C<dirs> or C<both>:

 $mdl->list(mode => 'both')

To only get files/dirs directly under the current dir specify a C<recurse>
option of 0.

Please note: the exact order in which files and directories are listed will
change from OS to OS.

=cut

sub list {
    my ($self, %opt) = @_;
    my @files;
    $opt{mode} ||= 'files';
    $opt{recurse} = 1 unless exists $opt{recurse};

    $opt{dir}  = 1 if $opt{mode} =~ /^both|dirs$/;
    $opt{file} = 1 if $opt{mode} =~ /^both|files$/;

    if ($opt{recurse}) {
        $self->_dir->recurse(callback => sub {
            my ($entry) = @_;
            push @files, $entry
                if !$entry->is_dir && $opt{file} 
                || $entry->is_dir && $opt{dir};
        });
        return map { $self->_rebless($_) } @files;
    }

    @files = map { $self->_rebless($_) } $self->_dir->children;

    return @files if $opt{dir} && $opt{file};

    return $opt{dir} ?
      grep { $_->is_dir } @files :
      grep { !$_->is_dir } @files;

}

sub _rebless {
  my ($self, $entity) = @_;

  $entity = $entity->absolute($self->root_dir);
  if ($entity->is_dir) {
    bless $entity, 'Catalyst::Model::File::Dir';
  }
  else {
    bless $entity, 'Catalyst::Model::File::File';
  }

  $entity->{stringify_as} = $entity->relative($self->_dir)->as_foreign('Unix')->stringify;
  return $entity;
}

=head2 change_dir

=head2 cd

Set current working directory (relative to current) and return $self.

=cut

sub cd { shift->change_dir(@_) }


sub change_dir {
    my $self = shift;

    my $dir = shift;

    return $self unless defined $dir;

    $dir = Path::Class::dir($dir, @_) unless ref $dir;

    my @dir_list = ();
    $self->_directory(Path::Class::dir(''));

    if ($dir->is_absolute) {
        $self->_clear_dir;
        @dir_list = $dir->dir_list(1);
    } else {
        $dir = $self->_dir->subdir($dir);
        $self->_clear_dir;
        return $self unless ($self->root_dir->subsumes($dir) );

        @dir_list = $dir->relative($self->{root_dir})->dir_list;
    }

#    $self->_directory($self->_directory->subdir(@dir_list));
    foreach my $subdir (@dir_list) {
        $self->_dir($self->_dir->subdir($subdir)) unless $subdir eq '..';
        $self->_dir($self->_dir->parent) if $subdir eq '..';
    }

    $self->_directory($self->_dir->relative($self->root_dir)->absolute('/'));

    return $self;
}

=head2 directory

=head2 pwd

Get the current working directory, from which all relative paths are based.

=cut

sub pwd { shift->directory(@_) }

sub directory {
    return shift->_directory->as_foreign('Unix');
}

=head2 parent

Move up to the parent of the working directory. Returns $self.

=cut

sub parent {
    my ($self) = @_;

    $self->_dir($self->_dir->parent);

    unless ($self->root_dir->subsumes($self->_dir)) {
        $self->_clear_dir;
        return $self;
    }

    $self->_directory($self->_dir->relative($self->root_dir)->absolute('/'));

    return $self;
}

=head2 $self->file($file)

Returns an L<Path::Class::File> object of $file (which can be a string or a
Class::Path::File object,) or undef if the file is an invalid path - i.e.
outside the directory structure specified in the config.

=cut

sub file {
    my ($self, $file) = @_;

    return unless $file;

    $file = (ref $file ? $file : Path::Class::file($file) )->absolute($self->_dir);

    return undef unless $self->root_dir->subsumes($file);

    # Make sure the dir tree exists
    $file->dir->mkpath(0, oct($self->dir_create_mask));
    return $file;

}

=head2 $self->slurp($file)

Shortcut to $self->file($file)->slurp.

In a scalar context, returns the contents of $file in a string.  In a list
context, returns the lines of $file (according to how $/ is set) as a list.  If
the file can't be read, this method will throw an exception.

If you want "chomp()" run on each line of the file, pass a true value for the
"chomp" or "chomped" parameters:

 my @lines = $self->slurp($file, chomp => 1);


=cut

sub slurp {
    my $file = shift->file(shift) or return wantarray ? () : undef;

    return $file->stat ? $file->slurp(@_) : wantarray ? () : undef;
}

=head2 $self->splat($file, PRINT_ARGS)

Does a print to C<$file> with the specified C<PRINT_ARGS>. Does the same as
C<$self->file->openw->print(@_)>

=cut

sub splat {
    my $file = shift->file(shift) or return;

    $file->openw->print(@_);
}

__PACKAGE__->meta->make_immutable;

package #
   Catalyst::Model::File::File;
use base 'Path::Class::File';
sub stringify {
  return $_[0]->{stringify_as} || $_[0]->abs_stringify;
}

sub abs_stringify {
  Path::Class::File::stringify(shift)
}

# All these would probably be better done with Moose or something, but i'm lazy
sub open {
  my $s = shift;
  local $s->{stringify_as};
  return $s->SUPER::open(@_);
}

sub touch {
  my $s = shift;
  local $s->{stringify_as};
  return $s->SUPER::touch(@_);
}

sub remove {
  my $s = shift;
  local $s->{stringify_as};
  return $s->SUPER::touch(@_);
}

sub stat {
  my $s = shift;
  local $s->{stringify_as};
  return $s->SUPER::stat(@_);
}
sub lstat {
  my $s = shift;
  local $s->{stringify_as};
  return $s->SUPER::lstat(@_);
}

@Catalyst::Model::File::Dir::ISA = 'Path::Class::Dir';
sub Catalyst::Model::File::Dir::stringify {
  return $_[0]->{stringify_as}
      || Path::Class::Dir::stringify($_[0]);
}

=head1 AUTHOR

Ash Berlin, C<ash@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

