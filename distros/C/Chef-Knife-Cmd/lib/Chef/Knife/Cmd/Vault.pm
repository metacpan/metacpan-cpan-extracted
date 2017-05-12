package Chef::Knife::Cmd::Vault;
use Moo;

has knife => (is => 'ro', required => 1, handles => [qw/handle_options run/]);

sub create {
    my ($self, $vault, $item, $values, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife vault create/, $vault, $item);
    push @cmd, $values if $values;
    push @cmd, @opts;
    $self->run(@cmd);
}

sub update {
    my ($self, $vault, $item, $values, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife vault update/, $vault, $item);
    push @cmd, $values if $values;
    push @cmd, @opts;
    $self->run(@cmd);
}

sub delete {
    my ($self, $vault, $item, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife vault delete/, $vault, $item);
    push @cmd, @opts;
    $self->run(@cmd);
}

sub show {
    my ($self, $vault, $item, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife vault show/, $vault);
    push @cmd, $item if $item;
    push @cmd, @opts;
    $self->run(@cmd);
}

sub list {
    my ($self, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife vault list/);
    push @cmd, @opts;
    $self->run(@cmd);
}

sub remove {
    my ($self, $vault, $item, $values, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife vault remove/, $vault, $item);
    push @cmd, $values if $values;
    push @cmd, @opts;
    $self->run(@cmd);
}

sub download {
    my ($self, $vault, $item, $path, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife vault download/, $vault, $item, $path);
    push @cmd, @opts;
    $self->run(@cmd);
}

1;
