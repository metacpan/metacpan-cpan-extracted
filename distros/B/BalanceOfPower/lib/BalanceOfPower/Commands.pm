package BalanceOfPower::Commands;
$BalanceOfPower::Commands::VERSION = '0.400115';
use v5.10;
use Moo;
use IO::Prompter [-stdio];
use Term::ANSIColor;
use BalanceOfPower::Player;
use BalanceOfPower::Executive;
use BalanceOfPower::Constants ":all";
use BalanceOfPower::Utils qw(next_turn prev_turn get_year_turns compare_turns evidence_text);
use Data::Dumper;

with 'BalanceOfPower::Role::Logger';

has world => (
    is => 'ro'
);
has query => (
    is => 'rw',
    default => "" 
);
has keep_query => (
    is => 'rw',
    default => 0 
);
has nation => (
    is => 'rw',
    default => ""
);
has active => (
    is => 'rw',
    default => 1
);

has active_player => (
    is => 'rw',
    default => ""
);

has executive => (
    is => 'rw',
);

has latest_result => (
    is => 'rw',
);

sub welcome
{
    my $self = shift;
    my $welcome_message = <<'WELCOME';
Welcome to Balance of Power, simulation of a real dangerous world!

Hide in the darkness to gain power and richness while the world burn
WELCOME
    say $welcome_message;
}

sub set_auto_years
{
    my $self = shift;
    my $auto_years = prompt "Tell a number of years to generate before game start: ", -i;
    return $auto_years;
}
sub input_player
{
    my $self = shift;
    my $player = prompt "Say your name, player: ";
    if($player)
    {
        $self->set_player($player);
    }
    else
    {
        say "Bad entry";
    }
}

sub set_player
{
    my $self = shift;
    my $player = shift;
    $self->world->create_player($player);
    $self->active_player($player);
}

sub get_active_player
{
    my $self = shift;
    return $self->world->get_player($self->active_player);
}


sub welcome_player
{
    my $self = shift;
    #TODO: wallet situation will be printed
}
sub get_prompt_text
{
    my $self = shift;
    my $player = $self->world->get_player($self->active_player);
    my $prompt_text = "";
    my $controlled = undef;
    my $ctrl_n = undef;
    my $influence = undef;
    if($self->executive)
    {
        $controlled = $self->executive->actor;
        $ctrl_n = $self->world->get_nation($controlled);
        $influence = $player->influence($controlled);
    }
     
    $prompt_text = "[" . $player->name . ", Money: " . $player->money;
    if($controlled)
    {
        $prompt_text .= ", Influence: $influence";
    }
    $prompt_text .= ". Turn is " . $self->world->current_year . "]\n";
    if($controlled)
    {
        $prompt_text .= "Controlling $controlled (" . "Int:" . $ctrl_n->production_for_domestic . "    Exp:" . $ctrl_n->production_for_export . "    Prtg:" . $ctrl_n->prestige . "    Army:" . $ctrl_n->army . ")\n";
        $prompt_text .= "Control orders: " .  $player->get_control_order($controlled) . "\n" if $player->get_control_order($controlled);
    }
    $prompt_text .= "You're in " . $player->position . "\n";
    $prompt_text .= $self->nation ? "(" . $self->nation . " [" . $player->influence($self->nation) .  "]) ?" : "?";
    return $prompt_text;
}

sub get_query
{
    my $self = shift;
    if($self->query)
    {
        $self->log("[Not interactive query] " . $self->query);
        return;
    }
    print color("cyan");
    my $input_query = prompt $self->get_prompt_text();
    $input_query .= "";
    print color("reset");
    while ($input_query =~ m/\x08/g) {
        substr($input_query, pos($input_query)-2, 2, '');
    }
    print "\n";
    $self->query($input_query);
    $self->log("[Interactive query] " . $self->query);
}

sub clear_query
{
    my $self = shift;
    if($self->keep_query)
    {
        $self->keep_query(0);
    }
    else
    {
        $self->query(undef);
    }
}

sub verify_nation
{
    my $self = shift;
    my $query = shift;
    return 0 if (! $query);
    my @good_nation = grep { $query  =~ /^$_$/ } @{$self->world->nation_names};
    return @good_nation > 0;
}

sub set_executive
{
    my $self = shift;
    my $controlled_nation = shift;

    my $exec = BalanceOfPower::Executive->new;
    $exec->init($self->world);
    $exec->actor($controlled_nation);
    $self->executive($exec);
    return $exec;
}

sub turn_command
{
    my $self = shift;
    my $query = $self->query;
    if($query eq "turn")
    {
        #$self->nation(undef);
        $self->query(undef);
        return { status => 1 };
    }
    else
    {
        return { status => 0 };
    }
}

sub report_commands
{
    my $self = shift;
    my $query = $self->query;

    my $commands = <<'COMMANDS';
Say the name of a nation to select it and obtain its status.
Say <nations> for the full list of nations.
Say <clear> to un-select nation.

With a nation selected you can use:
<borders>
<near>
<relations>
<events>
<status>
<history>
<plot %attribute%>
[year/turn]
You can also say one of those commands as: [nation name] [command]

[year/turn] with no nation selected gives all the events of the year/turns

say <years> for available range of years

say <wars> for a list of wars, <crises> for all the ongoing crises

say <war history> for a list of finished wars

say <hotspots> gives you wars and crises with also your diplomatic relationship with countries involved

say <supports> for military supports

say <rebel supports> for rebel military supports

say <influences> for influences

say <distance NATION1-NATION2> for distance between nations

say <turn> to elaborate events for a new turn

<orders> display a list of command you can give to your nation for the next turn

<clearorders> nullify the command issued for the next turn    
COMMANDS

    my $result = { status => 0 };

    $query = lc $query;

    if($query eq "quit") { $self->active(0); $result = { status => 1 }; }
    elsif($query eq "nations")
    {
        $query = prompt "?", -menu=>$self->world->nation_names;
        $self->nation(undef);
        $self->keep_query(1);
        $result = { status => 1 };
    }
    elsif($query eq "years")
    {
        say "From " . $self->world->first_year . "/1 to " . $self->world->current_year; 
        $result = { status => 1 };
    }
    elsif($query eq "clear")
    {
        $self->nation(undef);
        $result = { status => 1 };
    }
    elsif($query eq "commands")
    {
        print $commands;
        $result = { status => 1 };
    }
    elsif($query eq "wars")
    {
        print $self->world->print_wars();
        $result = { status => 1 };
    }
    elsif($query eq "crises")
    {
        print $self->world->print_all_crises();
        $result = { status => 1 };
    }
    elsif($query eq "alliances")
    {
        print $self->world->print_allies(undef, 'print');
        $result = { status => 1 };
    }
    elsif($query eq "static")
    {
        open(my $html, "> report.html");
        print {$html} "<html><head></head><body>\n";
        print {$html} $self->world->print_hotspots('html');
        print {$html} "\n";
        print {$html} $self->world->print_allies(undef, 'html');
        print {$html} "\n";
        print {$html} $self->world->print_influences(undef, 'html');
        print {$html} "\n";
        print {$html} $self->world->print_military_supports(undef, 'html');
        print {$html} "\n";
        print {$html} $self->world->print_rebel_military_supports(undef, 'html');
        print {$html} "\n";
        print {$html} $self->world->print_war_history('html');
        print {$html} "\n";
        print {$html} $self->world->print_turn_statistics($self->world->get_prev_year(), undef, 'html');  
        print {$html} "\n";
        print {$html} $self->world->print_borders_analysis('Italy', 'html');  
        print {$html} "\n";
        print {$html} $self->world->print_near_analysis('Italy', 'html');  
        print {$html} "\n";
        print {$html} $self->world->print_diplomacy('Italy', 'html');  
        print {$html} "\n";
        print {$html} $self->world->print_formatted_turn_events('1975', undef, 'html');  
        print {$html} "\n";
        print {$html} $self->world->print_nation_events('Italy', '1975', undef, 'html');  
        print {$html} "\n";
        print {$html} "</body></html>";
        close($html);
        $result = { status => 1 };
    }
    elsif($query eq "influences")
    {
        print $self->world->print_influences();
        $result = { status => 1 };
    }
    elsif($query eq "hotspots")
    {
        print $self->world->print_hotspots();
        $result = { status => 1 };
    }
    elsif($query eq "war history")
    {
        print $self->world->print_war_history();
        $result = { status => 1 };
    }
    elsif($query eq "civil war history")
    {
        print $self->world->print_civil_war_history();
        $result = { status => 1 };
    }
    elsif($query eq "treaties")
    {
        print $self->world->print_treaties_table();
        $result = { status => 1 };
    }
    elsif($query =~ /^situation( (.*))?$/)
    {
        my $order = $2;
        say $self->world->print_turn_statistics($self->world->get_prev_year(), $order);  
        $result = { status => 1 };
    }
    elsif($query eq "supports")
    {
        say $self->world->print_military_supports();  
        $result = { status => 1 };
    }
    elsif($query eq "rebel supports")
    {
        say $self->world->print_rebel_military_supports();  
        $result = { status => 1 };
    }
    elsif($query =~ /save( (.*))?$/)
    {
        my $savefile = $2;
        $savefile ||= $self->world->savefile;
        say $self->world->dump_all($savefile);  
        $result = { status => 1 };
    }
    elsif($query =~ /^distance (.*)-(.*)$/)
    {
        my $n1 = $self->world->correct_nation_name($1);
        my $n2 = $self->world->correct_nation_name($2);
        if($self->verify_nation($n1) && $self->verify_nation($n2))
        {
            say $self->world->print_distance($n1, $n2);
            $result = { status => 1 };
        }
    }
    elsif($query =~ /^((.*) )?borders$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if($self->nation)
        {
            print $self->world->print_borders_analysis($self->nation);
            $result = { status => 1 };
        }
        else
        {
            $result = { status => -1 };
        }
    }
    elsif($query =~ /^((.*) )?near$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if($self->nation)
        {
            print $self->world->print_near_analysis($self->nation);
            $result = { status => 1 };
        }
        else
        {
            $result = { status => -1 };
        }
    }
    elsif($query =~ /^((.*) )?relations$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if($self->nation)
        {
            print $self->world->print_diplomacy($self->nation);
            $result = { status => 1 };
        }
        else
        {
            $result = { status => -1 };
        }
    }
    elsif($query =~ /^((.*) )?events( ((\d+)(\/\d+)?))?$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        my $input_year = $4;
        $input_year ||= undef;
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if($self->nation)
        {
            if($input_year)
            {
                my @turns = get_year_turns($input_year); 
                foreach my $t (@turns)
                {
                    print $self->world->print_nation_events($self->nation, $t);
                    my $wait = prompt "... press enter to continue ...\n\n" if($t ne $turns[-1]);
                }
                $result = { status => 1 };
            }
            else
            {
                print $self->world->print_nation_events($self->nation, prev_turn($self->world->current_year) );
                $result = { status => 1 };
            }
        }
        else
        {
            if($input_year)
            {
                $query = $input_year;
                $self->keep_query(1);
                $result = { status => 1 };
            } 
            else
            {
                $query = prev_turn($self->world->current_year);
                $self->keep_query(1);
                $result = { status => 1 };
            }
        }
    }
    elsif($query =~ /^((.*) )?status$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        if($input_nation)
        {
            $query = $input_nation;
            $self->keep_query(1);
        }
        elsif($self->nation)
        {
           $query = $self->nation;
           $self->keep_query(1);
        }
        $result = { status => 1 };
    }
    elsif($query =~ /^((.*) )?history$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if($self->nation)
        {
            print $self->world->print_nation_statistics($self->nation, $self->world->first_year, prev_turn($self->world->current_year));
            $result = { status => 1 };
        }
        else
        {
            $result = { status => -1 };
        }
    }
    elsif($query =~ /^((.*) )?plot (.*)$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if($self->nation)
        {
            print $self->world->plot_nation_factor($self->nation, $3, $self->world->first_year, prev_turn($self->world->current_year));
            $result = { status => 1 };
        }
        else
        {
            $result = { status => -1 };
        }
    }
    elsif($query eq "targets")
    {
        print $self->world->print_targets($self->get_active_player()->name);
        $result = { status => 1 };
    }
    elsif($query =~ /^friends( (.*))?$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        print $self->get_active_player->print_friendship($input_nation);
        $result = { status => 1 };
    }
    else
    {
        my $nation_query = $self->world->correct_nation_name($query);
        if($self->verify_nation($nation_query)) #it's a nation
        { 
            print $self->world->print_nation_actual_situation($nation_query, 1);
            $self->nation($nation_query);
            $result = { status => 1 };
        }
        else
        {
            my @good_year = ();
            if($query =~ /^(\d+)(\/\d+)?/) #it's an year or a turn
            {
                if((compare_turns($query, $self->world->current_year) == 0 || compare_turns($query, $self->world->current_year) == -1) &&
                    compare_turns($query, $self->world->first_year) >= 0)
                {
                    if($self->nation)
                    {
                        $query = "events $query";
                        $self->keep_query(1);
                        $result = { status => 1 };
                    }
                    else
                    {
                        my @turns = get_year_turns($query); 
                        foreach my $t (@turns)
                        {
                            say $self->world->print_formatted_turn_events($t);
                            my $wait = prompt "... press enter to continue ...\n" if($t ne $turns[-1]);
                        }
                        $result = { status => 1 };
                    }
                }
            }
        }
    }
    print "\n";
    $self->query($query);
    return $result;
}

sub orders
{
    my $self = shift;
    if($self->executive && $self->executive->actor)
    {
        if($self->get_active_player->influence($self->executive->actor) >= INFLUENCE_COST)
        {
            return $self->executive->recognize_command($self->nation,
                                                       $self->query);
        }
        else
        {
            return { status => -4 };
        }
    }
    else
    {
        return { status => 0 };
    }
}

sub stock_commands
{
    my $self = shift;
    my $query = $self->query;
    my $result = { status => 0 };
    $query = lc $query;
    if($query =~ /^buy\s+(\d+)(\s+(.*))?$/)
    {
        my $stock_nation = $3;
        if($stock_nation)
        {
            $stock_nation = $self->world->correct_nation_name($stock_nation);
        }
        else
        {
            $stock_nation = $self->nation;
        }
        my $q = $1;
        if($stock_nation)
        {
            $result = $self->world->buy_stock($self->active_player, $stock_nation, $q, 1);
            if($result->{ status } == 1)
            {
                $self->get_active_player()->add_stock_order($result->{ command });
            }
        }
    } 
    if($query =~ /^sell\s+(\d+)(\s+(.*))?$/)
    {
        my $stock_nation = $3;
        if($stock_nation)
        {
            $stock_nation = $self->world->correct_nation_name($stock_nation);
        }
        else
        {
            $stock_nation = $self->nation;
        }
        my $q = $1;
        if($stock_nation)
        {
            $result = $self->world->sell_stock($self->active_player, $stock_nation, $q, 1);
            if($result->{ status } == 1)
            {
                $self->get_active_player()->add_stock_order($result->{ command });
            }
        }
    } 
    elsif($query eq 'market')
    {
        say $self->world->print_market;
        $result = { status => 2 };
    }
    elsif($query eq 'show stocks')
    {
        say $self->world->print_stocks($self->active_player);
        $result = { status => 2 };
    }
    elsif($query eq 'show stock orders')
    {
        my $player = $self->get_active_player;
        say $player->print_stock_orders();
        $result = { status => 2 };
    }
    elsif($query eq 'empty stock orders')
    {
        my $player = $self->get_active_player;
        $player->empty_stock_orders();
        $result = { status => 1 };
    }
    elsif($query =~ /^remove stock orders( (.*))?/)
    {
        my $stock_nation = $2;
        if($stock_nation)
        {
            $stock_nation = $self->world->correct_nation_name($stock_nation);
        }
        else
        {
            $stock_nation = $self->nation;
        }
        if($stock_nation)
        {
            my $player = $self->get_active_player;
            $player->remove_stock_orders($stock_nation);
            $result = { status => 1 };
        }
    }
    elsif($query =~ /^stockevents( ((\d+)(\/\d+)?))?$/)
    {
        my $input_year = $2;
        $input_year ||= prev_turn($self->world->current_year);
        #my @turns = get_year_turns($input_year); 
        #foreach my $t (@turns)
        #{
        print $self->world->print_stock_events($self->active_player, $input_year, "My stock events", 3);
            #    my $wait = prompt "... press enter to continue ...\n\n" if($t ne $turns[-1]);
            #}
            #print "\n";
        $result = { status => 2 };
    }

    return $result;
}

sub control_commands
{
    my $self = shift;
    my $query = $self->query;
    my $result = { status => 0 };
    $query = lc $query;
    if($query =~ /^control( (.*))$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        my $controlled_nation = undef;
        if($input_nation)
        {
            $controlled_nation = $input_nation;
        }
        if(! $controlled_nation)
        {
            $controlled_nation = $self->nation;
        }
        if($controlled_nation)
        {
            if($self->world->at_war($controlled_nation))
            {
                return { status => -2 };
            }
            if($self->world->at_civil_war($controlled_nation))
            {
                return { status => -3 };
            }
            my $player = $self->get_active_player();
            if($player->influence($controlled_nation) > 0)
            {
                $self->set_executive($controlled_nation);
                say $self->world->print_nation_actual_situation($controlled_nation, 1);
                $result = { status => 1 };
            }
            else
            {
                $result = { status => -1 };
            }
        }
    }
    elsif($query =~ /^uncontrol$/)
    {
        $self->executive(undef);
        $result = { status => 1 };
    }
    elsif($query =~ /^show control orders/)
    {
        say $self->get_active_player->print_control_orders();
        $result = { status => 1 }
    }
    elsif($query eq "orders")
    {
        if($self->executive)
        {
           say $self->executive->print_orders();;
           $result = { status => 1 };
        }
    }
    elsif($query eq 'clearorders')
    {
        if($self->executive)
        {
            $self->get_active_player->add_control_order($self->executive->actor, undef);
            $result = { status => 2 };
        }
    }
    return $result;
}

sub travel_commands
{
    my $self = shift;
    my $query = $self->query;
    my $result = { status => 0 };
    $query = lc $query;
    if($query eq "travels")
    {
        say $self->get_active_player->print_travel_plan($self->world);  
        $result = { status => 2 };
    }
    elsif($query =~ /^go( (.*))$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        my ($status, $info) = $self->get_active_player->go($self->world, $input_nation);
        if($status != 1)
        {
            $result = { status => $status };       
        }
        else
        {
            $result = { status => 1, travel => $info };
        }
    }
    return $result;
}

sub shop_commands
{
    my $self = shift;
    my $query = $self->query;
    my $result = { status => 0 };
    $query = lc $query;
    if($query =~ /^prices( (.*))$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        if($input_nation)
        {
            say $self->world->print_nation_shop_prices($self->world->current_year, $input_nation);
            $result = { status => 1 }
        }
        else
        {
            $result = { status => -1 }
        }
    }
    elsif($query eq 'cargo')
    {
        say $self->get_active_player->print_cargo();
        $result = { status => 1 };
    }
    elsif($query =~ /^sbuy +([0-9]+) +(.*)$/)
    {
        my ($res, $cost) = $self->world->do_transaction($self->get_active_player, 'buy', $1, $2);
        if($res == 1)
        {
            $result = { status => 20, cost => $cost};
        }
        else
        {
            $result = { status => $res };
        }
    }
    elsif($query =~ /^ssell +([0-9]+) +(.*?)( +(bm))?$/)
    {
        my $flags = {};
        if($4 && $4 eq 'bm')
        {
            $flags->{'bm'} = 1;   
        }
        my ($res, $cost) = $self->world->do_transaction($self->get_active_player, 'sell', $1, $2, $flags);
        if($res == 1)
        {
            $result = { status => 30, cost => $cost};
        }
        else
        {
            $result = { status => $res };
        }
    }
    return $result;
}


sub commands
{
    my $self = shift;
    my $result;
    $result = $self->turn_command();
    if($self->handle_result('turn', $result))
    {
        $self->latest_result($result);
        return 1;
    }
    $result = $self->report_commands();
    if($self->handle_result('report', $result))
    {
        $self->latest_result($result);
        return 1;
    }
    $result = $self->stock_commands();
    if($self->handle_result('stock', $result))
    {
        $self->latest_result($result);
        return 1;
    }
    $result = $self->control_commands();
    if($self->handle_result('control', $result))
    {
        $self->latest_result($result);
        return 1;
    }
    #$result = $self->travel_commands();
    #if($self->handle_result('travel', $result))
    #{
    #    $self->latest_result($result);
    #    return 1;
    #}
    #$result = $self->shop_commands();
    #if($self->handle_result('shop', $result))
    #{
    #    $self->latest_result($result);
    #    return 1;
    #}
    $result = $self->orders();
    if($self->handle_result('orders', $result))
    {
        $self->latest_result($result);
        return 1;
    }
    return 0;
}

sub interact
{
    my $self = shift;
    my $pre_decisions = shift;
    $pre_decisions = 1 if(! defined $pre_decisions);
    $self->world->pre_decisions_elaborations() if $pre_decisions;
    while($self->active)
    {
        my $result = undef;
        $self->clear_query();
        $self->get_query();
        if(! $self->commands())
        {
            $self->latest_result(undef);
            say "Bad command";
        }
    }
}

sub handle_result
{
    my $self = shift;
    my $type = shift;
    my $result = shift;
    #say $self->query . " - $type: " . $result->{status};
    #say Dumper($result);
    if($type eq 'turn')
    {
        if($result->{status} == 1)
        {
            say "Elaborating " . $self->world->current_year . "...\n";
            $self->world->decisions();
            $self->world->post_decisions_elaborations();
            if($self->nation)
            {
                say evidence_text($self->world->print_formatted_turn_events($self->world->current_year), $self->nation);
            }
            else
            {
                say $self->world->print_formatted_turn_events($self->world->current_year);
            }
            $self->world->pre_decisions_elaborations();
            $self->executive(undef);
            return 1;
        }
        else
        {
            return 0;
        }
    }
    elsif($type eq 'report')
    {
        if($result->{status} == 1) 
        {
            return 1;
        }
        elsif($result->{status} == -1)
        {
            say "No nation selected";
            return 1;
        } 
        else
        {
            return 0;
        }
    }
    elsif($type eq 'stock')
    {
        if($result->{status} == -11)
        {
            say "Requested stock quantity not available";
            return 1;
        }
        elsif($result->{status} == -12)
        {
            say "Not enough money";
            return 1;
        }
        elsif($result->{status} == -13)
        {
            say "You haven't that quantity";
            return 1;
        }
        elsif($result->{status} == -14)
        {
            say "You can't trade during civil war";
            return 1;
        }
        elsif($result->{status} == -15)
        {
            say "You can't buy more than " . MAX_BUY_STOCK .  " stocks";
            return 1;
        }
        elsif($result->{status} == 1)
        {
            say "Stock order registered";
            return 1;
        }
        elsif($result->{status} == 2)
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
    elsif($type eq 'control')
    {
        if($result->{status} == 1)
        {
            return 1;
        }
        if($result->{status} == 2)
        {
            say "Order revoked";
            return 1;
        }
        elsif($result->{status} == -1)
        {
            say "No influence on requested nation";
            return 1;
        }
        elsif($result->{status} == -2)
        {
            say "No control during war";
        }
        elsif($result->{status} == -3)
        {
            say "No control during civil war";
        }

        else
        {
            return 0;
        }
    }
    elsif($type eq 'orders')
    {
        if($result->{status} == -1)
        {
            say "Command not allowed";
            return 1;
        }
        elsif($result->{status} == -2)
        {
            say "No options available";
            return 1;
        }
        elsif($result->{status} == -3)
        {
            say "Command aborted";
            return 1;
        }
        elsif($result->{status} == -4)
        {
            say "Not enough influence";
            return 1;
        }
        elsif($result->{status} == 1)
        {
            say "Order selected for " .
                $self->executive->actor .  
                ": " . $result->{command};
            my $player = $self->get_active_player();
            #$player->add_influence(-1 * INFLUENCE_COST, $self->executive->actor);
            $player->add_control_order($self->executive->actor, $result->{command});
            return 1;
        } 
        else
        {
            return 0;
        }
    }
    elsif($type eq 'travel')
    {
        if($result->{status} == -1)
        {
            say "Route blocked";
            return 1;
        }
        elsif($result->{status} == -2)
        {
            say "Not enough movements";
            return 1;
        }
        elsif($result->{status} == -3)
        {
            say "Destination unreachable";
            return 1;
        }
        elsif($result->{status} == 1)
        {
            say "Moved to " . $result->{travel}->{destination} . " via " . $result->{travel}->{way};
            say $result->{travel}->{cost} . " movements payed";
            say "Movements available are now " . $self->get_active_player->movements;
            print "\n";
        } 
        elsif($result->{status} == 2)
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
    elsif($type eq 'shop')
    {
        if($result->{status} == 1)
        {
            return 1;
        }
        elsif($result->{status} == 20)
        {
            say "Transaction completed. Payed: " . $result->{cost};
            return 1;
        }
        elsif($result->{status} == 30)
        {
            say "Transaction completed. Earned: " . $result->{cost};
            return 1;
        }
        elsif($result->{status} == -1)
        {
            say "Bad nation";
            return 1;
        }
        elsif($result->{status} == -10)
        {
            say "Bad type of trade";
            return 1;
        }
        elsif($result->{status} == -11)
        {
            say "Not enough money";
            return 1;
        }
        elsif($result->{status} == -12)
        {
            say "Not enough cargo space";
            return 1;
        }
        if($result->{status} == -13)
        {
            say "You don't owe that quantity";
            return 1;
        }
        if($result->{status} == -14)
        {
            say "You can't trade. This nation hates you!";
            return 1;
        }
        else
        {
            return 0;
        }
    }
}


1;
