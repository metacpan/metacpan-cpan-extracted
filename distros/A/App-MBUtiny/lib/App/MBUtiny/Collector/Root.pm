package App::MBUtiny::Collector::Root; # $Id: Root.pm 66 2014-09-10 14:42:30Z abalama $
use strict;

=head1 NAME

App::MBUtiny::Collector::Root - Root controller for Collector Server

=head1 VERSION

Version 1.03

=head1 SYNOPSIS

    none

=head1 DESCRIPTION

Root controller for Collector Server. No public subroutines

=head1 HISTORY

See C<CHANGES> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<App::MBUtiny>, L<WWW::MLite>, L<App::MBUtiny::Collector>

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
$VERSION = '1.03';

use Encode;
use WWW::MLite::Util;
use CTK::Util qw/ :BASE :FORMAT /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use App::MBUtiny::Util;

#use Data::Dumper; $Data::Dumper::Deparse = 1;

use constant {
        TABLE_NAME      => 'mbutiny',
    };


sub meta {(
    default => { # Умолчание
        handler => {
            access  => sub {1},
            form    => [ \&App::MBUtiny::Collector::before_view, \&default_form, \&App::MBUtiny::Collector::after_view, ],
            deny    => sub {1},
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Умолчание"),
    },
    check => { # Проверка готовности коллектора и список доступных обработчиков
        handler => {
            access  => \&default_access,
            form    => [ \&App::MBUtiny::Collector::before_view, \&check_form, \&App::MBUtiny::Collector::after_view, ],
            deny    => [ \&App::MBUtiny::Collector::before_view, \&App::MBUtiny::Collector::after_view ],
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Проверка готовности коллектора и список доступных обработчиков"),
        bd_enable   => 1,
    },
    upload => { # Аплоадинг
        handler => {
            access  => \&default_access,
            form    => [ \&App::MBUtiny::Collector::before_view, \&upload_form, \&App::MBUtiny::Collector::after_view, ],
            deny    => [ \&App::MBUtiny::Collector::before_view, \&App::MBUtiny::Collector::after_view ],
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Аплоадинг"),
        bd_enable   => 1,
    },
    fixup => { # Фиксирование
        handler => {
            access  => \&default_access,
            form    => [ \&App::MBUtiny::Collector::before_view, \&fixup_form, \&App::MBUtiny::Collector::after_view, ],
            deny    => [ \&App::MBUtiny::Collector::before_view, \&App::MBUtiny::Collector::after_view ],
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Фиксирование"),
        bd_enable   => 1,
    },
    list => { # Список файлов для хоста
        handler => {
            access  => \&default_access,
            form    => [ \&App::MBUtiny::Collector::before_view, \&list_form, \&App::MBUtiny::Collector::after_view, ],
            deny    => [ \&App::MBUtiny::Collector::before_view, \&App::MBUtiny::Collector::after_view ],
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Список файлов для хоста"),
        bd_enable   => 1,
    },
    delete => { # Удаление файла для хоста
        handler => {
            access  => \&default_access,
            form    => [ \&App::MBUtiny::Collector::before_view, \&delete_form, \&App::MBUtiny::Collector::after_view, ],
            deny    => [ \&App::MBUtiny::Collector::before_view, \&App::MBUtiny::Collector::after_view ],
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Удаление файла для хоста"),
        bd_enable   => 1,
    },
    info => { # Получение информации о файле для хоста
        handler => {
            access  => \&default_access,
            form    => [ \&App::MBUtiny::Collector::before_view, \&info_form, \&App::MBUtiny::Collector::after_view, ],
            deny    => [ \&App::MBUtiny::Collector::before_view, \&App::MBUtiny::Collector::after_view ],
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Получение информации о файле для хоста"),
        bd_enable   => 1,
    },
    download => { # Скачивание файла
        handler => {
            access  => [ \&default_access, \&download_access ],
            form    => \&download_form,
            deny    => [ \&App::MBUtiny::Collector::before_view_406, \&App::MBUtiny::Collector::after_view ],
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Скачивание файла"),
        bd_enable   => 1,
    },
    report => { # Отчет по резервным копиям
        handler => {
            access  => \&default_access,
            form    => [ \&App::MBUtiny::Collector::before_view, \&report_form, \&App::MBUtiny::Collector::after_view, ],
            deny    => [ \&App::MBUtiny::Collector::before_view, \&App::MBUtiny::Collector::after_view ],
            chck    => sub {1},
            proc    => sub {1},
        },
        description => to_utf8("Отчет по резервным копиям"),
        bd_enable   => 1,
    },
)}

sub default_access { # Проверка готовности коллектора
    my $self = shift;
    my $error   = $self->error;
    my $db      = $self->db;

    # Проверка готовности БД
    if ($db) {
        my $dbh = $db->connect;
        if ($db->err) {
            push @$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state);
            return 0;
        } else {
            push(@$error, to_utf8("Ошибка пропинговки")) && return 0 unless $dbh->ping;
        }
    } else {
        push @$error, to_utf8("Ошибки соединения с базой данных. См. логи");
        return 0
    }    
    
    return 1;
}
sub download_access { # Проверка параметров для скачивания
    my $self = shift;
    my $usr     = $self->usr;
    my $error   = $self->error;
    my $db      = $self->db;
    my $table   = value($self->config->collector, "dbi/table") || TABLE_NAME;
    
    # Статические данные
    my $agent_ip    = $self->config->remote_addr || '127.0.0.1';
    
    # Шaг 1. Принимаем данные в виде XML 
    my $request = $usr->{request}; Encode::_utf8_on($request); 
    my %in_data = App::MBUtiny::Collector::read_api_xml($request);
    
    # Шаг 2. Смотрим статус и ошибки чтениЯ XML
    unless (%in_data && $in_data{object}) {
        push @$error, to_utf8("Некорректно переданы данные в параметре request или неверно задано значение тега <object>");
        push @$error, $request if $request;
        return 0;
    }
    
    # Шаг 3. Ожидаем параметры, проверка и подготовка
    my $host = value($in_data{data} => 'host');
    my $file = value($in_data{data} => 'file');
    push(@$error, to_utf8("Некорректно задано значение тега <host>")) && return 0 unless $host;
    push(@$error, to_utf8("Некорректно задано значение тега <file>")) && return 0 unless $file;
    
    # Шаг 4. Получение ID для данного файла на данном коллекторе
    my $id = $db->field("SELECT id FROM $table WHERE 1 = 1
                AND `type` = 1
                AND file_name = ?
                AND agent_ip = ?
                AND agent_name = ?
                AND date_finish IS NULL      
            ",
            $file, $agent_ip, $host,
        );
    push(@$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state)) && return 0 if $db->err;

    # Файл найти не удалось
    push(@$error, to_utf8("Файл найти не удалось или отсутствуют необходимые права")) && return 0 unless $id;
    
    # Всё нормально, устанавливаем переменную file для скачивания (полный путь)!
    my $base_dir = value($self->config->collector, "datadir") || $self->config->document_root || '.';
    my $data_dir = catdir($base_dir, $host);
    my $data_file = catfile($data_dir, $file);
    $usr->{file} = $file;
    $usr->{path} = $data_file;
    
    return 1;
}
sub default_form { # Умолчание
    my $self = shift;
    my $usr     = $self->usr;
    my $error   = $self->error;
    
    push @$error, to_utf8("Неверно указан обработчик. Список доступных обработчиков доступен через операцию check");
    return 0;
    
    #$self->set(status => 1);
    #$self->set(data => {
    #        message => [to_utf8("Всё хорошо")]
    #    });
    #return 1;
}
sub check_form { # Проверка готовности коллектора и список доступных обработчиков
    my $self = shift;
    my $usr     = $self->usr;
    my $error   = $self->error;
    
    my $base_dir = value($self->config->collector, "datadir") || $self->config->document_root || '.';

    # Проверки прошли, возвращаем спиок обработчиков
    $self->set(status => 1);
    $self->set(data => {
            action => [
                    to_utf8("check"),
                    to_utf8("upload"),
                    to_utf8("fixup"),
                    to_utf8("report"),
                    to_utf8("list"),
                    to_utf8("info"),
                    to_utf8("download"),
                    to_utf8("delete"),
                ],
            dir => [ $base_dir ],
            message => [ 'OK' ],
        });
    return 1;
}
sub upload_form { # Алоадинг
    my $self = shift;
    my $q       = $self->q;
    my $usr     = $self->usr;
    my $error   = $self->error;
    
    # Шaг 1. Принимаем данные в виде XML 
    my $request = $usr->{request}; Encode::_utf8_on($request); 
    my %in_data = App::MBUtiny::Collector::read_api_xml($request);
    
    # Шаг 2. Смотрим статус и ошибки чтениЯ XML
    unless (%in_data && $in_data{object}) { #  && $in_data{status}
        #my $in_error = array($in_data{error});
        #push @$error, @$in_error;
        push @$error, to_utf8("Некорректно переданы данные в параметре request или неверно задано значение тега <object>");
        push @$error, $request if $request;
        #use Data::Dumper; push @$error, Dumper(\%in_data);
        return 0;
    }

    # Шаг 3. Ожидаем параметры
    my $host = value($in_data{data} => 'host');
    my $file = value($in_data{data} => 'file');
    my $md5  = value($in_data{data} => 'md5') || '';
    my $sha1 = value($in_data{data} => 'sha1') || '';
    my $comment = value($in_data{data} => 'comment') || '';
    my $filef = $usr->{data} || '';
    
    # Шаг 4. Проверки параметров
    push(@$error, to_utf8("Некорректно задано значение тега <host>")) && return 0 unless $host;
    push(@$error, to_utf8("Некорректно задано значение тега <file>")) && return 0 unless $file;
    push(@$error, to_utf8("Некорректно задано имя файла")) && return 0 unless "$filef";
    
    # Шаг 5. Проверки прошли. Аплоадим
    my $base_dir = value($self->config->collector, "datadir") || $self->config->document_root || '.';
    my $data_dir = catdir($base_dir, $host); preparedir($data_dir) unless -e $data_dir;
    my $data_file = catfile($data_dir, $file);
    
    # Шаг 5a. Непосредственно аплоадинг и получение размера файла. Пустые файлы аплоадить нельзя!
    my $uploadsize = _upload( $data_file, $q->upload('data') );
    push(@$error, to_utf8("Файл загрузить неудалось. См. логи коллектора")) && return 0 unless $uploadsize;
    
    # Шаг 5b. Проверяем суммы
    if ($md5) {
        my $fact_md5 = md5sum($data_file);
        push(@$error, sprintf(to_utf8("Некорректно вычислена контрольная сумма MD5. Вычислино на коллекторе: \"%s\"; Передано от агента: \"%s\""), $fact_md5, $md5)) && return 0 
            unless lc($fact_md5) eq lc($md5);
    }
    if ($sha1) {
        my $fact_sha1 = sha1sum($data_file);
        push(@$error, sprintf(to_utf8("Некорректно вычислена контрольная сумма SHA1. Вычислино на коллекторе: \"%s\"; Передано от агента: \"%s\""), $fact_sha1, $sha1)) && return 0
            unless lc($fact_sha1) eq lc($sha1);
    }
    
    # Шаг 6. Теперь пытаемся заинсёртить данные.
    my $db = $self->db;
    my $table = value($self->config->collector, "dbi/table") || TABLE_NAME;
    my $agent_ip    = $self->config->remote_addr || '127.0.0.1';
    my $agent_host  = lc(resolv($agent_ip) || '');
    my $server_ip   = $self->config->server_addr || '127.0.0.1';
    my $server_host = lc($self->config->server_name || resolv($server_ip) || 'localhost');
    $db->execute("INSERT INTO $table
                        (
                            `type`, `datestamp`, 
                            agent_host, agent_ip, agent_name, server_host, server_ip,
                            `status`, date_start, date_finish,
                            file_name, file_size, file_md5, file_sha1,
                            `comment`
                        )
                    VALUES
                        (
                            1, NOW(),
                            ?, ?, ?, ?, ?,
                            1, NULL, NULL,
                            ?, ?, ?, ?,
                            ?
                        )",
                    $agent_host, $agent_ip, $host, $server_host, $server_ip, 
                    $file, $uploadsize, $md5, $sha1,
                    $comment
                )->finish;
    push(@$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state)) && return 0 if $db->err;
    
    # Шаг 6a. Возврат созданной записи хитрым способом (её ID)
    my $insertid = $db->field("SELECT id FROM $table WHERE 1 = 1
                AND `type` = 1
                AND agent_host = ?
                AND agent_ip = ?
                AND agent_name = ?
                AND file_name = ?
                AND file_size = ?
                AND date_start is NULL
                AND date_finish is NULL
                ORDER BY id DESC
            ",
                $agent_host, $agent_ip, $host, $file, $uploadsize,
            );
    push(@$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state)) && return 0 if $db->err;
    push(@$error, to_utf8("Uploading and inserting failed! Не удалось получить ID созданной записи в БД. Возможно, нет прав доступа к операции")) && return 0 unless $insertid;
    
    # Вывод данных
    $self->set(status => 1);
    #$self->set(data => [ Dumper($q) ]);
    $self->set(data => {
            path    => [ $data_file ],
            id      => [ $insertid ],
            message => [ $uploadsize ? to_utf8("Uploading sucess") : to_utf8("Failed uploading!") ],
        });
    
    return 1;
}
sub fixup_form { # Фиксирование
    my $self = shift;
    my $q       = $self->q;
    my $usr     = $self->usr;
    my $error   = $self->error;
    my $db      = $self->db;
    my $table   = value($self->config->collector, "dbi/table") || TABLE_NAME;

    # Статические данные
    my $agent_ip    = $self->config->remote_addr || '127.0.0.1';
    my $agent_host  = lc(resolv($agent_ip) || '');
    my $server_ip   = $self->config->server_addr || '127.0.0.1';
    my $server_host = lc($self->config->server_name || resolv($server_ip) || 'localhost');

    
    # Шaг 1. Принимаем данные в виде XML 
    my $request = $usr->{request}; Encode::_utf8_on($request); 
    my %in_data = App::MBUtiny::Collector::read_api_xml($request);
    
    # Шаг 2. Смотрим статус и ошибки чтениЯ XML
    unless (%in_data && $in_data{object}) {
        #my $in_error = array($in_data{error});
        #push @$error, @$in_error;
        push @$error, to_utf8("Некорректно переданы данные в параметре request или неверно задано значение тега <object>");
        push @$error, $request if $request;
        #use Data::Dumper; push @$error, Dumper(\%in_data);
        return 0;
    }
    
    # Шаг 3. Ожидаем параметры, проверка и подготовка
    my $id = value($in_data{data} => 'id') || 0;
    my $type = value($in_data{data} => 'type') || 0;
    my $status = value($in_data{data} => 'status') ? 1 : 0;
    my $comment = value($in_data{data} => 'comment') || '';
    my $message = value($in_data{data} => 'message') || '';
    
    # Шаг 4. Фиксация
    # Если type = 1 (Internal/внутренний) то трогаем date_start -- инача ставим = NOW()
    if ($type && is_int($type) && $type == 1) {
        
        push(@$error, to_utf8("Некорректно задано значение тега <id>")) && return 0 unless is_int($id) && $id > 0;
        
        # Шаг 4a. Апдейт
        $db->execute("UPDATE $table
                    SET
                        date_start = NOW(),
                        `status` = ?,
                        `comment` = ?, 
                        `message` = ?
                    WHERE 1 = 1
                        AND id = ?
                        AND `type` = 1
                        AND agent_ip = ?
                    ",
                    $status, $comment, $message,
                    $id, $agent_ip
                )->finish;
        push(@$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state)) && return 0 if $db->err;
        
        # Шаг 4b. Получение ID обновленной записи
        my $test_id = $db->field("SELECT id FROM $table WHERE 1 = 1
                AND `type` = 1
                AND id = ?
                AND agent_ip = ?
                AND date_finish IS NULL
            ",
                $id, $agent_ip
            );
        push(@$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state)) && return 0 if $db->err;
        push(@$error, to_utf8("Fixing and updating failed! Не удалось получить ID записи в БД #$id. Возможно, нет прав доступа к операции")) && return 0 unless $test_id;
    
    } else {
        my $host = value($in_data{data} => 'host');
        my $file = value($in_data{data} => 'file');
        my $size = value($in_data{data} => 'size') || 0;
        my $md5  = value($in_data{data} => 'md5') || '';
        my $sha1 = value($in_data{data} => 'sha1') || '';
    
        push(@$error, to_utf8("Некорректно задано значение тега <host>")) && return 0 unless $host;
        push(@$error, to_utf8("Некорректно задано значение тега <file>")) && return 0 unless $file;
        push(@$error, to_utf8("Некорректно задано значение тега <size>")) && return 0 unless is_int($size) && $size > 0;
        
        # Шаг 4a. Инсёрт
        $db->execute("INSERT INTO $table
                        (
                            `type`, `datestamp`, 
                            agent_host, agent_ip, agent_name, server_host, server_ip,
                            `status`, date_start, date_finish,
                            file_name, file_size, file_md5, file_sha1,
                            `comment`, `message`
                        )
                    VALUES
                        (
                            0, NOW(),
                            ?, ?, ?, ?, ?,
                            ?, NOW(), NULL,
                            ?, ?, ?, ?,
                            ?, ?
                        )",
                    $agent_host, $agent_ip, $host, $server_host, $server_ip, 
                    $status,
                    $file, $size, $md5, $sha1,
                    $comment, $message
                )->finish;
        push(@$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state)) && return 0 if $db->err;
        
        # Шаг 4b. Получение LAST_INSERT_ID хитрым способом
        $id = $db->field("SELECT id FROM $table WHERE 1 = 1
                AND `type` = 0
                AND agent_host = ?
                AND agent_ip = ?
                AND agent_name = ?
                AND file_name = ?
                AND file_size = ?
                AND date_finish IS NULL
                ORDER BY id DESC
            ",
                $agent_host, $agent_ip, $host, $file, $size,
            );
        push(@$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state)) && return 0 if $db->err;
        push(@$error, to_utf8("Fixing and inserting failed! Не удалось получить ID созданной записи в БД. Возможно, нет прав доступа к операции")) && return 0 unless $id;
    }

    # Вывод данных
    $self->set(status => 1);
    $self->set(data => {
            id      => [ $id ],
            message => [to_utf8("Fixing sucess. The data successfully inserted to table of database")],
        });
    
    return 1;
}
sub list_form { # Список файлов для хоста
    my $self = shift;
    my $q       = $self->q;
    my $usr     = $self->usr;
    my $error   = $self->error;
    my $db      = $self->db;
    my $table   = value($self->config->collector, "dbi/table") || TABLE_NAME;

    # Статические данные
    my $agent_ip    = $self->config->remote_addr || '127.0.0.1';
    
    # Шaг 1. Принимаем данные в виде XML 
    my $request = $usr->{request}; Encode::_utf8_on($request); 
    my %in_data = App::MBUtiny::Collector::read_api_xml($request);
    
    # Шаг 2. Смотрим статус и ошибки чтениЯ XML
    unless (%in_data && $in_data{object}) {
        push @$error, to_utf8("Некорректно переданы данные в параметре request или неверно задано значение тега <object>");
        push @$error, $request if $request;
        return 0;
    }
    
    # Шаг 3. Ожидаем параметры, проверка и подготовка
    my $host = value($in_data{data} => 'host');
    push(@$error, to_utf8("Некорректно задано значение тега <host>")) && return 0 unless $host;
        
    # Шаг 4. Получение списка файлов
    my @record = map {$_ = $_->[0]} $db->table("SELECT DISTINCT file_name FROM $table WHERE 1 = 1
                AND `type` = 1
                AND agent_ip = ?
                AND agent_name = ?
                AND date_finish IS NULL      
            ",
            $agent_ip, $host,
        );
    push(@$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state)) && return 0 if $db->err;

    # Вывод данных
    $self->set(status => 1);
    $self->set(data => {
            list    => [@record],
            message => [@record ? to_utf8("Список файлов для хоста успешно получен") : to_utf8("Список файлов для хоста пуст")],
        });
    
    return 1;
}
sub delete_form { # Удаление файла для хоста
    my $self = shift;
    my $q       = $self->q;
    my $usr     = $self->usr;
    my $error   = $self->error;
    my $db      = $self->db;
    my $table   = value($self->config->collector, "dbi/table") || TABLE_NAME;

    # Статические данные
    my $agent_ip    = $self->config->remote_addr || '127.0.0.1';
    
    # Шaг 1. Принимаем данные в виде XML 
    my $request = $usr->{request}; Encode::_utf8_on($request); 
    my %in_data = App::MBUtiny::Collector::read_api_xml($request);
    
    # Шаг 2. Смотрим статус и ошибки чтениЯ XML
    unless (%in_data && $in_data{object}) {
        push @$error, to_utf8("Некорректно переданы данные в параметре request или неверно задано значение тега <object>");
        push @$error, $request if $request;
        return 0;
    }
    
    # Шаг 3. Ожидаем параметры, проверка и подготовка
    my $host = value($in_data{data} => 'host');
    my $file = value($in_data{data} => 'file');
    push(@$error, to_utf8("Некорректно задано значение тега <host>")) && return 0 unless $host;
    push(@$error, to_utf8("Некорректно задано значение тега <file>")) && return 0 unless $file;
        
    # Шаг 4. Получение ID и Type для данного файла на данном коллекторе
    my ($id, $type) = $db->record("SELECT id, `type` FROM $table WHERE 1 = 1
                AND file_name = ?
                AND agent_ip = ?
                AND agent_name = ?
                AND date_finish IS NULL      
            ",
            $file, $agent_ip, $host,
        );
    push(@$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state)) && return 0 if $db->err;
    
    # Файл найти не удалось
    push(@$error, to_utf8("Файл найти не удалось или отсутствуют необходимые права на удаление")) && return 0 unless $id;
    
    # Для type=1 удаляем сам файл физически на сервере
    my $base_dir = value($self->config->collector, "datadir") || $self->config->document_root || '.';
    my $data_dir = catdir($base_dir, $host);
    my $data_file = catfile($data_dir, $file);
    my $msg = "File $data_file esuccessfully deleted";
    if ($type) {
        if (-e $data_file) {
            unless (unlink($data_file)) {
                $msg = "Could not unlink $data_file: $!"
            }
        } else {
            $msg = "File $data_file not exists";
        }
    } else {
        $msg = "Skipped. File $data_file is located in another storage";
    }
    #$self->syslog($msg, "debug");
    
    # Закрываем запись date_finish = NOW(),
    $db->execute("UPDATE $table
            SET
                date_finish = NOW()
            WHERE 1 = 1
                AND id = ?
            ",
            $id
        )->finish;
    push(@$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state)) && return 0 if $db->err;
    
    # Вывод данных
    $self->set(status => 1);
    $self->set(data => {
            id      => [$id],
            message => [$type ? to_utf8("Файл успешно удален: $msg") : to_utf8("Запись в БД для данного файла успешно закрыта")],
        });
    
    return 1;
}
sub info_form { # Получение информации о файле для хоста
    my $self = shift;
    my $q       = $self->q;
    my $usr     = $self->usr;
    my $error   = $self->error;
    my $db      = $self->db;
    my $table   = value($self->config->collector, "dbi/table") || TABLE_NAME;
    
    # Шaг 1. Принимаем данные в виде XML 
    my $request = $usr->{request}; Encode::_utf8_on($request); 
    my %in_data = App::MBUtiny::Collector::read_api_xml($request);
    
    # Шаг 2. Смотрим статус и ошибки чтениЯ XML
    unless (%in_data && $in_data{object}) {
        push @$error, to_utf8("Некорректно переданы данные в параметре request или неверно задано значение тега <object>");
        push @$error, $request if $request;
        return 0;
    }
    
    # Шаг 3. Ожидаем параметры, проверка и подготовка
    my $host = value($in_data{data} => 'host');
    my $file = value($in_data{data} => 'file');
    push(@$error, to_utf8("Некорректно задано значение тега <host>")) && return 0 unless $host;
    push(@$error, to_utf8("Некорректно задано значение тега <file>")) && return 0 unless $file;
        
    # Шаг 4. Получение данных данного файла на данном коллекторе
    my %record = $db->recordh("SELECT * FROM $table WHERE 1 = 1
                AND file_name = ?
                AND agent_name = ?
                ORDER BY date_start DESC
            ",
            $file, $host,
        );
    push(@$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state)) && return 0 if $db->err;
    
    # Файл найти не удалось
    push(@$error, to_utf8("Файл найти не удалось или отсутствуют необходимые права")) && return 0 unless %record && $record{id};
    
    # Файл найден, корректируем вывод.
    my %outdata = ();
    foreach my $k (keys %record) {
        $outdata{$k} = [$record{$k}];
    }
    
    # Вывод данных
    $self->set(status => 1);
    $self->set(data => {%outdata});
    
    return 1;
}
sub download_form {
    my $self = shift;
    my $q       = $self->q;
    my $usr     = $self->usr;
    
    my $file = $usr->{file};
    #my $file = "README";
    my $path = $usr->{path};
    #my $path = "README";

    binmode STDOUT;
    print $q->header( 
            -type => "application/octet-stream",
            -attachment => $file,
        );
    
    local(*FILE);
    my $ostat = open FILE, '<', $path;
    unless ($ostat) {
        carp("[FILE BIN: Can't open file to load \'$path\'] $!");
        return 0;
    }
    binmode FILE;
    
    my $cnt = 0;
    my $buf = "";
    my $n;
    while ($n = sysread(FILE, $buf, 8*1024)) {
        last if !$n;
        $cnt += $n;
        print STDOUT $buf;
    }

    close FILE;
    
    return 1;
}
sub report_form { # Отчет по резервным копиям
    my $self = shift;
    my $q       = $self->q;
    my $usr     = $self->usr;
    my $error   = $self->error;
    my $db      = $self->db;
    my $table   = value($self->config->collector, "dbi/table") || TABLE_NAME;
    
    # Шaг 1. Принимаем данные в виде XML 
    my $request = $usr->{request}; Encode::_utf8_on($request); 
    my %in_data = App::MBUtiny::Collector::read_api_xml($request);
    
    # Шаг 2. Смотрим статус и ошибки чтениЯ XML
    unless (%in_data && $in_data{object}) {
        push @$error, to_utf8("Некорректно переданы данные в параметре request или неверно задано значение тега <object>");
        push @$error, $request if $request;
        return 0;
    }
    
    # Шаг 3. Ожидаем параметры, проверка и подготовка
    my $date_start  = correct_date(value($in_data{data} => 'date_start') || localtime2date());
    my $date_finish = correct_date(value($in_data{data} => 'date_finish') || localtime2date());
    my $host = value($in_data{data} => 'host');
    my $type = value($in_data{data} => 'type');
    
    push(@$error, to_utf8("Некорректно задано значение тега <date_start>")) && return 0 unless $date_start;
    push(@$error, to_utf8("Некорректно задано значение тега <date_finish>")) && return 0 unless $date_finish;
    push(@$error, to_utf8("Некорректно задано значение тега <type>")) && return 0 unless defined $type;
    
    # Корректировка
    my $dts = $date_start;
    my $dtf = $date_finish;
    if (date2dig($date_finish) < date2dig($date_start)) {
        $dts = $date_finish;
        $dtf = $date_start;
    }
    
        
    # Шаг 4. Получение списка файлов
    my @out_data;
    my $fields = "
            id, `type`, agent_host, agent_ip, agent_name, server_host, server_ip,
            `status`, date_start, file_name, file_size, file_md5, file_sha1,
            `message`, `comment`
        ";
    my $where_type = $type eq '1' ? "AND `type` = 1" : $type ? '' : "AND `type` = 0";
    my $where_host = $host ? "AND agent_name = ?" : "AND agent_name != ?";
    my @table = $db->table("SELECT $fields FROM $table WHERE 1 = 1
                AND date_finish IS NULL
                AND date_start >= STR_TO_DATE(?,\'%d.%m.%Y\')
                AND date_start <= DATE_ADD(STR_TO_DATE(?,\'%d.%m.%Y\'), INTERVAL 1 DAY)
                $where_type
                $where_host
            ",
            $dts, $dtf,
            ($host ? $host : '---'),
        );
    push(@$error, sprintf("ERR: %s; ERRSTR: %s; STATE: %s", $db->err, $db->errstr, $db->state)) && return 0 if $db->err;
    my $i = 0;
    foreach my $row (@table) {$i++;
        push @out_data, {
                n           => [$i],
                id          => [fv2zero($row->[0])],
                type        => [fv2zero($row->[1])],
                agent_host  => [fv2null($row->[2])],
                agent_ip    => [fv2null($row->[3])],
                agent_name  => [fv2null($row->[4])],
                server_host => [uv2null($row->[5])],
                server_ip   => [fv2null($row->[6])],
                status      => [fv2zero($row->[7])],
                date_start  => [fv2null($row->[8])],
                file_name   => [uv2null($row->[9])],
                file_size   => [uv2zero($row->[10])],
                file_md5    => [uv2null($row->[11])],
                file_sha1   => [uv2null($row->[12])],
                message     => [uv2null($row->[13])],
                comment     => [uv2null($row->[14])],
            };
    }

    # Вывод данных
    $self->set(status => 1);
    $self->set(data => {
            backup  => [@out_data],
            message => [@table ? to_utf8("Список успешно получен") : to_utf8("Список пуст")],
            number  => [scalar(@out_data)],
        });
    
    return 1;

}

sub _upload { # Функция возвращает размер файла после аплоадинга или 0 в случае неуспеха
    my $fn = shift || '';
    my $fh = shift; # $q->upload('newfile') а само имя файла тen: $::usr{newfile}
    return 0 unless $fn && $fh;
    
    $fn =~ s/\/{2,}/\//; # Преобразование пути
    
    unless (open(UPLOAD,">$fn")) {
        carp("Can't write data to file \"$fn\". Please check permissions: $!");
        return 0;
    }
    #flock(UPLOAD, 2) or die("$!: Невозможно заблокировать файл при записи $file");

    binmode(UPLOAD);    
    print UPLOAD <$fh>;
    close UPLOAD;
    
    my $sz = -s $fn || 0;
    return $sz;
}
1;



__END__
