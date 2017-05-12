package Net::NNTP;

use warnings;
use strict;

use List::Util qw(min max);

BEGIN
{
    $INC{'Net/NNTP.pm'} = "/usr/lib/perl5/site_perl/5.8.6/Net/NNTP.pm";
}

use vars (qw($groups));

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    my $server = shift;
    $self->{'_server'} = $server;
    return $self;
}

sub _get_groups
{
    return $groups;
}

sub list
{
    my $self = shift;
    return +{ map { $_ => $self->_get_group_info($_), } keys(%{$self->_get_groups()}) };
}

sub _get_group_info
{
    my ($self, $group) = @_;
    my $group_hash = $self->_get_groups()->{$group};
    return [max(keys(%$group_hash)), min(keys(%$group_hash)), undef];
}

sub group
{
    my ($self, $group) = @_;
    if (!exists($self->_get_groups()->{$group}))
    {
        die "Unknown group.";
    }
    $self->{'_group'} = $group;
    my $group_hash = $self->_get_groups()->{$group};
    my $keys = [keys(%$group_hash)];
    return wantarray() ?
        ( scalar(@$keys), min(@$keys), max(@$keys), $group ) :
        $group;
}

sub head
{
    my ($self, $idx) = @_;
    my $group = $self->{'_group'};
    my $group_hash = $self->_get_groups()->{$group};
    if (!exists($group_hash->{$idx}))
    {
        die "Non existant index $idx.";
    }
    return [ @{$group_hash->{$idx}->{'head'}} ];
}

1;

