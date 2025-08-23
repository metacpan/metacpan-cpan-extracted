package DBIx::QuickORM::Schema::Autofill;
use strict;
use warnings;

our $VERSION = '0.000019';

use List::Util qw/first/;
use DBIx::QuickORM::Util qw/load_class/;

use DBIx::QuickORM::Util::HashBase qw{
    <types
    <affinities
    <hooks
    <autorow
    +skip
};

my %HOOKS = (
    column         => 1,
    columns        => 1,
    index          => 1,
    indexes        => 1,
    links          => 1,
    post_column    => 1,
    post_table     => 1,
    pre_column     => 1,
    pre_table      => 1,
    primary_key    => 1,
    table          => 1,
    unique_keys    => 1,
    link_accessor  => 1,
    field_accessor => 1,
);

sub is_valid_hook { $HOOKS{$_[-1]} ? 1 : 0 }

sub hook {
    my $self = shift;
    my ($hook, $args, $seed) = @_;
    my $out = $seed;
    $out = $_->(%$args, autofill => $self) for @{$self->{+HOOKS}->{$hook} // []};
    return $out;
}

sub skip {
    my $self = shift;

    my $from = $self->{+SKIP};
    while(my $arg = shift @_) {
        $from = $from->{$arg} or return 0;
    }
    return $from;
}

sub process_column {
    my $self = shift;
    my ($col) = @_;

    my $type = $col->{type};
    my $tref = ref($type);
    return unless $tref && $tref eq 'SCALAR';

    my $new_type;
    $new_type = $self->{+TYPES}->{$$type} // $self->{+TYPES}->{uc($$type)} // $self->{+TYPES}->{lc($$type)};

    unless ($new_type) {
        if (my $aff = $col->{affinity}) {
            if (my $list = $self->{+AFFINITIES}->{$aff}) {
                for my $cb (@$list) {
                    $new_type = $cb->(%$col) and last;
                }
            }
        }
    }

    return unless $new_type;

    $col->{type} = $new_type;
    $col->{affinity} = $new_type->qorm_affinity(sql_type => $$type);
}

sub define_autorow {
    my $self = shift;
    my ($row_class, $table) = @_;

    unless(load_class($row_class)) {
        my $err = $@;
        die $@ unless $@ =~ m/Can't locate.*in \@INC/;
        my $row_file = $row_class;
        $row_file =~ s{::}{/}g;
        $row_file .= ".pm";
        $INC{$row_file} = __FILE__;
    }

    for my $column ($table->columns) {
        my $field = $column->name;
        my $accessor = $self->hook(field_accessor => {table => $table, name => $field, field => $field, column => $column}, $field);
        next unless $accessor;

        no strict 'refs';
        next if defined &{"$row_class\::$accessor"};
        *{"$row_class\::$accessor"} = sub { shift->field($field, @_) };
    }

    for my $link (@{$table->links}) {
        my $to = $link->other_table;
        my $aliases = $link->aliases;

        unless ($aliases && @$aliases) {
            $aliases = [$link->unique ? $to : "${to}s" ];
        }

        for my $alias (@$aliases) {
            my $accessor = $self->hook(link_accessor => {table => $table, linked_table => $link->other_table, name => $alias, link => $link}, $alias);
            next unless $accessor;
            no strict 'refs';
            next if defined &{"$row_class\::$accessor"};
            *{"$row_class\::$accessor"} = $link->unique ? sub { shift->obtain($link) } : sub { shift->follow($link) };
        }
    }
}

1;

__END__


