package App::Donburi::Logger;
use strict;
use warnings;
use utf8;

sub new {
    my ($class) = @_;
    bless {
        logs  => [],
        limit => 30,
    }, $class;
}

sub logs {
    my ($class) = @_;
    return $class->{logs};
}

sub log {
    my ($self, $level, $tmpl, @msg) = @_;

    # get time 
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
        localtime(time);
    my $time = sprintf(
        "%04d-%02d-%02dT%02d:%02d:%02d",
        $year + 1900,
        $mon + 1, $mday, $hour, $min, $sec
    );

    # format message
    my $msg = "$time [$level] " . sprintf($tmpl, @msg);

    # print it.
    print STDERR $msg . "\n";

    # push new post
    push @{$self->{logs}}, sprintf($msg);

    # remove old post if reached to limit.
    if (@{$self->{logs}} > $self->{limit}) {
        shift @{$self->{logs}};
    }
}

for my $level (qw/warn crit info/) {
    no strict 'refs';
    *{__PACKAGE__ . '::' . $level} = sub {
        my $self = shift;
        $self->log($level, @_);
    };
}

1;
