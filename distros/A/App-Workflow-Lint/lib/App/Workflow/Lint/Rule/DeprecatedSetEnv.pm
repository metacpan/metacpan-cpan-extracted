package App::Workflow::Lint::Rule::DeprecatedSetEnv;

use strict;
use warnings;
use Carp qw(croak carp);
use parent 'App::Workflow::Lint::Rule';

sub id          { 'deprecated-set-env' }
sub description { 'The ::set-env command is deprecated and insecure' }
sub applies_to  { 'step' }
sub level       { 'error' }

sub check_step {
    my ($self, $step, $ctx) = @_;

    return () unless exists $step->{run};

    my $run = $step->{run};

    return () unless $run =~ /::set-env/;

    return $self->diag(
        message => "Deprecated ::set-env command used",
        path    => "/jobs/$ctx->{job_name}/steps/$ctx->{step_index}",
        file    => $ctx->{file},
    );
}

1;

