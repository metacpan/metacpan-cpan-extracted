package Baseball::Sabermetrics::Team;
use Baseball::Sabermetrics::abstract;
use strict;

our @ISA = qw/ Baseball::Sabermetrics::abstract /;

sub players
{
    my ($self, $name) = @_;
    if ($name) {
	die "Player not found: $name\n" unless exists $self->{players}->{$name};
	return $self->{players}->{$name};
    }
    return values %{$self->{players}};
}

sub pitchers
{
    my $self = shift;
    return grep { exists $_->{np} and $_->{np} > 0 } $self->players;
}

sub batters
{
    my $self = shift;
    return grep { exists $_->{pa} and $_->{pa} > 0 } $self->players;
}

sub left_handed_pitchers
{
    my $self = shift;
    return grep { exists $_->{np} and $_->{np} > 0 and $_->{bio}->{throws} eq 'left' } $self->players;
}

sub right_handed_pitchers
{
    my $self = shift;
    return grep { exists $_->{np} and $_->{np} > 0 and $_->{bio}->{throws} eq 'right' } $self->players;
}

sub report
{
    my ($self, @cols) = @_;
    print join("\t", @cols), "\n";
    for ($self->players) {
	$_->print(@cols);
    }
}

sub report_pitchers
{
    my ($self, @cols) = @_;
    print join("\t", @cols), "\n";
    for ($self->pitchers) {
	$_->print(@cols);
    }
}

sub report_batters
{
    my ($self, @cols) = @_;
    print join("\t", @cols), "\n";
    for ($self->batters) {
	$_->print(@cols);
    }
}

1;
