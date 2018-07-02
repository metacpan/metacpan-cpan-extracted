package Data::MuForm::Role::Model::DBIC;

# ABSTRACT: model role that interfaces with DBIx::Class

use Moo::Role;

use Carp;
use DBIx::Class::ResultClass::HashRefInflator;
use DBIx::Class::ResultSet::RecursiveUpdate;
use Scalar::Util ('blessed');
use Types::Standard -types;

has 'schema' => ( is => 'rw', );

has unique_constraints => (
    is         => 'ro',
    isa        => ArrayRef,
    lazy       => 1,
    builder => '_build_unique_constraints',
);

sub _build_unique_constraints {
    my $self = shift;
    return [ grep { $_ ne 'primary' }
            $self->resultset->result_source->unique_constraint_names ];
}

has unique_messages => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

sub use_model_for_defaults {
    my $self = shift;
    return ( $self->model && $self->model->in_storage ? 1 : 0 );
}

sub validate_model {
    my ($self) = @_;
    return unless $self->validate_unique;
    return 1;
}

sub clear_model {
    my $self = shift;
    $self->model(undef);
    $self->model_id(undef);
}

sub update_model {
    my $self   = shift;
    my $model   = $self->model;
    my $source = $self->source;

    my %update_params = (
        resultset => $self->resultset,
        updates   => $self->values,
        unknown_params_ok => 1,
    );
    $update_params{object} = $self->model if $self->model;
    my $new_model;

    # perform update in a transaction, since RecursiveUpdate may do multiple
    # updates if there are compound or multiple fields
    $self->schema->txn_do(
        sub {
            $new_model = DBIx::Class::ResultSet::RecursiveUpdate::Functions::recursive_update(
                %update_params);
            $new_model->discard_changes;
        }
    );
    $self->model($new_model) if $new_model;
    return $self->model;
}


sub lookup_options {
    my ( $self, $field, $accessor_path ) = @_;

    return unless $self->schema;
    my $self_source = $self->get_source($accessor_path);

    my $accessor = $field->accessor;

    # if this field doesn't refer to a foreign key, return
    my $f_class;
    my $source;

    # belongs_to single select
    if ( $self_source->has_relationship($accessor) ) {
        $f_class = $self_source->related_class($accessor);
        $source  = $self->schema->source($f_class);
    }
    else {

        # check for many_to_many multiple select
        my $resultset = $self_source->resultset;
        my $new_result = $resultset->new_result( {} );
        if ( $new_result && $new_result->can("add_to_$accessor") ) {
            $source = $new_result->$accessor->result_source;
        }
    }
    return unless $source;

    my $label_column = $field->label_column;
    return
        unless ( $source->has_column($label_column) ||
        $source->result_class->can($label_column) );

    my $active_col = $field->active_column;
    $active_col = '' unless $source->has_column($active_col);
    my $sort_col = $field->sort_column;
    my ($primary_key) = $source->primary_columns;

    # if no sort_column and label_column is a source method, not a real column, must
    # use some other column for sort. There's probably some other column that should
    # be specified, but this will prevent breakage
    if ( !defined $sort_col ) {
        $sort_col = $source->has_column($label_column) ? $label_column : $primary_key;
    }

    # If there's an active column, only select active OR models already selected
    my $criteria = {};
    if ($active_col) {
        my @or = ( $active_col => 1 );

        # But also include any existing non-active
        push @or, ( "$primary_key" => $field->init_value )
            if $self->model && defined $field->init_value;
        $criteria->{'-or'} = \@or;
    }

    # get an array of row objects
    my @rows =
        $self->schema->resultset( $source->source_name )
        ->search( $criteria, { order_by => $sort_col } )->all;
    my @options;
    foreach my $row (@rows) {
        my $label = $row->$label_column;
        next unless defined $label;    # this means there's an invalid value
        push @options, $row->id, $active_col && !$row->$active_col ? "[ $label ]" : "$label";
    }
    return \@options;
}

sub init_value {
    my ( $self, $field, $value ) = @_;
    if ( ref $value eq 'ARRAY' ) {
        $value = [ map { $self->_fix_value( $field, $_ ) } @$value ];
    }
    else {
        $value = $self->_fix_value( $field, $value );
    }
    $field->init_value($value);
    $field->value($value);
}

sub _fix_value {
    my ( $self, $field, $value ) = @_;
    if ( blessed $value && $value->isa('DBIx::Class') ) {
        return $value->id;
    }
    return $value;
}

sub _get_related_source {
    my ( $self, $source, $name ) = @_;

    if ( $source->has_relationship($name) ) {
        return $source->related_source($name);
    }

    # many to many case
    my $row = $source->resultset->new( {} );
    if ( $row->can($name) and
        $row->can( 'add_to_' . $name ) and
        $row->can( 'set_' . $name ) )
    {
        return $row->$name->result_source;
    }
    return;
}

# this needs to be rewritten to be called at the field level
# right now it will only work on fields immediately contained
# by the form
sub validate_unique {
    my ($self) = @_;

    my $rs          = $self->resultset;
    my $found_error = 0;
    my $fields      = $self->fields;

    my @id_clause = ();
    @id_clause = _id_clause( $rs, $self->model_id ) if defined $self->model;

    my $value = $self->value;
    for my $field (@$fields) {
        next unless $field->unique;
        next if $field->is_inactive;
        next if $field->has_errors;
        my $value = $field->value;
        next unless defined $value;
        my $accessor = $field->accessor;

        my $count = $rs->search( { $accessor => $value, @id_clause } )->count;
        next if $count < 1;
        my $field_error = $field->get_message('unique') || $field->unique_message || 'Duplicate value for [_1]';
        $field->add_error( $field_error, $field->loc_label );
        $found_error++;
    }

    # validate unique constraints in the model
    for my $constraint ( @{ $self->unique_constraints } ) {
        my @columns = $rs->result_source->unique_constraint_columns($constraint);

        # check for matching field in the form
        my $field;
        for my $col (@columns) {
            ($field) = grep { $_->accessor eq $col } @$fields;
            last if $field;
        }
        next unless defined $field;
        next if ( $field->has_unique );    # already handled or don't do

        my @values = map {
            exists( $value->{$_} ) ? $value->{$_} : undef ||
                ( $self->model ? $self->model->get_column($_) : undef )
        } @columns;

        next
            if @columns !=
                @values; # don't check unique constraints for which we don't have all the values
        next
            if grep { !defined $_ } @values;   # don't check unique constraints with NULL values

        my %where;
        @where{@columns} = @values;
        my $count = $rs->search( \%where )->search( {@id_clause} )->count;
        next if $count < 1;

        my $field_error = $self->unique_message_for_constraint($constraint);
        $field->add_error( $field_error, $constraint );
        $found_error++;
    }

    return $found_error;
}

sub unique_message_for_constraint {
    my $self       = shift;
    my $constraint = shift;

    return $self->unique_messages->{$constraint} ||=
        "Duplicate value for [_1] unique constraint";
}

sub _id_clause {
    my ( $resultset, $id ) = @_;

    my @pks = $resultset->result_source->primary_columns;
    my %clause;
    # multiple primary key
    if ( scalar @pks > 1 ) {
        die "multiple primary key invalid" if ref $id ne 'ARRAY';
        my $cond = $id->[0];
        my @phrase;
        foreach my $col ( keys %$cond ) {
            $clause{$col} = { '!=' => $cond->{$col} };
        }
    }
    else {
        %clause = ( $pks[0] => { '!=' => $id } );
    }
    return %clause;
}

sub build_model {
    my $self = shift;

    my $model_id = $self->model_id or return;
    my $model = $self->resultset->find( ref $model_id eq 'ARRAY' ? @{$model_id} : $model_id );
    $self->model_id(undef) unless $model;
    return $model;
}

sub set_model {
    my ( $self, $model ) = @_;
    return unless $model;

    # when the model (DBIC row) is set, set the model_id, model_class
    # and schema from the model
    my @primary_columns = $model->result_source->primary_columns;
    my $model_id;
    if ( @primary_columns == 1 ) {
        $model_id = $model->get_column( $primary_columns[0] );
    }
    elsif ( @primary_columns > 1 ) {
        my @pks = map {  $_ => $model->get_column($_) } @primary_columns;
        $model_id = [ { @pks }, { key => 'primary' } ];
    }
    if ($model_id) {
        $self->model_id($model_id);
    }
    else {
        $self->clear_model_id;
    }
    $self->model_class( $model->result_source->source_name );
    $self->schema( $model->result_source->schema );
}

sub set_model_id {
    my ( $self, $model_id ) = @_;

    # if a new model_id has been set
    # clear an existing model
    if ( defined $self->model ) {
        $self->clear_model
            if (
            !defined $model_id ||
            ( ref $model_id eq 'ARRAY' &&
                join( '', @{$model_id} ) ne join( '', $self->model->id ) ) ||
            ( ref \$model_id eq 'SCALAR' &&
                $model_id ne $self->model->id )
            );
    }
}

sub source {
    my ( $self, $f_class ) = @_;
    return $self->schema->source( $self->model_class );
}

sub resultset {
    my ( $self, $f_class ) = @_;
    die "You must supply a schema for your MuForm form"
        unless $self->schema;
    return $self->schema->resultset( $self->model_class );
}

sub get_source {
    my ( $self, $accessor_path ) = @_;
    return unless $self->schema;
    my $source = $self->source;
    return $source unless $accessor_path;
    my @accessors = split /\./, $accessor_path;
    for my $accessor (@accessors) {
        $source = $self->_get_related_source( $source, $accessor );
        die "unable to get source for $accessor" unless $source;
    }
    return $source;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Role::Model::DBIC - model role that interfaces with DBIx::Class

=head1 VERSION

version 0.03

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
