package App::MultiModule::Test::StatefulStream;
$App::MultiModule::Test::StatefulStream::VERSION = '1.143160';
use strict;use warnings;
use Test::More;
use IPC::Transit;
use Storable;
use Message::Match qw(mmatch);

use App::MultiModule::API;

my $inc;
{
my $i;
$inc = sub {
    $i = 1 unless $i;
    $i++;
    return $i;
};
}


=head2 send
=cut
sub new {
    my $class = shift;
    my %args = @_;
    die "App::MultiModule::Test::StatefulStream::new: required argument 'task_name' not passed"
        unless $args{task_name};
#    die "App::MultiModule::Test::StatefulStream::new: required argument 'program_pid' not passed"
#        unless $args{program_pid};
    $args{timeout} = 40 unless $args{timeout};
    $args{match} = {
        this => int rand 10000,
        that => $inc->(),
    } unless $args{match};
    my $self = {
        increment => int rand 10000,
        task_name => $args{task_name},
        program_pid => $args{program_pid},
        current_id => 1,
        sent_messages => [],
        timeout => $args{timeout},
        out_qname => $args{task_name} . '_out',
        match => $args{match},
    };

    bless ($self, $class);

    return $self;
}

=head2 send
=cut
sub send {
    my $self = shift;
    my %args = @_;
    my $ct = int rand 10000;
    my $id = $self->{current_id}++;
    push @{$self->{sent_messages}}, { id => $id, ct => $ct };
    my $message = Storable::dclone $self->{match};
    if($args{extras}) {
        while(my($key,$value) = each %{$args{extras}}) {
            $message->{$key} = $value;
        }
    }
    $message->{ct} = $ct;
    $message->{id} = $id;
    ok IPC::Transit::send(qname => $self->{task_name}, message => $message);
}

my $incrementer_emit_ct;

=head2 receive
=cut
sub receive {
    my $self = shift;
    my %args = @_;
    $incrementer_emit_ct = 1 unless defined $incrementer_emit_ct;
    my $ret;
    while(my $message = IPC::Transit::receive(qname => 'Incrementer_out', nonblock => 1)) {
#        print STDERR '$message->{emit_ct} == $incrementer_emit_ct' . "$message->{emit_ct} == $incrementer_emit_ct\n";
        ok $message->{emit_ct} == $incrementer_emit_ct;
        $incrementer_emit_ct++;
    }
    return undef unless scalar @{$self->{sent_messages}};
    my $task_name = $self->{task_name};
    my $out_qname = $self->{out_qname};
    my $module_pid;
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm $self->{timeout};
        ok my $msg = IPC::Transit::receive(qname => $out_qname);
        $ret = $msg;
        $module_pid = $msg->{module_pid};
        if($args{match}) {
#            print STDERR 'msg: ' . Data::Dumper::Dumper $msg;
#            print STDERR 'match: ' . Data::Dumper::Dumper $args{match};
            ok mmatch $msg, $args{match};
        }
        my $info = shift @{$self->{sent_messages}};

        print STDERR '$msg->{ct} == $info->{ct}: ' . "$msg->{ct} : $info->{ct}\n" unless $msg->{ct} == $info->{ct};
        ok $msg->{ct} == $info->{ct};

        print STDERR '$msg->{id} == $info->{id}: ' . "$msg->{id} : $info->{id}\n" unless $msg->{id} == $info->{id};
        ok $msg->{id} == $info->{id};

        print '$msg->{my_ct} == $info->{ct} + $self->{increment}: ' . "$msg->{my_ct} : " . ($info->{ct} + $self->{increment}) . "\n" unless $msg->{my_ct} == $info->{ct} + $self->{increment};
        ok $msg->{my_ct} == $info->{ct} + $self->{increment};

        if($self->{program_pid}) {
            if($args{type} and $args{type} eq 'external') {
                ok $msg->{module_pid} != $self->{program_pid};
            }
            if($args{type} and $args{type} eq 'internal') {
                ok $msg->{module_pid} == $self->{program_pid};
            }
        }
    };
    alarm 0;
    ok not $@ unless $args{no_fail_exceptions};
    if($@) {
        print STDERR "exception: $@\n";
        print STDERR Data::Dumper::Dumper \%args;
        print STDERR "\$task_name=$task_name \$out_qname=$out_qname \$module_pid=$module_pid\n";
    } else {
        print STDERR "OK: \$task_name=$task_name \$out_qname=$out_qname \$module_pid=$module_pid\n";
    }
    return undef if $@;
    return $ret;
}
1;
