package Class::Enumemon;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Carp ();
use Guard ();

sub import {
    shift;
    my $pkg = caller;
    my $meta = {};
    my $defs = [];
    while (my $v = shift @_) {
        if (ref $v) {
            push @$defs, $v;
        } else {
            $meta->{$v} = shift @_;
        }
    }

    my $data = _generate_data($pkg, $meta, $defs);
    _mk_values($pkg, $data)         if $meta->{values};
    _mk_getter($pkg, $defs)         if $meta->{getter};
    _mk_indexer($pkg, $meta, $data) if $meta->{indexer};
    _mk_local($pkg, $meta, $data);
}

sub _generate_data {
    my ($pkg, $meta, $defs) = @_;
    my $data = {};

    # values
    $data->{values} = [ map { bless $_, $pkg } @$defs ];

    # indexer
    if ($meta->{indexer}) {
        $data->{indexer} = {};
        for my $indexer (keys %{$meta->{indexer}}) {
            my $field = $meta->{indexer}->{$indexer};
            $data->{indexer}->{$indexer} = +{
                map { ( $_->{$field} => $_ ) } @{$data->{values}}
            }
        }
    }

    return $data;
}

sub _mk_values {
    my ($pkg, $data) = @_;
    no strict 'refs';
    *{"$pkg\::values"} = sub {
        my $values = $data->{values};
        wantarray ? @$values : [ @$values ];
    };
}

sub _mk_indexer {
    my ($pkg, $meta, $data) = @_;
    for my $indexer (keys %{$meta->{indexer}}) {
        my $field = $meta->{indexer}->{$indexer};

        no strict 'refs';
        *{"$pkg\::$indexer"} = sub {
            my ($class, $field_val) = @_;
            return defined $field_val
                ? $data->{indexer}->{$indexer}->{$field_val}
                : undef;
        };
    }
}

sub _mk_getter {
    my ($pkg, $defs) = @_;
    my $all_keys = [ keys %{ +{ map { %$_ } @$defs } }];
    for my $field (@$all_keys) {
        no strict 'refs';
        *{"$pkg\::$field"} = sub { $_[0]->{$field} } ;
    }
}

sub _mk_local {
    my ($pkg, $meta, $data) = @_;
    no strict 'refs';
    *{"$pkg\::local"} = sub {
        my ($class, @defs) = @_;
        Carp::croak("Cannot use $class\::local in void context") unless defined wantarray;

        my %orig_data = %$data;
        my $local_data = _generate_data($pkg, $meta, \@defs);
        %$data = %$local_data;
        return Guard::guard { %$data = %orig_data };
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Class::Enumemon - enum-like class generator

=head1 SYNOPSIS

    package IdolType;
    use Class::Enumemon (
        values => 1,
        getter => 1,
        indexer => {
            by_id     => 'id',
            from_type => 'type',
        },
        {
            id   => 1,
            type => 'cute',
        },
        {
            id   => 2,
            type => 'cool',
        },
        {
            id   => 3,
            type => 'passion',
        },
    );

    1;

    package My::Pkg;
    use IdolType;

    # `values`: defines a method for getting all values
    IdolType->values; #=> [ bless({ id => 1, type => 'cute' }, 'IdolType'), ... ]

    # `indexer`: defines indexer methods to package
    my $cu = IdolType->by_id(1); #=> bless({ id => 1, type => 'cute' }, 'IdolType')
    IdonType->from_type('cool'); #=> bless({ id => 2, type => 'cool' }, 'IdolType')
    IdonType->values->[2];       #=> bless({ id => 3, type => 'passion' }, 'IdolType')

    # `getter`: defines getter methods to instance
    $cu->id;   #=> 1
    $cu->type; #=> 'cute'

    # `local`: makes a guard object for overriding its data lexically
    {
        my $guard = IdolType->local(
            {
                id   => 1,
                type => 'vocal',
            },
            {
                id   => 2,
                type => 'dance',
            },
            {
                id   => 3,
                type => 'visual',
            },
        );

        IdolType->by_id(1)           #=> bless({ id => 1, type => 'vocal' }, 'IdolType')
        IdolType->from_type('dance') #=> bless({ id => 1, type => 'dance' }, 'IdolType')
        IdolType->from_type('cute')  #=> undef
    }

    IdolType->from_type('cute') #=> bless({ id => 1, type => 'cute' }, 'IdolType')

=head1 DESCRIPTION

Class::Enumemon generate enum-like classes with typical methods that are getter for all, indexer, accessor and guard generator.
An instance fetched from package is always same reference with another.

=head1 LICENSE

Copyright (C) pokutuna.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

pokutuna (POKUDA Tunahiko) E<lt>popopopopokutuna@gmail.comE<gt>

nanto_vi (TOYAMA Nao) E<lt>nanto@moon.email.ne.jpE<gt>

mechairoi (TSUJIKAWA Takaya) E<lt>ttsujikawa@gmail.comE<gt>

=head1 SEE ALSO

L<https://github.com/mechairoi/Class-Enum>

=cut
