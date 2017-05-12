package DBIx::Class::DynamicSubclass;
use base qw/DBIx::Class/;
use strict;
use warnings;

our $VERSION = 0.03;

__PACKAGE__->mk_group_accessors(inherited => qw/_typecast_map typecast_column/);

=head1 NAME

DBIx::Class::DynamicSubclass - Convenient way to use dynamic subclassing.

=head1 SYNOPSIS

    package My::Schema::Game;

    __PACKAGE__->load_components(qw/DynamicSubclass Core/);
    __PACKAGE__->add_column(qw/id name data type/);

    __PACKAGE__->typecast_map(type => {
        1 => 'My::Schema::Game::Online',
        2 => 'My::Schema::Game::Shareware',
        3 => 'My::Schema::Game::PDA',
    });

    $game = $schema->resultset('Game')->new({..., type => 1});
    #  ref $game = 'My::Schema::Game::Online'

    @games = $game->search({type => 2});
    # @games are all of class My::Schema::Game::Shareware

    $game->type(3); # game is now of class My::Schema::Game::PDA

    $game =  $schema->resultset('Game')->new({});
    # or
    $game->type(undef);
    # game is now of type My::Schema::Game


    #Dynamic properties with DBIx::Class::FrozenColumns
    package My::Schema::Game;
    __PACKAGE__->load_components(qw/... FrozenColumns .../);

    package My::Schema::Game::Online;
    use base 'My::Schema::Game';
    __PACKAGE__->add_frozen_columns(data => qw/flash server_host server_port/);

    package My::Schema::Game::Shareware;
    use base 'My::Schema::Game';
    __PACKAGE__->add_frozen_columns(data => qw/price download_url/);

    ...

    $game->type(1); #game would have now additional columns 'flash', 'server_host', etc.
    $game->server_host('...'); #(stored in 'data')

    $game->type(2);
    $game->server_host; #error
    $game->price('$3.00'); #ok

    $game = $rs->new({
        type  => 1,
        flash => 'game.swf',
    }); #ok

    #More flexible way

    package My::Schema::Game;
    __PACKAGE__->typecast_column('type');

    sub classify { #called each time the object gets or losses its 'type'
        my $self = shift;
        #decide which class do you want
        bless $self, $class;
    }

=head1 DESCRIPTION

This plugin implements methodics described here
L<DBIx::Class::Manual::Cookbook/Dynamic_Sub-classing_DBIx::Class_proxy_classes_(AKA_multi-class_object_inflation_from_one_table)>.

DynamicSubclass has 2 ways to work: static defining and dynamic defining.

Static defining is used in most cases. This is when you define

    __PACKAGE__->typecast_map(defining_column => {column_value => 'subclass', ...});

The plugin preloads all of the subclasses and changes the class of the row object
when you are creating new object or fetching it from a database or changing
'defining_column' value.
If the value is not exists in the 'typecast_map' then object is blessed into
the base class and losses all of its additional methods/columns/etc.

Dynamic defining is when you only say

    __PACKAGE__->typecast_column('defining_column');

and define a method 'classify' that would bless a row object into proper class.
This method is called when object is created, fetched or have its
'defining_column' value changed.

=head1 METHODS

=head2 typecast_map

Arguments: $column, %typecast_hash

%typecast_hash is a hash with keys equal to possible $column values and with
subclasses as values.

=head2 classify

A standart method for static subclassing. You should redefine this method in your
result source in order to use dynamic subclassing (second way).

=head1 OVERLOADED METHODS

new, inflate_result, store_column

=head1 SEE ALSO

L<DBIx::Class>, L<DBIx::Class::FrozenColumns>.

=head1 AUTHOR

Pronin Oleg <syber@cpan.org>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

sub typecast_map {
    my ($this, $column, $map) = @_;
    $this->throw_exception("cannot find column '$column'")
        unless $this->has_column($column);
    $this->throw_exception("typecast map must be a hash reference")
        unless $map && ref $map && ref $map eq 'HASH';
    $this->ensure_class_loaded($_) for values %$map;
    $this->_typecast_map($map);
    $this->typecast_column($column);
}

sub inflate_result {
    my $self = shift;
    my $ret = $self->next::method(@_);
    $ret->classify;
    return $ret;
}

sub new {
    my $this = shift;
    my $data = shift;

    my $deferred;
    if ($this->can('add_frozen_columns')) {
        my $real_columns = $this->result_source_instance->_columns;
        map {
            $deferred->{$_} = delete $data->{$_}
                unless index($_, '-') == 0 or exists $real_columns->{$_};
        } keys %$data;
    }

    my $ret = $this->next::method($data, @_);
    $ret->classify;

    if ($deferred) {
        $ret->set_columns($deferred);
    }

    return $ret;
}

sub classify {
    my $self = shift;
    my $col = $self->typecast_column or $self->throw_exception(
        'Neither typecast_map defined nor "classify" method redefined in your result source'
    );

    my $val = $self->get_column($col);
    $val = '' unless defined $val;
    if (my $target_class = $self->_typecast_map->{$val}) {
        bless $self, $target_class;
    }
    else {
        bless $self, $self->result_source->result_class;
    }

    return $self;
}

sub store_column {
    my ($self, $column, $value) = @_;
    my $tc_col;
    if ($tc_col = $self->typecast_column and $tc_col eq $column) {
        my $ret = $self->next::method($column, $value);
        $self->classify;
        return $ret;
    }

    $self->next::method($column, $value);
}

1;
