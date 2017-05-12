package App::MultiModule::Tasks::OutOfBand;
$App::MultiModule::Tasks::OutOfBand::VERSION = '1.143160';
use strict;use warnings;
use Storable;
use Message::Match qw(mmatch);
use IPC::Transit;
use PadWalker qw(peek_my);

$Storable::Deparse = 1;
$Storable::Deparse = 1;
$Storable::Eval = 1;
$Storable::Eval = 1;

use parent 'App::MultiModule::Task';

=head2 message

No docs yet, sorry.

=cut
sub message {
#All debugging messages land here; if we are external, then we will
#re-send as a non-local send.  If we're on the parent, then we'll
#actually handle the debug stream.
    my $self = shift;
    my $oob_message = shift;
    my %args = @_;

    my $root_object = $args{root_object};
    if($root_object->{module} ne 'main') {
        #in this case, do a non-local Transit send so MultiModule parent
        #debug can pick it up
        IPC::Transit::send(
            qname => 'OutOfBand',
            message => $oob_message,
            override_local => 1);
        return;
    }
    my $type = $oob_message->{type};
    if(not $type) {
        $self->error(   "OutOfBand: message received with no 'type' field",
                        message => $oob_message);
        return;
    }
    my $filter_config;
    eval {
        $filter_config = $args{root_object}->{api}->get_task_state('MultiModule') or die;
        $filter_config = $filter_config->{OOB} or die;
        $filter_config = $filter_config->{$type} or die;
    };
    my $include_message = 0;
    if($filter_config and $filter_config->{include_matches}) {
        while(my($filter_name, $filter_def) = each %{$filter_config->{include_matches}}) {
            $include_message = 1 if mmatch($oob_message, $filter_def);
        }
    } else {
        $include_message = 1;
    }

    if($filter_config and $filter_config->{exclude_matches}) {
        while(my($filter_name, $filter_def) = each %{$filter_config->{exclude_matches}}) {
            $include_message = 0 if mmatch($oob_message, $filter_def);
        }
    }

    return unless $include_message;
    {   
        $oob_message->{oob_tags} = {};
        my $use_message;
        my @messages = ();
        for (0 .. 10) {
            my $level = $_;
            my @caller = caller($level);
            next unless @caller;
            foreach my $tag (split '::', $caller[0]) {
                $oob_message->{oob_tags}->{$tag} = 1;
            }
            foreach my $tag (split '/', $caller[1]) {
                $oob_message->{oob_tags}->{$tag} = 1;
            }
            $oob_message->{oob_tags}->{'line:' . $caller[2]} = 1;
            $oob_message->{oob_tags}->{$caller[0] . ':' . $caller[2]} = 1;
            foreach my $tag (split '::', $caller[3]) {
                $oob_message->{oob_tags}->{$tag} = 1;
            }
            my $h = peek_my($level);
            if(     $h->{'$message'} and
                    ${$h->{'$message'}} and
                    ref ${$h->{'$message'}} and
                    ref ${$h->{'$message'}} eq 'HASH') {
                $use_message = Storable::dclone ${$h->{'$message'}} unless $use_message;
                push @messages, Storable::dclone ${$h->{'$message'}};
            };
        }
        $oob_message->{messages} = \@messages;
        if($use_message and ref $use_message eq 'HASH') {
            $oob_message->{oob_tags}->{message} = {};
            while(my($key,$value) = each %{$use_message}) {
                $oob_message->{oob_tags}->{message}->{$key} = $value
                    if not ref $value;
            }
        }
    }
    if($filter_config and $filter_config->{transit_endpoints}) {
        while(my($transit_name, $transit_def) = each %{$filter_config->{transit_endpoints}}) {
            if($transit_def->{destination}) {
                IPC::Transit::send(
                    qname => $transit_def->{qname},
                    message => $oob_message,
                    destination => $transit_def->{destination}
                );
            } else {
                IPC::Transit::send(
                    qname => $transit_def->{qname},
                    message => $oob_message
                );
            }
        }
    }
    my $oob_config = $self->{root_object}->{oob_opts}->{$type};
    if(     not $oob_config and
            not $self->{root_object}->{oob_opts}->{error}) {
        $self->error('unable to find error handler', message => $oob_message);
        return;
    }
    if(not $oob_config) {
        $oob_config = $self->{root_object}->{oob_opts}->{'error'};
    }
    my $now = scalar localtime;
    my $line = "$now: ($$): [" . uc($type) . "] $oob_message->{str}\n";
    if($oob_config eq '2') {  #STDERR
        print STDERR $line;
        return;
    }
    if($oob_config eq '1') {  #STDOUT
        print $line;
        return;
    }
    if($oob_config =~ /\//) {   #logfile
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 1;
        eval {
            open my $fh, '>>', $oob_config or die;
            print $fh "$now: ($$): $oob_message->{str}\n" or die;
            close $fh or die;
        };
        alarm 0;
        if($@) {
            $self->error("OutOfBand: ($type): failed to write log line to $oob_config: $!");
        }
        return;
    }
    if($oob_config eq 'router') {
        $self->emit($oob_message);
        return;
    }
    #otherwise, send to Transit queue directly
    IPC::Transit::send(
        qname => $oob_config,
        message => $oob_message);
}
1;
