package BioX::Workflow::Command::run::Utils::Files::TrackChanges;

use MooseX::App::Role;
use namespace::autoclean;

use Data::Walk 2.01;
use File::Details;
use File::stat;
use Time::localtime;
use File::Basename;
use DateTime::Format::Strptime;

=head3 files

Container for list of files just for this rule

=cut

has 'files' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        has_files  => 'count',
        all_files  => 'elements',
        push_files => 'push',
        sort_files => 'sort_in_place',
        uniq_files => 'uniq',
    },
    clearer => 'clear_files',
);

sub walk_FILES {
    my $self = shift;
    my $attr = shift;

    $self->pre_FILES( $attr, 'INPUT' );
    $self->add_graph('INPUT');
    $self->clear_files;
    $self->files( [] );

    $self->pre_FILES( $attr, 'OUTPUT' );
    $self->add_graph('OUTPUT');
    $self->clear_files;
    $self->files( [] );
}

sub pre_FILES {
    my $self = shift;
    my $attr = shift;
    my $cond = shift;

    walk {
        wanted => sub { $self->walk_INPUT(@_) }
      },
      $attr->$cond;

    $self->uniq_files;
    $self->sort_files;
}

=head3 walk_INPUT

walk the INPUT/OUTPUT and catch all Path::Tiny references

=cut

sub walk_INPUT {
    my $self = shift;
    my $ref  = shift;

    return unless $ref;

    my $ref_name = ref($ref);
    return unless $ref_name;
    return unless $ref_name eq 'Path::Tiny';

    my $file = $ref->absolute;
    $file = "$file";
    $self->push_files($file);
}

1;
