package Datahub::Factory::Fixer::Fix;

use Datahub::Factory::Sane;

use Moo;
use Catmandu;
use namespace::clean;

has file_name => (is => 'ro', required => 1);

with 'Datahub::Factory::Fixer';

# Make role; implement -> fixer (must work the same as CM::Fixer)

sub _build_fixer {
    my $self = shift;
    my $fixer = Catmandu->fixer($self->file_name);
    return $fixer;
}

1;