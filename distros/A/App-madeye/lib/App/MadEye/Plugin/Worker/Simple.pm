package App::MadEye::Plugin::Worker::Simple;
use strict;
use warnings;
use base qw/App::MadEye::Plugin::Base/;
use App::MadEye::Util;
use Params::Validate;

sub run_job :Method {
    my ($self, $context, $args) = @_;

    $context->log( debug => "watching $args->{target} by $args->{plugin}" );

    my $timeout = $self->config->{config}->{task_timeout} or die "missing task_timeout";

    my $error = timeout $timeout, "watching $args->{target} $args->{plugin}", sub {
        if ( my $message = $args->{plugin}->is_dead( $args->{target} ) ) {
            $context->add_result(
                plugin  => $args->{plugin},
                target  => $args->{target},
                message => $message,
            );
        }
    };

    if ($error) {
        $context->add_result(
            plugin  => $args->{plugin},
            target  => $args->{target},
            message => $error,
        );
    }

    $context->log( debug => "finished $args->{target} by $args->{plugin}" );
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Worker::Simple - simple worker

=head1 SCHEMA

    type: map
    mapping:
        task_timeout:
            required: yes
            type: int

=head1 SEE ALSO

L<App::MadEye>
