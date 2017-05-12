package BPM::Engine::Util::YAMLWorkflowLoader;
BEGIN {
    $BPM::Engine::Util::YAMLWorkflowLoader::VERSION   = '0.01';
    $BPM::Engine::Util::YAMLWorkflowLoader::AUTHORITY = 'cpan:SITETECH';
    }

use Moose;
use Class::Workflow;
extends 'Class::Workflow::YAML';
use namespace::clean;
use Sub::Exporter -setup => { exports => [ qw(load_workflow_from_yaml) ] };

sub empty_workflow {
    my $w = Class::Workflow->new;
    $w->instance_class('Class::Workflow::Instance::Simple');
    $w->transition_class('Class::Workflow::Transition::Simple');
    $w->state_class('BPM::Engine::Class::Workflow::State');
    return $w;
    }

sub load_workflow_from_yaml {
    my ($yaml) = @_;
    my $y = __PACKAGE__->new;
    $y->load_string($yaml);
    }

__PACKAGE__->meta->make_immutable;

## no critic (ProhibitMultiplePackages)
{
package 
  BPM::Engine::Class::Workflow::State;

use namespace::autoclean;
use Moose;

with qw/
    Class::Workflow::State
    Class::Workflow::State::TransitionHash
    Class::Workflow::State::AcceptHooks
    Class::Workflow::State::AutoApply
    /;

has name => (
    isa => "Str",
    is  => "rw",
    );

sub stringify {
    my $self = shift;
    if ( defined( my $name = $self->name ) ) {
        return $name;
        }
    #return overload::StrVal($_[0]);
    die "Unknown state name";
    }

__PACKAGE__->meta->make_immutable;
}

1;
__END__
