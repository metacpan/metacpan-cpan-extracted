package Config::From::Backend::DBIx;
$Config::From::Backend::DBIx::VERSION = '0.06';

use utf8;
use Moose;
extends 'Config::From::Backend';

use Carp qw/croak/;

has 'schema'     => (
                     is        => 'rw',
                     predicate => 'has_schema',
                    );

has 'table' => (
                is       => 'rw',
                isa      => 'Str',
               );

has datas => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);


sub _build_datas {
    my $self = shift;

    my $config = {};
    my @roots = $self->schema->resultset($self->table)->search({parent_id => 0 })->all;
    foreach my $root ( @roots ) {
        my $config_root = {};
        $config->{$root->name} = $self->_build_config_node($root, $config_root);
    }

    return $config;
}


sub _build_config_node {
    my $self = shift;
    my $node = shift;
    my $config = shift;

    my @children = $self->schema->resultset($self->table)->search({ parent_id => $node->id});

    if ( ! $children[0] ) {
        return $node->value;
    }
    foreach my $child ( @children ) {
        my $conf_child = {};
        $config->{$child->name} = $self->_build_config_node($child, $conf_child);
    }
    return $config;
}

=head1 NAME

Config::From::Backend::DBIx -  DBIx Backend for Config::From


=head1 VERSION

version 0.06

=head1 SYNOPSIS

    my $bckdbix = Config::From::Backend::DBIx->new(schema => $schema, table => 'Config');

    my $config = $bckdbix->datas

=head1 SUBROUTINES/METHODS



=head1 AUTHOR

Daniel Brosseau, C<< <dab at catapulse.org> >>

=cut

1; # End of Config::From::Backend::File
