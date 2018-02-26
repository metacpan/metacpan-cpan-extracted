package App::Glacier::Glob;
use strict;
use warnings;
use Exporter;
use parent 'Exporter';
use Carp;

sub glob2regex {
    my @glob = @_;
    return undef unless @glob;
    my %patmap = (
	'*' => '.*',
	'?' => '.',
	'[' => '[',
	']' => ']',
    );
    return '^'
	. join('|', map { s{(.)} { $patmap{$1} || "\Q$1\E" }gex; "(?:$_)" } @glob)
	. '$';
}

sub new {
    my $class = shift;
    my $rx = glob2regex(@_);
    my $self = bless { }, $class;
    if (@_ == 1 && $_[0] !~ /[][*?]/) {
	$self->{_rx} = $_[0];
	$self->{_is_literal} = 1;
    } elsif ($rx) {
	$self->{_rx} = $rx;
    }; 
    return $self;
}

sub matches_all {
    my ($self) = @_;
    return ! defined $self->{_rx};
}

sub is_literal {
    my ($self) = @_;
    return $self->{_is_literal};
}

sub match {
    my ($self, $s) = @_;
    return 1 if $self->matches_all;
    return $s eq $self->{_rx} if $self->is_literal;
    return $s =~ /$self->{_rx}/;
}

sub filter {
    my $self = shift;
    my $fun = shift;
    croak "first argument must be a sub" unless ref($fun) eq 'CODE';
    return @_ if $self->matches_all;
    return grep { $self->match(&{$fun}($_)) } @_;
}

sub grep {
    my $self = shift;
    return @_ if $self->matches_all;
    return grep { $self->match($_) } @_;
}

1;
