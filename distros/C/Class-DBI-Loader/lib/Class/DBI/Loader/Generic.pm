package Class::DBI::Loader::Generic;

use strict;
use vars qw($VERSION);
use Carp;
use Lingua::EN::Inflect;

$VERSION = '0.30';

=head1 NAME

Class::DBI::Loader::Generic - Generic Class::DBI::Loader Implementation.

=head1 SYNOPSIS

See L<Class::DBI::Loader>

=head1 DESCRIPTION

=head1 METHODS

=head2 new %args

See the documentation for C<Class::DBI::Loader-E<gt>new()>

=cut

sub new {
    my ( $class, %args ) = @_;
    if ( $args{debug} ) {
        no strict 'refs';
        *{"$class\::debug"} = sub { 1 };
    }
    my $additional = $args{additional_classes} || [];
    $additional = [$additional] unless ref $additional eq 'ARRAY';
    my $additional_base = $args{additional_base_classes} || [];
    $additional_base = [$additional_base]
      unless ref $additional_base eq 'ARRAY';
    my $left_base = $args{left_base_classes} || [];
    $left_base = [$left_base] unless ref $left_base eq 'ARRAY';
    my $self = bless {
        _datasource =>
          [ $args{dsn}, $args{user}, $args{password}, $args{options} ],
        _namespace       => $args{namespace},
        _additional      => $additional,
        _additional_base => $additional_base,
        _left_base       => $left_base,
        _constraint      => $args{constraint} || '.*',
        _exclude         => $args{exclude},
        _relationships   => $args{relationships},
        _inflect         => $args{inflect},
        _require         => $args{require},
        _require_warn    => $args{require_warn},
        CLASSES          => {},
    }, $class;
    warn qq/\### START Class::DBI::Loader dump ###\n/ if $self->debug;
    $self->_load_classes;
    $self->_relationships                           if $self->{_relationships};
    warn qq/\### END Class::DBI::Loader dump ###\n/ if $self->debug;

    # disconnect to avoid confusion.
    foreach my $table ($self->tables) {
        $self->find_class($table)->db_Main->disconnect;
    }

    $self;
}

=head3 find_class

Returns a tables class.

    my $class = $loader->find_class($table);

=cut

sub find_class {
    my ( $self, $table ) = @_;
    return $self->{CLASSES}->{$table};
}

=head3 classes

Returns a sorted list of classes.

    my $@classes = $loader->classes;

=cut

sub classes {
    my $self = shift;
    return sort values %{ $self->{CLASSES} };
}

=head3 debug

Overload to enable debug messages.

=cut

sub debug { 0 }

=head3 tables

Returns a sorted list of tables.

    my @tables = $loader->tables;

=cut

sub tables {
    my $self = shift;
    return sort keys %{ $self->{CLASSES} };
}

# Overload in your driver class
sub _db_class { croak "ABSTRACT METHOD" }

# Setup has_a and has_many relationships
sub _has_a_many {
    my ( $self, $table, $column, $other ) = @_;
    my $table_class = $self->find_class($table);
    my $other_class = $self->find_class($other);
    warn qq/\# Has_a relationship\n/ if $self->debug;
    warn qq/$table_class->has_a( '$column' => '$other_class' );\n\n/
      if $self->debug;
    $table_class->has_a( $column => $other_class );
    my ($table_class_base) = $table_class =~ /.*::(.+)/;
    my $plural = Lingua::EN::Inflect::PL( lc $table_class_base );
    $plural = $self->{_inflect}->{ lc $table_class_base }
      if $self->{_inflect}
      and exists $self->{_inflect}->{ lc $table_class_base };
    warn qq/\# Has_many relationship\n/ if $self->debug;
    warn qq/$other_class->has_many( '$plural' => '$table_class' );\n\n/
      if $self->debug;
    $other_class->has_many( $plural => $table_class );
}

# Load and setup classes
sub _load_classes {
    my $self            = shift;
    my @tables          = $self->_tables();
    my $db_class        = $self->_db_class();
    my $additional      = join '', map "use $_;\n", @{ $self->{_additional} };
    my $additional_base = join '', map "use base '$_';\n",
      @{ $self->{_additional_base} };
    my $left_base  = join '', map "use base '$_';\n", @{ $self->{_left_base} };
    my $constraint = $self->{_constraint};
    my $exclude    = $self->{_exclude};

    my $use_connection = $Class::DBI::VERSION >= 0.96;
    foreach my $table (@tables) {
        next unless $table =~ /$constraint/;
        next if ( defined $exclude && $table =~ /$exclude/ );
        my $class = $self->_table2class($table);
        warn qq/\# Initializing table "$table" as "$class"\n/ if $self->debug;
        {
            no strict 'refs';
            @{"$class\::ISA"} = $db_class;
        }
        if ($use_connection) {
            $class->connection(@{$self->{_datasource}});
        } else {
            $class->set_db( Main => @{ $self->{_datasource} } );
        }
        $class->set_up_table($table);
        $self->{CLASSES}->{$table} = $class;

        my $code = "package $class;$additional_base$additional$left_base";
        warn qq/$code/  if $self->debug;
        warn qq/$class->table('$table');\n\n/ if $self->debug;
        eval $code;
        croak qq/Couldn't load additional classes "$@"/ if $@;
        {
            no strict 'refs';
            unshift @{"$class\::ISA"}, $_ foreach ( @{ $self->{_left_base} } );
        }

        if ($self->{_require}) {
            eval "require $class";
            if ($self->{_require_warn} && $@ && $@ !~ /Can't locate/) {
                warn;
            }
        }
    }
}

# Find and setup relationships
sub _relationships {
    my $self = shift;
    foreach my $table ( $self->tables ) {
        my $dbh = $self->find_class($table)->db_Main;
        if ( my $sth = $dbh->foreign_key_info( '', '', '', '', '', $table ) ) {
            for my $res ( @{ $sth->fetchall_arrayref( {} ) } ) {
                my $column = $res->{FK_COLUMN_NAME};
                my $other  = $res->{UK_TABLE_NAME};
                eval { $self->_has_a_many( $table, $column, $other ) };
                warn qq/\# has_a_many failed "$@"\n\n/ if $@ && $self->debug;
            }
        }
    }
}

# Make a class from a table
sub _table2class {
    my ( $self, $table ) = @_;
    my $namespace = $self->{_namespace} || "";
    $namespace =~ s/(.*)::$/$1/;
    my $subclass = join '', map ucfirst, split /[\W_]+/, $table;
    my $class = $namespace ? "$namespace\::" . $subclass : $subclass;
}

# Overload in driver class
sub _tables { croak "ABSTRACT METHOD" }

=head1 SEE ALSO

L<Class::DBI::Loader>, L<Class::DBI::Loader::mysql>, L<Class::DBI::Loader::Pg>,
L<Class::DBI::Loader::SQLite>

=cut

1;
