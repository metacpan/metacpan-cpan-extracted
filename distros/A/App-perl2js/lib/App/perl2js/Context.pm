package App::perl2js::Context;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub clone {
    my ($self, $current_block) = @_;
    my $class = ref($self);
    return bless({
        %$self,
        current_block => $current_block,
    }, $class);
}

sub root {
    my ($self, $root) = @_;
    if ($root) {
        $self->{root} = $root;
        $self->current_block($root);
    } else {
        return $self->{root};
    }
}

sub current_class {
    my ($self, $current_class) = @_;
    if ($current_class) {
        $self->{current_class} = $current_class;
    } else {
        return $self->{current_class};
    }
}

sub current_block {
    my ($self, $current_block) = @_;
    if ($current_block) {
        $self->{current_block} = $current_block;
    } else {
        return $self->{current_block};
    }
}

1;
