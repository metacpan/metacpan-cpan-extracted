package App::Ordo::Command::Server::List;
use Moo;
use feature qw(say);
use utf8;
use open ':std', ':utf8';

use Term::ANSIColor qw(colored);
use Text::Table::Tiny 1.02 qw(generate_table);


extends 'App::Ordo::Command::Base';

sub name    { "server list" }
sub summary { "List all worker servers" }
sub usage   { "" }
sub aliases { ['server ls'] }

sub option_spec { {} }

sub execute {
    my ($self) = @_;
    my $res = $self->api->call('find_monitor', {});

    unless ($res->{success} && $res->{servers}) {
       say colored(["bold yellow"], "No servers found");
       return;
    }

    my $rows = [ [qw(ID NAME HOST USER CPU MEM DISK PING UPDATED)] ];
    for my $s (@{$res->{servers} || []}) {
        push @$rows, [
            $s->{id},
            $s->{name} || '-',
            $s->{host} || '-',
            $s->{user} || '-',
            $s->{cpu} ? sprintf("%.1f", $s->{cpu}) : '-',
            $s->{total_memory} ? sprintf("%.1f%%", ($s->{used_memory}/$s->{total_memory})*100) : '-',
            $s->{total_disk} ? sprintf("%.1f%%", ($s->{used_disk}/$s->{total_disk})*100) : '-',
            $s->{ping} ? sprintf("%.0fms", $s->{ping}) : '-',
            $s->{update_time} ? time - $s->{update_time} . 's ago' : '-',
        ];
    }
    say generate_table(rows => $rows, header_row => 1, style => 'boxrule');
}

1;
