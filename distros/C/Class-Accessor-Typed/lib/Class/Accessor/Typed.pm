package Class::Accessor::Typed;
use 5.008001;
use strict;
use warnings;

use Carp;
use Mouse::Util::TypeConstraints ();

our $VERSION = "0.01";

*_get_isa_type_constraint  = \&Mouse::Util::TypeConstraints::find_or_create_isa_type_constraint;
*_get_does_type_constraint = \&Mouse::Util::TypeConstraints::find_or_create_does_type_constraint;

our $VERBOSE = 1;

my %key_ctor = (
    rw => \&_mk_accessors,
    ro => \&_mk_ro_accessors,
    wo => \&_mk_wo_accessors,
);

sub import {
    my ($class, %args) = @_;
    my $pkg = caller(0);

    my %rules;
    for my $key (sort keys %key_ctor) {
        if (defined $args{$key}) {
            croak("value of the '$key' parameter should be an hashref") unless ref($args{$key}) eq 'HASH';

            for my $n (sort keys %{$args{$key}}) {
                my $rule = ref($args{$key}->{$n}) eq 'HASH'
                    ? $args{$key}->{$n} : { isa => $args{$key}->{$n} };

                $rule->{type} = do {
                    if (defined $rule->{isa}) {
                        _get_isa_type_constraint($rule->{isa});
                    } elsif (defined $rule->{does}) {
                        _get_does_type_constraint($rule->{does});
                    }
                };
                $args{$key}->{$n} = $rule;
                $rules{$n}        = $rule;
            }
            $key_ctor{$key}->($pkg, %{$args{$key}});
        }
    }
    _mk_new($pkg, %rules) if $args{new};
    return 1;
}

sub _mk_new {
    my $pkg = shift;
    no strict 'refs';

    *{$pkg . '::new'} = __m_new($pkg, @_);
}

sub _mk_accessors {
    my $pkg = shift;
    no strict 'refs';

    while (@_) {
        my $n = shift;
        my $rule = shift;
        *{$pkg . '::' . $n} = __m($n, $rule->{type});
    }
}

sub _mk_rw_accessors {
    my $pkg = shift;
    no strict 'refs';

    while (@_) {
        my $n = shift;
        my $rule = shift;
        *{$pkg . '::' . $n} = __m($pkg, $n, $rule->{type});
    }
}

sub _mk_ro_accessors {
    my $pkg = shift;
    no strict 'refs';

    while (@_) {
        my $n = shift;
        my $rule = shift;
        *{$pkg . '::' . $n} = __m_ro($pkg, $n);
    }
}

sub _mk_wo_accessors {
    my $pkg = shift;
    no strict 'refs';

    while (@_) {
        my $n = shift;
        my $rule = shift;
        *{$pkg . '::' . $n} = __m_wo($pkg, $n, $rule->{type});
    }
}


sub __m_new {
    my $pkg = shift;
    my %rules = @_;
    no strict 'refs';
    return sub {
        my $klass = shift;
        my %args = (@_ == 1 && ref($_[0]) eq 'HASH' ? %{$_[0]} : @_);
        my %params;

        for my $n (sort keys %rules) {
            if (! exists $args{$n}) {
                if ($rules{$n}->{default}) {
                    $args{$n} = $rules{$n}->{default};
                } else {
                    error("missing mandatory parameter named '\$$n'");
                }
            }
            $params{$n} = _check($n, $rules{$n}->{type}, $args{$n});
        }

        if (keys %args > keys %rules) {
            my $message = 'unknown arguments: ' . join ', ', sort grep { not exists $rules{$_} } keys %args;
            warnings::warn( void => $message );
        }
        bless \%params, $klass;
    };
}

sub __m {
    my ($n, $type) = @_;

    sub {
        return $_[0]->{$n} if @_ == 1;
        return $_[0]->{$n} = _check($n, $type, $_[1]) if @_ == 2;
    };
}

sub __m_ro {
    my ($pkg, $n) = @_;

    sub {
        return $_[0]->{$n} if @_ == 1;
        my $caller = caller(0);
        error("'$caller' cannot access the value of '$n' on objects of class '$pkg'");
    };
}

sub __m_wo {
    my ($pkg, $n, $type) = @_;

    sub {
        return $_[0]->{$n} = _check($n, $type, $_[1]) if @_ == 2;
        my $caller = caller(0);
        error("'$caller' cannot alter the value of '$n' on objects of class '$pkg'");
    };
}

sub _check {
    my $n = shift;
    my $type = shift;
    my $value = shift;

    return $value unless defined $type;
    return $value if $type->check($value);
    if ($type->has_coercion) {
        $value = $type->coerce($value);
        return $value if $type->check($value);
    }

    error("'$n': " . $type->get_message($value));
}

sub error {
    my $message = shift;

    if ($VERBOSE) {
        confess($message);
    } else {
        croak($message);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Class::Accessor::Typed - Class::Accessor::Lite with Type

=head1 SYNOPSIS

    package Synopsis;

    use Class::Accessor::Typed (
        rw => {
            baz => { isa => 'Str', default => 'string' },
        },
        ro => {
            foo => 'Str',
            bar => 'Int',
        },
        wo => {
            hoge => 'Int',
        },
        new => 1,
    );

=head1 DESCRIPTION

Class::Accessor::Typed is variant of C<Class::Accessor::Lite>. It supports argument validation like C<Smart::Args>.

=head1 THE USE STATEMENT

The use statement of the module takes a single hash.
An arguments specifies the read/write type (rw, ro, wo) and setting of properties.
Setting of property is defined by hash reference that specifies property name as key and property rule as value.

    use Class::Accessor::Typed (
        rw => { # read/write type
            baz => 'Int', # property name => property rule
        },
    );

=over 4

=item new => $true_of_false

If value evaluates to true, the default constructor is created.

=item rw => \%name_and_option_of_the_properties

create a read / write accessor.

=item ro => \%name_and_option_of_the_properties

create a read-only accessor.

=item wo => \%name_and_option_of_the_properties

create a write-only accessor.

=back

=head2 PROPERTY RULE

Property rule can receive string of type name (e.g. C<Int>) or hash reference (with C<isa>/C<does> and C<default>).

=head1 SEE ALSO

L<Class::Accessor::Lite>

L<Smart::Args>

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=cut

