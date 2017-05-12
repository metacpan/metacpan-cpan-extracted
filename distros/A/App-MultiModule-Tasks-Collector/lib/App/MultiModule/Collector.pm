package App::MultiModule::Collector;
$App::MultiModule::Collector::VERSION = '1.143110';
use parent 'App::MultiModule::Task';
use IPC::Transit;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
    $args{collector_name} = 'unknown' unless $args{collector_name};
#    my $self  = $class->SUPER::new();
    my $self = {};
    $self->{collector_name} = $args{collector_name};
    bless ($self, $class);
    return $self;
}

sub emit {
    my $self = shift;
    my $message = shift;
    $message->{collector_name} = $self->{collector_name};
    $message->{source} = 'Collector';
    IPC::Transit::send(qname => 'Router', message => $message, override_local => 1);
}

1;
