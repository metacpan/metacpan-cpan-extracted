package TestML;

use TestML::Base;
our $VERSION = '0.49';

has runtime => ();
has compiler => ();
has bridge => ();
has library => ();
has testml => ();

sub run {
    my ($self) = @_;
    $self->set_default_classes;
    $self->runtime->new(
        compiler => $self->compiler,
        bridge => $self->bridge,
        library => $self->library,
        testml => $self->testml,
    )->run;
}

sub set_default_classes {
    my ($self) = @_;
    if (not $self->runtime) {
        require TestML::Runtime::TAP;
        $self->{runtime} = 'TestML::Runtime::TAP';
    }
    if (not $self->compiler) {
        require TestML::Compiler::Pegex;
        $self->{compiler} = 'TestML::Compiler::Pegex';
    }
    if (not $self->bridge) {
        require TestML::Bridge;
        $self->{bridge} = 'TestML::Bridge';
    }
    if (not $self->library) {
        require TestML::Library::Standard;
        require TestML::Library::Debug;
        $self->{library} = [
            'TestML::Library::Standard',
            'TestML::Library::Debug',
        ];
    }
}

1;
