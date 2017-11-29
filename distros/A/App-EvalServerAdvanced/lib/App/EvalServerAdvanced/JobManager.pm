package App::EvalServerAdvanced::JobManager;

use v5.20;
use strict;
use warnings;
use feature qw(postderef);
no warnings qw(experimental::postderef);

our $VERSION = '0.021';

use Data::Dumper;
use Moo;
use App::EvalServerAdvanced::Config;
use App::EvalServerAdvanced::Log;
use Function::Parameters;
use POSIX qw/dup2 _exit/;

has loop => (is => 'ro');
has workers => (is => 'ro', builder => sub {+{}});
has jobs => (is => 'ro', builder => sub {+{}});

method add_job($eval_obj) {
    my $job_fut = $self->loop->new_future();
    my $prio = $eval_obj->{priority} // "realtime";

    debug "Got job, $prio";
    my $job = {future => $job_fut, eval_obj => $eval_obj};
    push $self->jobs->{$prio}->@*, $job;
    $self->tick(); # start anything if possible
    $job_fut->on_ready(sub {$self->tick()});

    return $job;
}

method run_job($eval_job) {
    my $eval_obj = $eval_job->{eval_obj};
    my $job_future = $eval_job->{future};
    my $out = '';
    my $in = '';

    my ($code_file) = grep {$_->filename eq '__code'} $eval_obj->{files}->@*;
    my $code = $code_file->get_contents;

    my $proc_future;
    my $proc = IO::Async::Process->new(
        code => sub {
            close(STDERR);
            dup2(1,2) or _exit(212); # Setup the C side of things
            *STDERR = \*STDOUT; # Setup the perl side of things
            binmode STDOUT, ":encoding(utf8)"; # these really only affect perl subs, but they should also support other encodings
            binmode STDERR, ":encoding(utf8)";
            binmode STDIN, ":encoding(utf8)";

            $SIG{$_} = sub {_exit(1)} for (keys %SIG);

            eval {
                App::EvalServerAdvanced::Sandbox::run_eval($code, $eval_obj->{language}, $eval_obj->{files});
            };
            if ($@) {
                print "$@";
            }

            _exit(0);
        },
        stdout => {into => \$out},
        # TODO these two things need to be handled differently for encoding
        stdin => {from => Encode::encode("utf8", $in)},
        on_finish => sub { my $out_utf8 = Encode::decode("utf8", $out); $job_future->done($out_utf8) unless $job_future->is_ready; delete $self->workers->{$proc_future}; }
    );

    $proc_future = $self->loop->timeout_future(after => config->jobmanager->timeout // 10);
    $proc_future->on_ready(sub {if ($proc->is_running) {$proc->kill(15); $job_future->fail("timeout") };  delete $self->workers->{$proc_future}; }); # kill the process
    $self->workers->{$proc_future} = $proc_future;

    $self->loop->add($proc);
}

method tick() {
    debug "Tick ", "".$self->workers->%*;
    if (keys $self->workers->%* < config->jobmanager->max_workers) { ## no critic
        my $rtcount =()= $self->jobs->{realtime}->@*;
        # TODO implement deadline jobs properly

        JOB: for my $prio (qw/realtime deadline batch/) {
            # Try to find a non-cancled job
            $self->jobs->{$prio} //= [];
            debug "Searching $prio, ".$self->jobs->{$prio}->@*;
            while(my $candidate = shift $self->jobs->{$prio}->@*) {
                if ($candidate && !$candidate->{canceled}) {
                    $candidate->{running} = 1;

                    $self->run_job($candidate);

                    return 1;
                } 
            }
        }

        return 0; # No jobs found
    } else {
        return 0; # No free workers
    }
}

1;
