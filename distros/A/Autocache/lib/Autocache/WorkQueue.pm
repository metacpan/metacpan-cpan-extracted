package Autocache::WorkQueue;

use Any::Moose;

use Autocache::Logger qw(get_logger);

#
# Null Memory Strategy - never expire, in memory cache
#

has '_queue' => (
    is => 'rw',
    default => sub { [] },
    init_arg => undef,
);

#
# push
#
sub push
{
    my ($self,$task) = @_;
    get_logger()->debug( "push" );
    push @{$self->_queue}, $task;
    return 1;
}

#
# pop
#
sub pop
{
    my ($self,$key,$rec) = @_;
    get_logger()->debug( "pop" );
    shift @{$self->_queue};
}

sub size
{
    my ($self,$key,$rec) = @_;
    get_logger()->debug( "size" );
    return scalar @{$self->_queue};
}


#
# execute
#
sub execute
{
    my ($self) = @_;
    get_logger()->debug( "execute" );
    return 0 unless $self->size();
    my $count = 0;
    while( my $task = $self->pop )
    {
        $task->();
        ++$count;
    }
    return $count;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
