package Bio::Grid::Run::SGE::Index::RunOnce;

use Mouse;

use warnings;
use strict;

use POSIX qw/ceil/;

our $VERSION = '0.060'; # VERSION

has idx_file  => ( is => 'rw', required => 0 );

with 'Bio::Grid::Run::SGE::Role::Indexable';

sub get_elem { return 1; }

sub type { return 'direct'; }

sub create { return $_[0]; }

sub num_elem { return 1; } 

sub close { return $_[0]}

__PACKAGE__->meta->make_immutable;
1;

__END__
