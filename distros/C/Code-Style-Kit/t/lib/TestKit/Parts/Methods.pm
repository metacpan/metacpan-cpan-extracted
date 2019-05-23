package TestKit::Parts::Methods;

sub feature_one_export {
    my ($self, $caller) = @_;
    *{"${caller}::one"} = sub { 1 };
}

sub feature_two_export {
    my ($self, $caller) = @_;
    *{"${caller}::two"} = sub { 2 };
    $self->also_export('one');
    $self->maybe_also_export('not_there');
    $self->maybe_also_export('args',[4,5,6]);
}

sub feature_not_two_export {
    my ($self, $caller) = @_;
    die "not two" if $self->is_feature_requested('two');
}

1;
