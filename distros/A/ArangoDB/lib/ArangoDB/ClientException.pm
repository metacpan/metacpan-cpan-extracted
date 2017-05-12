package ArangoDB::ClientException;
use strict;
use warnings;
use utf8;
use 5.008001;
use Class::Accessor::Lite ( ro => [qw/message package file line subrutine/] );
use overload
    q{""}    => sub { $_[0]->message },
    fallback => 1;

sub new {
    my ( $class, $message ) = @_;
    my @caller_info = caller;
    my $self        = bless {
        message   => $message,
        package   => $caller_info[0],
        file      => $caller_info[1],
        line      => $caller_info[2],
        subrutine => $caller_info[3],
    }, $class;
    return $self;
}

1;
__END__
