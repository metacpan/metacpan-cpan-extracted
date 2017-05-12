package DBD::Mock::StatementTrack;

use strict;
use warnings;

sub new {
    my ( $class, %params ) = @_;

    # these params have default values
    # but can be overridden
    $params{return_data}  ||= [];
    $params{fields}       ||= [];
    $params{bound_params} ||= [];
    $params{statement}    ||= "";
    $params{failure}      ||= undef;

    # these params should never be overridden
    # and should always start out in a default
    # state to assure the sanity of this class
    $params{is_executed}        = 'no';
    $params{is_finished}        = 'no';
    $params{current_record_num} = 0;

    # NOTE:
    # changed from \%params here because that
    # would bind the hash sent in so that it
    # would reflect alterations in the object
    # this violates encapsulation
    my $self = bless {%params}, $class;
    return $self;
}

sub has_failure {
    my ($self) = @_;
    $self->{failure} ? 1 : 0;
}

sub get_failure {
    my ($self) = @_;
    @{ $self->{failure} };
}

sub num_fields {
    my ($self) = @_;
    return scalar @{ $self->{fields} };
}

sub num_rows {
    my ($self) = @_;
    return scalar @{ $self->{return_data} };
}

sub num_params {
    my ($self) = @_;
    return scalar @{ $self->{bound_params} };
}

sub bind_col {
    my ( $self, $param_num, $ref ) = @_;
    $self->{bind_cols}->[ $param_num - 1 ] = $ref;
}

sub bound_param {
    my ( $self, $param_num, $value ) = @_;

    # Basic support for named parameters
    if ( $param_num !~ /^\d+/ ) {
        $param_num = $self->num_params + 1;
    }

    $self->{bound_params}->[ $param_num - 1 ] = $value;
    return $self->bound_params;
}

sub bound_param_trailing {
    my ( $self, @values ) = @_;
    push @{ $self->{bound_params} }, @values;
}

sub bind_cols {
    my $self = shift;
    return @{ $self->{bind_cols} || [] };
}

sub bind_params {
    my ( $self, @values ) = @_;
    @{ $self->{bound_params} } = @values;
}

# Rely on the DBI's notion of Active: a statement is active if it's
# currently in a SELECT and has more records to fetch

sub is_active {
    my ($self) = @_;
    return 0 unless $self->statement =~ /^\s*select/ism;
    return 0 unless $self->is_executed eq 'yes';
    return 0 if $self->is_depleted;
    return 1;
}

sub is_finished {
    my ( $self, $value ) = @_;
    if ( defined $value && $value eq 'yes' ) {
        $self->{is_finished} = 'yes';
        $self->current_record_num(0);
        $self->{return_data} = [];
    }
    elsif ( defined $value ) {
        $self->{is_finished} = 'no';
    }
    return $self->{is_finished};
}

####################
# RETURN VALUES

sub mark_executed {
    my ($self) = @_;
    $self->is_executed('yes');
    $self->current_record_num(0);
}

sub next_record {
    my ($self) = @_;
    return if $self->is_depleted;
    my $rec_num = $self->current_record_num;
    my $rec     = $self->return_data->[$rec_num];
    $self->current_record_num( $rec_num + 1 );
    return $rec;
}

sub is_depleted {
    my ($self) = @_;
    return ( $self->current_record_num >= scalar @{ $self->return_data } );
}

# DEBUGGING AID

sub to_string {
    my ($self) = @_;
    return join "\n" => (
        $self->{statement},
        "Values: [" . join( '] [', @{ $self->{bound_params} } ) . "]",
        "Records: on $self->{current_record_num} of "
          . scalar( @{ $self->return_data } ) . "\n",
        "Executed? $self->{is_executed}; Finished? $self->{is_finished}"
    );
}

# PROPERTIES

# boolean

sub is_executed {
    my ( $self, $yes_no ) = @_;
    $self->{is_executed} = $yes_no if defined $yes_no;
    return ( $self->{is_executed} eq 'yes' ) ? 'yes' : 'no';
}

# single-element fields

sub statement {
    my ( $self, $value ) = @_;
    $self->{statement} = $value if defined $value;
    return $self->{statement};
}

sub current_record_num {
    my ( $self, $value ) = @_;
    $self->{current_record_num} = $value if defined $value;
    return $self->{current_record_num};
}

# multi-element fields

sub return_data {
    my ( $self, @values ) = @_;
    push @{ $self->{return_data} }, @values if scalar @values;
    return $self->{return_data};
}

sub fields {
    my ( $self, @values ) = @_;
    push @{ $self->{fields} }, @values if scalar @values;
    return $self->{fields};
}

sub bound_params {
    my ( $self, @values ) = @_;
    push @{ $self->{bound_params} }, @values if scalar @values;
    return $self->{bound_params};
}

1;
