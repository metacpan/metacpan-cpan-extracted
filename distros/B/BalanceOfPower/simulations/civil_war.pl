use v5.10;
use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;
use BalanceOfPower::Utils qw( next_turn prev_turn );
use Data::Dumper;

army_variation(1000, 15, 10, 5, 0);

sub army_variation
{
    my $tries = shift;
    my @armies = @_;
    for(@armies)
    {
        my $a = $_;
        say "Government with an army of $a";
        tries( army => $a, tries => $tries, quiet => 1);
        say "Government with an army of $a and military support";
        tries( army => $a, tries => $tries, 'military support' => 1, quiet => 1);
        say "Government with an army of $a and rebel military support";
        tries( army => $a, tries => $tries, 'rebel support' => 1, quiet => 1);
        say "Government with an army of $a and both supports";
        tries( army => $a, tries => $tries, 'military support' => 1, 'rebel support' => 1, quiet => 1);
    }
}


sub tries
{
    my %data = @_;
    my %tot;
    my %times;
    my %medium;
    $tot{'GOV'} = 0;
    $tot{'REB'} = 0;
    $tot{'NO'} = 0;
    $times{'GOV'} = [];
    $times{'REB'} = [];
    $times{'NO'} = [];
    for(my $i = 0; $i < $data{tries}; $i++)
    {
        my $result = run_scenario(%data);
        $tot{$result->{winner}}++;
        push @{$times{$result->{winner}}}, $result->{time};
    }
    foreach my $t (('GOV', 'REB'))
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
    say "GOV: " . $tot{'GOV'} . " (" . $medium{'GOV'} . ")";
    say "REB: " . $tot{'REB'} . " (" . $medium{'REB'} . ")";
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
    my $france = $world->get_nation('France');
    my $russia = $world->get_nation('Russia');
    $italy->army($data{army});
    $italy->add_internal_disorder(90, $world);
    if($data{'military support'})
    {
        $france->army(15);
        $world->start_military_support($france, $italy);
    }
    if($data{'rebel support'})
    {
        $russia->army(15);
        $world->start_rebel_military_support($russia, $italy);
    }
    my $turns = 0;
    my $turns_limit = 40;
    while($turns < $turns_limit)
    {
        $turn = next_turn($world->current_year);
        $world->log("--- $turn ---");
        $world->current_year($turn);
        $italy->current_year($turn);
        my @end_check = $italy->get_events("THE GOVERNMENT WON THE CIVIL WAR", prev_turn($italy->current_year));
        if(@end_check)
        {
            return { 'winner' => 'GOV', 'time' => $turns };
        }
        @end_check = $italy->get_events("THE REBELS WON THE CIVIL WAR", prev_turn($italy->current_year));
        if(@end_check)
        {
            return { 'winner' => 'REB', 'time' => $turns };
        }
        $turns++;
        $italy->fight_civil_war($world);
        say $world->print_civil_war_report('Italy') if $log_stdout;
    }
    return { 'winner' => 'NO', 'time' => $turns_limit };
}

