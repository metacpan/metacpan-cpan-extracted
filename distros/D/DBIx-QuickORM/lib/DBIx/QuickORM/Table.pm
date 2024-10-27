package DBIx::QuickORM::Table;
use strict;
use warnings;

our $VERSION = '0.000002';

use Carp qw/croak confess/;
use Storable qw/dclone/;
use Sub::Util qw/set_subname/;
use Scalar::Util qw/blessed/;
use List::Util qw/max/;
use Role::Tiny::With qw/with/;

use DBIx::QuickORM::Util qw/mod2file merge_hash_of_objs mesh_accessors/;

use DBIx::QuickORM::Util::HashBase qw{
    <name
    <columns
    <relations
    <indexes
    <unique
    <primary_key
    <is_view
    <is_temp
    +row_class
    <accessors
    +sql_spec

    +deps
    <created
};

with 'DBIx::QuickORM::Role::HasSQLSpec';

sub sqla_columns { [$_[0]->column_names] }

sub sqla_source  { $_[0]->{+NAME} }

sub init {
    my $self = shift;

    croak "The 'name' attribute is required" unless $self->{+NAME};

    my $cols = $self->{+COLUMNS} or croak "The 'columns' attribute is required";
    croak "The 'columns' attribute must be a hashref" unless ref($cols) eq 'HASH';
    croak "The 'columns' hash may not be empty" unless keys %$cols;

    for my $cname (sort keys %$cols) {
        my $cval = $cols->{$cname} or croak "Column '$cname' is empty";
        croak "Columns '$cname' is not an instance of 'DBIx::QuickORM::Table::Column', got: '$cval'" unless blessed($cval) && $cval->isa('DBIx::QuickORM::Table::Column');
    }

    $self->{+RELATIONS} //= {};
    $self->{+INDEXES}   //= {};

    $self->{+IS_VIEW} //= 0;
    $self->{+IS_TEMP} //= 0;
}

sub row_class { shift->{+ROW_CLASS} // undef };

sub prefetch_relations {
    my $self = shift;
    my ($add) = @_;

    if ($add) {
        my $todo = ref($add) ? $add : [$add];
        $add = {};
        for my $name (@$todo) {
            $add->{$name} = $self->{+RELATIONS}->{$name} or croak "Relation '$name' does not exist, cannot prefetch";
        }
    }

    my $tname = $self->{+NAME};

    my @prefetch;
    for my $alias (keys %{$self->{+RELATIONS}}) {
        my $relation = $self->{+RELATIONS}->{$alias};
        next unless $relation->prefetch || ($add && $add->{$alias});
        push @prefetch => [$alias => $relation];
    }

    return \@prefetch;
}

sub add_relation {
    my $self = shift;
    my ($name, $relation) = @_;

    if (my $ex = $self->{+RELATIONS}->{$name}) {
        return if $ex->compare($relation);
        croak "Relation '$name' already defined";
    }

    croak "'$relation' is not an instance of 'DBIx::QuickORM::Table::Relation'" unless $relation->isa('DBIx::QuickORM::Table::Relation');

    $self->{+RELATIONS}->{$name} = $relation;
}

sub relation {
    my $self = shift;
    my ($name) = @_;

    return $self->{+RELATIONS}->{$name} // undef;
}

sub deps {
    my $self = shift;
    return $self->{+DEPS} //= { map {( $_->table() => 1 )} grep { $_->gets_one } values %{$self->{+RELATIONS} // {}} };
}

sub column_names { keys %{$_[0]->{+COLUMNS}} }

sub column {
    my $self = shift;
    my ($cname, $row) = @_;

    return $self->{+COLUMNS}->{$cname} // undef;
}

sub merge {
    my $self = shift;
    my ($other, %params) = @_;

    $params{+SQL_SPEC}    //= $self->{+SQL_SPEC}->merge($other->{+SQL_SPEC});
    $params{+COLUMNS}     //= merge_hash_of_objs($self->{+COLUMNS}, $other->{+COLUMNS});
    $params{+UNIQUE}      //= {map { ($_ => [@{$self->{+UNIQUE}->{$_}}]) } keys %{$self->{+UNIQUE}}};
    $params{+RELATIONS}   //= {%{$other->{+RELATIONS}}, %{$self->{+RELATIONS}}};
    $params{+INDEXES}     //= {%{$other->{+INDEXES}},   %{$self->{+INDEXES}}};
    $params{+PRIMARY_KEY} //= [@{$self->{+PRIMARY_KEY} // $other->{+PRIMARY_KEY}}] if $self->{+PRIMARY_KEY} || $other->{+PRIMARY_KEY};
    $params{+ACCESSORS}   //= mesh_accessors($other->{+ACCESSORS}, $self->{+ACCESSORS});
    $params{+ROW_CLASS}   //= $self->{+ROW_CLASS};
    $params{+DEPS}        //= undef;

    if (my $name_cb = $params{name_cb}) {
        my @args = (table => $self->{+NAME}, merge => [$self, $other], params => \%params);
        $name_cb->(@args);

        my $rels = $params{+RELATIONS};

        for my $rname (sort keys %$rels) {
            my $rel = $rels->{$rname};
            my $new_name = $name_cb->(@args, relation => $rel, relations => $rels, name => $rname);

            if (!$new_name) { # Removing
                delete $rels->{$rname};
            }
            elsif ($new_name ne $rname) {
                if ($rels->{$new_name} && !$rel->compare($rels->{$new_name}, ON_DELETE => 0)) {
                    my $len = max(length($rname), length($new_name)) + 1;
                    croak "Attempt to rename relation '$rname' to '$new_name' failed as there is already a relation named '$new_name' with different parameters:\n"
                        . sprintf("  %-${len}s %s\n", "$rname:", $rel->display(ON_DELETE => 0))
                        . sprintf("  %-${len}s %s\n", "$new_name:", $rels->{$new_name}->display(ON_DELETE => 0));

                    # Nothing to do, new and existing relations match
                }
                else {
                    $rels->{$new_name} = delete $rels->{$rname};
                }

            }
            # No change to name
        }
    }

    my $new = ref($self)->new(%$self, %params);
}

sub clone {
    my $self   = shift;
    my %params = @_;

    $params{+SQL_SPEC}    //= $self->{+SQL_SPEC}->clone();
    $params{+RELATIONS}   //= {%{$self->{+RELATIONS}}};
    $params{+INDEXES}     //= {%{$self->{+INDEXES}}};
    $params{+PRIMARY_KEY} //= [@{$self->{+PRIMARY_KEY}}] if $self->{+PRIMARY_KEY};
    $params{+COLUMNS}     //= {map { ($_ => $self->{+COLUMNS}->{$_}->clone) } keys %{$self->{+COLUMNS}}};
    $params{+UNIQUE}      //= {map { ($_ => [@{$self->{+UNIQUE}->{$_}}]) } keys %{$self->{+UNIQUE}}};
    $params{+ACCESSORS}   //= mesh_accessors($self->{+ACCESSORS});
    $params{+ROW_CLASS}   //= $self->{+ROW_CLASS};

    my $new = ref($self)->new(%$self, %params);
}

sub generate_accessors {
    my $self = shift;
    my ($pkg) = @_;

    my $acc = $self->{+ACCESSORS};

    my $include   = $acc->{include}   // {};
    my $exclude   = $acc->{exclude}   // {};
    my $name_cbs  = $acc->{name_cbs}  // [];
    my $relations = $acc->{RELATIONS} // 1;
    my $columns   = $acc->{COLUMNS}   // 1;
    my $none      = $acc->{NONE}      // 0;
    my $all       = $acc->{ALL}       // $none ? 0 : 1;

    confess "Specified :ALL and :NONE, these are mutually exclusive" if $all && $none;

    my %seen;
    my $keep = sub {
        my ($name, %cb_args) = @_;

        $seen{$name}++;

        # Include list always wins
        unless ($cb_args{include_name} = $include->{$name}) {
            # Default to no if none was specified
            return if $none && !$include->{$name};

            # Skip if it is on the exclude list
            return if $exclude->{$name};
        }

        $cb_args{package}       = $pkg // $acc->{inject_into};
        $cb_args{original_name} = $name;
        $cb_args{exclude}       = $exclude;
        $cb_args{include}       = $exclude;

        for my $cb (@$name_cbs) {
            my $out = $cb->(%cb_args) or next;
            return $out;
        }

        return $include->{$name} // $name;
    };

    my %out;

    if ($columns) {
        my $cols = $self->{+COLUMNS} // {};
        for my $cname (keys %$cols) {
            my $col = $cols->{$cname};
            my $kname = $keep->($cname, column => $col) or next;

            for my $prefix ('', 'raw_', 'dirty_', 'stored_', 'inflated_') {
                my $as = $prefix ? $keep->("${prefix}${kname}", column => $col, prefix => $prefix, root_name => $kname) : "${prefix}${kname}";
                next unless $as;

                confess "Cannot add column accessor '$as' for column '$cname', accessor is already defined for $out{$as}->{debug}" if $out{$as};

                my $meth = "${prefix}column";

                my $rn = $cname;
                $out{$as} = {column => $col, column_name => $cname, orig_name => "${prefix}${cname}", debug => "column '$cname'", sub => sub { shift->$meth($cname, @_) }};
            }
        }
    }

    if ($relations) {
        my $rels = $self->{+RELATIONS} // {};
        for my $rname (keys %$rels) {
            my $rel = $rels->{$rname};
            my $as = $keep->($rname, relation => $rel) or next;

            confess "Cannot add relation accessor '$as' for relation '$rname', accessor is already defined for $out{$as}->{debug}" if $out{$as};

            my $meth = $rel->gets_one ? 'relation' : 'relations';

            my $rn = $rname;
            $out{$as} = {relation => $rel, orig_name => $rname, debug => "relation '$rname'", sub => sub { shift->$meth($rn, @_) }};
        }
    }

    if (my @bad = grep { !$seen{$_} } keys %$include) {
        confess "No relation or column for requested accessors: " . join(', ' => @bad);
    }

    return \%out;
}

1;
