package App::TLSMe::Logger;

use strict;
use warnings;

use IO::Handle;
use Time::Piece;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{fh} ||= \*STDERR;
    $self->{fh}->autoflush(1);

    return $self;
}

sub log {
    my $self = shift;
    my ($message) = @_;

    chomp $message;

    my $date = Time::Piece->new->strftime('%Y-%m-%d %T');

    print {$self->{fh}} sprintf("%s: %s\n", $date, $message);
}

1;
