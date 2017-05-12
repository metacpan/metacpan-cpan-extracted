package DBIx::Class::FromSledge;
use strict;
use warnings;
use base 'DBIx::Class';
use Carp::Clan qw/^DBIx::Class/;

our $VERSION = '0.03';

sub create_from_sledge {
    my ($self, $model, $page, $args) = @_;
    croak "error detected at validator" if $page->valid->is_error;

    my $cols = $args || {};
    my $rs = $self->resultset($model);

    for my $col ($rs->result_source->columns) {
        unless ($cols->{$col}) {
            if ($page->valid->{PLAN}->{$col}) {
                $cols->{$col} = &_get_val($page, $col);
            } elsif ($page->valid->{PLAN}->{"$col\_year"}) {
                if ($page->r->param("$col\_year")) {
                    $cols->{$col} =  sprintf '%d-%02d-%02d', map {$page->r->param("$col\_$_")} qw(year month day);

                    if ($page->valid->{PLAN}->{"$col\_hour"}) {
                        $cols->{$col} = $cols->{$col} . " " . sprintf '%02d:%02d:%02d', map {$page->r->param("$col\_$_")} qw(hour minute second);
                    }
                } else {
                    $cols->{$col} = undef;
                }
            }
        }
    }

    return $rs->create($cols);
}

sub update_from_sledge {
    my ($self, $page, $args) = @_;
    croak "error detected at validator" if $page->valid->is_error;

    for my $col ($self->result_source->columns) {
        if ($page->valid->{PLAN}->{$col}) {
            $self->$col(&_get_val($page, $col));
        } elsif ($page->valid->{PLAN}->{"$col\_year"}) {
            if ($page->r->param("$col\_year")) {
                my $ymd = sprintf '%d-%02d-%02d', map {$page->r->param("$col\_$_") || 0} qw(year month day);

                if ($page->r->param("$col\_hour")) {
                    $self->$col($ymd . " " . sprintf '%02d:%02d:%02d', map {$page->r->param("$col\_$_")} qw(hour minute second));
                } else {
                    $self->$col($ymd);
                }
            } else {
                $self->$col(undef);
            }
        }
    }

    while (my ($col, $val) = each %{$args}) {
        $self->$col($val);
    }

    $self->update;
    return 1;
}

sub _get_val {
    my ($page, $col) = @_;

    my @val = $page->r->param($col);
    if (@val==1) {
        return $val[0] ne '' ? $val[0] : undef; # scalar
    } else {
        return join ',', @val; # array
    }
}

1;
__END__

=head1 NAME

DBIx::Class::FromSledge - Update or Insert DBIx::Class data using from Sledge

=head1 SYNOPSIS

    package Test::DB;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->load_components(qw/
        FromSledge
    /);
    
    package Test::DB::User;
    use base 'DBIx::Class';
    __PACKAGE__->load_components(qw/
        FromSledge
        PK::Auto
        Core
    /);
    
    package Test::Pages::Root;
    use base 'Test::Pages';
    sub valid_create {
        shift->valid->check( ... );
    }
    sub dispatch_create {
        my $self = shift;
        $self->model->create_from_sledge('User',$self,
            {
                service_id => $self->service->id,
            }
        );
    }

=head1 DESCRIPTION

Update or Insert DBIx::Class objects from Sledge::Plugin::Validator.

=head1 METHODS

=head2 create_from_sledge

call DBIC's create method.

=head2 update_from_sledge

call DBIC's update method.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Atsushi Kobayashi  C<< <atsushi __at__ mobilefactory.jp> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Atsushi Kobayashi C<< <atsushi __at__ mobilefactory.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

