package BalanceOfPower::Targets::Fall;
$BalanceOfPower::Targets::Fall::VERSION = '0.400115';
use Moo;

with "BalanceOfPower::Targets::Role::Target";

has government_id => (
    is => 'ro'
);

use constant INTERNAL_DISORDER_LIMIT_FOR_CHOOSE => 40;



sub type
{
    return "FALL";
}
sub name 
{
    my $self = shift;
    return "Fall of " . $self->target_obj->name
}
sub description
{
    return "Make government fall";
}
sub achieved
{
    my $self = shift;
    my $world = shift;
    return $self->target_obj->government_id > $self->government_id;
}
sub select_random_target
{
    my $self = shift;
    my $world = shift;
    my @possible_targets = ();
    for(@{$world->nations})
    {
        my $n = $_;
        if((! $world->war_busy($n->name)) &&
           $n->internal_disorder < INTERNAL_DISORDER_LIMIT_FOR_CHOOSE )
        {
            push @possible_targets, $n;
        }
    }
    if(@possible_targets > 0)
    {
        @possible_targets = $world->shuffle("Choosing FALL target", @possible_targets);
        return $possible_targets[0];
    }
    else
    {
        return undef;
    }
}
sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . 
                join(";", "FALL", $self->target_obj->name, $self->government_id, $self->countdown) . "\n";
}
sub load_target
{
    my $self = shift;
    my $world = shift;
    my $nation_obj = $world->get_nation($self->target_to_load);
    $self->target_obj($nation_obj);
}
sub load
{
    my $self = shift;
    my $data = shift;
    my $f_line = ( split /\n/, $data )[0];
    $f_line =~ s/^\s+//;
    chomp $f_line;
    my ($type, $nation, $government, $countdown) = split ";", $f_line;
    $data =~ s/^.*?\n//;
    return $self->new( target_to_load => $nation, government_id => $government, countdown => $countdown);
}
1;
