package BioSAILs::Utils::Files::CacheDir;

use Moose::Role;
use namespace::autoclean;

use MooseX::Types::Path::Tiny qw/Path/;
use Cwd qw(getcwd);
use File::Spec;

has 'cache_dir' => (
    is      => 'rw',
    isa     => Path,
    coerce  => 1,
    default => sub {
        return File::Spec->catdir( getcwd(), '.biosails' );
    },
    documentation => 'BioSAILs will cache some information during your runs. '
      . 'Delete with caution! '
);

has 'cache_file' => (
    is       => 'rw',
    required => 0,
    isa      => Path,
    coerce   => 1,
    documentation => 'BioSAILs caches relevant files.',
    trigger => sub {
      my $self  = shift;
      $self->cache_file->touchpath;
    },
);

1;
