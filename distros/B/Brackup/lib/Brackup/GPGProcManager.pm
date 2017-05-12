package Brackup::GPGProcManager;
use strict;
use warnings;
use Brackup::GPGProcess;
use POSIX ":sys_wait_h";

sub new {
    my ($class, $iter, $target) = @_;
    return bless {
        chunkiter => $iter,
        procs     => {},  # "addr(pchunk)" => GPGProcess
        target    => $target,
        procs_running => {}, # pid -> GPGProcess
        uncollected_bytes => 0,
        uncollected_chunks => 0,
    }, $class;
}

sub enc_chunkref_of {
    my ($self, $pchunk) = @_;

    my $proc = $self->{procs}{$pchunk};
    unless ($proc) {
        # catch iterator up to the point that was
        # requested, or blow up.
        my $found = 0;
        my $iters = 0;
        while (my $ich = $self->{chunkiter}->next) {
            if ($ich == $pchunk) {
                $found = 1;
                last;
            }
            $iters++;
            warn "iters = $iters\n";
        }
        die "Not found" unless $found;
        $proc = $self->gen_process_for($pchunk);
    }

    while ($proc->running) {
        my $pid = $self->wait_for_a_process(1) or die
            "No processes were reaped!";
    }

    $self->_proc_summary_dump;
    my ($cref, $enc_length) = $self->get_proc_chunkref($proc);
    $self->_proc_summary_dump;
    $self->start_some_processes;

    return ($cref, $enc_length);
}

sub start_some_processes {
    my $self = shift;

    # eat up any pending zombies
    while ($self->wait_for_a_process(0)) {}

    my $pchunk;
    # TODO: make this stuff configurable/auto-tuned
    while ($self->num_running_procs < 5 &&
           $self->uncollected_chunks < 20 &&
           $self->num_uncollected_bytes < 128 * 1024 * 1024 &&
           ($pchunk = $self->next_chunk_to_encrypt)) {
        $self->_proc_summary_dump;
        $self->gen_process_for($pchunk);
        $self->_proc_summary_dump;
    }
}

sub _proc_summary_dump {
    my $self = shift;
    return unless $ENV{GPG_DEBUG};

    printf STDERR "num_running=%d, num_outstanding_bytes=%d uncollected_chunks=%d\n",
    $self->num_running_procs,  $self->num_uncollected_bytes, $self->uncollected_chunks;
}

sub next_chunk_to_encrypt {
    my $self = shift;
    while (my $ev = $self->{chunkiter}->next) {
        next if $ev->isa("Brackup::File");
        my $pchunk = $ev;
        next if $self->{target}->stored_chunk_from_inventory($pchunk);
        return $pchunk;
    }
    return undef;
}

sub get_proc_chunkref {
    my ($self, $proc) = @_;
    my $cref = $proc->chunkref;
    delete $self->{procs}{$proc};
    $self->{uncollected_bytes} -= $proc->size_on_disk;
    $self->{uncollected_chunks}--;
    return ($cref, $proc->size_on_disk);
}

# returns PID of a process that finished
sub wait_for_a_process {
    my ($self, $block) = @_;
    my $flags = $block ? 0 : WNOHANG;
    my $kid = waitpid(-1, $flags);
    return 0 if ! $block && $kid <= 0;
    die "no child?" if $kid < 0;
    return 0 unless $kid;

    my $proc = $self->{procs_running}{$kid} or die "Unknown child
        process $kid finished!\n";

    delete $self->{procs_running}{$proc->pid} or die;
    $proc->note_stopped;
    $self->{uncollected_bytes} += $proc->size_on_disk;

    return $kid;
}

sub num_uncollected_bytes { $_[0]{uncollected_bytes} }

sub uncollected_chunks { $_[0]{uncollected_chunks} }

sub gen_process_for {
    my ($self, $pchunk) = @_;
    my $proc = Brackup::GPGProcess->new($pchunk);
    $self->{procs_running}{$proc->pid} = $proc;
    $self->{procs}{$pchunk} = $proc;
    $self->{uncollected_chunks}++;
    return $proc;
}

sub num_running_procs {
    my $self = shift;
    return scalar keys %{$self->{procs_running}};
}

1;

