package App::MBUtiny; # $Id: MBUtiny.pm 76 2014-09-24 15:02:37Z abalama $
use strict;

=head1 NAME

App::MBUtiny - BackUp system for Your WEBsites

=head1 VERSION

Version 1.09

=head1 SYNOPSIS

    use App::MBUtiny;

=head1 ABSTRACT

App::MBUtiny - BackUp system for Your WEBsites

=head1 DESCRIPTION

BackUp system for Your WEBsites

=head1 METHODS

=over 8

=item B<new>

    my $mbu = new App::MBUtiny( $c );

Returns object. $c -- CTK object

=item B<backup>

    my $status = $mbu->backup( [qw( ... host names ... )] );

Run BackUp for all or specified names of hosts

=item B<restore>

    my $status = $mbu->test( [qw( ... host names ... ), $date] );

Restore files for all or specified hosts by date

=item B<test>

    my $status = $mbu->test( [qw( ... host names ... )] );

Testing all or specified hosts

=item B<checkup>

    my $status = $mbu->checkup( [qw( ... host names ... )] );

Checking backups for all or specified names of hosts

=item B<c>

    my $c = $mbu->c;

Returns CTK object

=item B<msg>

    print $mbu->msg;

Set/Get message. Method returns informational message of MBUtiny

=item B<show>

    print $mbu->show;

Set/Get message for user. Method returns informational message for user of MBUtiny

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<CTK>, L<WWW::MLite>

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
$VERSION = '1.09';

use CTK::Util;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use Text::Unidecode;
use Text::SimpleTable;
use File::Path; # mkpath / rmtree

use App::MBUtiny::Util;
use App::MBUtiny::CopyExclusive;
use App::MBUtiny::CollectorAgent;

#use Data::Dumper; $Data::Dumper::Deparse = 1;
#$App::MBUtiny::CollectorAgent::DEBUG = 1;

use constant {
    OBJECTS_DIR => 'files',
    EXCLUDE_DIR => 'excludes',
    RESTORE_DIR => 'restore',
};

sub new {
    my $class = shift;
    my $c     = shift;
    croak("The method is called without the required parameter. CTK Object mismatch") unless ref($c) =~ /CTK/;
    
    my $objdir = catdir($c->datadir,OBJECTS_DIR);
    my $excdir = catdir($c->datadir,EXCLUDE_DIR);
    my $rstdir = catdir($c->datadir,RESTORE_DIR);
    preparedir({
            objdir => $objdir,
            excdir => $excdir,
            rstdir => $rstdir,
        });
    
    my $self = bless { 
            c   => $c,
            msg => '',
            show   => '',
            objdir => $objdir,
            excdir => $excdir,
            rstdir => $rstdir,
        }, $class;
    
    #$c->log_debug("new say: Blah-Blah-Blah");
    
    return $self;
}
sub c { return shift->{c} }
sub msg { 
    my $self = shift;
    my $s = shift;
    $self->{msg} = $s if defined $s;
    return $self->{msg};
}
sub show { 
    my $self = shift;
    my $s = shift;
    $self->{show} = $s if defined $s;
    return $self->{show};
}
sub backup {
    my $self = shift;
    my $args = array(shift);
    my $c    = $self->c;
    my $config = $c->config;
    my $ret = "";
    my $status = 1;
    
    # Табличные заголовки
    my @tblfields = ( # 
            [19, 'DATE AND TIME'],
            [32, 'PROCESS NAME'],
            [42, 'DESCRIPTION OF PROCCESS / DATA OF PROCCESS'],
            [8,  'STATUS'],
        );
        
    # Определяем данные архиваторов
    my $arcdef = $config->{arc};
    croak "Error! Undefined <arc> section." unless $arcdef;
    
    # Получение обработчиков
    my @joblist = $self->get_jobs;
    $c->log_debug("Start processing hosts");
    foreach my $job (sort {(keys(%$a))[0] cmp (keys(%$b))[0]} @joblist) {
        my $hostname = _name($job);
        my $hostskip = (!@$args || grep {lc($hostname) eq lc($_)} @$args) ? 0 : 1;
        my @paths_for_remove;
        $c->log_debug(sprintf("Loading configuration for host \"%s\"... %s", $hostname, ($hostskip ? 'SKIPPED' : 'LOADED') ));
        next if $hostskip;
        
        # Обработка хостов
        my $enabled  = value($job, $hostname => 'enable');
        if ($enabled) {
            $c->log_debug(sprintf("--> Begin processing: \"%s\"", $hostname));
            my $pfx = " " x 3;
            my $step = '';
            
            my $sendreport      = value($job, $hostname => 'sendreport') || 0;
            my $senderrorreport = value($job, $hostname => 'senderrorreport') || 0;
            my $ostat = 0;  # Статус операции
            my $ferror = 0; # Найденные ошибки: 0 - их нет / 1 - ошибки были
            
            my $tbl = Text::SimpleTable->new(@tblfields);
            
            #
            # Step 00. Определения умолчаний
            #
            $step = "Step 00."; $c->log_debug($pfx, $step, "Loading and preparing data");
            
            # Формирование данных для архиватора
            my $arcname = value($job, $hostname => 'arcname') || 'tar';

            # Получение данных почты
            my $maildata = node($job, $hostname => 'sendmail'); $maildata = node($config => 'sendmail') unless value($maildata => "to"); 
            my $usemail = value($maildata => "to") ? 1 : 0;
            $c->log_warning($pfx, "MAIL data not defined") unless $usemail;

            # Получение маски файлов архивов и преобразование ее согласно формату
            # Маски файлов могут иметь сложный вид, по умолчанию используется маска вида:
            #    [HOST]-[YEAR]-[MONTH]-[DAY].[EXT]
            # Ключи могут быть использованы следующие:
            #
            #    DEFAULT  -- Значение соответствующее формату [HOST]-[YEAR]-[MONTH]-[DAY].[EXT]
            #    HOST     -- Имя секции хоста
            #    YEAR     -- Год создания архива
            #    MONTH    -- Месяц создания архива
            #    DAY      -- День создания архива
            #    EXT      -- Расширение файла архива
            #    TYPE     -- Тип архива
            #
            my $arcmask = value($job, $hostname => 'arcmask') || '[HOST]-[YEAR]-[MONTH]-[DAY].[EXT]';
            $arcmask =~ s/\[DEFAULT\]/[HOST]-[YEAR]-[MONTH]-[DAY].[EXT]/gi;
            my %maskfmt = (
                    HOST  => $hostname,
                    YEAR  => '',
                    MONTH => '',
                    DAY   => '',
                    EXT   => value($arcdef, 'arc'=>$arcname=>'ext')  || '',
                    TYPE  => value($arcdef, 'arc'=>$arcname=>'type') || '',
                );
            
            # Получение BU характеристик для определения сжатия файлов
            my $buday   = value($job, $hostname => 'buday') || value($config => 'buday') || 0;
            my $buweek  = value($job, $hostname => 'buweek') || value($config => 'buweek') || 0;
            my $bumonth = value($job, $hostname => 'bumonth') || value($config => 'bumonth') || 0;

            # Получение списка ДАТ файлов, которые нужно будет сохранить
            my @dates = $self->get_dates($buday,$buweek,$bumonth);

            # Формируем ТЕСТОВЫХ имена файлов исходя из масок для того чтобы включить их в исключения
            my %keepfiles;
            foreach my $td (@dates) {
                ($maskfmt{YEAR}, $maskfmt{MONTH}, $maskfmt{DAY}) = ($1,$2,$3) if $td =~ /(\d{4})(\d{2})(\d{2})/;
                $keepfiles{dformat($arcmask,\%maskfmt)} = $td;
            }
            $tbl->row(localtime2date_time, sprintf("%s Loading data", $step), '', 'OK');

            #
            # Step 01. Выполнение предшествующих триггеров, один за другим выполняется триггер (команда)
            #          слудует заметить, что порядок выполнения не определен!
            #
            $step = "Step 01."; $c->log_debug($pfx, $step, "Triggers");
            my $triggers = array($job, $hostname => 'trigger');
            $tbl->row(localtime2date_time, sprintf("%s Triggers", $step), "No triggers", 'SKIPPED') unless @$triggers;
            foreach my $trg (@$triggers) {
                my $exe_err = '';
                my $exe_out = exe($trg, undef, \$exe_err);
                my $exe_stt = (defined ($exe_err) && $exe_err ne '') ? 0 : 1;
                $c->log_debug($pfx, sprintf(" # \"%s\": %s", $trg, $exe_stt ? 'OK' : 'ERROR'));
                $c->log_debug($pfx, sprintf(" < STDOUT:\n%s\n", $exe_out)) if defined ($exe_out) && $exe_out ne '';
                $c->log_error($pfx, sprintf(" < STDERROR:\n%s\n", $exe_err)) unless $exe_stt;
                $tbl->row(localtime2date_time, sprintf("%s Trigger", $step), $exe_stt ? $trg : sprintf("\"%s\"\nSee log: %s", $trg, $c->logfile), $exe_stt ? 'OK' : 'ERROR');
            }
            
            
            #
            # Step 02. Получение списка обычных и эксклюзивных файлов для обработки (exclude)
            # <Exclude ["sample"]> # -- под этим имененм сохраняется в папкке EXCLUDE_DIR, опционально
            #    Object d:\\Temp\\exclude1 # -- отсюда берутся сами файлы
            #    Target d:\\Temp\\exclude2 # -- optional. сюда пишем папку куда произойдет коирование если не хотим чтобы было в "sample" папке
            #    Exclude file1.txt
            #    Exclude file2.txt
            #    Exclude foo/file2.txt
            # </Exclude>
            #
            $step = "Step 02."; $c->log_debug($pfx, $step, "Objects");
            my $objects = array($job, $hostname => 'object');
            my $exclude_node = _node_correct(node($job, $hostname => "exclude"), "object");
            foreach my $exclude (@$exclude_node) {
                # Готовим данные для эксклюзивного копирования
                my $exc_name = _name($exclude);
                my $exc_data = hash($exclude, $exc_name);
                #::debug($exc_name, Data::Dumper::Dumper($exc_data));
                my $exc_object = value($exc_data, "object");
                $c->log_warning($pfx, sprintf("Object in <Exclude \"%s\"> section missing or incorrect directory \"%s\"", $exc_name, $exc_object )) && next 
                    unless $exc_object && (-e $exc_object and -d $exc_object);
                my $exc_target = value($exc_data, "target") || catdir($c->datadir,EXCLUDE_DIR,$exc_name);
                $c->log_error($pfx, sprintf("Target directory specified in <Exclude \"%s\"> section already exists: \"%s\"", $exc_name, $exc_target )) && next 
                    if $exc_target && -e $exc_target;
                my $exc_exclude = array($exc_data, "exclude") || [];
                
                # Копирование
                $App::MBUtiny::CopyExclusive::DEBUG = 1 if $c->debugmode;
                if (xcopy($exc_object, $exc_target, $exc_exclude)) {
                    push @paths_for_remove, $exc_target;
                    push @$objects, $exc_target;
                    $c->log_debug($pfx, sprintf(" - \"%s\" -> \"%s\"", $exc_object, $exc_target));
                } else {
                    $c->log_error($pfx, sprintf("Copying directory \"%s\" to \"%s\" in exclusive mode failed!", 
                            $exc_object, $exc_target
                        ));
                }
            }
            @$objects = grep {-e} @$objects; # Проверка доступности файлов для обработки
            $ostat  = @$objects ? 1 : 0;
            $ferror = 1 unless $ostat;
            $c->log_debug($pfx, sprintf(" - %s",$_)) foreach @$objects;
            $tbl->row(localtime2date_time, sprintf("%s Objects", $step), $ostat ? join("\n", @$objects) : '--- NONE ---', $ostat ? 'OK' : 'ERROR');


            #####
            # Step 03. Получение нод коллекторов и создание объектов с ними. 
            #          Для этого делается запрос на проверку готовности коллектора - check. после этого сразу
            #          пишутся данные в лог и табличку, что типа - готов колеектор (ready) или неготов (unready/offline)
            #####
            $step = "Step 03."; $c->log_debug($pfx, $step, "Get collector data");
            my $collector_node = _node2anode(node($job, $hostname => 'collector'));
            my $colls = [];
            foreach my $coll (grep {value($_ => 'uri')}  @$collector_node) {
                my $coll_uri = value($coll, 'uri') || '';
                my $agent = new App::MBUtiny::CollectorAgent(
                            uri         => $coll_uri,
                            user        => value($coll, 'user'),
                            password    => value($coll, 'password'),
                            timeout     => value($coll, 'timeout'),
                        );
                my $coll_status = $agent->check;
                
                # Итог операции
                $c->log_debug($pfx, sprintf(" - %s",$coll_uri));
                $tbl->row(localtime2date_time, sprintf("%s Collector ready", $step), sprintf("%s\n%s",$coll_uri, unidecode($agent->error)), $coll_status ? 'OK' : 'ERROR');
                if ($coll_status) {
                    push @$colls, $agent
                } else {
                    $c->log_error($pfx x 2, sprintf("ERROR: %s",unidecode($agent->error)));
                    $ferror = 1;
                }
            }

            
            #####
            # Step 04. Получение нод приёмников
            #####
            
            # Step 04a. Получение списка файлов имеющихся архивов в первом локальном хранилище если указаны его атрибуты
            $step = "Step 04a."; $c->log_debug($pfx, $step, "Files on the first LOCAL storage");
            my $localdir_node = array($job, $hostname => 'local/localdir') || [];
            my $first_localdir = $localdir_node->[0];
            my $uselocal = $first_localdir ? 1 : 0;
            preparedir($first_localdir) unless $uselocal && (-e $first_localdir) && (-d $first_localdir or -l $first_localdir);
            my $locallist = $uselocal ? getlist($first_localdir) : [];
            my @localfiles = sort {$a cmp $b} @$locallist;
            $c->log_debug($pfx, sprintf(" - %s",$_)) foreach @localfiles;
            $c->log_debug($pfx x 2, "SKIPPED") unless $uselocal;
            $tbl->row(localtime2date_time, sprintf("%s Files on LOCAL", $step), $uselocal ? join("\n", @localfiles) : '--- NONE ---', $uselocal ? 'OK' : 'SKIPPED');
            
            # Step 04b. Получение списка файлов имеющихся архивов на FTP первого источника если указаны его атрибуты
            $step = "Step 04b."; $c->log_debug($pfx, $step, "Files on the first FTP storage");
            my $ftp_node = _node2anode(node($job, $hostname => 'ftp'));
            my $ftpct_first = $ftp_node->[0];
            _ftpattr_set($ftpct_first);
            my $useftp = value($ftpct_first, 'ftphost') ? 1 : 0;
            my $ftplist = $useftp ? ftpgetlist($ftpct_first, qr/^[^.]/) : [];
            my @ftpfiles = sort {$a cmp $b} @$ftplist;
            $c->log_debug($pfx, sprintf(" - %s",$_)) foreach @ftpfiles;
            $c->log_debug($pfx x 2, "SKIPPED") unless $useftp;
            $tbl->row(localtime2date_time, sprintf("%s Files on FTP", $step), $useftp ? join("\n", @ftpfiles) : '--- NONE ---', $useftp ? 'OK' : 'SKIPPED');
            
            # Step 04c. Получение списка файлов имеющихся архивов на HTTP первого источника если указаны его атрибуты
            $step = "Step 04c."; $c->log_debug($pfx, $step, "Files on the first HTTP storage");
            my $http_node = _node2anode(node($job, $hostname => 'http'));
            my $usehttp = value($http_node->[0], 'uri') ? 1 : 0;
            my $httplist = [];
            if ($usehttp) {
                my $first_uri = value($http_node->[0], 'uri') || '';
                my $first_agent = new App::MBUtiny::CollectorAgent(
                        uri         => $first_uri,
                        user        => value($http_node->[0], 'user'),
                        password    => value($http_node->[0], 'password'),
                        timeout     => value($http_node->[0], 'timeout'),
                    );
                my $first_status = $first_agent->list(
                        host        => $hostname,
                    );
                        
                # Итог операции
                if ($first_status) {
                    my $ag_res = $first_agent->response;
                    $httplist = array($ag_res => 'data/list');
                    $c->log_debug($pfx, sprintf(" - %s",$_)) foreach @$httplist;
                } else {
                    $c->log_error($pfx x 2, sprintf("ERROR: %s",unidecode($first_agent->error)));
                    $ferror = 1;
                }
                $tbl->row(localtime2date_time, sprintf("%s Files on HTTP", $step), 
                    $first_status ? (join("\n", @$httplist) || ' --- NONE --- ') : unidecode($first_agent->error), $first_status ? 'OK' : 'ERROR');
            } else {
                $c->log_debug($pfx x 2, "SKIPPED");
                $tbl->row(localtime2date_time, sprintf("%s Files on HTTP", $step), '--- NONE ---', 'SKIPPED');
            }
            my @httpfiles = sort {$a cmp $b} @$httplist;

            
            #####
            # Step 05. Удаление старых файлов архивов на приемниках
            #####
            
            # Step 05a. Удаление старых файлов архивов на локальном хранилище
            $step = "Step 05a."; $c->log_debug($pfx, $step, "Delete old backups on LOCAL storage");
            if ($uselocal) {
                foreach my $localdir (@$localdir_node) {
                    preparedir($localdir) unless (-e $localdir) && (-d $localdir or -l $localdir);
                    foreach my $f (@localfiles) {
                        my $ffull = catfile($localdir,$f);
                        if ($keepfiles{$f}) {
                            $c->log_debug($pfx, sprintf(" - [ SKIP ] %s", $ffull));
                        } else {
                            if (unlink($ffull)) {
                                $c->log_debug($pfx, sprintf(" - [DELETE] %s", $ffull));
                                $tbl->row(localtime2date_time, sprintf("%s Delete from LOCAL", $step), $ffull, 'OK');
                                
                                # Удаляем на коллекторах
                                if (value($job, $hostname => 'local/fixup')) {
                                    my $delstat = $self->_del($colls, host => $hostname, file => $f);
                                    $tbl->row(localtime2date_time, "COLLECTOR DELETE [LOCAL]", sprintf("See log: %s", $c->logfile), 'ERROR') unless $delstat;
                                }
                            } else {
                                $c->log_error($pfx x 2, sprintf("ERROR: Can't delete file \"%s\": %s", $ffull, $!));
                                $tbl->row(localtime2date_time, sprintf("%s Delete from LOCAL", $step), sprintf("Can't delete file \"%s\": %s", $ffull, $!), 'ERROR');                            
                            }
                        }
                    }
                }
            } else {
                $c->log_debug($pfx x 2, "SKIPPED");
                $tbl->row(localtime2date_time, sprintf("%s Delete from LOCAL", $step), 'Undefined <Local> section', 'SKIPPED');
            }
            
            # Step 05b. Удаление старых файлов архивов на FTP
            $step = "Step 05b."; $c->log_debug($pfx, $step, "Delete old backups on FTP storage");
            if ($useftp) {
                foreach my $ftpct (@$ftp_node) {
                    _ftpattr_set($ftpct);
                    my $ftph = ftp($ftpct, 'connect');
                    my $ftpuri = sprintf("ftp://%s\@%s/%s", value($ftpct, 'ftpuser'), value($ftpct, 'ftphost'), value($ftpct, 'ftpdir'));
                    unless ($ftph) {
                        my $reason = sprintf("ERROR: Can't connect to remote FTP server %s", $ftpuri);
                        $c->log_error($pfx x 2, $reason);
                        $tbl->row(localtime2date_time, sprintf("%s Delete from FTP", $step), $reason, 'ERROR');
                        $ftpct->{skip} = 1;
                        $ftpct->{reason} = $reason;
                        $ferror = 1;
                        next;
                    };
                    foreach my $f (@ftpfiles) {
                        if ($keepfiles{$f}) {
                                $c->log_debug($pfx, sprintf(" - [ SKIP ] %s", $f));
                        } else {
                            if ($ftph->delete($f)) {
                                $c->log_debug($pfx, sprintf(" - [DELETE] %s from %s", $f, $ftpuri));
                                $tbl->row(localtime2date_time, sprintf("%s Delete from FTP", $step), sprintf("%s from %s", $f, $ftpuri), 'OK');
                                
                                # Удаляем на коллекторах
                                if (value($job, $hostname => 'ftp/fixup')) {
                                    my $delstat = $self->_del($colls, host => $hostname, file => $f);
                                    $tbl->row(localtime2date_time, "COLLECTOR DELETE [FTP]", sprintf("See log: %s", $c->logfile), 'ERROR') unless $delstat;
                                }
                            } else {
                                $c->log_error($pfx x 2, sprintf("ERROR: Can't delete file \"%s\" from %s: %s", $f, $ftpuri, $ftph->message));
                                $tbl->row(localtime2date_time, sprintf("%s Delete from FTP", $step), sprintf("%s from %s\n%s", $f, $ftpuri, $ftph->message || ''), 'ERROR');
                                $ferror = 1;
                            }
                        }
                    }
                    $ftph->quit() if $ftph;
                }
            } else {
                $c->log_debug($pfx x 2, "SKIPPED");
                $tbl->row(localtime2date_time, sprintf("%s Delete from FTP", $step), 'Undefined <FTP> section', 'SKIPPED');
            }

            # Step 05c. Удаление старых файлов архивов на HTTP хранилище
            $step = "Step 05c."; $c->log_debug($pfx, $step, "Delete old backups on HTTP storage");
            if ($usehttp) {
                foreach my $httpct (@$http_node) {
                    my $http_uri = value($httpct, 'uri') || '';
                    my $agent = new App::MBUtiny::CollectorAgent(
                            uri         => $http_uri,
                            user        => value($httpct, 'user'),
                            password    => value($httpct, 'password'),
                            timeout     => value($httpct, 'timeout'),
                        );
                    foreach my $f (@httpfiles) {
                        if ($keepfiles{$f}) {
                            $c->log_debug($pfx, sprintf(" - [ SKIP ] %s", $f));
                        } else {
                            my $del_status = $agent->del(
                                host    => $hostname,
                                file    => $f,
                            );
                            
                            if ($del_status) {
                                $c->log_debug($pfx, sprintf(" - [DELETE] %s from %s", $f, $http_uri));
                                $tbl->row(localtime2date_time, sprintf("%s Delete from HTTP", $step), sprintf("%s from %s: %s", $f, $http_uri, unidecode(value($agent->response => 'data/message') || '')), 'OK');
                                
                                # Удаляем на коллекторах
                                if (value($job, $hostname => 'ftp/fixup')) {
                                    my $delstat = $self->_del($colls, host => $hostname, file => $f, http_uri => $http_uri);
                                    $tbl->row(localtime2date_time, "COLLECTOR DELETE [HTTP]", sprintf("See log: %s", $c->logfile), 'ERROR') unless $delstat;
                                }
                            } else {
                                $c->log_error($pfx x 2, sprintf("ERROR: Can't delete file \"%s\" from %s: %s", $f, $http_uri, unidecode($agent->error)));
                                $tbl->row(localtime2date_time, sprintf("%s Delete from HTTP", $step), sprintf("%s from %s\n%s", $f, $http_uri, unidecode($agent->error)), 'ERROR');
                                $ferror = 1;
                            }
                        }
                    }
                }
            } else {
                $c->log_debug($pfx x 2, "SKIPPED");
                $tbl->row(localtime2date_time, sprintf("%s Delete from HTTP", $step), 'Undefined <HTTP> section', 'SKIPPED');
            }

            # Step 06. Сжатие во временную папку (DATADIR)
            $step = "Step 06."; $c->log_debug($pfx, $step, "Compression");
            my $cdd = date2dig(); ($maskfmt{YEAR}, $maskfmt{MONTH}, $maskfmt{DAY}) = ($1,$2,$3) if $cdd =~ /(\d{4})(\d{2})(\d{2})/;
            my $fout = dformat($arcmask,\%maskfmt);
            my $outd = catdir($c->datadir,OBJECTS_DIR);
            my $outf = catfile($outd,$fout);
            $c->fcompress(
                -list   => $objects,
                -out    => $outf,
                -arcdef => $arcdef,
            );
            $ostat = -e $outf;
            $ferror = 1 unless $ostat;
            $c->log_debug($pfx x 2, "$outf:", $ostat ? 'OK' : 'ERROR');
            $tbl->row(localtime2date_time, sprintf("%s Compression", $step), $fout, $ostat ? 'OK' : 'ERROR');
            
            # Step 06a. Генерация контролькной суммы SHA1
            $step = "Step 06a."; $c->log_debug($pfx, $step, "SHA1");
            my $sha1 = '';
            if (value($job, $hostname => "sha1sum")) {
                $sha1 = sha1sum($outf);
                $c->log_debug($pfx x 2, $sha1);
                $tbl->row(localtime2date_time, sprintf("%s SHA1", $step), $sha1 ? $sha1 : '', $sha1 ? 'OK' : 'ERROR');
            } else {
                $c->log_debug($pfx x 2, "SKIPPED");
            }
            
            # Step 06b. Генерация контролькной суммы MD5
            $step = "Step 06b."; $c->log_debug($pfx, $step, "MD5");
            my $md5 = '';
            if (value($job, $hostname => "md5sum")) {
                $md5 = md5sum($outf);
                $c->log_debug($pfx x 2, $md5);
                $tbl->row(localtime2date_time, sprintf("%s MD5", $step), $md5 ? $md5 : '', $md5 ? 'OK' : 'ERROR');
            } else {
                $c->log_debug($pfx x 2, "SKIPPED");
            }
            

            #####
            # Step 07. Отправка архива в хранилища
            #####
            
            # Step 07a. Отправка архива в локальные хранилища
            $step = "Step 07a."; $c->log_debug($pfx, $step, "Store file \"$fout\" to LOCAL directories");
            if ($uselocal) {
                foreach my $localdir (@$localdir_node) {
                    $c->fcopy(
                        -in     => $outd,
                        -out    => $localdir, # Destination directory
                        -list   => $fout,
                    );
                    my $ffull = catfile($localdir,$fout);
                    $ostat = (-e $ffull) && (-s $ffull == -s $outf);
                    
                    # Итог операции
                    $c->log_debug($pfx, sprintf(" - %s on %s: %s", $fout, $localdir, $ostat ? 'OK' : 'ERROR'));
                    $tbl->row(localtime2date_time, sprintf("%s Store file to LOCAL", $step), sprintf("%s on\n%s", $fout, $localdir), $ostat ? 'OK' : 'ERROR');
                    $ferror = 1 unless $ostat;
                    
                    # Фиксап по операции
                    if (value($job, $hostname => 'local/fixup')) {
                        my $fixstat = $self->_fixup($colls,
                                status  => $ostat ? 1 : 0,
                                host    => $hostname,
                                file    => $fout, # Name
                                path    => $outf, # /path/to/file
                                sha1    => $sha1, # Optional
                                md5     => $md5,  # Optional
                                comment => value($job, $hostname => 'local/comment'), # Optional
                                message => sprintf("%s: %s -> %s",
                                        ($ostat ? 'Files successfully stored to LOCAL directoy' : 'An error occurred while sending data to an LOCAL directory'), $fout, $localdir,
                                    ), # Optional
                            ); # данные для фиксапа
                        $tbl->row(localtime2date_time, "COLLECTOR FIXUP (LOCAL)", sprintf("See log: %s", $c->logfile), 'ERROR') && ($ferror = 1) unless $fixstat;
                    }
                }
            } else {
                $c->log_debug($pfx, sprintf(" - %s: %s", $fout, "SKIPPED because undefined LOCAL section"));
                $tbl->row(localtime2date_time, sprintf("%s Store file to LOCAL", $step), 'Undefined <Local> section', 'SKIPPED');
            }

            # Step 07b. Отправка архива по FTP
            $step = "Step 07b."; $c->log_debug($pfx, $step, "Store file \"$fout\" to FTP");
            if ($useftp) {
                foreach my $ftpct (@$ftp_node) {
                    _ftpattr_set($ftpct);
                    my $ftpuri = sprintf("ftp://%s\@%s/%s", value($ftpct, 'ftpuser') || '', value($ftpct, 'ftphost') || '', value($ftpct, 'ftpdir') || '');
                    my $reason = "File successfully stored to FTP";
                    if (value($ftpct, 'skip')) {
                        $ostat = 0;
                        $reason = value($ftpct, 'reason') || sprintf("Undefined error with FTP connection: %s", $ftpuri);
                    } else {
                        my $ftph    = ftp($ftpct, 'connect');
                        $ftph->binary;
                        my $fssrc   = -e $outf ? (-s $outf) : 0; # Размер исходного файла
                        my $fsdst = $ftph->size($fout) || 0;
                        if ($fssrc && $fssrc == $fsdst) {
                            $ostat = 1;
                            $reason = "File has been stored to FTP previously";
                        } else {
                            $ostat = $ftph->put($outf,$fout);
                            if ($ostat) {
                                $fsdst = $ftph->size($fout) || 0;
                                unless ($fssrc && $fssrc == $fsdst) {
                                    $ostat = 0;
                                    $reason = sprintf("An error occurred while sending data to an FTP. SRC_FILE_SIZE = %d; DST_FILE_SIZE = %d", $fssrc, $fsdst);
                                }
                            } else {
                                $reason = sprintf("Cannot put file \"%s\": %s", $outf, $ftph->message);
                            }
                        }
                        $ftph->quit() if $ftph;
                    }
                    
                    # Итог операции
                    $c->log_debug($pfx, sprintf(" - %s on %s: %s", $fout, $ftpuri, $ostat ? 'OK' : 'ERROR'));
                    $c->log_debug($pfx x 2, $reason);
                    $tbl->row(localtime2date_time, sprintf("%s Store file to FTP", $step), sprintf("%s on\n%s", $fout, $ftpuri), $ostat ? 'OK' : 'ERROR');
                    $ferror = 1 unless $ostat;
                        
                    # Фиксап по операции
                    if (value($ftpct, 'fixup')) {
                        my $fixstat = $self->_fixup($colls,
                                status  => $ostat ? 1 : 0,
                                host    => $hostname,
                                file    => $fout, # Name
                                path    => $outf, # /path/to/file
                                sha1    => $sha1, # Optional
                                md5     => $md5,  # Optional
                                comment => value($ftpct, 'comment'), # Optional
                                message => sprintf("%s: %s -> %s", $reason, $fout, $ftpuri), # Optional
                            ); # данные для фиксапа
                        $tbl->row(localtime2date_time, "COLLECTOR FIXUP (FTP)", sprintf("See log: %s", $c->logfile), 'ERROR') && ($ferror = 1) unless $fixstat;
                    }
                }
            } else {
                $c->log_debug($pfx, sprintf(" - %s: %s", $fout, "SKIPPED because undefined FTP section"));
                $tbl->row(localtime2date_time, sprintf("%s Store file to FTP", $step), 'Undefined <FTP> section', 'SKIPPED');
            }

            # Step 07c. Отправка архива по HTTP
            $step = "Step 07c."; $c->log_debug($pfx, $step, "Store file \"$fout\" to HTTP");
            if ($usehttp) {
                foreach my $httpct (@$http_node) {
                    my $http_uri = value($httpct, 'uri') || '';
                    my $agent = new App::MBUtiny::CollectorAgent(
                            uri         => $http_uri,
                            user        => value($httpct, 'user'),
                            password    => value($httpct, 'password'),
                            timeout     => value($httpct, 'timeout'),
                        );
                    my $upload_status = $agent->upload(
                            host        => $hostname,
                            file        => $fout, # Name
                            path        => $outf, # /path/to/file
                            sha1        => $sha1, # Optional
                            md5         => $md5,  # Optional
                            comment     => value($httpct, 'comment'), # Optional
                        );
                        
                    # Итог операции
                    my $ag_res = $agent->response;
                    my $ag_id = $upload_status ? (value($ag_res => 'data/id') || 0) : 0;
                    $c->log_debug($pfx, sprintf(" - %s on %s: %s", $fout, $http_uri, $upload_status ? 'OK' : 'ERROR'));
                    $tbl->row(localtime2date_time, sprintf("%s Store file to HTTP", $step), sprintf("#%d %s on\n%s", $ag_id, $fout, $http_uri), 
                        $upload_status ? 'OK' : 'ERROR');
                    
                    # Status
                    if ($upload_status) {
                        $c->log_debug($pfx x 2, sprintf("#%d %s: %s", $ag_id, value($ag_res => 'data/path') || '', unidecode(value($ag_res => 'data/message') || '')));
                    } else {
                        $c->log_error($pfx x 2, sprintf("UPLOAD ERROR: %s",unidecode($agent->error)));
                        $ferror = 1;
                    }       

                    # FixUp
                    if (value($httpct, 'fixup')) {
                        my $fixstat = $self->_fixup($colls, 
                                status  => $upload_status ? 1 : 0,
                                id      => $ag_id,
                                http_uri=> $http_uri,
                                host    => $hostname,
                                file    => $fout, # Name
                                path    => $outf, # /path/to/file
                                sha1    => $sha1,                       # Optional
                                md5     => $md5,                        # Optional
                                comment => value($httpct, 'comment'),   # Optional
                                message => $upload_status               # Optional
                                    ? sprintf(
                                            "%s: %s -> %s (%s)",
                                            value($ag_res => 'data/message') || '', $fout, $http_uri, value($ag_res => 'data/path') || '',
                                        )
                                    : sprintf("%s: %s -> %s",
                                            $agent->error, $fout, $http_uri,
                                        ), 
                            ); # данные для фиксапа
                        $tbl->row(localtime2date_time, sprintf("COLLECTOR FIXUP (HTTP by %s)", $ag_id ? "id" : "file" ), sprintf("See log: %s", $c->logfile), 'ERROR') && ($ferror = 1) unless $fixstat;
                    }
                }
            } else {
                $c->log_debug($pfx, sprintf(" - %s: %s", $fout, "SKIPPED because undefined HTTP section"));
                $tbl->row(localtime2date_time, sprintf("%s Store file to HTTP", $step), 'Undefined <HTTP> section', 'SKIPPED');
            }
            
            
            #
            # Step 08. Удаление архива из временной папки (DATADIR)
            #
            $step = "Step 08."; $c->log_debug($pfx, $step, "Delete temporary file \"$fout\"");
            $c->frm(
                -in       => $outd,
                -list     => $fout,
            );
            
            # Step 08a. Удаление путей paths_for_remove
            $step = "Step 08a."; $c->log_debug($pfx, $step, "Delete temporary files") if @paths_for_remove;
            foreach my $rmo (@paths_for_remove) {
                $c->log_debug($pfx x 2, sprintf(" - \"%s\"", $rmo));
                rmtree($rmo) if -e $rmo;
            }
            
            # формирование вывода в виде таблички
            $status = 0 if $ferror;
            $tbl->hr;
            $tbl->row(localtime2date_time, 'STATUS', '', $ferror ? 'ERROR' : 'OK');
            my $tbl_rslt = $tbl->draw() || '';
            $ret .= sprintf("Host: %s; Status: %s\n", $hostname, $ferror ? 'ERROR' : 'OK');
            $ret .= sprintf("%s\n", $tbl_rslt);
            
            
            #
            # Отправка письма об статусе операции если установлен флаг отправки отчета
            #
            if ($usemail && ($sendreport || ($senderrorreport && $ferror)) ) {
                my %ma = ();
                foreach my $k (keys %$maildata) {
                    $ma{"-".$k} = $maildata->{$k};
                }
                
                if ($c->testmode) { # Тестовый режим
                    $ma{'-to'} = $maildata->{'testmail'} || $ma{'-to'};
                    $c->log_debug($pfx, "Sending report to TEST e-mail");
                } elsif ($senderrorreport && $ferror) { # Найдены ошибки! Значит ошибочный режим
                    $ma{'-to'} = $maildata->{'errormail'} || $ma{'-to'};
                    $c->log_debug($pfx, "Sending report to ERROR e-mail");
                } else {
                    $c->log_debug($pfx, "Sending report to e-mail");
                }
                
                my $testpfx = $c->testmode() ? '[TEST MODE] ' : '';
                $ma{'-subject'} ||= !$ferror
                    ? sprintf($testpfx."MBUtiny %s BACKUP Report: %s", $VERSION, $hostname)
                    : sprintf($testpfx."MBUtiny %s BACKUP ERROR Report: %s", $VERSION, $hostname);
                $ma{'-message'} ||= !$ferror
                    ? sprintf("Хост \"%s\" обработан без ошибок\n\n%s", $hostname, $tbl_rslt)
                    : sprintf("Хост \"%s\" обработан с ошибками\n\n%s", $hostname, $tbl_rslt);
                $ma{'-message'} .= "\n---\n"
                                 . sprintf("Generated by    : MBUtiny %s\n", $VERSION)
                                 . sprintf("Date generation : %s\n", localtime2date_time())
                                 . sprintf("MBUTiny Id      : %s\n", '$Id: MBUtiny.pm 76 2014-09-24 15:02:37Z abalama $')
                                 . sprintf("Time Stamp      : %s\n", $c->tms())
                                 . sprintf("Configuration   : %s\n", $c->cfgfile);
                $ma{'-attach'} = _attach($ma{'-attach'}) || [];
                my $sent = send_mail(%ma);
                $c->log_debug($pfx, sprintf(" - %s:", $ma{'-to'}), $sent ? 'OK (Mail has been sent)' : 'FAILED (Mail was not sent)');
            } else {
                $c->log_debug($pfx, "Sending report disabled by user");
            }
            
            #
            # END
            #
            
            $c->log_debug(sprintf("--> Done: \"%s\". %s", $hostname, $ferror ? 'ERROR' : 'OK'));
        } else {
            $ret .= sprintf("Host: %s; Status: %s\n\n", $hostname, 'SKIP');
            $c->log_debug(sprintf("--> Skipped \"%s\". Enable flag is off", $hostname));
        }
        
        
        #::say(Data::Dumper::Dumper(_node2anode(node($job, $hostname, "test"))));
    }
    $c->log_debug("Finish processing hosts");    
    
    $self->msg($ret);
    #$c->log_debug(Data::Dumper::Dumper(@joblist));
    
    return $status;
}
sub test {
    my $self = shift;
    my $args = array(shift);
    my $c    = $self->c;
    my $config = $c->config;
    my @saybuffer;
    
    # Данные для тестирования
    my $sendreport      = value($config => 'sendreport') || 0;
    my $senderrorreport = value($config => 'senderrorreport') || 0;

    # Табличные заголовки
    my @tblfields = ( # 
            [20, 'TEST NAME'],
            [45, 'DESCRIPTION OF TEST / DATA OF TEST'],
            [8,  'STATUS'],
        );
    
    # Part 1. Internal constants
    push @saybuffer, "PART 1. INTERNAL CONSTANTS";
    my $tbl_constants = new Text::SimpleTable((
            [20, 'PARAM'],
            [56, 'VALUE'],
        ));        
    $tbl_constants->row('Config File', $c->cfgfile);
    $tbl_constants->row('Config Dir',  $c->confdir);
    $tbl_constants->row('Data Dir',    $c->datadir);
    $tbl_constants->row('Void File',   $c->voidfile);
    $tbl_constants->row('Log File',    $c->logfile);
    $tbl_constants->row('Log Dir',     $c->logdir);
    push @saybuffer, $tbl_constants->draw() || '';
    
    # Part 2. Loaded configuration files
    push @saybuffer, "PART 2. LOADED CONFIGURATION FILES";
    my $loadstatus = value($config => 'loadstatus');
    push(@saybuffer, sprintf("Can't read configuration file \"%s\"!"), $c->cfgfile) && return 0 unless $loadstatus;
    my $tbl_configfiles = new Text::SimpleTable(( [79, 'FILE'] ));
    my $configfiles = array($config => 'configfiles') || [];
    $tbl_configfiles->row($_) foreach (@$configfiles);
    push @saybuffer, $tbl_configfiles->draw() || '';
    
    # Part 3. Readed hosts
    push @saybuffer, "PART 3. READED HOSTS";
    my $tbl_jobs = new Text::SimpleTable((
            [68, 'HOST'],
            [8,  'STATUS'],
        ));
    my @joblist;
    foreach my $job ((sort {(keys(%$a))[0] cmp (keys(%$b))[0]} ($self->get_jobs))) {
        my $hostname = _name($job);
        my $hostskip = (!@$args || grep {lc($hostname) eq lc($_)} @$args) ? 0 : 1;
        $c->log_debug(sprintf("Loading host \"%s\"... %s", $hostname, ($hostskip ? 'SKIPPED' : 'LOADED') ));
        if ($hostskip) {
            $tbl_jobs->row($hostname,'SKIPPED');
        } else {
            my $enabled = value($job, $hostname => 'enable');
            push @joblist, $job if $enabled;
            $tbl_jobs->row($hostname, $enabled ? 'ENABLED' : 'DISABLED');
        }
    }
    push @saybuffer, $tbl_jobs->draw();    
    
    # Part 4. Testing hosts
    push @saybuffer, "PART 4. TESTING HOSTS";
    $c->log_debug("Start testing hosts");
    my $pfx = " " x 3;
    my $gstatus = 1;
    foreach my $job (@joblist) {
        my $hostname = _name($job);
        $c->log_debug(sprintf("--> Testing %s", $hostname));
        my $tbl = Text::SimpleTable->new(@tblfields);
        my $status = 1;
        
        # Имя хоста
        $tbl->row('Host name', $hostname || '', $hostname ? 'PASSED' : 'FAILED');
        
        # Step 01a. Получение списка объектов для обработки
        $c->log_debug($pfx, "Step 01a. Regular objects");
        my $objects = array($job, $hostname => 'object');
        my $objects_num = scalar(@$objects) || 0;
        $tbl->row("Regular objects", $objects_num, ($objects_num ? 'PASSED' : 'SKIPPED'));
        
        
        # Step 01b. Получение списка эксклюзивных объектов для обработки (exclude)
        $c->log_debug($pfx, "Step 01b. Exclusive objects");
        my $exclude_node = _node_correct(node($job, $hostname => "exclude"), "object");
        my @exc_objects;
        foreach my $exclude (@$exclude_node) {
            my $exc_name = _name($exclude);
            my $exc_object = value($exclude, $exc_name, "object");
            push @exc_objects, $exc_object if $exc_object;
        }
        push @$objects, @exc_objects;
        my $exc_objects_num = scalar(@exc_objects) || 0;
        $tbl->row("Exclusive objects", $exc_objects_num, ($exc_objects_num ? 'PASSED' : 'SKIPPED'));
       
        
        # Step 02. Проверка доступности файлов для обработки
        $c->log_debug($pfx, "Step 02. Check available objects (files & directories)");
        my $avlobj = 0;
        my @resobjs;
        foreach my $obj (@$objects) {
            my $est = -e $obj ? 1 : 0;
            push @resobjs, sprintf("%s: %s", ($est ? 'OK' : 'NO'), variant_stf($obj, 41));
            $avlobj++ if $est;
            if ($est) {
                $c->log_debug($pfx, " -           \"$obj\"");
            } else {
                $c->log_debug($pfx, " - [MISSING] \"$obj\"");
            }
        }
        $tbl->row("Existing objects", (join("\n", @resobjs) || '--- NONE ---'), $avlobj ? ((scalar(@$objects) == $avlobj) ? 'PASSED' : 'FAILED') : 'SKIPPED');
        
        
        # Step 03. Получение нод коллекторов и создание объектов с ними. 
        $c->log_debug($pfx, "Step 03. Get collector data");
        my $collector_node = _node2anode(node($job, $hostname => 'collector'));
        my @colls;
        my $coll_errs = 0;
        foreach my $coll (grep {value($_ => 'uri')}  @$collector_node) {
            my $coll_uri = value($coll, 'uri') || '';
            my $agent = new App::MBUtiny::CollectorAgent(
                        uri         => $coll_uri,
                        user        => value($coll, 'user'),
                        password    => value($coll, 'password'),
                        timeout     => value($coll, 'timeout'),
                    );
            if ($agent->check) {
                $c->log_debug($pfx, sprintf(" -         %s", $coll_uri));
                push @colls, sprintf("OK: %s", variant_stf($coll_uri, 41));
            } else {
                $c->log_debug($pfx, sprintf(" - [ERROR] %s: %s", $coll_uri, unidecode($agent->error)));
                push @colls, sprintf("NO: %s", variant_stf($coll_uri, 41));
                $coll_errs++;
            }
        }
        $status = 0 if $coll_errs;
        $tbl->row("Collectors", (join("\n", @colls) || '--- NONE ---'), !$coll_errs ? 'PASSED' : 'FAILED');

        # Step 04a. Получение последнего файла, имеющегося архива в каждом локальном хранидище
        $c->log_debug($pfx, "Step 04a. Check LOCAL storages");
        my $localdir_node = array($job, $hostname => 'local/localdir') || [];
        foreach my $localdir (@$localdir_node) {
            next unless $localdir;
            if ((-e $localdir) && (-d $localdir or -l $localdir)) {
                my $locallist = getlist($localdir) || [];
                my @localfiles = sort {$a cmp $b} @$locallist;
                
                $c->log_debug($pfx, sprintf(" - %s %s", (@localfiles ? '         ' : '[MISSING]'), $localdir));
                $c->log_debug($pfx, sprintf("              - %s",$_)) foreach (@localfiles);
                
                my $last_obj = @localfiles ? pop( @localfiles) : '';
                $tbl->row('Last LOCAL file', $localdir."/\n".($last_obj || '--- NONE ---'), $last_obj ? 'PASSED' : 'SKIPPED');
            } else {
                $tbl->row('Last LOCAL file', sprintf("Bad local storage \"%s\"",$localdir), 'FAILED');
                $status = 0;
            }
        }
        

        # Step 04b. Получение последнего файла, имеющегося архива на каждом FTP сервере
        $c->log_debug($pfx, "Step 04b. Check FTP storages");
        my $ftp_node = _node2anode(node($job, $hostname => 'ftp'));
        foreach my $ftpct (@$ftp_node) {
            if (value($ftpct, 'ftphost')) {
                _ftpattr_set($ftpct);
                #::debug(Dumper($ftpct));
                my $ftpuri = sprintf("ftp://%s\@%s/%s", value($ftpct, 'ftpuser'), value($ftpct, 'ftphost'), value($ftpct, 'ftpdir'));
                my $ftplist = ftpgetlist($ftpct, qr/^[^.]/) || [];
                my @ftpfiles = sort {$a cmp $b} @$ftplist;
                
                $c->log_debug($pfx, sprintf(" - %s %s", (@ftpfiles ? '         ' : '[MISSING]'), $ftpuri));
                $c->log_debug($pfx, sprintf("              - %s",$_)) foreach (@ftpfiles);
                my $last_obj = @ftpfiles ? pop(@ftpfiles) : '';
                $tbl->row('Last FTP file', $ftpuri."/\n".($last_obj || '--- NONE ---'), $last_obj ? 'PASSED' : 'SKIPPED');
            }
        }
        
        
        # Step 04c. Получение последнего файла, имеющегося архива на каждом HTTP сервере
        my $http_node = _node2anode(node($job, $hostname => 'http'));
        foreach my $httpct (@$http_node) {
            my $http_uri = value($httpct, 'uri') || '';
            if ($http_uri) {
                my $agent = new App::MBUtiny::CollectorAgent(
                        uri         => $http_uri,
                        user        => value($httpct, 'user'),
                        password    => value($httpct, 'password'),
                        timeout     => value($httpct, 'timeout'),
                    );
                my $http_status = $agent->list( host => $hostname );
                if ($http_status) {
                    my $ag_res = $agent->response;
                    my $httplist = array($ag_res => 'data/list');
                    
                    $c->log_debug($pfx, sprintf(" - %s %s", (@$httplist ? '         ' : '[MISSING]'), $http_uri));
                    $c->log_debug($pfx, sprintf("              - %s",$_)) foreach (@$httplist);
                    my $last_obj = @$httplist ? pop(@$httplist) : '';
                    $tbl->row('Last HTTP file', sprintf("%s/\n%s", $http_uri,($last_obj || '--- NONE ---')), $last_obj ? 'PASSED' : 'SKIPPED');
                } else {
                    $c->log_debug($pfx, sprintf(" - %s %s", '[ ERROR ]', $http_uri));
                    $c->log_debug($pfx x 2, sprintf("%s", unidecode($agent->error)));
                    $tbl->row('Last HTTP file', sprintf("%s/\n%s", $http_uri, unidecode($agent->error)), 'FAILED');
                    $status = 0;
                }
            }
        }


        # Status
        $tbl->hr;
        $tbl->row('STATUS', '', $status ? 'PASSED' : 'FAILED');
        $gstatus = 0 unless $status;
        
        push @saybuffer, $tbl->draw();    
        $c->log_debug(sprintf("--> Done"));
    }
    $c->log_debug("Finish testing hosts");    
    
    # Result
    my $rslt = join("\n",@saybuffer);

    # Отправка письма об статусе операции если установлен флаг отправки отчета
    my $maildata = node($config => 'sendmail');
    if (value($maildata, "to") && ($sendreport || ($senderrorreport && !$gstatus)) ) {
        my %ma = ();
        foreach my $k (keys %$maildata) {
            $ma{"-".$k} = value($maildata, $k);
        }
                
        if ($c->testmode) { # Тестовый режим
            $ma{'-to'} = value($maildata, 'testmail') || $ma{'-to'} || '';
            $c->log_debug("Sending report to TEST e-mail");
        } elsif ($senderrorreport && !$gstatus) { # Найдены ошибки! Значит ошибочный режим
            $ma{'-to'} = value($maildata, 'errormail') || $ma{'-to'} || '';
            $c->log_debug("Sending report to ERROR e-mail");
        } else {
            $c->log_debug("Sending report to e-mail");
        }

        my $testpfx = $c->testmode() ? '[TEST MODE] ' : '';
        $ma{'-subject'} ||= $gstatus
            ? sprintf($testpfx."MBUtiny %s TEST Report", $VERSION)
            : sprintf($testpfx."MBUtiny %s TEST ERROR Report", $VERSION);
        $ma{'-message'} ||= $gstatus
            ? sprintf("Тестирование прошло без ошибок\n\n%s", $rslt)
            : sprintf("Тестирование прошло с ошибками\n\n%s", $rslt);
        $ma{'-message'} .= "\n---\n"
            . sprintf("Generated by    : MBUtiny %s\n", $VERSION)
            . sprintf("Date generation : %s\n", localtime2date_time())
            . sprintf("MBUTiny Id      : %s\n", '$Id: MBUtiny.pm 76 2014-09-24 15:02:37Z abalama $')
            . sprintf("Time Stamp      : %s\n", $c->tms())
            . sprintf("Configuration   : %s\n", $c->cfgfile);
        $ma{'-attach'} = _attach($ma{'-attach'}) || [];
        my $sent = send_mail(%ma);
        $c->log_debug($pfx, sprintf(" - %s:", $ma{'-to'}), $sent ? 'OK (Mail has been sent)' : 'FAILED (Mail was not sent)');
    } else {
        $c->log_debug("Sending report disabled by user");
    }

    $self->msg($rslt);
    return $gstatus;
}
sub restore {
    my $self = shift;
    my $args = array(shift);
    my $c    = $self->c;
    my $config = $c->config;
    my $ret = "";
    
    # Табличные заголовки
    my @tblfields = ( # 
            [19, 'DATE AND TIME'],
            [32, 'PROCESS NAME'],
            [42, 'DESCRIPTION OF PROCCESS / DATA OF PROCCESS'],
            [8,  'STATUS'],
        );
        
    # Определяем данные архиваторов
    my $arcdef = $config->{arc};
    croak "Error! Undefined <arc> section." unless $arcdef;
    
    # Определение даты
    my $tdate = pop @$args;
    my ( $_y, $_m, $_d ) = (localtime( time ))[5,4,3];
    my @ymd = (($_y+1900), ($_m+1), $_d);
    if (defined($tdate)) {
        if ($tdate =~ /(\d{4})\D+(\d{2})\D+(\d{2})/) {
            @ymd = ($1,$2,$3);
        } elsif ($tdate =~ /(\d{2})\D+(\d{2})\D+(\d{4})/) {
            @ymd = ($3,$2,$1);
        } else {
            push @$args, $tdate;
        }
    }
    #$c->log_debug(sprintf(">>> %d/%d/%d", @ymd));
    
    # Получение обработчиков
    my @joblist = $self->get_jobs;
    $c->log_debug("Start processing hosts");
    foreach my $job (sort {(keys(%$a))[0] cmp (keys(%$b))[0]} @joblist) {
        my $hostname = _name($job);
        my $hostskip = (!@$args || grep {lc($hostname) eq lc($_)} @$args) ? 0 : 1;
        $c->log_debug(sprintf("Loading configuration for host \"%s\"... %s", $hostname, ($hostskip ? 'SKIPPED' : 'LOADED') ));
        next if $hostskip;
        
        # Обработка хостов
        my $enabled  = value($job, $hostname => 'enable');
        if ($enabled) {
            $c->log_debug(sprintf("--> Begin processing: \"%s\"", $hostname));
            my $tbl = Text::SimpleTable->new(@tblfields);
            my $pfx = " " x 3;
            my $step = '';
            my $status = 0;
            
            #
            # Step 00. Определения умолчаний
            #
            $step = "Step 00."; $c->log_debug($pfx, $step, "Loading and preparing data");
            
            # Cоздание целевой папки (куда скачается файл и куда он разархивируется)
            my $target_dir = catdir($c->datadir, RESTORE_DIR, $hostname, sprintf("%04d%02d%02d",@ymd));
            preparedir($target_dir);
            
            # Формирование данных для архиватора
            my $arcname = value($job, $hostname => 'arcname') || 'tar';

            # Получение маски файлов архивов и преобразование ее согласно формату
            my $arcmask = value($job, $hostname => 'arcmask') || '[HOST]-[YEAR]-[MONTH]-[DAY].[EXT]';
            $arcmask =~ s/\[DEFAULT\]/[HOST]-[YEAR]-[MONTH]-[DAY].[EXT]/gi;
            my %maskfmt = (
                    HOST  => $hostname,
                    EXT   => value($arcdef, 'arc'=>$arcname=>'ext')  || '',
                    TYPE  => value($arcdef, 'arc'=>$arcname=>'type') || '',
                );
            ($maskfmt{YEAR}, $maskfmt{MONTH}, $maskfmt{DAY}) = 
                (sprintf("%04d",$ymd[0]), sprintf("%02d",$ymd[1]), sprintf("%02d",$ymd[2]));
            my $find_file = dformat($arcmask,\%maskfmt);
            $tbl->row(localtime2date_time, sprintf("%s Loading data", $step), $find_file, 'OK');
            $c->log_debug($pfx x 2, $find_file);
            
            #####
            # Step 01. Получение нод коллекторов и создание объектов с ними. 
            #####
            $step = "Step 01."; $c->log_debug($pfx, $step, "Get collector data");
            my $collector_node = _node2anode(node($job, $hostname => 'collector'));
            my $colls = [];
            foreach my $coll (grep {value($_ => 'uri')}  @$collector_node) {
                my $coll_uri = value($coll, 'uri') || '';
                my $agent = new App::MBUtiny::CollectorAgent(
                            uri         => $coll_uri,
                            user        => value($coll, 'user'),
                            password    => value($coll, 'password'),
                            timeout     => value($coll, 'timeout'),
                        );
                my $coll_status = $agent->check;
                
                # Итог операции
                $c->log_debug($pfx, sprintf(" - %s",$coll_uri));
                $tbl->row(localtime2date_time, sprintf("%s Collector ready", $step), sprintf("%s\n%s",$coll_uri, unidecode($agent->error)), $coll_status ? 'OK' : 'ERROR');
                if ($coll_status) {
                    push @$colls, $agent
                } else {
                    $c->log_error($pfx x 2, sprintf("ERROR: %s",unidecode($agent->error)));
                }
            }

            #####
            # Step 02. Получение нод приёмников
            #####
            my $downloaded = 0; # Статус того что файл уже скачен и распакован. Флаг для следующих обработок
            my $meta; # мета-данные взятые с коллектора, если они есть

            # Step 02a. Получение списка файлов имеющихся архивов в локальных хранилищах если указаны их атрибуты
            $step = "Step 02a."; $c->log_debug($pfx, $step, "Search file on the LOCAL storages");
            my $localdir_node = array($job, $hostname => 'local/localdir') || [];
            my $trylocal;
            foreach my $localdir (@$localdir_node) {
                my $locallist = getlist($localdir);
                $trylocal = _search_file($locallist, $find_file);
                if ($trylocal) { # Файл нашелся! Ура! 
                    my $file_src = catfile($localdir,$trylocal);
                    my $file_dst = catfile($target_dir,$trylocal);
                    $c->log_debug($pfx x 2, sprintf("Restore file %s from the LOCAL storage %s", $trylocal, $localdir));
                    
                    # Непосредственно копируем файл
                    $c->fcopy(
                        -in     => $localdir,
                        -out    => $target_dir,
                        -list   => $trylocal,
                    );
                    unless (-e $file_dst) {
                        $c->log_error($pfx, sprintf(" - [ERROR] Can't copy file %s from %s to %s",$trylocal, $localdir, $target_dir));
                        next
                    }
                    
                    # Пробуем получить данные с коллектора для него: 
                    $meta = $self->_info($colls, host => $hostname, file => $trylocal) if value($job, $hostname => 'local/fixup');
                    if ($meta) {
                        my $size = -s $file_dst || 0;
                        if (value($meta => "file_size") && value($meta => "file_size") ne $size){
                            $c->log_error($pfx, sprintf(" - [ERROR] File incorrect %s. Size got: %s; expected: %s",$file_dst, $size, uv2null(value($meta => "file_size"))));
                            next;
                        }
                        my $md5 = md5sum($file_dst);
                        if (value($meta => "file_md5") && value($meta => "file_md5") ne $md5) {
                            $c->log_error($pfx, sprintf(" - [ERROR] File incorrect %s. MD5 got: %s; expected: %s",$file_dst, $md5, uv2null(value($meta => "file_md5"))));
                            next;
                        }
                        my $sha1 = sha1sum($file_dst);
                        if (value($meta => "file_sha1") && value($meta => "file_sha1") ne $sha1) {
                            $c->log_error($pfx, sprintf(" - [ERROR] File incorrect %s. SHA1 got: %s; expected: %s",$file_dst, $sha1, uv2null(value($meta => "file_sha1"))));
                            next;
                        }
                    }
                    
                    # OK! Все проверки прошли
                    $c->log_debug($pfx, sprintf(" - [ OK ] %s from %s",$trylocal, $localdir));
                    $tbl->row(localtime2date_time, sprintf("%s File from LOCAL", $step), sprintf("%s from\n%s", $trylocal, $localdir), 'OK');
                    $downloaded = 1;
                    last;
                } else {
                    $c->log_debug($pfx, sprintf(" - [SKIP] %s", $localdir));
                }
            }
            $c->log_debug($pfx x 2, "SKIPPED") unless $downloaded;
            $tbl->row(localtime2date_time, sprintf("%s File from LOCAL", $step), '--- NONE ---' , 'SKIPPED') unless $downloaded;


            # Step 02b. Получение списка файлов имеющихся архивов на FTP хранилищах если указаны их атрибуты
            $step = "Step 02b."; $c->log_debug($pfx, $step, "Search file on the FTP storages");
            if ($downloaded) {
                $c->log_debug($pfx x 2, "SKIPPED");
                $tbl->row(localtime2date_time, sprintf("%s File from FTP", $step), '--- NONE ---' , 'SKIPPED');
            } else {
                # Попытка получить файл из FTP источника
                my $ftp_node = _node2anode(node($job, $hostname => 'ftp'));
                my $tryftp;
                foreach my $ftpct (@$ftp_node) {
                    _ftpattr_set($ftpct);
                    my $ftpuri = sprintf("ftp://%s\@%s/%s", value($ftpct, 'ftpuser'), value($ftpct, 'ftphost'), value($ftpct, 'ftpdir'));
                    my $ftph = ftp($ftpct, 'connect');
                    if ($ftph) {
                        $ftph->quit();
                    } else {
                        $c->log_error($pfx x 2, sprintf("ERROR: Can't connect to remote FTP server %s", $ftpuri));
                        next;
                    };
                    my $ftplist = ftpgetlist($ftpct, qr/^[^.]/);
                    $tryftp = _search_file($ftplist, $find_file);
                    if ($tryftp) { # Файл нашелся! Ура! 
                        my $file_dst = catfile($target_dir,$tryftp);
                        $c->log_debug($pfx x 2, sprintf("Restore file %s from the FTP storage %s", $tryftp, $ftpuri));
                        
                        # Скачиваем файл
                        my $ftp_status = $c->fetch(
                            -connect  => $ftpct,
                            -protocol => 'ftp',
                            -dir      => $target_dir,
                            -cmd      => 'copy',
                            -mode     => 'bin',
                            -list     => $tryftp,
                        );
                        unless ($ftp_status && -e $file_dst) {
                            $c->log_error($pfx, sprintf(" - [ERROR] Can't fetch file %s from %s to %s",$tryftp, $ftpuri, $target_dir));
                            next
                        }
                        
                        # Пробуем получить данные с коллектора для него: 
                        $meta = $self->_info($colls, host => $hostname, file => $tryftp) if value($ftpct => 'fixup');
                        if ($meta) {
                            my $size = -s $file_dst || 0;
                            if (value($meta => "file_size") && value($meta => "file_size") ne $size){
                                $c->log_error($pfx, sprintf(" - [ERROR] File incorrect %s. Size got: %s; expected: %s",$file_dst, $size, uv2null(value($meta => "file_size"))));
                                next;
                            }
                            my $md5 = md5sum($file_dst);
                            if (value($meta => "file_md5") && value($meta => "file_md5") ne $md5) {
                                $c->log_error($pfx, sprintf(" - [ERROR] File incorrect %s. MD5 got: %s; expected: %s",$file_dst, $md5, uv2null(value($meta => "file_md5"))));
                                next;
                            }
                            my $sha1 = sha1sum($file_dst);
                            if (value($meta => "file_sha1") && value($meta => "file_sha1") ne $sha1) {
                                $c->log_error($pfx, sprintf(" - [ERROR] File incorrect %s. SHA1 got: %s; expected: %s",$file_dst, $sha1, uv2null(value($meta => "file_sha1"))));
                                next;
                            }
                        }
                        
                        # OK! Все проверки прошли
                        $c->log_debug($pfx, sprintf(" - [ OK ] %s from %s",$tryftp, $ftpuri));
                        $tbl->row(localtime2date_time, sprintf("%s File from FTP", $step), sprintf("%s from\n%s", $tryftp, $ftpuri), 'OK');
                        $downloaded = 1;
                        last;
                    } else {
                        $c->log_debug($pfx, sprintf(" - [SKIP] %s", $ftpuri));
                    }
                }
                $c->log_debug($pfx x 2, "SKIPPED") unless $downloaded;
                $tbl->row(localtime2date_time, sprintf("%s File from FTP", $step), '--- NONE ---' , 'SKIPPED') unless $downloaded;
            }


            # Step 02c. Получение списка файлов имеющихся архивов на HTTP хранилищах если указаны их атрибуты
            $step = "Step 02c."; $c->log_debug($pfx, $step, "Search file on the HTTP storages");
            if ($downloaded) {
                $c->log_debug($pfx x 2, "SKIPPED");
                $tbl->row(localtime2date_time, sprintf("%s File from HTTP", $step), '--- NONE ---' , 'SKIPPED');
            } else {
                # Попытка получить файл из HTTP источника
                my $http_node = _node2anode(node($job, $hostname => 'http'));
                my $tryhttp;
                foreach my $httpct (@$http_node) {
                    my $http_uri = value($httpct, 'uri') || '';
                    my $agent = new App::MBUtiny::CollectorAgent(
                            uri         => $http_uri,
                            user        => value($httpct, 'user'),
                            password    => value($httpct, 'password'),
                            timeout     => value($httpct, 'timeout'),
                        );
                    my $http_status = $agent->list(
                            host        => $hostname,
                        );
                    # Итог операции
                    if ($http_status) {
                        my $httplist = array($agent->response => 'data/list');
                        $tryhttp = _search_file($httplist, $find_file);
                        #::debug(Dumper($httplist));
                    } else {
                        $c->log_error($pfx x 2, sprintf("ERROR %s: %s", $http_uri, unidecode($agent->error)));
                        next;
                    }
                    # Анализ найденного файла
                    if ($tryhttp) { # Файл нашелся! Ура! 
                        my $file_dst = catfile($target_dir,$tryhttp);
                        $c->log_debug($pfx x 2, sprintf("Restore file %s from the HTTP storage %s", $tryhttp, $http_uri));
                        
                        # Скачиваем файл
                        my $download_status = $agent->download(
                                host        => $hostname,
                                file        => $tryhttp,
                                path        => $file_dst,
                            );
                        if ($download_status) {
                            $c->log_debug($pfx x 2, sprintf("OK %s: %s", $http_uri, unidecode(value($agent->response => 'data/message') || '')));
                        } else {
                            $c->log_error($pfx x 2, sprintf("ERROR %s: %s", $http_uri, unidecode($agent->error)));
                            next;
                        }
                        unless (-e $file_dst) {
                            $c->log_error($pfx, sprintf(" - [ERROR] Can't fetch file %s from %s to %s",$tryhttp, $http_uri, $target_dir));
                            next
                        }

                        # Пробуем получить данные с коллектора для него: 
                        $meta = $self->_info($colls, host => $hostname, file => $tryhttp) if value($httpct => 'fixup');
                        if ($meta) {
                            my $size = -s $file_dst || 0;
                            if (value($meta => "file_size") && value($meta => "file_size") ne $size){
                                $c->log_error($pfx, sprintf(" - [ERROR] File incorrect %s. Size got: %s; expected: %s",$file_dst, $size, uv2null(value($meta => "file_size"))));
                                next;
                            }
                            my $md5 = md5sum($file_dst);
                            if (value($meta => "file_md5") && value($meta => "file_md5") ne $md5) {
                                $c->log_error($pfx, sprintf(" - [ERROR] File incorrect %s. MD5 got: %s; expected: %s",$file_dst, $md5, uv2null(value($meta => "file_md5"))));
                                next;
                            }
                            my $sha1 = sha1sum($file_dst);
                            if (value($meta => "file_sha1") && value($meta => "file_sha1") ne $sha1) {
                                $c->log_error($pfx, sprintf(" - [ERROR] File incorrect %s. SHA1 got: %s; expected: %s",$file_dst, $sha1, uv2null(value($meta => "file_sha1"))));
                                next;
                            }
                        }

                        # OK! Все проверки прошли
                        $c->log_debug($pfx, sprintf(" - [ OK ] %s from %s",$tryhttp, $http_uri));
                        $tbl->row(localtime2date_time, sprintf("%s File from HTTP", $step), sprintf("%s from\n%s", $tryhttp, $http_uri), 'OK');
                        $downloaded = 1;
                        last;
                    } else {
                        $c->log_debug($pfx, sprintf(" - [SKIP] %s", $http_uri));
                    }
                }
                $c->log_debug($pfx x 2, "SKIPPED") unless $downloaded;
                $tbl->row(localtime2date_time, sprintf("%s File from HTTP", $step), '--- NONE ---' , 'SKIPPED') unless $downloaded;
            }
            
            # Step 03. Извлечение во временную папку (DATADIR)
            $step = "Step 03."; $c->log_debug($pfx, $step, "Extraction");
            if ($downloaded) {
                my $x_ext = value($arcdef, 'arc'=>$arcname=>'ext') || 'zip';
                $c->fextract(
                    -in     => $target_dir,
                    -out    => $target_dir,
                    -method => 'ext',
                    -list   => qr/\.$x_ext$/,
                    -arcdef => $arcdef,
                );
                $c->log_debug($pfx x 2, 'OK');
                $tbl->row(localtime2date_time, sprintf("%s Extraction", $step), $target_dir, 'OK');
                my $oldshow = $self->show;
                $self->show( ($oldshow ? ($oldshow."\n") : ""). sprintf("Your restored files located in \"%s\" directory for host %s", $target_dir, $hostname));
                $status = 1;
            } else {
                $c->log_debug($pfx x 2, 'SKIPPED');
                $tbl->row(localtime2date_time, sprintf("%s Extraction", $step), $target_dir, 'SKIPPED');
            }
            
            # формирование вывода в виде таблички
            $tbl->hr;
            $tbl->row(localtime2date_time, 'STATUS', '', $status ? 'OK' : 'ERROR');
            my $tbl_rslt = $tbl->draw() || '';
            $ret .= sprintf("Host: %s; Status: %s\n", $hostname, $status ? 'OK' : 'ERROR');
            $ret .= sprintf("%s\n", $tbl_rslt);
            
            $c->log_debug(sprintf("--> Done: \"%s\". %s", $hostname, $status ? 'OK' : 'ERROR'));
        } else {
            $ret .= sprintf("Host: %s; Status: %s\n\n", $hostname, 'SKIP');
            $c->log_debug(sprintf("--> Skipped \"%s\". Enable flag is off", $hostname));
        }

    }
    $c->log_debug("Finish processing hosts");    
    
    $self->msg($ret);
    
    return 1;
}
sub checkup {
    # CHECKUP: Обработчик пробегается по всем активным хостам, забирает все коллекторы, строит 
    # линейный массив списка этих коллекторов и обходит каждый из них. Получет список всех бэкапов, 
    # пройденных за последние сутки. После этого система генерирует отчет как mbuchecker.
    # помимо этого строится список хостов для которых наличие записи коллектора обязательно
    # и если данной записи не окажется на коллекторе в течении последнийх суток то ставится 
    # статус UNKNOWN. Эта строка попадает в ту же сводную табличку что и при простом 
    # переборе данных коллекторов. Вызов checkup следует также ставить в крон на час X.
    my $self = shift;
    my $args = array(shift);
    my $c    = $self->c;
    my $config = $c->config;
    my $status = 1;
    my @saybuffer;
    my @hosts; # Список локальных хостов (их имён)
    my @req_hosts = split(/\s+/, value($config => 'checkuprequire') || '');
    my %colls; # Список локальных коллекторов (объектов на них) {URL}{AGENT,MESSAGE}
    my $sendreport      = value($config => 'sendreport') || 0;
    my $senderrorreport = value($config => 'senderrorreport') || 0;

    
    my $tbl_colls = Text::SimpleTable->new(
            [70, 'URL'],
            [76, 'MESSAGE'],
            [8,  'STATUS'], # OK, ERROR
        );
    my $tbl_backups = Text::SimpleTable->new(
            [32, 'HOST'],
            [24, 'AGENT'],
            [24, 'SERVER'],
            [32, 'FILE/SIZE'],
            [3,  'TYP'],
            [19, 'DATE'],
            [8,  'STATUS'], # PASSED, UNKNOWN, FAILED
        );
    my $tbl_errors = Text::SimpleTable->new(
            [160, 'ERROR'],
        );

    # Определение даты
    my $tdate = pop @$args;
    my ( $_y, $_m, $_d ) = (localtime( time ))[5,4,3];
    my @ymd = (($_y+1900), ($_m+1), $_d);
    if (defined($tdate)) {
        if ($tdate =~ /(\d{4})\D+(\d{2})\D+(\d{2})/) {
            @ymd = ($1,$2,$3);
        } elsif ($tdate =~ /(\d{2})\D+(\d{2})\D+(\d{4})/) {
            @ymd = ($3,$2,$1);
        } else {
            push @$args, $tdate;
        }
    }
    #$c->log_debug(sprintf(">>> %d/%d/%d", @ymd));
    
    # Получение обработчиков
    my @joblist = $self->get_jobs;
    $c->log_debug("Start processing hosts");
    foreach my $job (sort {(keys(%$a))[0] cmp (keys(%$b))[0]} @joblist) {
        my $hostname = _name($job);
        my $hostskip = (!@$args || grep {lc($hostname) eq lc($_)} @$args) ? 0 : 1;
        $c->log_debug(sprintf("Loading configuration for host \"%s\"... %s", $hostname, ($hostskip ? 'SKIPPED' : 'LOADED') ));
        next if $hostskip;
        
        # Обработка хостов
        my $enabled  = value($job, $hostname => 'enable');
        if ($enabled) {
            $c->log_debug(sprintf("--> Begin processing: \"%s\"", $hostname));
            push @hosts, $hostname;
            my $collector_node = _node2anode(node($job, $hostname => 'collector'));
            foreach my $coll (grep {value($_ => 'uri')}  @$collector_node) {
                my $coll_uri = value($coll, 'uri') || '';
                my $agent = new App::MBUtiny::CollectorAgent(
                            uri         => $coll_uri,
                            user        => value($coll, 'user'),
                            password    => value($coll, 'password'),
                            timeout     => value($coll, 'timeout'),
                        );
                my $coll_status = $agent->check;
                # Итог операции
                $c->log_debug(sprintf(" - %s",$coll_uri));
                $c->log_error(sprintf("   ERROR: %s",unidecode($agent->error))) unless $coll_status;
                $colls{$coll_uri} = {
                        agent => $agent,
                        message => $coll_status
                            ? unidecode(value($agent->response => 'data/message') || '')
                            : unidecode($agent->error)
                    } unless $colls{$coll_uri};
            }
            
        } else {
            $c->log_debug(sprintf("--> Skipped \"%s\". Enable flag is off", $hostname));
        }

    }
    $c->log_debug("Finish processing hosts");
    
    # Обработка коллекторов, получение данных
    my %data;
    my %req_data;
    foreach (@hosts, @req_hosts) {$req_data{$_} = 0};
    my @error;
    $c->log_debug("Start processing collectors");
    foreach my $coll_uri (keys %colls) {
        my $agent = $colls{$coll_uri}{agent};
        $tbl_colls->row($coll_uri, $colls{$coll_uri}{message}, $agent->status ? "OK" : "ERROR");
        if ($agent->status) {
            $c->log_debug(sprintf("--> Reading list from collector %s", $coll_uri));
            # Статус коллектора определен и он работает!
            my $dte = sprintf("%s.%s.%s", reverse(@ymd));
            my $stt = $agent->report(
                    start   => $dte,
                    finish  => $dte,
                );
            $c->log_debug(sprintf("    Status: %s", $stt ? unidecode(value($agent->response => 'data/message') || '') : unidecode($agent->error)));
            if ($stt) {
                my $res = _node2anode(node($agent->response => 'data/backup'));
                $c->log_debug(sprintf("    Loaded: %d backups", fv2zero(value($agent->response => 'data/number'))));
                #$data_box->loop( agent_name => Data::Dumper::Dumper($res) );
                foreach my $bu (@$res) {
                    my $name = uv2null(value($bu => "agent_name"));
                    $req_data{$name} = 1; # признак того что данные для хоста получены
                    $tbl_backups->row(
                            $name,
                            sprintf("%s\n%s", uv2null(value($bu => "agent_host")),uv2null(value($bu => "agent_ip"))), 
                            sprintf("%s\n%s", uv2null(value($bu => "server_host")),uv2null(value($bu => "server_ip"))), 
                            sprintf("%s\n%s bytes", variant_stf(uv2null(value($bu => "file_name")), 32), correct_number(uv2zero(value($bu => "file_size")))), 
                            value($bu => "type") ? 'INT' : 'EXT',
                            uv2null(value($bu => "date_start")), 
                            value($bu => "status") ? "PASSED" : "FAILED"
                        );
                    unless (value($bu => "status")) {
                        $status = 0;
                        push @error, sprintf("%s / %s", 
                                unidecode(uv2null(value($bu => "message"))), 
                                unidecode(uv2null(value($bu => "comment")))
                            );
                    }
                }
            }

        }
    }
    $tbl_backups->hr if grep { $_ == 0} values(%req_data);
    foreach my $name (grep {!$req_data{$_}} keys %req_data) {
        $status = 0;
        $tbl_backups->row($name,'','','','','',"UNKNOWN");
    }
    
    $tbl_backups->hr;
    $tbl_backups->row('STATUS', '', '', '', '', localtime2date_time(), $status ? 'PASSED' : 'FAILED');
    $c->log_debug("Finish processing collectors");
    
    # Результат
    push @saybuffer, "COLLECTORS:";
    push @saybuffer, $tbl_colls->draw;
    push @saybuffer, "BACKUPS:";
    push @saybuffer, $tbl_backups->draw;
    if (@error) {
        push @saybuffer, "ERRORS:";
        $tbl_errors->row($_) for @error;
        push @saybuffer, $tbl_errors->draw;
    }
    
    my $result = join("\n",@saybuffer);
    
    # Отправка письма об статусе операции если установлен флаг отправки отчета
    my $maildata = node($config => 'sendmail');
    if (value($maildata, "to") && ($sendreport || ($senderrorreport && !$status)) ) {
        my %ma = ();
        foreach my $k (keys %$maildata) {
            $ma{"-".$k} = value($maildata, $k);
        }
                
        if ($c->testmode) { # Тестовый режим
            $ma{'-to'} = value($maildata, 'testmail') || $ma{'-to'} || '';
            $c->log_debug("Sending report to TEST e-mail");
        } elsif ($senderrorreport && !$status) { # Найдены ошибки! Значит ошибочный режим
            $ma{'-to'} = value($maildata, 'errormail') || $ma{'-to'} || '';
            $c->log_debug("Sending report to ERROR e-mail");
        } else {
            $c->log_debug("Sending report to e-mail");
        }

        my $testpfx = $c->testmode() ? '[TEST MODE] ' : '';
        $ma{'-subject'} ||= $status
            ? sprintf($testpfx."MBUtiny %s CHECKUP Report", $VERSION)
            : sprintf($testpfx."MBUtiny %s CHECKUP ERROR Report", $VERSION);
        $ma{'-message'} ||= $status
            ? sprintf("Проверка статуса выполненных резервных копий не выявила никаких ошибок\n\n%s", $result)
            : sprintf("Проверка статуса выполненных резервных копий выявила ошибки\n\n%s", $result);
        $ma{'-message'} .= "\n---\n"
            . sprintf("Generated by    : MBUtiny %s\n", $VERSION)
            . sprintf("Date generation : %s\n", localtime2date_time())
            . sprintf("MBUTiny Id      : %s\n", '$Id: MBUtiny.pm 76 2014-09-24 15:02:37Z abalama $')
            . sprintf("Time Stamp      : %s\n", $c->tms())
            . sprintf("Configuration   : %s\n", $c->cfgfile);
        $ma{'-attach'} = _attach($ma{'-attach'}) || [];
        my $sent = send_mail(%ma);
        $c->log_debug(sprintf(" - %s:", $ma{'-to'}), $sent ? 'OK (Mail has been sent)' : 'FAILED (Mail was not sent)');
    } else {
        $c->log_debug("Sending report disabled by user");
    }    
    
    $self->msg($result);
    return $status;
}

sub get_jobs { # Получение списка задач. Представляет свобой либо массив атриботуов хоста либо массив с именованными хэшами для атрибутов
    my $self = shift;
    my $c    = $self->c;
    my $config = $c->config;
    my $hosts  = node($config, "host" ); # либо вернулись хосты либо нет!
    unless ($hosts) {
        $c->log_info(sprintf("Mismatch <Host> sections in configuration file \"%s\"", $c->cfgfile));
        return ();
    }
    my @jobs = (); # работы
    if (ref($hosts) eq 'ARRAY') {
        foreach my $r (@$hosts) {
            if ((ref($r) eq 'HASH') && exists $r->{enable}) {
                push @jobs, $r;
            } elsif (ref($r) eq 'HASH') {
                foreach my $k (keys %$r) {
                    push @jobs, { $k => $r->{$k} };
                }
            } else {
                #push @jobs, @$hosts;
                # debug "!!! OOPS !!!";
            }
        }
    } elsif ((ref($hosts) eq 'HASH') && !exists $hosts->{enable}) {
        foreach my $k (keys %$hosts) {
            push @jobs, { $k => $hosts->{$k} };
        }        
    } else {
        push @jobs, $hosts;
    }
    return @jobs;
}
sub get_dates { # Возвращает список разрешенных dig-дат: все разрешенные дневные, недельные и месячные даты
    my $self = shift;
    my $buday   = shift || 0; # Дневные
    my $buweek  = shift || 0; # Недельные
    my $bumonth = shift || 0; # Месячные
    
    my %dates = ();
	my $wcnt = 0;
	my $mcnt = 0;
    
    # Установка периода, равного как максимальное количество дней отмотанных "назад"
	my $period = 7 * $buweek > $buday ? 7 * $buweek : $buday;
	$period = 30 * $bumonth if 30 * $bumonth > $period;
	# debug("period: ",$period);


	# Установка хэша дат (все разрешенные и неразрешенные дневные, недельные и месячные)
    for (my $i=0; $i<$period; $i++) {
		my ( $y, $m, $d, $wd ) = (localtime( time - $i * 86400 ))[5,4,3,6];
		my $date = sprintf( "%04d%02d%02d", ($y+1900), ($m+1), $d );
        
		if (($i < $buday)
                || (($i < $buweek * 7) && $wd == 0) # do weekly backups on sunday
                || (($i < $bumonth * 30) && $d == 1)) # do monthly backups on 1-st day of month
        {
			$dates{ $date } = 1; # Проставляем "1" на все разрешенные даты без учета количества
		} else {
			$dates{ $date } = 0; # Проставляем "0" на все НЕразрешенные даты
		}
        
        # Корректиковка с учетом нужного количества бэкапов на период
        if (($i < $buday)
                || (($wd == 0) && ($wcnt++ < $buweek))
                || (($d == 1) && ($mcnt++ < $bumonth))) 
        {
			$dates{$date} ++;
		}
        
        # Удаляем строку если она нулевая, нет смысла хранить нулевые строки
        delete $dates{$date} unless $dates{$date};
	}

    return sort keys %dates;
}
sub _fixup { # Интерфейс для фиксации на коллекторе проделанной работы по копированию файла на приёмник
    my $self = shift;
    my $colls = shift; # Массив созданных заранее объектов на колелкторы "
    croak("Second argument must be reference to array!") unless $colls && ref($colls) eq 'ARRAY';
    my %data = @_;
    my $c = $self->c;

    my $gst = @$colls ? 1 : 0;
    foreach my $cl (@$colls) {
        
        # Логика корректиррующая тип исходя из http_uri
        if ($data{id} && $data{http_uri} && $cl->{uri} && $data{http_uri} eq $cl->{uri}) {
            $data{type} = 1; # Internal
        } else {
            $data{type} = 0; # External
        }
        my $fst = $cl->fixup(%data);
        
        if ($fst) {
            $c->log_debug(" " x 6, sprintf("COLLECTOR> FIXUP OK %s: %s", $cl->{uri}, unidecode(value($cl->response => 'data/message') || '')));
        } else {
            $c->log_error(" " x 6, sprintf("COLLECTOR> FIXUP ERROR %s: %s", $cl->{uri}, unidecode($cl->error) || ''));
            $gst = 0;
        }
        
    }
    
    return $gst;
}
sub _del { # Интерфейс для удалении файлов на коллекторах
    my $self = shift;
    my $colls = shift; # Массив созданных заранее объектов на колелкторы "
    croak("Second argument must be reference to array!") unless $colls && ref($colls) eq 'ARRAY';
    my %data = @_;
    my $c = $self->c;

    my $gst = @$colls ? 1 : 0;
    foreach my $cl (@$colls) {
        # Логика корректиррующая тип исходя из http_uri
        if ($data{http_uri} && $cl->{uri} && $data{http_uri} eq $cl->{uri}) {
            $c->log_debug(" " x 6, sprintf("COLLECTOR> DELETE SKIPPED %s", $cl->{uri}));
            return 1; # Internal -- skipped
        }
        
        if ($cl->del(%data)) {
            $c->log_debug(" " x 6, sprintf("COLLECTOR> DELETE OK %s: %s", $cl->{uri}, unidecode(value($cl->response => 'data/message') || '')));
        } else {
            $c->log_error(" " x 6, sprintf("COLLECTOR> DELETE ERROR %s: %s", $cl->{uri}, unidecode($cl->error) || ''));
            $gst = 0;
        }
        
    }
    
    return $gst;
}
sub _info { # Интерфейс для получения информации о файле на коллекторах
    my $self = shift;
    my $colls = shift; # Массив созданных заранее объектов на колелкторы "
    croak("Second argument must be reference to array!") unless $colls && ref($colls) eq 'ARRAY';
    my %data = @_;
    my $c = $self->c;
    
    foreach my $cl (@$colls) {
        if ($cl->info(%data)) {
            $c->log_debug(" " x 6, sprintf("COLLECTOR> INFO OK %s: %s", $cl->{uri}, unidecode(value($cl->response => 'data/message') || '')));
            my $reth = hash($cl->response => 'data');
            return {%$reth};
        } else {
            $c->log_error(" " x 6, sprintf("COLLECTOR> INFO ERROR %s: %s", $cl->{uri}, unidecode($cl->error) || ''));
        }
    }
    
    return undef;
}

sub DESTROY {
    my $self = shift;
  
    rmtree($self->{objdir}) if $self->{objdir} && -e $self->{objdir};
    rmtree($self->{excdir}) if $self->{excdir} && -e $self->{excdir};
    1;
}

sub _name { # Получение имени обрабатываемого хоста
    my $host = hash(shift);
    my @ks = keys %$host;
    return '' unless @ks;
    return 'VIRTUAL' if exists $ks[1];
    return ($ks[0] && ref($host->{$ks[0]}) eq 'HASH') ? $ks[0] : 'VIRTUAL';
}
sub _attach { # Форматирует вложения для письма
    my $d = shift;
    return undef unless $d && ref($d) =~ /ARRAY|HASH/;
    
    my @r;
    if (ref($d) eq 'HASH') {
        push @r, $d
    } else {
        @r = @$d
    }
    
    my @cr;
    foreach my $h (@r) {
        next unless $h && ref($h) eq 'HASH';
        my %t;
        foreach (keys %$h) {
           $t{ucfirst($_)} = $h->{$_}
        }
        push @cr, {%t};
    }

    return [@cr];
}
sub _node2anode { # Переводит ноду в массив нод
    my $n = shift;
    return [] unless $n && ref($n) =~ /ARRAY|HASH/;
    return [$n] if ref($n) eq 'HASH';
    return $n;
}
sub _node_correct { # корректирует ноду как массив таким образом чтобы использовать именованные и неименованные конструкции
    my $j = shift; # Нода
    my $kk = shift || 'object'; # тестовый ключ, "обязательны" в теле ноды атрибут
    
    my @nc = ();
    if (ref($j) eq 'ARRAY') {
        my $i = 0;
        foreach my $r (@$j) {$i++;
            if ((ref($r) eq 'HASH') && exists $r->{$kk}) {
                push @nc, { sprintf("virtual_%03d",$i) => $r };
            } elsif (ref($r) eq 'HASH') {
                foreach my $k (keys %$r) {
                    push @nc, { $k => $r->{$k} };
                }
            }
        }
    } elsif ((ref($j) eq 'HASH') && !exists $j->{$kk}) {
        foreach my $k (keys %$j) {
            push @nc, { $k => $j->{$k} };
        }        
    } else {
        push @nc, { "virtual" => $j } if defined $j;
    }
    return [@nc];
}
sub _search_file { # Поиск ближайшего файла к указанному по дате
    my $list = shift;
    my $file = shift;
    return undef unless $list && ref($list) eq 'ARRAY';
    
    my $s = undef;
    my $l = undef;
    foreach (sort {$a cmp $b} @$list) {
        $s = $_;
        return $s if $file && $s eq $file;
        if ($file && $s gt $file) {
            return $l;
        }
        $l = $s;
        
    }
    return $s
}
sub _ftpattr_set {
    my $in = shift;
    my $attr = array($in => "set");
    my %attrs;
    foreach (@$attr) {
        $attrs{$1} = $2 if $_ =~ /^\s*(\S+)\s+(.+)$/;
    }
    if ($in && ref($in) eq 'HASH') {
        $in->{ftpattr} = {%attrs};
    } 
    return;
}

1;

__END__
