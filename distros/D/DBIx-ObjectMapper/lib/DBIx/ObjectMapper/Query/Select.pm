package DBIx::ObjectMapper::Query::Select;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use Data::Page;
use base qw(DBIx::ObjectMapper::Query::Base);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->builder( $self->engine->query->select );
    return $self;
}

{
    no strict 'refs';
    my $pkg = __PACKAGE__;
    for my $meth ( qw( column from where join order_by
                       group_by limit offset having
                       add_column add_where add_join
                       add_order_by add_group_by add_having ) ) {
        *{"$pkg\::$meth"} = sub {
            my $self = shift;
            $self->builder->$meth(@_);
            return $self;
        };
    }
};


sub pager {
    my $self = shift;
    my $page = shift || 1;
    confess 'page must be integer.' unless $page =~ /^\d+$/ and $page > 0;

    my $limit = $self->builder->limit->[0] || confess "limit is not set.";
    $self->offset( ( $page - 1 ) * $limit );

    my $pager = Data::Page->new();
    $pager->total_entries( $self->count );
    $pager->entries_per_page( $self->builder->{limit}->[0] || 0 );
    $pager->current_page( $page );
    return $pager;
}

sub execute {
    my $self = shift;
    return $self->engine->select( $self->builder, $self->callback, @_ );
}

sub count {
    my $self = shift;
    my $builder = $self->_count_builder;
    return $self->engine->select_single(
        $builder,
        sub { $_[0] ? $_[0]->[0] : 0 }
    );
}

sub _count_builder {
    my $self = shift;
    my $builder = $self->builder->clone;

    $builder->column({ count => '*' });
    $builder->order_by(undef);
    $builder->group_by(undef);
    $builder->having(undef);
    $builder->limit(0);
    $builder->offset(0);
    return $builder;
}

sub first {
    my $self = shift;
    my $builder = $self->builder->clone;
    $builder->limit(1);
    return $self->engine->select( $builder, $self->callback )->first;
}

1;
