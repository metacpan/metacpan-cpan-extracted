package DBIx::CouchLike::Iterator;

use Data::Dumper;
use strict;
use warnings;
use base qw/ Class::Accessor::Fast /;
__PACKAGE__->mk_accessors(qw/ couch sth query reduce /);

my $Sub = {};

sub _next {
    my $self  = shift;
    my $couch = $self->{couch};

    my $r = $self->{sth}->fetchrow_arrayref;
    return unless $r;

    my $res = {
        id    => $r->[0],
        key   => $r->[1],
        value => ( $r->[2] =~ /^[{\[]/ )
                 ? $couch->from_json($r->[2])
                 : $r->[2],
    };
    if ( $self->{query}->{include_docs} ) {
        $res->{document} = $couch->from_json($r->[3]);
        $res->{document}->{_id} = $r->[0];
    }
    delete $res->{key} unless defined $res->{key};

    return $res;
}

sub next {
    my $self = shift;
    return $self->{reduce} ? $self->_next_reduce()
                           : $self->_next();
}

sub all {
    my $self = shift;
    my @res;
    if ( $self->{reduce} ) {
        push @res, $_ while $_ = $self->_next_reduce();
    }
    else {
        push @res, $_ while $_ = $self->_next();
    }
    return @res;
}

sub _next_reduce {
    my $self    = shift;
    my $sub_str = $self->{reduce};

    return if $self->{_exit};

    my $sub = ( $Sub->{$sub_str} ||= eval $sub_str );  ## no critic
    if ($@) {
        carp $@;
        return;
    }

    my $keys    = $self->{_pre_key}   || [];
    my $values  = $self->{_pre_value} || [];
    my $pre_key = $self->{_pre_key} ? $self->{_pre_key}->[0]->[0] : undef;
    while ( my $r = $self->_next ) {
        $pre_key = $r->{key} unless defined $pre_key;
        if ( $r->{key} eq $pre_key ) {
            # key が同じうちは貯めていく
            push @$keys,   [ $r->{key}, $r->{id} ];
            push @$values, $r->{value};
            $pre_key = $r->{key};
            next;
        }
        # key が変わったら貯めていた分を return
        $self->{_pre_key}   = [ [ $r->{key}, $r->{id} ] ];
        $self->{_pre_value} = [ $r->{value} ];
        return $self->_do_reduce( $sub, $keys, $values );
    }

    $self->{_exit} = 1;
    return unless defined $keys->[0];

    # 最後の
    return $self->_do_reduce( $sub, $keys, $values );
}

sub _do_reduce {
    my $self   = shift;
    my ( $sub, $keys, $values ) = @_;
    return {
        key   => $keys->[0]->[0],
        value => eval { $sub->( $keys, $values ) },
    };
}

sub DESTROY {
    my $self = shift;
    $self->{sth}->finish() if $self->{sth};
}

1;

