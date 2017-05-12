package BioX::Workflow::Command::Utils::Files::TrackChanges;

use Moose::Role;
use DBM::Deep;
use File::Spec;

#TODO most of these should be in run

has 'track_files' => (
    is      => 'rw',
    isa     => 'DBM::Deep',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $file = File::Spec->catfile( $self->cache_dir, 'track_files.db' );
        my $db   = DBM::Deep->new($file);
        return $db;
    },
);




1;
