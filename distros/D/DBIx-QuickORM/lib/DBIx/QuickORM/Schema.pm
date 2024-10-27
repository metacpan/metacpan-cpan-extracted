package DBIx::QuickORM::Schema;
use strict;
use warnings;

our $VERSION = '0.000002';

use Carp qw/confess croak/;
use Scalar::Util qw/blessed/;

use DBIx::QuickORM::GlobalLookup;

use DBIx::QuickORM::Util qw/merge_hash_of_objs mod2file/;

use DBIx::QuickORM::Util::HashBase qw{
    <name
    +tables
    <locator
    <accessor_name_cb
    <created
};

sub init {
    my $self = shift;

    delete $self->{+NAME} unless defined $self->{+NAME};

    $self->{+LOCATOR} = DBIx::QuickORM::GlobalLookup->register($self);
}

my $GEN_ID = 1;
sub compile {
    my $self = shift;

    my $gen_id = $GEN_ID++;
    my $tables = $self->{+TABLES};

    for my $tname (keys %$tables) {
        my $table = $tables->{$tname};

        my $rels = $table->relations;
        for my $alias (keys %$rels) {
            my $rel = $rels->{$alias};
            my $t2 = $rel->table;
            next if $self->{+TABLES}->{$t2};

            confess "Relation '$alias' in table '$tname' points to table '$t2' but that table does not exist";
        }

        my $acc = $table->accessors or next;
        my $pkg = $acc->{inject_into} // $self->_gen_row_package($table->row_class, $gen_id, $self->{+NAME}, $tname);

        my ($meta);

        {
            no strict 'refs';
            if (defined(&{"$pkg\::_quickorm_compile_meta"})) {
                $meta = $pkg->_quickorm_compile_meta;
            }
            else {
                $meta = {};
                *{"$pkg\::_quickorm_compile_meta"} = sub { $meta };
            }
        }

        my $inj = $meta->{injected_accessors} //= {};

        my $accessors = $table->generate_accessors($pkg);
        for my $name (keys %$accessors) {
            my $spec = $accessors->{$name};

            if ($pkg->can($name)) {
                my $i = $inj->{$name};
                croak "Accessor '$name' for $spec->{debug} would override existing sub" unless $i;
                croak "Accessor '$name' was originally injected for $i->debug, attempt to override it for $spec->{debug}" unless $i->{debug} eq $spec->{debug};
            }

            $inj->{$name} = $spec;

            no strict 'refs';
            no warnings 'redefine';
            *{"$pkg\::$name"} = $spec->{sub};
        }

        $tables->{$tname} = $table->clone(row_class => $pkg) unless $pkg eq $table->row_class;
    }

    return $self;
}

sub _gen_row_package {
    my $self = shift;
    my ($parent, $gen_id, @names) = @_;

    $parent //= 'DBIx::QuickORM::Row';
    require(mod2file($parent));

    my $pkg = join '::' => (
        'DBIx::QuickORM::Row',
        "__GEN${gen_id}__",
        @names,
    );

    my $file = mod2file($pkg);
    $INC{$file} = __FILE__;

    {
        no strict 'refs';
        no warnings 'once';
        push @{"$pkg\::ISA"} => $parent;
    }

    return $pkg;
}

sub tables       { values %{$_[0]->{+TABLES}} }
sub table        { $_[0]->{+TABLES}->{$_[1]} or croak "Table '$_[1]' is not defined" }
sub maybe_table  { return $_[0]->{+TABLES}->{$_[1]} // undef }

sub add_table {
    my $self = shift;
    my ($name, $table) = @_;

    croak "Table '$name' already defined" if $self->{+TABLES}->{$name};

    return $self->{+TABLES}->{$name} = $table;
}

sub merge {
    my $self = shift;
    my ($other, %params) = @_;

    $params{+TABLES}  //= merge_hash_of_objs($self->{+TABLES}, $other->{+TABLES}, \%params);
    $params{+NAME}    //= $self->{+NAME};

    return ref($self)->new(%$self, %params, __MERGE__ => 1)->compile;
}

sub clone {
    my $self   = shift;
    my %params = @_;

    $params{+TABLES}  //= [map { $_->clone } $self->tables];
    $params{+NAME}    //= $self->{+NAME};

    return ref($self)->new(%$self, %params, __CLONE__ => 1);
}

1;

__END__

