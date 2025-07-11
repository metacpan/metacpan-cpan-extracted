package Example::Model::Stringification;

use Moose;

has '_append' => (
    is      => 'rw',
    default => sub { [] },
);

sub method1 {
    my ($self, $arg) = @_;
    my $current = $self->_append;
    $self->_append([@$current, $arg]);
    return $self;
}

sub method2 {
    my ($self, $arg) = @_;
    my $current = $self->_append;
    $self->_append([@$current, $arg]);
    return $self;
}

sub clear {
    my ($self) = @_;
    $self->_append([]);
    return $self;
}

sub to_safe_string {
    my ($self, $template) = @_;
    my @parts = map { ref($_) eq 'CODE' ? $_->() : $_ } @{$self->_append};
    return my $safe = $template->safe_concat(@parts);
}

__PACKAGE__->meta->make_immutable;
