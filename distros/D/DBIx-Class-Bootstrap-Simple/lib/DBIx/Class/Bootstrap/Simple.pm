package DBIx::Class::Bootstrap::Simple;
use strict;
use warnings;

our $VERSION = '0.03';

=head1 NAME

DBIx::Class::Bootstrap::Simple - Simplistic bootstrapping for DBIx::Class

=head1 SYNOPSIS

Your model:

   package YourNamespace::DB::User;

   use base 'DBIx::Class::Bootstrap::Simple';

   use strict;
   
   __PACKAGE__->init(
       table       => 'users',
       primary_key => 'user_id',
       definition  => [
           {
              key     => 'user_id',
              type    => 'INT(11)',
              special => 'AUTO_INCREMENT',
              null    => 0,
              primary => 1,
           },
           {
               key   => 'company_id',
               type  => 'INT',
           },
           {
              key     => 'password_id',
              type    => 'INT(11)',
           },
           {
              key     => 'stash',
              type    => 'BLOB',
           },
       },
       # link datetime objects here as well
       objects => {
           # class must have an inflate and deflate method
           # inflate method is Class->inflate(value_to_inflate)
           # deflate is $yourinflated_object->deflate;
           stash => 'YourApp::DB::DataType::Stash',
       },
       references  => {
           company => {
               class          => 'YourApp::DB::Company',
               column         => 'company_id',
               cascade_update => 1, #defaults to 0
               cascade_delete => 1, #defaults to 0
               cascade_copy   => 1, #defaults to 0

           },
           password => {
               class  => 'YourApp::DB::Password',
               column => 'password_id',
           },
       }
   );

Your application:

   # load other model classes
   DBIx::Class::Bootstrap::Simple->build_relations;
   my $schema = DBIx::Class::Bootstrap::Simple->connect(sub { });

   # on a connection basis
   $schema->storage->DESTROY;
   my $dbh = DBI->connect(..., {  RaiseError => 1 });
   $schema->storage->connect_info([{
       dbh_maker => sub { $dbh }
   }]);
   
   sub db
   {
       my ($self, $table) = @_;
   
       die "invalid table name: $table"
           unless $DBIx::Class::Bootstrap::Simple::CONFIG{$table};

       return $schema->model($table);
   }

=cut

use base qw/DBIx::Class::Schema DBIx::Class::Core/;

__PACKAGE__->load_namespaces;

our %CONFIG;

=head1 METHODS

=head2 init

The init method should be called in every "table package", it configures DBIx::Class::Bootstrap::Simple 
with the table's schema.

   __PACKAGE__->init(
       table       => 'users',
       primary_key => 'user_id',
       definition  => [
           {
              key     => 'user_id',
              type    => 'INT(11)',
              special => 'AUTO_INCREMENT',
              null    => 0,
              primary => 1,
           },
           {
               key   => 'company_id',
               type  => 'INT',
           },
           {
              key     => 'password_id',
              type    => 'INT(11)',
           },
           {
              key     => 'stash',
              type    => 'BLOB',
           },
       },
       # link datetime objects here as well
       objects => {
           # class must have an inflate and deflate method
           # inflate method is Class->inflate(value_to_inflate)
           # deflate is $yourinflated_object->deflate;
           stash => 'YourApp::DB::DataType::Stash',
       },
       references  => {
           company => {
               class          => 'YourApp::DB::Company',
               column         => 'company_id',
               cascade_update => 1, # defaults to 0
               cascade_delete => 1, # defaults to 0
               cascade_copy   => 1, # defaults to 0

           },
           password => {
               class  => 'YourApp::DB::Password',
               column => 'password_id',
           },
           banjos => {
               class  => 'YourApp::DB::Banjos',
               column => 'user_id', 
               # or, if mapping columns differ
               local_column   => 'banjo_user_id',
               foreign_column => 'eskimo_banjo_user_id',
           },

       }
   );


=cut

sub init
{
    my ($class, %params) = @_;

    $class = $params{class} if $params{class};

    $CONFIG{$class}{TABLE_NAME}      = $params{table};
    $CONFIG{$class}{PRIMARY_KEY}     = $params{primary_key};
    $CONFIG{$class}{REFERENCE_TABLE} = $params{references} || {};
    $CONFIG{$class}{OBJECTS}         = $params{objects}    || {};
    $CONFIG{$class}{DEFINITION}      = $params{definition} || [];
    $CONFIG{$class}{NONLOCAL}        = $params{nonlocal};

    $CONFIG{$class}{COLUMNS}         = [];

    push @{$CONFIG{$class}{COLUMNS}}, $_->{key}
        for @{ $params{definition} || [] };

    # reverse mapping
    $CONFIG{$params{table}}          = $class;

    my @columns =
        map { $_->{key} } @{ $params{definition} || [] };

    $class->table($params{table});
    $class->source_name("$class");
    $class->add_columns(@columns);
    $class->set_primary_key($params{primary_key});

    for my $rkey (keys %{ $params{references} || { } })
    {
        my $reference  = $params{references}{$rkey};
        my $local_col  = $reference->{local_column}   || $reference->{column};
        my $remote_col = $reference->{foreign_column} || $reference->{column};
        {
            no strict 'refs';
            no warnings 'redefine';
            *{"$class\:\:$rkey"} = sub { shift->$local_col(@_) };
        }
    }

    $CONFIG{$class}{OBJECTS} ||= {};

    my $i = 0;
    if (my $type_map = $class->object_type_map)
    {
        for my $column (@columns) {
            my $definition = $CONFIG{$class}{DEFINITION}[$i];
            if (my $object_class = $type_map->{lc($definition->{type})})
            {
                $CONFIG{$class}{OBJECTS}{$column} = $object_class;
            }
            $i++;
        }
    }

    for my $okey (keys %{ $CONFIG{$class}{OBJECTS} || { }})
    {
        my $obj = $CONFIG{$class}{OBJECTS}{$okey};

        {
            no strict 'refs';
            my $def = join('::', $obj, 'deflate');

            $class->inflate_column($okey, {
                inflate => sub { $obj->inflate(shift) },
                deflate => sub { &$def(shift) },
            });
        }
    }

    $class->resultset_class($class->override_resultset_class)
        if $class->override_resultset_class;

    __PACKAGE__->source_registrations->{$class} =
        $class->result_source_instance;
}

=head2 build_relations

Builds relationship mapping for used schema modules.

=cut

sub build_relations
{
    for my $module (keys %CONFIG)
    {
        my $table_conf = $CONFIG{$module};
        next unless ref $table_conf;

        for my $rkey (keys %{ $table_conf->{REFERENCE_TABLE} || { } })
        {
            my $reference  = $table_conf->{REFERENCE_TABLE}{$rkey};
            my $local_col  = $reference->{local_column}   || $reference->{column};
            my $remote_col = $reference->{foreign_column} || $reference->{column};
            my $table      = $table_conf->{table};

            {
                if ($reference->{has_many})
                {
                    $module->has_many(
                        $rkey, $reference->{class},
                        { "foreign.$remote_col", "self.$local_col" },
                        {
                            cascade_delete => $reference->{cascade_delete} || 0,
                            cascade_copy   => $reference->{cascade_copy}   || 0,
                            cascade_update => $reference->{cascade_update} || 0,
                            accessor       => 'multi',
                        },
                    );
                    $reference->{class}->belongs_to( $remote_col => $module );
                }
                else
                {
                    my $meth = $reference->{might_have} ? 'might_have' : 'has_one';

                    $module->$meth(
                        $local_col, $reference->{class},
                        { "foreign.$remote_col", "self.$local_col" },
                        {
                            cascade_delete => $reference->{cascade_delete} || 0,
                            cascade_copy   => $reference->{cascade_copy}   || 0,
                            cascade_update => $reference->{cascade_update} || 0,
                            accessor       => 'filter',
                        },
                    );
                }
            }
        }
    }
}

sub _nonlocal 
{ 
    my $class      = shift; 
    my $class_name = ref $class ? ref $class : $class; 

    return $CONFIG{$class}{NONLOCAL};
}

sub _definition 
{ 
    my $class      = shift; 
    my $class_name = ref $class ? ref $class : $class; 

    return $CONFIG{$class}{DEFINITION};
}

sub _primary_key {
    my $self  = shift;
    my $class = ref $self;
    my $pk    = $CONFIG{$class}{PRIMARY_KEY};
    return $pk;
}

=head2 dbh

Returns raw dbh handle.

=cut

sub dbh            { shift->result_source->storage->dbh }

=head2 begin_work

Begin a transaction.

=cut

sub begin_work     { shift->result_source->storage->txn_begin }

=head2 commit_work

Commit a transaction.

=cut

sub commit_work    { shift->result_source->storage->txn_commit }

=head2 rollback_work

Rollback a transaction.

=cut

sub rollback_work  { shift->result_source->storage->txn_rollback }

=head2 rs

Returns a resultset.

=cut

sub rs
{
    my $self = shift;

    return $self->result_source->resultset;
}

=head2 create

Mapping to resultset->create(...)

=cut

sub create         { shift->rs->create(@_)         }

=head2 search

Mapping to resultset->search(...)

=cut

sub search         { shift->rs->search(@_)         }

=head2 search_rs

Mapping to resultset->search_rs(...)

=cut

sub search_rs      { shift->rs->search_rs(@_)      }

=head2 find

Mapping to resultset->find(...)

=cut

sub find           { shift->rs->find(@_)           }

=head2 find_or_create

Mapping to resultset->find_or_create(...)

=cut

sub find_or_create { shift->rs->find_or_create(@_) }

=head2 model

Given a table name as an argument, return a resultset from a table name.

Example:

  DBIx::Class::Bootstrap::Simple->model('users')->create({ name => 'Moon Panda' });

=cut

sub model
{
    my ($self, $table) = @_;

    my $source = $self->{_result_source} ? $self->result_source->schema : $self;
    die "$table does not exist" unless $CONFIG{$table};

    my $rs  = $source->resultset($CONFIG{$table});
    my $obj = $rs->new({ });

    return $obj;
}

=head1 METHODS TO SUBCLASS

=head2 override_resultset_class

Subclass this to change the resultset class.

=cut 

sub override_resultset_class { '' }

=head2 object_type_map

This provides a default mapping of objects for inflation.

An example may be:

sub object_type_map {
    return {
        date => 'Your:::DateTime::Package',
    }
}  

=cut

sub object_type_map { return { } }

=head1 COPYRIGHT

Copyright 2012 Ohio-Pennsylvania Software, LLC.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

2012 Ohio-Pennsylvania Software, LLC

=cut

1;
