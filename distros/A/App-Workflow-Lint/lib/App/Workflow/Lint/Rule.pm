package App::Workflow::Lint::Rule;

use strict;
use warnings;
use Carp qw(croak carp);

#----------------------------------------------------------------------
# Base class for all lint rules.
#----------------------------------------------------------------------

sub new {
    my ($class, %opts) = @_;
    return bless { %opts }, $class;
}

#----------------------------------------------------------------------
# Metadata DSL
#----------------------------------------------------------------------

sub id          { croak ref($_[0]) . " must implement id()" }
sub description { croak ref($_[0]) . " must implement description()" }
sub level       { 'warning' }
sub applies_to  { 'workflow' }

#----------------------------------------------------------------------
# Diagnostic builder
#----------------------------------------------------------------------

sub diag {
    my ($self, %args) = @_;

    my $engine = $args{engine};
    my $line   = $engine
        ? $engine->line_for_path($args{file}, $args{path})
        : undef;

    return {
        rule    => $self->id,
        level   => $self->level,
        message => $args{message},
        path    => $args{path} // '/',
        file    => $args{file},
        line    => $line,
        fix     => $args{fix},
    };
}


#----------------------------------------------------------------------
# Scope-aware dispatcher
#----------------------------------------------------------------------

sub check {
    my ($self, $wf, $ctx) = @_;

    my $scope = $self->applies_to;

    if ($scope eq 'workflow') {
        return $self->check_workflow($wf, $ctx);
    }
    elsif ($scope eq 'job') {
        my @out;
        for my $job_name (keys %{ $wf->{jobs} // {} }) {
            my $job = $wf->{jobs}{$job_name};
            push @out, $self->check_job($job, { %$ctx, job_name => $job_name });
        }
        return @out;
    }
    elsif ($scope eq 'step') {
        my @out;
        for my $job_name (keys %{ $wf->{jobs} // {} }) {
            my $job = $wf->{jobs}{$job_name};
            for my $i (0 .. $#{ $job->{steps} // [] }) {
                my $step = $job->{steps}[$i];
                push @out, $self->check_step($step, {
                    %$ctx,
                    job_name   => $job_name,
                    step_index => $i,
                });
            }
        }
        return @out;
    }

    croak "Unknown applies_to scope '$scope' in rule " . $self->id;
}

# Default no-op implementations
sub check_workflow { return () }
sub check_job      { return () }
sub check_step     { return () }

1;

