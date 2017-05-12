package UberBot::Logger;
use strict;
use POE;
use POSIX qw/ strftime /;
use Data::Dumper;

sub new {
    my $class = shift;

    my %args = @_;

    my $self = {
        delimiter => $args{Delimiter} || undef,
        timestamp => $args{Timestamp} || undef,
    };

    if ( exists $args{FH} ) {
        $self->{_log} = $args{FH};
        return bless $self, $class;
    }
    elsif ( exists $args{FILE} ) {
        unless ( open ( LOGFILE, ">> $args{FILE}" ) ) {
            warn "Could not open $args{FILE}: $!";
            return undef;
        }
        select(LOGFILE); $| = 1;
        select(STDOUT);
        $self->{_log} = \*LOGFILE;
        return bless $self, $class;
    }
}

sub irc_public {
    my ($self, $bot, $who, $where, $msg) = @_[OBJECT, SENDER, ARG0..ARG2];
    my ($nick, $id_host) = split /!/, $who;

    my $timestamp = "";
    if ( defined $self->{timestamp} ) {
        $timestamp = strftime($self->{timestamp}, localtime);
        $timestamp .= " ";
    }

    my $entry = $timestamp .
      ($self->{delimiter}->[0] || "<") .
      "$nick/$where->[0]" .
      ($self->{delimiter}->[1] || ">") .
      " " . $msg;

    print { $self->{_log} } $entry, "\n";
    return 0;
}

sub irc_ctcp_action {
    my ($self, $bot, $who, $where, $msg) = @_[OBJECT, SENDER, ARG0..ARG2];
    my ($nick, $id_host) = split /!/, $who;

    my $timestamp = "";
    if ( defined $self->{timestamp} ) {
        $timestamp = strftime($self->{timestamp}, localtime);
        $timestamp .= " ";
    }

    my $entry = $timestamp .
      '* ' .
      "$nick/$where->[0]" .
      " " . $msg;

    print { $self->{_log} } $entry, "\n";
    return 0;
}
1;