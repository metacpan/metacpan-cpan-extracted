package App::MadEye;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.13';
use Class::Component;
use Params::Validate;
use UNIVERSAL::require;
use Log::Dispatch;
__PACKAGE__->load_components(qw/Plaggerize Autocall::InjectMethod/);

my $context;
sub context { $context }

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{results} = {};
    $context = $self;

    $self->_setup_logger;

    $self;
}

sub run {
    my $self = shift;
    $self->log(debug => 'run');

    unless (defined $self->class_component_methods->{'run_job'}) {
        $self->log(debug => 'use Worker::Simple');
        $self->load_plugins(
            {
                module => 'Worker::Simple',
                config => { config => { task_timeout => 10 } }
            }
        );
    }

    $self->run_hook('check');

    $self->run_hook('before_run_jobs');

        $self->run_hook('run_jobs');

    $self->run_hook('after_run_jobs');

    if (%{$self->{results}}) {
        for my $obj ( @{ $self->class_component_hooks->{notify} } ) {
            my ( $plugin, $method ) = ( $obj->{plugin}, $obj->{method} );
            if ($self->_should_run( plugin => $plugin )) {
                $plugin->$method($self, $self->{results});
            }
        }
    }

    $self->log(debug => 'finished');
}

sub add_result {
    my $self = shift;
    validate(
        @_ => +{
            plugin  => 1,
            target  => 1,
            message => 1,
        }
    );
    my $args = {@_};

    return unless $self->_should_add_result(target => $args->{target}, plugin => $args->{plugin});

    push @{$self->{results}->{ref $args->{plugin}}}, +{
        target  => $args->{target},
        message => $args->{message},
    };
}

sub _should_add_result {
    my $self = shift;
    validate(
        @_ => +{
            plugin => 1,
            target => 0,
        }
    );
    my $args = {@_};

    if ($args->{plugin}->config->{rule}) {
        for my $rule_conf ( @{ $args->{plugin}->config->{rule} } ) {
            my $rule = $self->_load_rule($rule_conf);
            my $ret = $rule->dispatch(
                $self,
                +{
                    plugin => $args->{plugin},
                    ($args->{target} ? ( target => $args->{target}) : () ),
                }
            );
            return 0 if $ret;
        }
    }
    return 1;
}
*_should_run = *_should_add_result;

sub _load_rule {
    my ($self, $rule) = @_;

    my $class = $rule->{module};
    if ($class =~ /^\+/) {
        $class =~ s/^\+//;
    } else {
        $class = __PACKAGE__ . '::Rule::' . $class;
    }
    $class->use or die $@;
    return $class->new($rule->{config});
}

sub _setup_logger {
    my $self = shift;

    my $logger = Log::Dispatch->new;
    for my $conf (@{ $self->conf->{global}->{logger} || [] }) {
        my $class = "Log::Dispatch::$conf->{class}";
        $class->use or die $@;
        $logger->add( $class->new( %{ $conf->{config} } ) );
    }
    $self->{logger} = $logger;
}

sub log {
    my ($self, $level, $msg) = @_;
    die "missing level" unless $level;
    die "missing msg" unless $msg;

    $self->{logger}->log( level => $level, message => "[$level] $msg\n" );
}

1;
__END__

=encoding utf8

=head1 NAME

App::MadEye - enterprise-class monitoring solutions

=head1 SYNOPSIS

    ./madeye.pl -c config.yaml

=head1 WARNINGS

THIS SOFT IS UNDER DEVELOPMENT.STILL UNDER BETA QUALITY.

=head1 DESCRIPTION

App::MadEye is enterprise-class monitoring solutions.

    - use Class::Component
    - Plagger style
    - Plagger like rule

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom GMAIL COME<gt>

=head1 SEE ALSO

L<App::MadEye>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
