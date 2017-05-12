package App::MonM::AlertGrid::Root; # $Id: Root.pm 57 2016-10-04 12:46:30Z abalama $
use strict;

=head1 NAME

App::MonM::AlertGrid::Root - Root controller for AlertGrid Server

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    none

=head1 DESCRIPTION

Root controller for alertGrid Server. No public subroutines

=head1 HISTORY

See C<CHANGES> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<App::MonM>, L<WWW::MLite>, L<App::MonM::AlertGrid::Server>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw/ $VERSION /;
$VERSION = '1.01';

use Encode;
use WWW::MLite::Util;
use CTK::Util qw/ :BASE :FORMAT /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Text::SimpleTable;
use App::MonM::AlertGrid;

#use Data::Dumper; $Data::Dumper::Deparse = 1;

use constant {
        TBL_HEADERS => [qw/
                id
                ip
                alertgrid
                count
                typ
                value
                pubdate
                expires
                err
                errmsg
                status
            /],
    };


sub meta {(
    default => { # Умолчание
        handler => {
            access  => sub {1},
            form    => [ \&App::MonM::AlertGrid::Server::before_view, \&default_form, \&App::MonM::AlertGrid::Server::after_view, ],
            deny    => sub {1},
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Умолчание"),
    },
    check => { # Проверка готовности сервера и получение списка доступных обработчиков
        handler => {
            access  => \&default_access,
            form    => [ \&App::MonM::AlertGrid::Server::before_view, \&check_form, \&App::MonM::AlertGrid::Server::after_view, ],
            deny    => [ \&App::MonM::AlertGrid::Server::before_view, \&App::MonM::AlertGrid::Server::after_view ],
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Проверка готовности сервера и получение списка доступных обработчиков"),
    },
    store => { # Добавление записи
        handler => {
            access  => \&default_access,
            form    => [ \&App::MonM::AlertGrid::Server::before_view, \&store_form, \&App::MonM::AlertGrid::Server::after_view, ],
            deny    => [ \&App::MonM::AlertGrid::Server::before_view, \&App::MonM::AlertGrid::Server::after_view ],
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Добавление записи"),
    },
    show => { # Отображение всех записей
        handler => {
            access  => \&default_access,
            form    => [ \&App::MonM::AlertGrid::Server::before_view, \&show_form, \&App::MonM::AlertGrid::Server::after_view, ],
            deny    => [ \&App::MonM::AlertGrid::Server::before_view, \&App::MonM::AlertGrid::Server::after_view ],
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Отображение всех записей"),
    },
    export => { # Выгрузка в виде YAML
        handler => {
            access  => \&default_access,
            form    => [ \&App::MonM::AlertGrid::Server::before_view, \&export_form, \&App::MonM::AlertGrid::Server::after_view, ],
            deny    => [ \&App::MonM::AlertGrid::Server::before_view, \&App::MonM::AlertGrid::Server::after_view ],
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Выгрузка"),
    },
)}

sub default_access { # Проверка готовности сервера
    my $self = shift;
    my $error   = $self->error;
    my $q       = $self->q;
    
    # Проверка доступности dbfile
    my $dbfile = $q->param('dbfile') || value($self->get('params') => "dbfile") || value($self->config->alertgrid, "server/dbfile") || '';
    unless ($dbfile && -e $dbfile && -s $dbfile) {
        if ($dbfile) {
            push(@$error, to_utf8("Некорректно задан параметр dbfile в запросе или в настройках скрипта сервера: $dbfile"));
        } else {
            push(@$error, to_utf8("Не передан обязательный параметр dbfile в запросе или в настройках скрипта сервера"));
        }
    }
    
    # Проверка корректности переданного IP
    my $ip = $self->config->remote_addr;
    push(@$error, to_utf8("Не удалось определить IP адрес клиента")) unless $ip;

    return @$error ? 0 : 1;
}
sub default_form { # Умолчание
    my $self = shift;
    my $usr     = $self->usr;
    my $error   = $self->error;
    
    push @$error, to_utf8("Неверно указан обработчик. Список доступных обработчиков доступен через операцию check");
    return 0;

}
sub check_form { # Проверка готовности сервера и список доступных обработчиков
    my $self = shift;
    my $usr     = $self->usr;
    my $error   = $self->error;
    my $q       = $self->q;
    
    my $dbfile = $q->param('dbfile') || value($self->get('params') => "dbfile") || value($self->config->alertgrid, "server/dbfile") || '';
    my $ip = $self->config->remote_addr;

    # Проверки прошли, возвращаем спиок обработчиков
    $self->set(data => sprintf("OK\nAvailable actions: %s\nDBfile: %s\nIP: %s", join("; ", 
                to_utf8("check"),
                to_utf8("store"),
                to_utf8("show"),
                to_utf8("export"),
            ),
            $dbfile,
            $ip,
        )
    );
    return 1;
}
sub store_form { # Добавление записи
    my $self = shift;
    my $usr     = $self->usr;
    my $error   = $self->error;
    my $q       = $self->q;
    
    my $dbfile = $q->param('dbfile') || value($self->get('params') => "dbfile") || value($self->config->alertgrid, "server/dbfile") || '';
    my $ip = $self->config->remote_addr;
    my $data = $q->param('data') || '';
    unless ($data) {
        push(@$error, to_utf8("Не переданы данные запроса"));
        return 0;
    }

    ag_normalize($dbfile);
    my ($stt, $err) = ag_server({
                dbfile  => $dbfile,
                agentip => $ip,
            }, 
            $data
        );
    
    if ($stt) {
        $self->set(data => "OK");
    } else {
        push(@$error, $err);
        return 0;
    }
    
    return 1;
}
sub show_form { # Отображение всех записей
    my $self = shift;
    my $usr     = $self->usr;
    my $error   = $self->error;
    my $q       = $self->q;
    
    my $dbfile = $q->param('dbfile') || value($self->get('params') => "dbfile") || value($self->config->alertgrid, "server/dbfile") || '';
    
    my $snapshot = ag_snapshot($dbfile);
    
    my $data = [];
    foreach my $row (@$snapshot) {
        push @$data, [
                $row->{id},
                $row->{ip},
                $row->{alertgrid_name},
                $row->{count_name},
                $row->{type},
                $row->{value},
                localtime2date_time($row->{pubdate}),
                localtime2date_time($row->{expires}),
                $row->{errcode},
                $row->{errmsg},
                $row->{status},
            ];
    }
    my $head = TBL_HEADERS;
    my %headers = ();
    my @headerc = ();
    my $i = 0;
    # максимумы данных
    foreach (@$head) {
        $headerc[$i] = length($_) || 1; # Счетчик
        $headers{$_} = $i;              # КЛЮЧ -> [индекс]
        $i++;
    }
    foreach my $row (@$data) {
        $i=0;
        foreach my $col (@$row) {
            $headerc[$i] = length($col) if defined($col) && length($col) > $headerc[$i];
            $i++
        }
    }
    
    # Формирование результата
    my $tbl = Text::SimpleTable->new(map {$_ = [$headerc[$headers{$_}],$_]} @$head) if @$head;
    foreach my $row (@$data) {
        my @tmp = ();
        foreach my $col (@$row) { push @tmp, (defined($col) ? $col : '') }
        $tbl->row(@tmp);
    }
    
    if (@$data) {
        $self->set(data => sprintf("OK\nDBFile: %s\n%s", $dbfile, $tbl->draw()));
    } else {
        push(@$error, to_utf8("Таблица пустая: $dbfile"));
        return 0;
    }
    
    return 1;
}
sub export_form { # Выгрузка в виде YAML
    my $self = shift;
    my $usr     = $self->usr;
    my $error   = $self->error;
    my $q       = $self->q;
    my $dbfile = $q->param('dbfile') || value($self->get('params') => "dbfile") || value($self->config->alertgrid, "server/dbfile") || '';
    my $snapshot = ag_snapshot($dbfile);

    require YAML;

    if (@$snapshot) {
        $self->set(data => sprintf("OK\n%s", YAML::Dump($snapshot)));
    } else {
        push(@$error, to_utf8("Таблица пустая: $dbfile"));
        return 0;
    }
    
    return 1;
}

1;

__END__
