package App::NDTools::NDPatch;

use strict;
use warnings FATAL => 'all';
use parent 'App::NDTools::NDTool';

use App::NDTools::Slurp qw(s_dump);
use Log::Log4Cli;
use Struct::Diff 0.96 qw();

our $VERSION = '0.09';

sub arg_opts {
    my $self = shift;

    return (
        $self->SUPER::arg_opts(),
    );
}

sub check_args {
    my $self = shift;

    die_fatal "One or two arguments expected", 1
        if (@{$self->{ARGV}} < 1 or @{$self->{ARGV}} > 2);

    return $self;
}

sub defaults {
    my $self = shift;

    return {
        %{$self->SUPER::defaults()},
    };
}

sub dump {
    my ($self, $uri, $struct) = @_;

    log_debug { "Restoring structure to '$uri'" };
    s_dump($uri, $self->{OPTS}->{ofmt},
        {pretty => $self->{OPTS}->{pretty}}, $struct);
}

sub exec {
    my $self = shift;

    my $uri = shift @{$self->{ARGV}};
    my $struct = $self->load_struct($uri, $self->{OPTS}->{ifmt});
    my $patch = $self->load_patch(
        @{$self->{ARGV}} ? shift @{$self->{ARGV}} : \*STDIN,
        $self->{OPTS}->{ifmt}
    );

    $self->patch($struct, $patch);
    $self->dump($uri, $struct);

    die_info "All done", 0;
}

sub load_patch {
    shift->load_struct(@_);
}

sub patch {
    my ($self, $struct, $patch) = @_;

    eval { Struct::Diff::patch($struct, $patch) };
    die_fatal "Failed to patch structure ($@)", 8 if ($@);
}

1; # End of App::NDTools::NDPatch
