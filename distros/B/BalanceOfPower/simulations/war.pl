use v5.10;
use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;
use BalanceOfPower::Utils qw( next_turn prev_turn );
use Data::Dumper;


army_variation(1000, 
               [15, 15, 0, 0], [15, 10, 0, 0], [15, 5, 0, 0],
               [15, 15, .5, 0], [15, 10, .5, 0], [15, 5, .5, 0],
               [15, 15, 0, .5], [15, 10, 0, .5], [15, 5, 0, .5],
);
sub army_variation
{
    my $tries = shift;
    my @armies = @_;
    for(@armies)
    {
        my $a = $_;
        say "Italy [ARMY: " . $a->[0] . ", PROGRESS: " . $a->[2] . "] === VS === Germany [ARMY: " . $a->[1] . ", PROGRESS: " . $a->[3] . "]";

        tries( army_italy => $a->[0], army_germany => $a->[1], progress_italy => $a->[2], progress_germany => $a->[3], tries => $tries, quiet => 1);
    }
}

sub tries
{
    my %data = @_;
    my %tot;
    my %times;
    my %medium;
    $tot{'ITA'} = 0;
    $tot{'GER'} = 0;
    $tot{'NO'} = 0;
    $times{'ITA'} = [];
    $times{'GER'} = [];
    $times{'NO'} = [];
    for(my $i = 0; $i < $data{tries}; $i++)
    {
        my $result = run_scenario(%data);
        $tot{$result->{winner}}++;
        push @{$times{$result->{winner}}}, $result->{time};
    }
    foreach my $t (('ITA', 'GER'))
    {
        my $total = 0;
        my $many = 0;
        for(@{$times{$t}})
        {
            $total += $_;
            $many++;
        }
        if($many)
        {
            $medium{$t} = int(($total / $many) * 100) / 100;
        }
        else
        {
            $medium{$t} = "--";
        }
    }
    say "ITA: " . $tot{'ITA'} . " (" . $medium{'ITA'} . ")";
    say "GER: " . $tot{'GER'} . " (" . $medium{'GER'} . ")";
    say "NO: " . $tot{'NO'}; 
    return { totals => \%tot, medium_time => \%medium };
}


sub run_scenario
{
    my %data = @_;
    my $quiet;
    my $log_stdout = 0;
    my $first_year = 1970;
    if(exists $data{'quiet'})
    {
        $quiet = $data{'quiet'};
        $log_stdout = ! $quiet;
    }
    else
    {
        $quiet = 0;
        $log_stdout = 1;
    }
    my $world = BalanceOfPower::World->new( silent => $quiet, first_year => $first_year, log_on_stdout => $log_stdout  );
    $world->init_random("nations-test1.txt", "borders-test1.txt", 
                        { alliances => 0,
                        trades => 0 });
    $world->current_year($first_year . "/1");
    my $italy = $world->get_nation('Italy');
    my $germany = $world->get_nation('Germany');
    $italy->army($data{'army_italy'});
    $germany->army($data{'army_germany'});
    $italy->progress($data{'progress_italy'});
    $germany->progress($data{'progress_germany'});
    $world->create_war($italy, $germany);
   
    my $turns = 0;
    my $turns_limit = 40;
    while($turns < $turns_limit)
    {
        $turn = next_turn($world->current_year);
        $world->log("--- $turn ---");
        $world->current_year($turn);
        $italy->current_year($turn);
        $germany->current_year($turn);
        $world->war_current_year();

        my @end_check = $italy->get_events("WAR BETWEEN Italy AND Germany WON BY Italy", prev_turn($world->current_year));
        if(@end_check)
        {
            return { 'winner' => 'ITA', 'time' => $turns };
        }
        @end_check = $italy->get_events("WAR BETWEEN Germany AND Italy WON BY Germany", prev_turn($world->current_year));
        if(@end_check)
        {
            return { 'winner' => 'GER', 'time' => $turns };
        }
        
        $turns++;
        $world->fight_wars();
        #$italy->fight_civil_war($world);
        #say $world->print_civil_war_report('Italy') if $log_stdout;
    }
    return { 'winner' => 'NO', 'time' => $turns_limit };
}
