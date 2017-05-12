package Alzabo::MethodMaker;

use strict;
use vars qw($VERSION);

use Alzabo::Exceptions;
use Alzabo::Runtime;
use Alzabo::Utils;

use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { Alzabo::Exception::Params->throw( error => join '', @_ ) } );

$VERSION = 2.0;

# types of methods that can be made - only ones that haven't been
# deprecated
my @options = qw( foreign_keys
                  linking_tables
                  lookup_columns
                  row_columns
                  self_relations

                  tables
                  table_columns

                  insert_hooks
                  update_hooks
                  select_hooks
                  delete_hooks
                );

sub import
{
    my $class = shift;

    validate( @_, { schema     => { type => SCALAR },
                    class_root => { type => SCALAR,
                                    optional => 1 },
                    name_maker => { type => CODEREF,
                                    optional => 1 },
                    ( map { $_ => { optional => 1 } } 'all', @options ) } );
    my %p = @_;

    return unless exists $p{schema};
    return unless grep { exists $p{$_} && $p{$_} } 'all', @options;

    my $maker = $class->new(%p);

    $maker->make;
}

sub new
{
    my $class = shift;
    my %p = @_;

    if ( delete $p{all} )
    {
        foreach (@options)
        {
            $p{$_} = 1 unless exists $p{$_} && ! $p{$_};
        }
    }

    my $s = Alzabo::Runtime::Schema->load_from_file( name => delete $p{schema} );

    my $class_root;
    if ( $p{class_root} )
    {
        $class_root = $p{class_root};
    }
    else
    {
        my $x = 0;
        do
        {
            $class_root = caller($x++);
            die "No base class could be determined\n" unless $class_root;
        } while ( $class_root->isa(__PACKAGE__) );
    }

    my $self;

    $p{name_maker} = sub { $self->name(@_) } unless ref $p{name_maker};

    $self = bless { opts => \%p,
                    class_root => $class_root,
                    schema => $s,
                  }, $class;

    return $self;
}

sub make
{
    my $self = shift;

    $self->{schema_class} = join '::', $self->{class_root}, 'Schema';
    bless $self->{schema}, $self->{schema_class};

    $self->eval_schema_class;
    $self->load_class( $self->{schema_class} );

   {
       # Users can add methods to these superclasses
       no strict 'refs';
       foreach my $thing ( qw( Table Row ) )
       {
           @{ "$self->{class_root}::${thing}::ISA" }
               = ( "Alzabo::Runtime::$thing", "Alzabo::DocumentationContainer" );
       }
    }

    foreach my $t ( sort { $a->name cmp $b->name  } $self->{schema}->tables )
    {
        $self->{table_class} = join '::', $self->{class_root}, 'Table', $t->name;
        $self->{row_class} = join '::', $self->{class_root}, 'Row', $t->name;

        bless $t, $self->{table_class};
        $self->eval_table_class;
        $self->{schema}->add_contained_class( table => $self->{table_class} );

        $self->eval_row_class;
        $t->add_contained_class( row => $self->{row_class} );

        if ( $self->{opts}{tables} )
        {
            $self->make_table_method($t);
        }

        $self->load_class( $self->{table_class} );
        $self->load_class( $self->{row_class} );

        if ( $self->{opts}{table_columns} )
        {
            $self->make_table_column_methods($t);
        }

        if ( $self->{opts}{row_columns} )
        {
            $self->make_row_column_methods($t);
        }
        if ( grep { $self->{opts}{$_} } qw( foreign_keys linking_tables lookup_columns ) )
        {
            $self->make_foreign_key_methods($t);
        }

        foreach ( qw( insert update select delete ) )
        {
            if ( $self->{opts}{"$_\_hooks"} )
            {
                $self->make_hooks($t, $_);
            }
        }
    }
}

sub eval_schema_class
{
    my $self = shift;

    eval <<"EOF";
package $self->{schema_class};

use base qw( Alzabo::Runtime::Schema Alzabo::DocumentationContainer );
EOF

    Alzabo::Exception::Eval->throw( error => $@ ) if $@;
}

sub eval_table_class
{
    my $self = shift;

    eval <<"EOF";
package $self->{table_class};

use base qw( $self->{class_root}::Table );

sub _row_class { '$self->{row_class}' }

EOF

    Alzabo::Exception::Eval->throw( error => $@ ) if $@;
}

sub eval_row_class
{
    my $self = shift;

    # Need to load this so that ->can checks can see them
    require Alzabo::Runtime;

    eval <<"EOF";
package $self->{row_class};

use base qw( $self->{class_root}::Row Alzabo::DocumentationContainer );

EOF

    Alzabo::Exception::Eval->throw( error => $@ ) if $@;
}

sub make_table_method
{
    my $self = shift;
    my $t = shift;

    my $name = $self->_make_method
        ( type => 'table',
          class => $self->{schema_class},
          returns => 'table object',
          code =>  sub { return $t; },
          table => $t,
        ) or return;

    $self->{schema_class}->add_method_docs
        ( Alzabo::MethodDocs->new
          ( name  => $name,
            group => 'Methods that return table objects',
            description => "returns the " . $t->name . " table object",
          ) );
}

sub load_class
{
    my $self = shift;
    my $class = shift;

    eval "use $class;";

    die $@ if $@ && $@ !~ /^Can\'t locate .* in \@INC/;
}

sub make_table_column_methods
{
    my $self = shift;
    my $t = shift;

    foreach my $c ( sort { $a->name cmp $b->name  } $t->columns )
    {
        my $col_name = $c->name;

        my $name = $self->_make_method
            ( type => 'table_column',
              class => $self->{table_class},
              returns => 'column_object',

              # We can't just return $c because we may need to go
              # through the alias bits.  And we need to use $_[0] for
              # the same reason.
              code => sub { return $_[0]->column($col_name) },
              column => $c,
            ) or next;

        $self->{table_class}->add_method_docs
            ( Alzabo::MethodDocs->new
              ( name  => $name,
                group => 'Methods that return column objects',
                description => "returns the " . $c->name . " column object",
              ) );
    }
}

sub make_row_column_methods
{
    my $self = shift;
    my $t = shift;

    foreach my $c ( sort { $a->name cmp $b->name  } $t->columns )
    {
        my $col_name = $c->name;

        my $name = $self->_make_method
            ( type => 'row_column',
              class => $self->{row_class},
              returns => 'scalar value/takes new value',
              code => sub { my $self = shift;
                            if (@_)
                            {
                                $self->update( $col_name => $_[0] );
                            }
                            return $self->select($col_name); },
              column => $c,
            ) or next;

        $self->{row_class}->add_method_docs
            ( Alzabo::MethodDocs->new
              ( name  => $name,
                group => 'Methods that update/return a column value',
                spec  => [ { type => SCALAR } ],
                description =>
                "returns the value of the " . $c->name . " column for a row.  Given a value, it will also update the row first.",
              ) );
    }
}

sub make_foreign_key_methods
{
    my $self = shift;
    my $t = shift;

    foreach my $other_t ( sort { $a->name cmp $b->name  } $t->schema->tables )
    {
        my @fk = $t->foreign_keys_by_table($other_t)
            or next;

        if ( @fk == 2 && $fk[0]->table_from eq $fk[0]->table_to &&
             $fk[1]->table_from eq $fk[1]->table_to )
        {
            unless ($fk[0]->is_one_to_one)
            {
                $self->make_self_relation($fk[0]) if $self->{opts}{self_relations};
            }
            next;
        }

        foreach my $fk (@fk)
        {
            $self->_make_fk_method($fk);
        }
    }
}

sub _make_method
{
    my $self = shift;
    my %p = validate @_, { type => { type => SCALAR },
                           class => { type => SCALAR },
                           returns => { type => SCALAR, optional => 1 },
                           code => { type => CODEREF },

                           # Stuff we can pass through to name_maker
                           foreign_key => { optional => 1 },
                           foreign_key_2 => { optional => 1 },
                           column => { optional => 1 },
                           table => { optional => 1 },
                           parent => { optional => 1 },
                           plural => { optional => 1 },
                         };

    my $name = $self->{opts}{name_maker}->( %p )
        or return;

    my ($code_name, $debug_name) = ("$p{class}::$name",
                                    "$p{class}\->$name");

    if ( $p{class}->can($name) )
    {
        warn "MethodMaker: Creating $p{type} method $debug_name will override"
             . " the method of the same name in the parent class\n";
    }

    no strict 'refs';  # We use symbolic references here
    if ( defined &$code_name )
    {
        # This should probably always be shown to the user, not just
        # when debugging mode is turned on, because name clashes can
        # cause confusion - whichever subroutine happens first will
        # arbitrarily win.

        warn "MethodMaker: skipping $p{type} method $debug_name, subroutine already exists\n";
        return;
    }

    if (Alzabo::Debug::METHODMAKER)
    {
        my $message = "Making $p{type} method $debug_name";
        $message .= ": returns $p{returns}" if $p{returns};
        print STDERR "$message\n";
    }

    *$code_name = $p{code};
    return $name;
}

sub _make_fk_method
{
    my $self = shift;
    my $fk = shift;
    my $table_to = $fk->table_to->name;

    # The table may be a linking or lookup table.  If we are
    # supposed to make that kind of method we will and then we'll
    # skip to the next foreign table.
    $self->make_linking_table_method($fk)
        if $self->{opts}{linking_tables};

    $self->make_lookup_columns_methods($fk)
        if $self->{opts}{lookup_columns};

    return unless $self->{opts}{foreign_keys};

    if ($fk->is_one_to_many)
    {
        my $name = $self->_make_method
            ( type => 'foreign_key',
              class => $self->{row_class},
              returns => 'row cursor',
              code => sub { my $self = shift;
                            return $self->rows_by_foreign_key( foreign_key => $fk, @_ ); },
              foreign_key => $fk,
              plural => 1,
            ) or return;

        $self->{row_class}->add_method_docs
            ( Alzabo::MethodDocs->new
              ( name  => $name,
                group => 'Methods that return cursors for foreign keys',
                description =>
                "returns a cursor containing related rows from the " . $fk->table_to->name . " table",
                spec  => 'same as Alzabo::Runtime::Table->rows_where',
              ) );
    }
    # Singular method name
    else
    {
        my $name = $self->_make_method
            ( type => 'foreign_key',
              class => $self->{row_class},
              returns => 'single row',
              code => sub { my $self = shift;
                            return $self->rows_by_foreign_key( foreign_key => $fk, @_ ); },
              foreign_key => $fk,
              plural => 0,
            ) or return;

        $self->{row_class}->add_method_docs
            ( Alzabo::MethodDocs->new
              ( name  => $name,
                group => 'Methods that return a single row for foreign keys',
                description =>
                "returns a single related row from the " . $fk->table_to->name . " table",
                spec  => 'same as Alzabo::Runtime::Table->one_row',
              ) );
    }
}

sub make_self_relation
{
    my $self = shift;
    my $fk = shift;

    my (@pairs, @reverse_pairs);
    if ($fk->is_one_to_many)
    {
        @pairs = map { [ $_->[0], $_->[1]->name ] } $fk->column_pairs;
        @reverse_pairs = map { [ $_->[1], $_->[0]->name ] } $fk->column_pairs;
    }
    else
    {
        @pairs = map { [ $_->[1], $_->[0]->name ] } $fk->column_pairs;
        @reverse_pairs = map { [ $_->[0], $_->[1]->name ] } $fk->column_pairs;
    }

    my $table = $fk->table_from;

    my $name = $self->_make_method
        ( type => 'self_relation',
          class => $self->{row_class},
          returns => 'single row',
          code => sub { my $self = shift;
                        my @where = map { [ $_->[0], '=', $self->select( $_->[1] ) ] } @pairs;
                        return $table->one_row( where => \@where, @_ ); },
          foreign_key => $fk,
          parent => 1,
        ) or last;

    if ($name)
    {
        $self->{row_class}->add_method_docs
            ( Alzabo::MethodDocs->new
              ( name  => $name,
                group => 'Methods that return a parent row',
                description =>
                "a single parent row from the same table",
                spec  => 'same as Alzabo::Runtime::Table->one_row',
              ) );
    }

    $name = $self->_make_method
        ( type => 'self_relation',
          class => $self->{row_class},
          returns => 'row cursor',
          code =>
          sub { my $self = shift;
                my %p = @_;
                my @where = map { [ $_->[0], '=', $self->select( $_->[1] ) ] } @reverse_pairs;
                if ( $p{where} )
                {
                    @where = ( '(', @where, ')' );

                    push @where,
                        Alzabo::Utils::is_arrayref( $p{where}->[0] ) ? @{ $p{where} } : $p{where};

                    delete $p{where};
                }
                return $table->rows_where( where => \@where,
                                           %p ); },
          foreign_key => $fk,
          parent => 0,
        ) or return;

    $self->{row_class}->add_method_docs
        ( Alzabo::MethodDocs->new
          ( name  => $name,
            group => 'Methods that return child rows',
            description =>
            "a row cursor of child rows from the same table",
            spec  => 'same as Alzabo::Runtime::Table->rows_where',
          ) );
}

sub make_linking_table_method
{
    my $self = shift;
    my $fk = shift;

    return unless $fk->table_to->primary_key_size == 2;

    # Find the foreign key from the linking table to the _other_ table
    my $fk_2;
    {
        my @fk = $fk->table_to->all_foreign_keys;
        return unless @fk == 2;

        # Get the foreign key that's not the one we already have
        $fk_2 = $fk[0]->is_same_relationship_as($fk) ? $fk[1] : $fk[0];
    }

    return unless $fk_2;

    # Not a linking table unless all the PK columns in the linking
    # table are part of the link.
    return unless $fk->table_to->primary_key_size == $fk->table_to->columns;

    # Not a linking table unless the PK in the middle table is the
    # same size as the sum of the two table's PK sizes
    return unless ( $fk->table_to->primary_key_size ==
                    ( $fk->table_from->primary_key_size + $fk_2->table_to->primary_key_size ) );

    my $s = $fk->table_to->schema;
    my @t = ( $fk->table_to, $fk_2->table_to );
    my $select = [ $t[1] ];

    my $name = $self->_make_method
        ( type => 'linking_table',
          class => $self->{row_class},
          returns => 'row cursor',
          code =>
          sub { my $self = shift;
                my %p = @_;
                if ( $p{where} )
                {
                    $p{where} = [ $p{where} ] unless Alzabo::Utils::is_arrayref( $p{where}[0] );
                }
                foreach my $pair ( $fk->column_pairs )
                {
                    push @{ $p{where} }, [ $pair->[1], '=', $self->select( $pair->[0]->name ) ];
                }

                return $s->join( tables => [[@t, $fk_2]],
                                 select => $select,
                                 %p ); },
          foreign_key => $fk,
          foreign_key_2 => $fk_2,
        ) or return;

    $self->{row_class}->add_method_docs
        ( Alzabo::MethodDocs->new
          ( name  => $name,
            group => 'Methods that follow a linking table',
            description =>
            "a row cursor of related rows from the " . $fk_2->table_to->name . " table, " .
            "via the " . $fk->table_to->name . " linking table",
            spec  => 'same as Alzabo::Runtime::Table->rows_where',
          ) );
}

sub make_lookup_columns_methods
{
    my $self = shift;
    my $fk = shift;

    return if $fk->is_one_to_many;

    # Make sure the relationship is to the foreign table's primary key
    my @to = $fk->columns_to;
    return unless ( ( scalar grep { $_->is_primary_key } @to ) == @to &&
                    ( $fk->table_to->primary_key_size == @to ) );

    foreach ( sort { $a->name cmp $b->name  } $fk->table_to->columns )
    {
        next if $_->is_primary_key;

        my $col_name = $_->name;

        my $name = $self->_make_method
            ( type => 'lookup_columns',
              class => $self->{row_class},
              returns => 'scalar value of column',
              code =>
              sub { my $self = shift;
                    my $row = $self->rows_by_foreign_key( foreign_key => $fk, @_ );
                    return unless $row;
                    return $row->select($col_name) },
              foreign_key => $fk,
              column => $_,
            ) or next;

        $self->{row_class}->add_method_docs
            ( Alzabo::MethodDocs->new
              ( name  => $name,
                group => 'Methods that follow a lookup table',
                description =>
                "returns the value of " . (join '.', $fk->table_to->name, $col_name) . " for the given row by following the foreign key relationship",
                spec  => 'same as Alzabo::Runtime::Table->rows_where',
              ) );
    }
}

sub make_hooks
{
    my $self = shift;
    my $table = shift;
    my $type = shift;

    my $class = $type eq 'insert' ? $self->{table_class} : $self->{row_class};

    my $pre = "pre_$type";
    my $post = "post_$type";

    return unless $class->can($pre) || $class->can($post);

    my $method = join '::', $class, $type;

    {
        no strict 'refs';
        return if *{$method}{CODE};
    }

    print STDERR "Making $type hooks method $class\->$type\n"
        if Alzabo::Debug::METHODMAKER;

    my $meth = "make_$type\_hooks";
    $self->$meth($table);
}

sub make_insert_hooks
{
    my $self = shift;

    my $code = '';
    $code .= "        return \$s->schema->run_in_transaction( sub {\n";
    $code .= "            my \$new;\n";
    $code .= "            \$s->pre_insert(\\\%p);\n" if $self->{table_class}->can('pre_insert');
    $code .= "            \$new = \$s->SUPER::insert(\%p);\n";
    $code .= "            \$s->post_insert({\%p, row => \$new});\n" if $self->{table_class}->can('post_insert');
    $code .= "            return \$new;\n";
    $code .= "        } );\n";

    eval <<"EOF";
{
    package $self->{table_class};
    sub insert
    {
        my \$s = shift;
        my \%p = \@_;

$code

    }
}
EOF

    Alzabo::Exception::Eval->throw( error => $@ ) if $@;

    my $hooks =
        $self->_hooks_doc_string( $self->{table_class}, 'pre_insert', 'post_insert' );

    $self->{table_class}->add_class_docs
        ( Alzabo::ClassDocs->new
          ( group => 'Hooks',
            description => "$hooks",
          ) );
}

sub _hooks_doc_string
{
    my $self = shift;
    my ($class, $hook1, $hook2) = @_;

    my @hooks;
    push @hooks, $hook1 if $class->can($hook1);

    push @hooks, $hook2 if $class->can($hook2);

    my $hooks = 'has';
    $hooks .= @hooks > 1 ? '' : ' a ';
    $hooks .= join ' and ', @hooks;
    $hooks .= @hooks > 1 ? ' hooks' : ' hook';

    return $hooks;
}

sub make_update_hooks
{
    my $self = shift;

    my $code = '';
    $code .= "        \$s->schema->run_in_transaction( sub {\n";
    $code .= "            \$s->pre_update(\\\%p);\n" if $self->{row_class}->can('pre_update');
    $code .= "            \$s->SUPER::update(\%p);\n";
    $code .= "            \$s->post_update(\\\%p);\n" if $self->{row_class}->can('post_update');
    $code .= "        } );\n";

    eval <<"EOF";
{
    package $self->{row_class};

    sub update
    {
        my \$s = shift;
        my \%p = \@_;

$code

    }
}
EOF

    Alzabo::Exception::Eval->throw( error => $@ ) if $@;

    my $hooks =
        $self->_hooks_doc_string( $self->{row_class}, 'pre_update', 'post_update' );

    $self->{row_class}->add_class_docs
        ( Alzabo::ClassDocs->new
          ( group => 'Hooks',
            description => "$hooks",
          ) );
}

sub make_select_hooks
{
    my $self = shift;

    my ($pre, $post) = ('', '');
    $pre  = "            \$s->pre_select(\\\@cols);\n"
        if $self->{row_class}->can('pre_update');

    $post = "            \$s->post_select(\\\%r);\n"
        if $self->{row_class}->can('post_update');

    eval <<"EOF";
{
    package $self->{row_class};

    sub select
    {
        my \$s = shift;
        my \@cols = \@_;

        return \$s->schema->run_in_transaction( sub {

$pre

            my \@r;
            my %r;

            if (wantarray)
            {
                \@r{ \@cols } = \$s->SUPER::select(\@cols);
            }
            else
            {
                \$r{ \$cols[0] } = (scalar \$s->SUPER::select(\$cols[0]));
            }
$post
            return wantarray ? \@r{\@cols} : \$r{ \$cols[0] };
        } );
    }

    sub select_hash
    {
        my \$s = shift;
        my \@cols = \@_;

        return \$s->schema->run_in_transaction( sub {

$pre

            my \%r = \$s->SUPER::select_hash(\@cols);

$post

            return \%r;
        } );
    }
}
EOF

    Alzabo::Exception::Eval->throw( error => $@ ) if $@;

    my $hooks =
        $self->_hooks_doc_string( $self->{row_class}, 'pre_select', 'post_select' );

    $self->{row_class}->add_class_docs
        ( Alzabo::ClassDocs->new
          ( group => 'Hooks',
            description => "$hooks",
          ) );
}

sub make_delete_hooks
{
    my $self = shift;

    my $code = '';
    $code .= "        \$s->schema->run_in_transaction( sub {\n";
    $code .= "            \$s->pre_delete(\\\%p);\n" if $self->{row_class}->can('pre_delete');
    $code .= "            \$s->SUPER::delete(\%p);\n";
    $code .= "            \$s->post_delete(\\\%p);\n" if $self->{row_class}->can('post_delete');
    $code .= "        } );\n";

    eval <<"EOF";
package $self->{row_class};

sub delete
{
    my \$s = shift;
    my \%p = \@_;

$code

}
EOF

    Alzabo::Exception::Eval->throw( error => $@ ) if $@;

    my $hooks =
        $self->_hooks_doc_string( $self->{row_class}, 'pre_delete', 'post_delete' );

    $self->{row_class}->add_class_docs
        ( Alzabo::ClassDocs->new
          ( group => 'Hooks',
            description => "$hooks",
          ) );
}

sub name
{
    my $self = shift;
    my %p = @_;

    return $p{table}->name if $p{type} eq 'table';

    return $p{column}->name if $p{type} eq 'table_column';

    return $p{column}->name if $p{type} eq 'row_column';

    if ( $p{type} eq 'foreign_key' )
    {
        return $p{foreign_key}->table_to->name;
    }

    if ( $p{type} eq 'linking_table' )
    {
        my $method = $p{foreign_key}->table_to->name;
        my $tname = $p{foreign_key}->table_from->name;
        $method =~ s/^$tname\_?//;
        $method =~ s/_?$tname$//;

        return $method;
    }

    return join '_', map { lc $_->name } $p{foreign_key}->table_to, $p{column}
        if $p{type} eq 'lookup_columns';

    return $p{column}->name if $p{type} eq 'lookup_columns';

    return $p{parent} ? 'parent' : 'children'
        if $p{type} eq 'self_relation';

    die "unknown type in call to naming sub: $p{type}\n";
}

package Alzabo::DocumentationContainer;

my %store;
sub add_method_docs
{
    my $class = shift;

    my $docs = shift;

    my $store = $class->_get_store($class);

    my $group = $docs->group;
    my $name = $docs->name;

    $store->{methods}{by_group}{$group} ||= Tie::IxHash->new;
    $store->{methods}{by_group}{$group}->Push( $name => $docs );

    $store->{methods}{by_name} ||= Tie::IxHash->new;
    $store->{methods}{by_name}->Push( $name => $docs );
}

sub add_class_docs
{
    my $class = shift;

    my $docs = shift;

    my $store = $class->_get_store($class);

    my $group = $docs->group;

    $store->{class}{by_group}{$group} ||= [];
    push @{ $store->{class}{by_group}{$group} }, $docs;
}

sub add_contained_class
{
    my $class = shift;

    my ($type, $contained) = @_;

    my $store = $class->_get_store($class);

    push @{ $store->{contained_classes}{by_name} }, $contained;

    push @{ $store->{contained_classes}{by_type}{$type} }, $contained;
}

sub _get_store
{
    my $class = shift;
    $class = ref $class || $class;

    $store{$class} ||= {};

    return $store{$class};
}

sub method_names
{
    my $class = shift;

    my $store = $class->_get_store($class);

    return $store->{methods}{by_name}->Keys;
}

sub methods_by_name
{
    my $class = shift;

    my $store = $class->_get_store($class);

    return $store->{methods}{by_name}->Values;
}

sub method_groups
{
    my $class = shift;

    my $store = $class->_get_store($class);

    return keys %{ $store->{methods}{by_group} };
}

sub methods_by_group
{
    my $class = shift;

    my $store = $class->_get_store($class);

    my $group = shift;

    return $store->{methods}{by_group}{$group}->Values
        if exists $store->{methods}{by_group}{$group};
}

sub class_groups
{
    my $class = shift;

    my $store = $class->_get_store($class);

    return keys %{ $store->{class}{by_group} };
}

sub class_docs_by_group
{
    my $class = shift;

    my $store = $class->_get_store($class);

    my $group = shift;

    return @{ $store->{class}{by_name}{$group} }
        if exists $store->{class}{by_name}{$group};
}

sub class_docs
{
    my $class = shift;

    my $store = $class->_get_store($class);

    my $group = shift;

    return map { @{ $store->{class}{by_group}{$_} } }
        keys %{ $store->{class}{by_group} };
}

sub contained_classes
{
    my $class = shift;

    my $store = $class->_get_store($class);

    return @{ $store->{contained_classes}{by_name} }
        if exists $store->{contained_classes}{by_name};

    return;
}

sub method
{
    my $class = shift;

    my $store = $class->_get_store($class);

    my $name = shift;

    return $store->{methods}{by_name}->FETCH($name)
        if exists $store->{methods}{by_name};
}

sub docs_as_pod
{
    my $self = shift;
    my $class = ref $self || $self;
    my $contained = shift;

    my $store = $class->_get_store($class);

    my $pod;

    $pod .= "=pod\n\n" unless $contained;

    $pod .= "=head1 $class\n\n";

    foreach my $class_doc ( $class->class_docs )
    {
        $pod .= $class_doc->as_pod;
    }

    foreach my $group ( $class->method_groups )
    {
        $pod .= "=head2 $group\n\n";

        foreach my $method ( $class->methods_by_group($group) )
        {
            $pod .= $method->as_pod;
        }
    }

    $pod .= $_ foreach $self->contained_docs;

    $pod .= "=cut\n\n" unless $contained;

    return $pod;
}

sub contained_docs
{
    my $self = shift;

    return map { $_->docs_as_pod(1) } $self->contained_classes;
}

package Alzabo::Docs;

sub group { shift->{group} }
sub description { shift->{description} }

# copied from Params::ValidatePP
{
    my %type_to_string =
        ( Params::Validate::SCALAR()    => 'scalar',
          Params::Validate::ARRAYREF()  => 'arrayref',
          Params::Validate::HASHREF()   => 'hashref',
          Params::Validate::CODEREF()   => 'coderef',
          Params::Validate::GLOB()      => 'glob',
          Params::Validate::GLOBREF()   => 'globref',
          Params::Validate::SCALARREF() => 'scalarref',
          Params::Validate::UNDEF()     => 'undef',
          Params::Validate::OBJECT()    => 'object',
        );

    sub _typemask_to_strings
    {
        shift;
        my $mask = shift;

        my @types;
        foreach ( Params::Validate::SCALAR, Params::Validate::ARRAYREF,
                  Params::Validate::HASHREF, Params::Validate::CODEREF,
                  Params::Validate::GLOB, Params::Validate::GLOBREF,
                  Params::Validate::SCALARREF, Params::Validate::UNDEF,
                  Params::Validate::OBJECT )
        {
            push @types, $type_to_string{$_} if $mask & $_;
        }
        return @types ? @types : ('unknown');
    }
}

package Alzabo::MethodDocs;

use Params::Validate qw( validate SCALAR ARRAYREF HASHREF );

use base qw(Alzabo::Docs);

sub new
{
    my $class = shift;
    my %p = validate( @_, { name    => { type => SCALAR },
                            group   => { type => SCALAR },
                            description => { type => SCALAR },
                            spec    => { type => SCALAR | ARRAYREF | HASHREF,
                                         default => undef },
                          } );

    return bless \%p, $class;
}

sub name { shift->{name} }
sub spec { shift->{spec} }

sub as_pod
{
    my $self = shift;

    my $desc = ucfirst $self->{description};

    my $spec = $self->spec;

    my $params;
    if ( defined $spec )
    {
        if ( Alzabo::Utils::is_arrayref( $spec ) )
        {
            $params = "=over 4\n\n";

            foreach my $p (@$spec)
            {
                $params .= "=item * ";
                if ( exists $p->{type} )
                {
                    # hack!
                    my $types =
                        join ', ', $self->_typemask_to_strings( $p->{type} );
                    $params .= "($types)";
                }
                $params .= "\n\n";
            }

            $params .= "=back\n\n";
        }
        elsif ( Alzabo::Utils::is_hashref($spec) )
        {
            $params = "=over 4\n\n";

            while ( my ($name, $p) = each %$spec )
            {
                $params .= "=item * $name ";
                if ( exists $p->{type} )
                {
                    # hack!
                    my $types =
                        join ', ', $self->_typemask_to_strings( $p->{type} );
                    $params .= "($types)";
                }
                $params .= "\n\n";
            }

            $params .= "=back\n\n";
        }
        else
        {
            $params = "Parameters: $spec\n\n";
        }
    }

    my $pod = <<"EOF";
=head3 $self->{name}

$desc

EOF
    $pod .= $params if $params;

    return $pod;
}


package Alzabo::ClassDocs;

use Params::Validate qw( validate SCALAR );

use base qw(Alzabo::Docs);

sub new
{
    my $class = shift;
    my %p = validate( @_, { group   => { type => SCALAR },
                            description => { type => SCALAR },
                          } );

    return bless \%p, $class;
}

sub as_pod
{
    my $self = shift;

    return ucfirst "$self->{description}\n\n";
}

1;


__END__

=head1 NAME

Alzabo::MethodMaker - Auto-generate useful methods based on an existing schema

=head1 SYNOPSIS

  use Alzabo::MethodMaker ( schema => 'schema_name', all => 1 );

=head1 DESCRIPTION

This module can take an existing schema and generate a number of
useful methods for this schema and its tables and rows.  The method
making is controlled by the parameters given along with the use
statement, as seen in the L<SYNOPSIS
section|Alzabo::MethodMaker/SYNOPSIS>.

=head1 PARAMETERS

These parameters are all passed to the module when it is imported via
C<use>.

=over 4

=item * schema => $schema_name

This parameter is B<required>.

=item * class_root => $class_name

If given, this will be used as the root of the class names generated
by this module.  This root should not end in '::'.  If none is given,
then the calling module's name is used as the root.  See L<New Class
Names|"New Class Names"> for more information.

=item * all => $bool

This tells this module to make all of the methods it possibly can.
See L<METHOD CREATION OPTIONS|"METHOD CREATION OPTIONS"> for more
details.

If individual method creation options are set as false, then that
setting will be respected, so you could use

  use Alzabo::MethodMaker( schema => 'foo', all => 1, tables => 0 );

to turn on all of the regular options B<except> for "tables".

=item * name_maker => \&naming_sub

If provided, then this callback will be called any time a method name
needs to be generated.  This allows you to have full control over the
resulting names.  Otherwise names are generated as described in the
documentation.

The callback is expected to return a name for the method to be used.
This name should not be fully qualified or contain any class
designation as this will be handled by MethodMaker.

It is important that none of the names returned conflict with existing
methods for the object the method is being added to.

For example, when adding methods that return column objects to a
table, if you have a column called 'name' and try to use that as the
method name, it won't work.  C<Alzabo::Table> objects already have
such a method, which returns the name of the table.  See the relevant
documentation of the schema, table, and row objects for a list of
methods they contain.

The L<NAMING SUB PARAMETERS|"NAMING SUB PARAMETERS"> section contains
the details of what parameters are passed to this callback.

I<Please note> that if you have a large complex schema you will almost
certainly need to provide a custom naming subroutine to avoid name
conflicts.

=back

=head1 EFFECTS

Using this module has several effects on your schema's objects.

=head2 New Class Names

Your schema, table, and row objects to be blessed into subclasses of
L<C<Alzabo::Runtime::Schema>|Alzabo::Runtime::Schema>,
L<C<Alzabo::Runtime::Table>|Alzabo::Runtime::Table>,
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row>, respectively.  These
subclasses contain the various methods created by this module.  The
new class names are formed by using the
L<"class_root"|Alzabo::MethodMaker/PARAMETERS> parameter and adding
onto it.

In order to make it convenient to add new methods to the table and row
classes, the created table classes are all subclasses of a new class
based on your class root, and the same thing is done for all created
row classes.


=over 4

=item * Schema

  <class root>::Schema

=item * Tables

  <class root>::Table::<table name>

All tables will be subclasses of:

  <class root>::Table

=item * Rows

  <class root>::Row::<table name>

All rows will be subclasses of:

  <class root>::Row

=back

With a root of "My::MovieDB", and a schema with only two tables,
"Movie" and "Image", this would result in the following class names:

 My::MovieDB::Schema

 My::MovieDB::Table::Movie - subclass of My::MovieDB::Table
 My::MovieDB::Row::Movie   - subclass of My::MovieDB::Row

 My::MovieDB::Table::Image - subclass of My::MovieDB::Table
 My::MovieDB::Row::Image   - subclass of My::MovieDB::Row

=head2 Loading Classes

For each class into which an object is blessed, this module will
attempt to load that class via a C<use> statement.  If there is no
module found this will not cause an error.  If this class defines any
methods that have the same name as those this module generates, then
this module will not attempt to generate them.

=head1 METHOD CREATION OPTIONS

When using Alzabo::MethodMaker, you may specify any of the following
parameters.  Specifying "all" causes all of them to be used.

=head2 Schema object methods

=over 4

=item * tables => $bool

Creates methods for the schema that return the table object matching
the name of the method.

For example, given a schema containing tables named "Movie" and
"Image", this would create methods that could be called as C<<
$schema->Movie >> and C<< $schema->Image >>.

=back

=head2 Table object methods.

=over 4

=item * table_columns => $bool

Creates methods for the tables that return the column object matching
the name of the method.  This is quite similar to the C<tables> option
for schemas.  So if our "Movie" table had a column called "title", we
could write C<< $schema->Movie->title >>.

=item * insert_hooks => $bool

Look for hooks to wrap around the C<insert()> method in
L<C<Alzabo::Runtime::Table>|Alzabo::Runtime::Table>.  See L<Loading
Classes> for more details.  You have to define either a
C<pre_insert()> and/or C<post_insert()> method for the generated table
class or this parameter will not do anything.  See the
L<HOOKS|/"HOOKS"> section for more details.

=back

=head2 Row object methods

=over 4

=item * row_columns => $bool

This tells MethodMaker to create get/set methods for each column a row
has.  These methods take a single optional argument, which if given
will cause that column to be updated for the row.

=item * update_hooks => $bool

Look for hooks to wrap around the C<update> method in
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row>.  See L<Loading
Classes> for more details.  You have to define a C<pre_update()>
and/or C<post_update()> method for the generated row class or this
parameter will not do anything.  See the L<HOOKS|/"HOOKS"> section for
more details.

=item * select_hooks => $bool

Look for hooks to wrap around the C<select> method in
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row>.  See L<Loading
Classes> for more details.  You have to define either a
C<pre_select()> and/or C<post_select()> method for the generated row
class or this parameter will not do anything.  See the
L<HOOKS|/"HOOKS"> section for more details.

=item * delete_hooks => $bool

Look for hooks to wrap around the C<delete> method in
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row>.  See L<Loading
Classes> for more details.  You have to define either a
C<pre_delete()> and/or C<post_delete()> method for the generated row
class or this parameter will not do anything.  See the
L<HOOKS|/"HOOKS"> section for more details.

=item * foreign_keys => $bool

Creates methods in row objects named for the table to which the
relationship exists.  These methods return either a single
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row> object or a single
L<C<Alzabo::Runtime::RowCursor>|Alzabo::Runtime::RowCursor> object,
depending on the cardinality of the relationship.

For exa

  Movie                     Credit
  ---------                 --------
  movie_id                  movie_id
  title                     person_id
                            role_name

This would create a method for Movie row objects called C<Credit()>
which would return a cursor for the associated Credit table rows.
Similarly, Credit row objects would have a method called C<Movie()>
which would return the associated Movie row object.

=item * linking_tables => $bool

A linking table, as defined here, is a table with a two column primary
key, with each column being a foreign key to another table's primary
key.  These tables exist to facilitate n..n logical relationships.  If
both C<foreign_keys> and C<linking_tables> are true, then methods will
be created that skip the intermediate linking tables.

For example, with the following tables:

  User           UserGroup        Group
  -------        ---------        --------
  user_id        user_id          group_id
  user_name      group_id         group_name

The "UserGroup" table exists solely to facilitate the n..n
relationship between "User" and "Group".  User row objects will have a
C<Group()> method, which returns a row cursor of Group row objects.
And Group row objects will have a C<User()> method which returns a row
cursor of User row objects.

=item * lookup_columns => $bool

Lookup columns are columns in foreign tables to which a table has a
many-to-one or one-to-one relationship to the foreign table's primary
key.  For example, given the tables below:

  Restaurant                    Cuisine
  ---------                     --------
  restaurant_id                 cuisine_id
  restaurant_name   (n..1)      description
  phone                         spiciness
  cuisine_id

In this example, Restaurant row objects would have
C<Cuisine_description()> and C<Cuisine_spiciness> methods which
returned the corresponding values from the C<Cuisine> table.

=item * self_relations => $bool

A self relation is when a table has a parent/child relationship with
itself.  Here is an example:

 Location
 --------
 location_id
 location_name
 parent_location_id

NOTE: If the relationship has a cardinality of 1..1 then no methods
will be created, as this option is really intended for parent/child
relationships.  This may change in the future.

In this case, Location row objects will have both C<parent()> and
C<children()> methods.  The parent method returns a single row, while
the C<children()> method returns a row cursor of Location rows.

=back

=head1 HOOKS

As was mentioned previously, it is possible to create pre- and
post-execution hooks to wrap around a number of methods.  This allows
you to do data validation on inserts and updates as well as giving you
a chance to filter incoming or outgoing data as needed.  For example,
this can be used to convert dates to and from a specific RDBMS
format.

All hooks are inside a transaction which is rolled back if any part of
the process fails.

It should be noted that Alzabo uses both the C<<
Alzabo::Runtime::Row->select >> and C<< Alzabo::Runtime::Row->delete >>
methods internally.  If their behavior is radically altered through
the use of hooks, then some of Alzabo's functionality may be broken.

Given this, it may be safer to create new methods to fetch and massage
data rather than to create post-select hooks that alter data.

Each of these hooks receives different parameters, documented below:

=head2 Insert Hooks

=over 4

=item * pre_insert

This method receives a hash reference of all the parameters that are
passed to the L<C<< Alzabo::Runtime::Table->insert()
>>|Alzabo::Runtime::Table/insert> method.

These are the actual parameters that will be passed to the C<insert>
method so alterations to this reference will be seen by that method.
This allows you to alter the values that actually end up going into
the database or change any other parameters as you see fit.

=item * post_insert

This method also receives a hash reference containing all of the
parameters passed to the C<insert()> method.  In addition, the hash
reference contains an additional key, "row", which contains the newly
created row.

=back

=head2 Update Hooks

=over 4

=item * pre_update

This method receives a hash reference of the parameters that will be
passed to the L<C<< Alzabo::Runtime::Row->update()
>>|Alzabo::Runtime::Row/update> method.  Again, alterations to these
parameters will be seen by the C<update> method.

=item * post_update

This method receives the same parameters as C<pre_update()>

=back

=head2 Select Hooks

=over 4

=item * pre_select

This method receives an array reference containing the names of the
requested columns.  This is called when either the L<C<<
Alzabo::Runtime::Row->select() >>|Alzabo::Runtime::Row/select> or
L<C<< Alzabo::Runtime::Row->select_hash()
>>|Alzabo::Runtime::Row/select_hash> methods are called.

=item * post_select

This method is called after the L<C<< Alzabo::Runtime::Row->select()
>>|Alzabo::Runtime::Row/select> or L<C<<
Alzabo::Runtime::Row->select_hash()
>>|Alzabo::Runtime::Row/select_hash> methods.  It receives a hash
containing the name and values returned from the revelant method,
which it may modify.  If the values of this hash reference are
modified, then this will be seen by the original caller.

=back

=head2 Delete hooks

=over 4

=item * pre_delete

This method receives no parameters.

=back

=head1 NAMING SUB PARAMETERS

The naming sub will receive a hash containing the following parameters:

=over 4

=item * type => $method_type

This will always be the same as one of the parameters you give to the
import method.  It will be one of the following: "foreign_key",
"linking_table", "lookup_columns", "row_column", "self_relation",
"table", "table_column".

=back

The following parameters vary from case to case, depending on the
value of "type".

When the type is "table":

=over 4

=item * table => Alzabo::Table object

This parameter will be passed when the type is C<table>.  It is the
table object the schema object's method will return.

=back

When the type is "table_column" or "row_column":

=over 4

=item * column => Alzabo::Column object

When the type is "table_column", this is the column object the method
will return.  When the type is "row_column", then it is the column
whose B<value> the method will return.

=back

When the type is "foreign_key", "linking_table", or "self_relation":

=over 4

=item * foreign_key => Alzabo::ForeignKey object

This is the foreign key on which the method is based.

=back

It is possible to create an n..n relationship between a table and
itself, and MethodMaker will attempt to generate linking table methods
for such relationships, so your naming sub may need to take this into
account.

When the type is "foreign_key":

=over 4

=item * plural => $bool

This indicates whether or not the method that is being created will
return a cursor object (true) or a row object (false).

=back

When the type is "linking_table":

=over 4

=item * foreign_key_2 => Alzabo::ForeignKey object

When making a linking table method, two foreign keys are used.  The
C<foreign_key> is from the table being linked from to the linking
table.  This parameter is the foreign key from the linking table to
the table being linked to.

=back

When the type is "lookup_columns":

=over 4

=item * column => Alzabo::Column object

When making lookup column methods, this column is the column in the
foreign table for which a method is being made.

=back

When the type is "self_relation":

=over 4

=item * parent => $boolean

This indicates whether or not the method being created will return
parent objects (true) or child objects (false).

=back

=head1 NAMING SUB EXAMPLE

Here is an example that covers all of the possible options:

 use Lingua::EN::Inflect;

 sub namer
 {
     my %p = @_;

     # Table object can be returned from the schema via methods such as $schema->User_t;
     return $p{table}->name . '_t' if $p{type} eq 'table';

     # Column objects are returned similarly, via $schema->User_t->username_c;
     return $p{column}->name . '_c' if $p{type} eq 'table_column';

     # If I have a row object, I can get at the columns via their
     # names, for example $user->username;
     return $p{column}->name if $p{type} eq 'row_column';

     # This manipulates the table names a bit to generate names.  For
     # example, if I have a table called UserRating and a 1..n
     # relationship from User to UserRating, I'll end up with a method
     # on rows in the User table called ->Ratings which returns a row
     # cursor of rows from the UserRating table.
     if ( $p{type} eq 'foreign_key' )
     {
         my $name = $p{foreign_key}->table_to->name;
         my $from = $p{foreign_key}->table_from->name;
         $name =~ s/$from//;

         if ($p{plural})
         {
             return my_PL( $name );
         }
         else
         {
             return $name;
         }
     }

     # This is very similar to how foreign keys are handled.  Assume
     # we have the tables Restaurant, Cuisine, and RestaurantCuisine.
     # If we are generating a method for the link from Restaurant
     # through to Cuisine, we'll have a method on Restaurant table
     # rows called ->Cuisines, which will return a cursor of rows from
     # the Cuisine table.
     #
     # Note: this will generate a bad name if given a linking table
     # that links a table to itself.
     if ( $p{type} eq 'linking_table' )
     {
         my $method = $p{foreign_key}->table_to->name;
         my $tname = $p{foreign_key}->table_from->name;
         $method =~ s/$tname//;

         return my_PL($method);
     }

     # Lookup columns are columns if foreign tables for which there
     # exists a one-to-one or many-to-one relationship.  In cases such
     # as these, it is often the case that the foreign table is rarely
     # used on its own, but rather it primarily used as a lookup table
     # for values that should appear to be part of other tables.
     #
     # For example, an Address table might have a many-to-one
     # relationship with a State table.  The State table would contain
     # the columns 'name' and 'abbreviation'.  If we have
     # an Address table row, it is convenient to simply be able to say
     # $address->state_name and $address->state_abbreviation.

     if ( $p{type} eq 'lookup_columns' )
     {
         return join '_', map { lc $_->name } $p{foreign_key}->table_to, $p{column};
     }

     # This should be fairly self-explanatory.
     return $p{parent} ? 'parent' : 'children'
         if $p{type} eq 'self_relation';

     # And just to make sure that nothing slips by us we do this.
     die "unknown type in call to naming sub: $p{type}\n";
 }

 # Lingua::EN::Inflect did not handle the word 'hours' properly when this was written
 sub my_PL
 {
     my $name = shift;
     return $name if $name =~ /hours$/i;

     return Lingua::EN::Inflect::PL($name);
 }

=head1 GENERATED DOCUMENTATION

This module keeps track of methods that are generated and can in turn
generate basic POD for those methods.

Any schema that has had methods generated for it by
Alzabo::MethodMaker will have an additional method, C<docs_as_pod>.
This will return documentation for the schema object's methods, as
well as any documentation available for objects that the schema
contains, in this case tables.  The tables in turn return their own
documentation plus that of their contained row classes.

It is also possible to call the C<docs_as_pod> method on any generated
table or row class individually.

A simple script like the following can be used to send all of the
generated documentation to C<STDOUT>.

  use Alzabo::MethodMaker ( schema => 'foo', all => 1 );

  my $s = Alzabo::Runtime::Schema->load_from_file( name => 'foo' );

  print $s->docs_as_pod;

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
