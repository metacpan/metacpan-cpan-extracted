package DBIx::Class::InflateColumn::FS;

use strict;
use warnings;
use DBIx::Class::UUIDColumns;
use File::Spec ();
use File::Path ();
use File::Copy ();
use Path::Class ();

our $VERSION = '0.01007';

=head1 NAME

DBIx::Class::InflateColumn::FS - Inflate/deflate columns to Path::Class::File objects

=head1 SYNOPSIS

  __PACKAGE__->load_components(qw/InflateColumn::FS Core/);
  __PACKAGE__->add_columns(
      id => {
          data_type         => 'INT',
          is_auto_increment => 1,
      },
      file => {
          data_type => 'TEXT',
          is_fs_column => 1,
          fs_column_path => '/var/lib/myapp/myfiles',
      },
      file_2 => {
          data_type => 'TEXT',
          is_fs_column => 1,
          fs_column_path => '/var/lib/myapp/myfiles',
          fs_new_on_update => 1
      },
  );
  __PACKAGE__->set_primary_key('id');

  # in application code
  $rs->create({ file => $file_handle });

  $row = $rs->find({ id => $id });
  my $fh = $row->file->open('r');

=head1 DESCRIPTION

Provides inflation to a Path::Class::File object allowing file system storage
of BLOBS.

The storage path is specified with C<fs_column_path>.  Each file receives a
unique name, so the storage for all FS columns can share the same path.

Within the path specified by C<fs_column_path>, files are stored in
sub-directories based on the first 2 characters of the unique file names.  Up to
256 sub-directories will be created, as needed.  Override C<_fs_column_dirs> in
a derived class to change this behavior.

C<fs_new_on_update> will create a new file name if the file has been updated.

=cut

=head1 METHODS

=cut

=head2 inflate_result

=cut

sub inflate_result {
    my ($class, $source, $me, $prefetch) = @_;

    my $new = $class->next::method($source, $me, $prefetch);
    
    while ( my($column, $data) = each %{$new->{_column_data}} ) {
        if ( $source->has_column($column) && $source->column_info($column)->{is_fs_column} && defined $data ) {
            $new->{_fs_column_filename}{$column} = $data;
        }
    }
    
    return $new;
}


=head2 register_column

=cut

sub register_column {
    my ($self, $column, $info, @rest) = @_;
    $self->next::method($column, $info, @rest);
    return unless defined($info->{is_fs_column});

    $self->inflate_column($column => {
        inflate => sub { 
            my ($value, $obj) = @_;
            $obj->_inflate_fs_column($column, $value);
        },
        deflate => sub {
            my ($value, $obj) = @_;
            $obj->_deflate_fs_column($column, $value);
        },
    });
}

=head2 fs_file_name

Provides the file naming algorithm.  Override this method to change it.

This method is called with two parameters: The name of the column and the
C<< column_info >> object.

=cut

sub fs_file_name {
    my ($self, $column, $column_info) = @_;
    return DBIx::Class::UUIDColumns->get_uuid;
}

sub _fs_column_storage {
    my ( $self, $column ) = @_;

    my $column_info = $self->result_source->column_info($column);
    $self->throw_exception("$column is not an fs_column")
        unless $column_info->{is_fs_column};

    $self->{_fs_column_filename}{$column} ||= do {
        my $filename = $self->fs_file_name($column, $column_info);
        File::Spec->catfile($self->_fs_column_dirs($filename), $filename);
    };

    return Path::Class::File->new($column_info->{fs_column_path}, $self->{_fs_column_filename}{$column});
}

=head2 _fs_column_dirs

Returns the sub-directory components for a given file name.  Override it to
provide a deeper directory tree or change the algorithm.

=cut

sub _fs_column_dirs {
    shift;
    my $filename = shift;

    return $filename =~ /(..)/;
}

=head2 copy

Copies a row object, duplicating the files backing fs columns.

=cut

sub copy {
    my ($self, $changes) = @_;

    $changes ||= {};
    my $col_data     = { %{$self->{_column_data}} };

    foreach my $col ( keys %$col_data ) {
        my $column_info = $self->result_source->column_info($col);
        if ( $column_info->{is_fs_column} && defined $col_data->{$col} ) {  # nothing special required for NULLs
            delete $col_data->{$col};
            
            # pass the original file to produce a copy on deflate
            $changes->{$col} = $self->get_inflated_column($col);
        }
    }

    my $temp = bless { _column_data => $col_data }, ref $self;
    $temp->result_source($self->result_source);

    return $temp->next::method($changes);
}

=head2 delete

Deletes the associated file system storage when a row is deleted.

=cut

sub delete {
    my ( $self, @rest ) = @_;

    for my $column ( $self->columns ) {
        my $column_info = $self->result_source->column_info($column);
        if ( $column_info->{is_fs_column} ) {
            my $accessor = $column_info->{accessor} || $column;
            $self->$accessor && $self->$accessor->remove;
        }
    }

    return $self->next::method(@rest);
}

=head2 set_column

Deletes file storage when an fs_column is set to undef.

=cut

sub set_column {
    my ($self, $column, $new_value) = @_;

    if ( !defined $new_value && $self->result_source->column_info($column)->{is_fs_column}
            && $self->{_fs_column_filename}{$column} ) {
        $self->_fs_column_storage($column)->remove;
        delete $self->{_fs_column_filename}{$column};
    }

    return $self->next::method($column, $new_value);
}

=head2 set_inflated_column

Re-inflates after setting an fs_column.

=cut

sub set_inflated_column {
    my ($self, $column, $inflated) = @_;

    $self->next::method($column, $inflated);

    # reinflate
    if ( defined $inflated && ref $inflated && ref $inflated ne 'SCALAR'
            && $self->result_source->column_info($column)->{is_fs_column} ) {
        $inflated = $self->{_inflated_column}{$column} = $self->_fs_column_storage($column);
    }
    return $inflated;
}

=head2 _inflate_fs_column

Inflates a file column to a Path::Class::File object.

=cut

sub _inflate_fs_column {
    my ( $self, $column, $value ) = @_;
    return unless defined $value;

    $self->{_fs_column_filename}{$column} = $value;
    return $self->_fs_column_storage($column);
}

=head2 _deflate_fs_column

Deflates a file column to its storage path name, relative to C<fs_column_path>.
In the database, a file column is just a place holder for inflation/deflation.
The actual file lives in the file system.

=cut

sub _deflate_fs_column {
    my ( $self, $column, $value ) = @_;

    my $column_info = $self->result_source->column_info($column);

    # kill the old storage, rather than overwrite, if fs_new_on_update
    if ( $column_info->{fs_new_on_update} && $self->{_fs_column_filename}{$column} ) {
        my $oldfile = $self->_fs_column_storage($column);
        if ( $oldfile ne $value ) {
            $oldfile->remove;
            delete $self->{_fs_column_filename}{$column};
        }
    }
    
    my $file = $self->_fs_column_storage($column);
    if ( $value ne $file ) {
        File::Path::mkpath([$file->dir]);

        # get a filehandle if we were passed a Path::Class::File
        my $fh1 = eval { $value->openr } || $value;
        my $fh2 = $file->openw or die;
        File::Copy::copy($fh1, $fh2);

        $self->{_inflated_column}{$column} = $file;

        # ensure the column will be marked dirty
        $self->{_column_data}{$column} = undef;
    }
    return $self->{_fs_column_filename}{$column};
}

sub DESTROY {
    my $self = shift;

    return if $self->in_storage;

    # If fs columns were deflated, but the row was never stored, we need to delete the
    # backing files.
    while ( my ( $col, $data ) = each %{ $self->{_column_data} } ) {
        my $column_info = $self->result_source->column_info($col);
        if ( $column_info->{is_fs_column} && defined $data ) {
            my $accessor = $column_info->{accessor} || $col;
            $self->$accessor->remove;
        }
    }
}

=head2 table

Overridden to provide a hook for specifying the resultset_class.  If
you provide your own resultset_class, inherit from
InflateColumn::FS::ResultSet.

=cut

sub table {
    my $self = shift;

    my $ret = $self->next::method(@_);
    if ( @_ && $self->result_source_instance->resultset_class
               eq 'DBIx::Class::ResultSet' ) {
        $self->result_source_instance
             ->resultset_class('DBIx::Class::InflateColumn::FS::ResultSet');
    }
    return $ret;
}

=head1 SUPPORT

Community support can be found via:

  Mailing list: http://lists.scsys.co.uk/mailman/listinfo/dbix-class/

  IRC: irc.perl.org#dbix-class

The author is C<semifor> on IRC and a member of the mailing list.

=head1 AUTHOR

semifor: Marc Mims <marc@questright.com>

=head1 CONTRIBUTORS

mst: Matt S. Trout <mst@shadowcatsystems.co.uk>

mo: Moritz Onken <onken@netcubed.de>

norbi: Norbert Buchmuller <norbi@nix.hu>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
