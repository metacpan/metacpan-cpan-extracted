
# general purpose undo and redo functionality for scalar values and with special powers

package App::GUI::Cellgraph::Compute::History;
use v5.12;

sub new {
    my ($pkg, ) = @_;
    bless { present => undef, past => [], future => [],
            guard => '', merge => '',  last_merge_data => [] };
}

#### code ref setter ###################################################
sub set_guard_condition { # code ref that checks if data is well formed or passes as wanted type
    my ($self, $condition) = @_;
    return unless ref $condition eq 'CODE'; # return 1 if data good
    $self->{'guard'} = $condition;
}
sub set_merge_condition { # code ref that checks if data just replaces present state
    my ($self, $condition) = @_;
    return unless ref $condition eq 'CODE'; # return 1 if data should replace presently held
    $self->{'merge'} = $condition;
}

#### predicates / getter ###############################################
sub can_undo      { int ((@{$_[0]->{'past'}}) > 0) }
sub can_redo      { int ((@{$_[0]->{'future'}}) > 0) }

sub current_value { $_[0]->{'present'} if defined $_[0]->{'present'} }
sub prev_value    { $_[0]->{'past'}[-1] if $_[0]->can_undo }
sub next_value    { $_[0]->{'future'}[0] if $_[0]->can_redo }

#### worker methods ####################################################
sub reset {
    my ($self, $full) = @_;
    $self->{'past'} = [];
    $self->{'future'} = [];
    $self->{'present'} = undef if defined $full and $full;
}

sub add_value {
    my ($self, $value, @data) = @_;
    return unless defined $value;
    return if defined $self->{'present'} and $value eq $self->{'present'};
    return if $self->{'guard'} and not $self->{'guard'}->($value);
    my $replace_present = 0;
    if ($self->{'merge'} and @data) {
        $replace_present = $self->{'merge'}->( [@data], $self->{'last_merge_data'} );
        $self->{'last_merge_data'} = [@data];
    }
    push @{$self->{'past'}}, $self->{'present'} if not $replace_present and defined $self->{'present'};
    $self->{'future'} = [];
    $self->{'present'} = $value;
}

sub undo {
    my ($self) = @_;
    return unless $self->can_undo;
    unshift @{ $self->{'future'} }, $self->{'present'};
    $self->{'present'} = pop @{ $self->{'past'} };
}

sub redo {
    my ($self) = @_;
    return unless $self->can_redo;
    push @{ $self->{'past'} }, $self->{'present'};
    $self->{'present'} = shift @{ $self->{'future'} };
}

1;
