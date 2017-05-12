package BalanceOfPower::Role::WebMaster;
$BalanceOfPower::Role::WebMaster::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;

use LWP::UserAgent;
use JSON;
use Data::Dumper;
use File::Path qw(make_path remove_tree);

use BalanceOfPower::Utils qw(prev_turn next_turn);


has site_root => (
    is => 'rw',
);
has api_url => (
    is => 'rw',
);
has admin_password => (
    is => 'rw'
);

requires 'print_hotspots';
requires 'print_allies';
requires 'print_influences';
requires 'print_military_supports';
requires 'print_rebel_military_supports';
requires 'print_war_history';
requires 'print_civil_war_history';
requires 'print_turn_statistics';
requires 'print_formatted_turn_events';
requires 'print_nation_actual_situation';
requires 'print_borders_analysis';
requires 'print_near_analysis';
requires 'print_diplomacy';
requires 'print_nation_events';
requires 'pre_decisions_elaborations';
requires 'decisions';
requires 'post_decisions_elaborations';
requires 'print_market';
requires 'print_nation_shop_prices';
requires 'print_all_nations_prices';
requires 'armies_on_territory';



sub build_pre_statics
{
    my $self = shift;
    my $game = shift;
    my $year = shift || $self->current_year;
    my $site_root = $self->site_root;
    my $dest_dir = "$site_root/views/generated/$game/" . $self->current_year();
    say "Generating pre-decisions statics";
    make_path $dest_dir;
    open(my $hotspots, "> $dest_dir/hotspots.tt");
    print {$hotspots} $self->print_hotspots('html');  
    close($hotspots);
    open(my $allies, "> $dest_dir/alliances.tt");
    print {$allies} $self->print_allies(undef, 'html');  
    close($allies);
    open(my $influences, "> $dest_dir/influences.tt");
    print {$influences} $self->print_influences(undef, 'html');
    close($influences);
    open(my $supports, "> $dest_dir/supports.tt");
    print {$supports} $self->print_military_supports(undef, 'html');
    close($supports);
    open(my $reb_supports, "> $dest_dir/rebel-supports.tt");
    print {$reb_supports} $self->print_rebel_military_supports(undef, 'html');
    close($reb_supports);
    open(my $whistory, "> $dest_dir/war-history.tt");
    print {$whistory} $self->print_war_history('html');
    close($whistory);
    open(my $cwhistory, "> $dest_dir/civil-war-history.tt");
    print {$cwhistory} $self->print_civil_war_history('html');
    close($cwhistory);
    open(my $market, "> $dest_dir/market.tt");
    print {$market} $self->print_market('html');
    close($market);
    open(my $prices, "> $dest_dir/prices.tt");
    print {$prices} $self->print_all_nations_prices($year, 'html');
    close($prices);
    $self->build_nations_statics($game, $site_root);
    $self->build_players_statics($game, $site_root);
}

sub build_post_statics
{
    my $self = shift;
    my $game = shift;
    my $site_root = $self->site_root;
    my $year = shift || $self->current_year;
    my $dest_dir = "$site_root/views/generated/$game/" . next_turn($year);
    make_path $dest_dir;
    say "Generating post-decisions statics";
    open(my $situation, "> $dest_dir/situation.tt");
    print {$situation} $self->print_turn_statistics($year, undef, 'html');  
    close($situation);
    open(my $events, "> $dest_dir/events.tt"); 
    print {$events} $self->print_formatted_turn_events($year, undef, 'html');  
    close($events);
    open(my $news, "> $dest_dir/newspaper.tt"); 
    print {$news} $self->print_newspaper($year, "News", 'html');  
    close($news);
}

sub build_meta_statics
{
    my $self = shift;
    my $game = shift;
    my $site_root = $self->site_root;
    my $dest_dir = "$site_root/metadata";
    make_path $dest_dir;
    my %nations_to_dump;
    foreach my $n (@{$self->nations})
    {
        $nations_to_dump{$n->name} = {
                                 code => $n->code,
                                 area => $n->area };
    }
    my %data = ( current_year => $self->current_year,
                 nations => \%nations_to_dump );
    open(my $meta, "> $dest_dir/$game.meta");
    print {$meta} Dumper(\%data);
    close($meta);
}

sub build_nations_statics
{
    my $self = shift;
    my $game = shift;
    my $site_root = $self->site_root;
    say "Generating nations statics";
    foreach my $code (keys %{$self->nation_codes})
    {
        my $nation = $self->nation_codes->{$code};

        my $dest_dir = "$site_root/views/generated/$game/" . $self->current_year() . "/n/$code";
        make_path($dest_dir);
        open(my $status, "> $dest_dir/actual.tt");
        print {$status} $self->print_nation_actual_situation($nation, 1, 'html');
        close($status);
        open(my $borders, "> $dest_dir/borders.tt");
        print {$borders} $self->print_borders_analysis($nation, 'html');  
        close($borders);
        open(my $near, "> $dest_dir/near.tt");
        print {$near} $self->print_near_analysis($nation, 'html');  
        close($near);
        open(my $diplomacy, "> $dest_dir/diplomacy.tt");
        print {$diplomacy} $self->print_diplomacy($nation, 'html');  
        close($diplomacy);
        open(my $events, "> $dest_dir/events.tt");
        print {$events} $self->print_nation_events($nation, prev_turn($self->current_year()), undef, 'html');  
        close($events);
        open(my $graphs, "> $dest_dir/graphs.tt");
        print {$graphs} $self->print_nation_graphs($nation, prev_turn($self->current_year()), 10, 'html');  
        close($graphs);
        open(my $prices, "> $dest_dir/prices.tt");
        print {$prices} $self->print_nation_shop_prices($self->current_year, $nation, 'html');  
        close($prices);
        $dest_dir = "$site_root/metadata/$game/n";
        make_path($dest_dir);
        open(my $nation_meta, "> $dest_dir/" . $code . ".data");
        my $at_civil_war = $self->at_civil_war($nation);
        my $at_war = $self->at_war($nation) ? 1 : 0;

        my $commands = $self->build_commands();
        my $exec = $commands->set_executive($nation);
        my @allowed = $exec->allowed_orders();
        my %command_matrix;
        for(@allowed)
        {
            my $com_name = $_;
            my $com = $exec->commands->{$com_name};
            if($com->has_argument)
            {
               my @targets = $com->get_available_targets();
               if(@targets)
               {
                    $command_matrix{$com_name}->{targets} = \@targets;
                    $command_matrix{$com_name}->{argument} = $com->has_argument();
               }
            }
            else
            {
                $command_matrix{$com_name}->{argument} = $com->has_argument();
            }
        }
        my $nation_obj = $self->get_nation($nation);
        my %travels = $self->make_travel_plan($nation);
        my %prices = $self->get_all_nation_prices($nation, $self->current_year);
        my $foreign_armies = $self->armies_on_territory($nation);
        my $invaded = @{$foreign_armies->{invaders}} > 0 ? 1 : 0;
        my %nation_hash = ( stocks => $nation_obj->available_stocks,
                            internal_production => $nation_obj->production_for_domestic,
                            export_production => $nation_obj->production_for_export,
                            prestige => $nation_obj->prestige,
                            army => $nation_obj->army,
                            war => $at_war,
                            civil_war => $at_civil_war,
                            invasion => $invaded,
                            commands => \%command_matrix,
                            travels => \%travels,
                            prices => \%prices,
                            foreigners => $foreign_armies );
        print {$nation_meta} Dumper(\%nation_hash);
        close($nation_meta);
    }
}
sub build_players_statics
{
    my $self = shift;
    my $game = shift;
    my $site_root = $self->site_root;
    say "Generating player statics";
    foreach my $p (@{$self->players})
    {
        my $dest_dir = "$site_root/views/generated/$game/" . $self->current_year() . '/p/' . $p->name;
        make_path($dest_dir);
        open(my $stocks, "> $dest_dir/stocks.tt");
        print {$stocks} $self->print_stocks($p->name, 'html');
        close($stocks);
        open(my $events, "> $dest_dir/events.tt");
        print {$events} $self->print_stock_events($p->name, prev_turn($self->current_year()), "My market events", 3, 'html');
        close($events);
        open(my $ranking, "> $dest_dir/ranking.tt");
        print {$ranking} $self->print_all_stocks('html');
        close($ranking);
        open(my $graphs, "> $dest_dir/graphs.tt");
        print {$graphs} $self->print_player_graphs($p->name, prev_turn($self->current_year()), 10, 'html');
        close($graphs);
        open(my $targets, "> $dest_dir/targets.tt");
        print {$targets} $self->print_targets($p->name, 'html');
        close($targets);


        $dest_dir = "$site_root/metadata/$game/p";
        make_path($dest_dir);
        open(my $metawallet, "> $dest_dir/" . $p->name . "-wallet.data");
        my %wallet;
        for(keys %{$p->wallet})
        {
            my $code = $self->get_nation($_)->code;
            $wallet{$code} = $p->wallet->{$_};
        }
        my $stock_status = $self->player_stocks_status($p->name);
        my $w_metadata = { wallet => \%wallet, stock_value => $stock_status->{'stock_value'} };
        print {$metawallet} Dumper($w_metadata);
        close($metawallet);
    }
}

sub clean_statics
{
    my $self = shift;
    my $game = shift;
    my $preservation_window = shift;
    my $site_root = $self->site_root;
    my $delete_year = $self->current_year;
    say "Current year: $delete_year";
    say "---";
    for(my $i = $preservation_window; $i > 0; $i--)
    {
        $delete_year = prev_turn($delete_year);
    }
    my $deleting = 1;
    while($deleting)
    {
        my $directory_to_delete = "$site_root/views/generated/$game/$delete_year";
        if (-e $directory_to_delete and -d $directory_to_delete) 
        {
            say "Deleting $directory_to_delete";
            remove_tree($directory_to_delete);
            if($delete_year =~ /1$/)
            {
                my $parent_directory_to_delete = $directory_to_delete;
                $parent_directory_to_delete =~ s/\/1$//;
                say "Deleting $parent_directory_to_delete";
                remove_tree($parent_directory_to_delete);
            }
            $delete_year = prev_turn($delete_year);
        }
        else 
        {
            $deleting = 0;
        }
    }
}

sub server_available
{
    my $self = shift;
    my $alive = $self->get_web_data('/keepalive', 1);
    if($alive && $alive eq 'OK')
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

sub generate_whole_turn
{
    my $self = shift;
    my $game = shift;
    my $turn = shift;
    my $site_root = shift;
    $self->pre_decisions_elaborations($turn);
    $self->build_pre_statics($game, $site_root);
    $self->decisions();
    $self->post_decisions_elaborations();
    $self->build_post_statics($game, $site_root);
}
sub generate_web_interactive_turn
{
    my $self = shift;
    my $game = shift;
    my $site_root = shift;
    $self->collect_api_data($game);
    $self->decisions();
    $self->post_decisions_elaborations();
    $self->build_post_statics($game, $site_root);
    $self->update_web_players($game);
    $self->pre_decisions_elaborations(next_turn($self->current_year));
    $self->build_pre_statics($game, $site_root);
}

sub manage_web_players
{
    my $self = shift;
    my $game = shift;
    my $players = $self->get_web_data("/api/$game/users");
    if($players)
    {
        my $many = @{$players} + 0;
        say "$game - $many players on DB";
        for(@{$players})
        {
            $self->create_player($_->{'username'}, $_->{'position'}, $_->{'money'});
        }
    }
    else
    {
        say "$game - players list NOT retrieved";
    }
}

sub collect_api_data
{
    my $self = shift;
    my $game = shift;
    $self->manage_web_players($game);
    $self->manage_stock_orders($game);
    $self->manage_influence_orders($game);
}

sub manage_stock_orders
{
    my $self = shift;
    my $game = shift;
    foreach my $p (@{$self->players})
    {
        my $password = $self->admin_password;
        my $user = $p->name;
        my $call = "/api/$game/stock-orders?player=$user&password=$password";
        my $orders = $self->get_web_data($call);
        if(defined $orders)
        {
            say "$game - Stock orders for $user retrieved";
            for(@{$orders})
            {
                $self->get_player($p->name)->add_stock_order($_); 
            }
        }
        else
        {
            say "$game - Stock orders for $user NOT retrieved";
        }
    }
}
sub manage_influence_orders
{
    my $self = shift;
    my $game = shift;
    foreach my $p (@{$self->players})
    {
        my $password = $self->admin_password;
        my $user = $p->name;
        my $call = "/api/$game/influence-orders?player=$user&password=$password";
        my $orders = $self->get_web_data($call);
        if(defined $orders)
        {
            say "$game - Influence orders for $user retrieved";
            for(@{$orders})
            {
                $self->get_player($p->name)->add_control_order($_->{nation}, $_->{command});
            }
        }
        else
        { 
            say "$game - Orders for $user NOT retrieved";
        }  
    }
}

sub update_web_players
{
    my $self = shift;
    my $game = shift;
    my $password = $self->admin_password;
    my @players = @{$self->players};
    foreach my $p (@players)
    {
        my $res = $self->post_web_data("/api/$game/user-data", { password => $password,
                                                                 player => $p->name,
                                                                 money => $p->money,
                                                                 position => $p->position });
        say "$game - Updating " . $p->name. ": " . $res;
    }
}

sub get_web_data
{
    my $self = shift;
    my $call = shift;
    my $bare = shift || 0;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    my $response = $ua->get($self->api_url . $call);

    
    if ($response->is_success) {
        if($bare)
        {
            return $response->decoded_content;
        }
        else
        {
            my $json = JSON->new->allow_nonref;
            return $json->decode( $response->decoded_content );
        }
    }
    else {
        return undef;
    }
}

sub post_web_data
{
    my $self = shift;
    my $call = shift;
    my $form = shift;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    my $response = $ua->post($self->api_url . $call, $form);
    return $response->code;
}

1;


