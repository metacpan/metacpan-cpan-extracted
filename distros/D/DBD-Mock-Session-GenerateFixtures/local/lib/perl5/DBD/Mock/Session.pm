package DBD::Mock::Session;

use strict;
use warnings;

my $INSTANCE_COUNT = 1;

# - Class - #

sub new {
    my $class = shift;
    my $name = ref( $_[0] ) ? "Session $INSTANCE_COUNT" : shift;
    $INSTANCE_COUNT++;

    $class->_verify_states( $name, @_ );

    bless {
        name        => $name,
        states      => \@_,
        state_index => 0
    }, $class;
}

sub _verify_state {
    my ( $class, $state, $index, $name ) = @_;

    die "You must specify session states as HASH refs"
      if ref($state) ne 'HASH';

    die "Bad state '$index' in DBD::Mock::Session ($name)"
      if not exists $state->{statement}
          or not exists $state->{results};

    my $stmt = $state->{statement};
    my $ref  = ref $stmt;

    die "Bad 'statement' value '$stmt' in DBD::Mock::Session ($name)",
      if ref($stmt) ne ''
          and $ref ne 'CODE'
          and $ref ne 'Regexp';
}

sub _verify_states {
    my ( $class, $name, @states ) = @_;

    die "You must specify at least one session state"
      if scalar @states == 0;

    for ( 0 .. scalar @states - 1 ) {
        $class->_verify_state( $states[$_], $_, $name );
    }
}

# - Instance - #

sub name {
    my $self = shift;
    $self->{name};
}

sub reset {
    my $self = shift;
    $self->{state_index} = 0;
}

sub current_state {
    my $self = shift;
    my $idx  = $self->{state_index};
    return $self->{states}[$idx];
}

sub has_states_left {
    my $self = shift;
    return $self->{state_index} < $self->_num_states;
}

sub verify_statement {
    my ( $self, $got ) = @_;

    unless ( $self->has_states_left ) {
        die "Session states exhausted, only '"
          . $self->_num_states
          . "' in DBD::Mock::Session ($self->name})";
    }

    my $state    = $self->current_state;
    my $expected = $state->{statement};
    my $ref      = ref($expected);

    if ( $ref eq 'Regexp' and $got !~ /$expected/ ) {
        die "Statement does not match current state (with Regexp) in "
          . "DBD::Mock::Session ($self->{name})\n"
          . "      got: $got\n"
          . " expected: $expected",

    }

    if ( $ref eq 'CODE' and not $expected->( $got, $state ) ) {
        die "Statement does not match current state (with CODE ref) in "
          . "DBD::Mock::Session ($self->{name})";
    }

    if ( not $ref and $got ne $expected ) {
        die "Statement does not match current state in "
          . "DBD::Mock::Session ($self->{name})\n"
          . "      got: $got\n"
          . " expected: $expected";
    }
}

sub results_for {
    my ( $self, $statment ) = @_;
    $self->_find_state_for($statment)->{results};
}

sub verify_bound_params {
    my ( $self, $params ) = @_;

    my $current_state = $self->current_state;
    if ( exists ${$current_state}{bound_params} ) {
        my $expected = $current_state->{bound_params};

        if ( scalar @$expected != scalar @$params ) {
            die "Not the same number of bound params in current state in "
              . "DBD::Mock::Session ($self->{name})\n"
              . "      got: @{$params}"
              . " expected: @{$expected}";
        }

        for ( 0 .. scalar @{$params} - 1 ) {
            $self->_verify_bound_param( $params->[$_], $expected->[$_], $_ );
        }

    }

    # and make sure we go to
    # the next statement
    $self->{state_index}++;
}

sub _find_state_for {
    my ( $self, $statement ) = @_;

    foreach ( $self->_remaining_states ) {
        my $stmt = $_->{statement};
        my $ref  = ref($stmt);

        return $_ if ( $ref eq 'Regexp' and $statement =~ /$stmt/ );
        return $_ if ( $ref eq 'CODE' and $stmt->( $statement, $_ ) );
        return $_ if ( not $ref and $stmt eq $statement );
    }

    die "Statement '$statement' not found in session ($self->{name})";
}

sub _num_states {
    my $self = shift;
    scalar @{ $self->{states} };
}

sub _remaining_states {
    my $self        = shift;
    my $start_index = $self->{state_index};
    my $end_index   = $self->_num_states - 1;
    @{ $self->{states} }[ $start_index .. $end_index ];
}

sub _verify_bound_param {
    my ( $self, $got, $expected, $index ) = @_;
    no warnings;

    my $ref = ref $expected;

    if ( $ref eq 'Regexp' ) {

        if ( $got !~ /$expected/ ) {
            die "Bound param $index do not match (using regexp) "
              . "in current state in DBD::Mock::Session ($self->{name})"
              . "      got: $got\n"
              . " expected: $expected";
        }

    } elsif ( $got ne $expected ) {
        die "Bound param $index do not match "
          . "in current state in DBD::Mock::Session ($self->{name})\n"
          . "     got: $got\n"
          . " expected: $expected";
    }
}

1;
