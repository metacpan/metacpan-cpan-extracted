package App::Workflow::Lint::Rule::UnpinnedActions;

use strict;
use warnings;
use Carp qw(croak carp);
use parent 'App::Workflow::Lint::Rule';

sub id          { 'unpinned-actions' }
sub description { 'Actions should be pinned to a specific version or SHA' }
sub applies_to  { 'step' }
sub level       { 'warning' }

sub check_step {
    my ($self, $step, $ctx) = @_;

    return () unless exists $step->{uses};

    my $uses = $step->{uses};

    # Must contain @version
    return $self->diag(
        message => "Action '$uses' is not pinned to a version",
        path    => "/jobs/$ctx->{job_name}/steps/$ctx->{step_index}",
        file    => $ctx->{file},
    ) unless $uses =~ /\@/;

    # Disallow @master, @main, @latest
    return $self->diag(
        message => "Action '$uses' uses an unsafe tag",
        path    => "/jobs/$ctx->{job_name}/steps/$ctx->{step_index}",
        file    => $ctx->{file},
    ) if $uses =~ /\@(master|main|latest)$/;

    return ();
}

1;

