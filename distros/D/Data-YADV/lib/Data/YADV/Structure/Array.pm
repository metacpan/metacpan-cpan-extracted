package Data::YADV::Structure::Array;

use strict;
use warnings;

use base 'Data::YADV::Structure::Base';

sub _get_child_node {
    my ($self, $entry) = @_;

    $self->die(qq(Wrong array index), $entry) unless $entry =~ /^\[(.+)\]$/;
    my $index = $1;

    my $structure = $self->get_structure;
    return undef unless abs($index) < scalar @$structure;

    $self->_build_node($entry, $structure->[$index]);
};

sub get_size { scalar @{$_[0]->get_structure} }

sub each {
    my ($self, $cb) = @_;

    my $size = $self->get_size;
    for (my $i = 0; $i < $size; ++$i) {
        $cb->($self->get_child("[$i]"), $i);
    }
}

1;
