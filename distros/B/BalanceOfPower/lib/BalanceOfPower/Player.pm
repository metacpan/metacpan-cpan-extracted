package BalanceOfPower::Player;
$BalanceOfPower::Player::VERSION = '0.400115';
use strict;
use v5.10;

use Moo;
use BalanceOfPower::Constants ':all';

with 'BalanceOfPower::Role::Reporter';
with 'BalanceOfPower::Player::Role::Broker';
with 'BalanceOfPower::Player::Role::Hitman';
with 'BalanceOfPower::Player::Role::Traveler';
with 'BalanceOfPower::Player::Role::Cargo';
#with 'BalanceOfPower::Player::Role::Friend';


has name => (
    is => 'ro',
    default => 'Player'
);
has current_year => (
    is => 'rw'
);


sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . 
                join(";", $self->name, $self->money, $self->current_year, $self->mission_points) . "\n";
    print {$io} $indent . " " . "### WALLET\n";
    $self->dump_wallet($io, " " . $indent);            
    print {$io} $indent . " " . "### EVENTS\n";
    $self->dump_events($io, " " . $indent);
    print {$io} $indent . " " . "### TARGETS\n";
    $self->dump_targets($io, " " . $indent);
}

sub load
{
    my $self = shift;
    my $data = shift;
    my $version = shift;
    my $world = shift;
    my @player_lines =  split /\n/, $data;
    my $player_line = shift @player_lines;
    $player_line =~ s/^\s+//;
    chomp $player_line;
    my %params = $self->manage_player_line($player_line, $version);
    my $what = '';
    my $extracted_data;
    my $wallet = {};
    my $targets = [];
    my $events = {};
    foreach my $line (@player_lines)
    {
        $line =~ s/^\s+//;
        chomp $line;
        if($line eq '### WALLET')
        {
            $what = 'wallet';
        }
        elsif($line eq '### EVENTS')
        {
            $what = 'events';
            $wallet = $self->load_wallet($extracted_data);
            $extracted_data = "";
        }
        elsif($line eq '### TARGETS')
        {
            $what = 'targets';
            $events = $self->load_events($extracted_data);
            $extracted_data = "";
        }
        else
        {
            $extracted_data .= $line . "\n";
        }
    }
    if($what eq 'targets')
    {
        $targets = $self->load_targets($extracted_data, $world);
    }
    elsif($what eq 'events')
    {
        $events = $self->load_events($extracted_data);
    }
    $params{'wallet'} = $wallet;
    $params{'events'} = $events;
    $params{'targets'} = $targets;
    return $self->new(%params);
}

sub manage_player_line
{
    my $self = shift;
    my $data = shift;
    my $version = shift;
    if($version >= 3)
    {
        my ($name, $money, $current_year, $mission_points) = split ";", $data;
        return ( name => $name,
                 money => $money,
                 current_year => $current_year,
                 mission_points => $mission_points );
    }
    else
    {
        my ($name, $money, $current_year) = split ";", $data;
        return ( name => $name,
                 money => $money,
                 current_year => $current_year,
                 mission_points => 0 );
    }

    
}



1;
