package App::MonM::AlertGrid; # $Id: AlertGrid.pm 57 2016-10-04 12:46:30Z abalama $
use strict;

=head1 NAME

App::MonM::AlertGrid - App::MonM AlertGrid functions

=head1 VIRSION

Version 1.02

=head1 SYNOPSIS

    use App::MonM::AlertGrid;

=head1 DESCRIPTION

App::MonM AlertGrid functions

See C<README> file

=head1 FUNCTIONS

=over 8

=item B<ag_init>

    my $stt = ag_init( $dbfile );

Function initialization of the file localDB

=item B<ag_clear, ag_clean>

    my $status = ag_clear( $dbfile );

Clearing of the file localDB

=item B<ag_normalize>

    my $status = ag_normalize( $dbfile );

Normalize data. Clear expired data (Delete records older than one day for fields "Expired")

=item B<ag_prepare>

    my $xml = ag_prepare( $attrs, $table );

Function convertion summary table $table to XML. Please do not use it.

=item B<ag_server>

    my ($stt, $err) = ag_server( $attrs, $data );

Function returns two values: status and error.
Status ($stt) may be: 0 or 1
Error ($err) contains reason of errors.

=item B<ag_client>

    my ($stt, $res, $err) = ag_client( $attrs );

Main Agent-function. Use for read data from counts.
Function returns three values: status, result an error message. Status ($stt) may be: 1 or 0. 
Result ($res) contains XML-hash with data of the count. Error ($err) contains reason of errors.

=item B<ag_snapshot>

    my $snapshot = ag_snapshot( $dbfile );

Function returns all fields of the $dbfile as anonymous array of hashes

=back

=head1 SEE ALSO

L<App::MonM>

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

use vars qw/$VERSION/;
$VERSION = '1.02';

use constant {
    LOCALHOSTIP => '127.0.0.1',
    NAMESEP     => '::',
    FOO         => 'bar',
    XMLDECL     => '<?xml version="1.0" encoding="utf-8"?>',
    ROOTNAME    => 'alertgrid',
    XMLDEFAULT  => '<?xml version="1.0" encoding="utf-8"?>'."\n".'<alertgrid />',
    NORMALIZE   => 24*60*60, # 1 day older
    
};

use base qw/Exporter/;
our @EXPORT = qw(
        ag_init
        ag_clear ag_clear ag_normalize
        ag_server ag_client ag_prepare
        ag_snapshot
    );

use CTK::DBI;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use URI;
use LWP::UserAgent();
use HTTP::Request();
use CTK::Util;
use XML::Simple;
use Try::Tiny;

sub ag_init { # Инициализация таблицы alertgrid
    my $dbf = shift || return 0;

    # Создание пустой базы SQLite если ее нет или она пуста
    my $dsn = "dbi:SQLite:dbname=$dbf";
    
    unless ($dbf && (-e $dbf) && !(-z _)) {
        my $sqlc = new CTK::DBI( -dsn  => $dsn );
        $sqlc->execute('
                CREATE TABLE 
                    IF NOT EXISTS alertgrid ( 
                        `id` INT(11) NOT NULL PRIMARY KEY,
                        `ip` CHAR(15) NOT NULL,
                        `alertgrid_name` CHAR(255),
                        `count_name` CHAR(255),
                        `type` CHAR(32),
                        `value` TEXT,
                        `pubdate` INT(11),
                        `expires` INT(11),
                        `status` CHAR(32),
                        `errcode` INT(11),
                        `errmsg` TEXT
                    )
            ');
        $sqlc->execute('CREATE INDEX I_ALERTGRID ON alertgrid(id)');
        $sqlc->disconnect;
        return 1;
    }
    return 0;
    
}
sub ag_clear { # Принудительная очистка базы
    my $dbf = shift || return 0;
    
    my $dsn = "dbi:SQLite:dbname=$dbf";
    
    if ($dbf && (-e $dbf) && !(-z _)) {
        my $sqlc = new CTK::DBI( -dsn  => $dsn);
        $sqlc->execute('DELETE FROM alertgrid WHERE 1 = 1');
        $sqlc->disconnect;
        return 1;
    }
    return 0;
}
sub ag_clean { goto &ag_clear } # Принудительная очистка базы, алиас
sub ag_normalize {
    my $dbf = shift || return 0;
    
    my $dsn = "dbi:SQLite:dbname=$dbf";
    
    if ($dbf && (-e $dbf) && !(-z _)) {
        my $sqlc = new CTK::DBI( -dsn  => $dsn);
        #my %table = $sqlc->tableh('id','SELECT * FROM alertgrid WHERE `expires` <= ?', time() - NORMALIZE); print STDERR Dumper(\%table);
        $sqlc->execute('DELETE FROM alertgrid WHERE `expires` <= ?', time() - NORMALIZE);
        $sqlc->disconnect;
        return 1;
    }
    return 0;
}
sub ag_snapshot {
    my $dbf = shift || return 0;
    carp("Can't load DB file. Please initialize the database") && return [] unless $dbf && -e $dbf;
    
    # Соединение с БД
    my $sqlc = new CTK::DBI( -dsn  => "dbi:SQLite:dbname=$dbf" );
    
    my %table = $sqlc->tableh('id','SELECT * FROM alertgrid'); # print Dumper(\%table);
    
    my @res;
    foreach my $countk (sort {$a <=> $b} keys %table) {
        my $count = $table{$countk};
        push @res, $count;
    }
    
    $sqlc->disconnect;
    return [@res];
}
sub ag_server { # Процедура сервера alertgrid (чтение данных от агентов).
    my $cfg = shift || {}; # Локальные настройки
    my $xml = shift || XMLDEFAULT; # XML документ или структура
    my ($stt, $err) = (0, 'Undefined error');
    
    # Основные данные
    my $dbfile  = $cfg->{dbfile} || '';
    my $agrntip = $cfg->{agentip} || LOCALHOSTIP;
    ag_init($dbfile);
    return ($stt, "Can't load DB file. Please initialize the database") unless $dbfile && -e $dbfile;
    
    # Чтение данных XML
    my $data;
    try {
        if ($xml && ref($xml) eq 'HASH') {
            $data = $xml;
        } else {
            $data = XMLin($xml, ForceArray => 0, KeyAttr => ['id']);
            $stt = 1;
        }
    } catch {
        $stt = 0;
        $err = "Can't load XML from input data: $_";
    };
    return ($stt, $err) unless $stt;
    
    # Соединение с БД
    my $sqlc = new CTK::DBI( -dsn  => "dbi:SQLite:dbname=$dbfile" );
    
    # Записываем данные, строчка за строчкой, в БД
    my $counts = array($data, 'count');
    my $alertgridname = value($data, 'name');
    foreach my $count (@$counts) {
        my @names = ();
        push @names, $agrntip if $agrntip; # IP берется только для отображения
        push @names, $alertgridname if $alertgridname; # Берется только для отображения
        my $name = value($count, 'name') || 'noname';
        push @names, $name;
        my $vname = join(NAMESEP, @names);
        #printf("%s\n", $vname);
        
        _replace($sqlc, {
                ip              => $agrntip,
                alertgrid_name  => $alertgridname || LOCALHOSTIP,
                count_name      => $name,
                type            => value($count, "value/type") || 'STR',
                value           => uv2void(value($count, "value/content")), # Пофиксить как только выйдет очередной релиз CTK с исправление #347
                pubdate         => value($count, "pubdate/date") || 0,
                expires         => value($count, "expires/date") || 0,
                status          => value($count, "status") || 'UNDEF', # OK, ERROR, UNDEF
                errcode         => value($count, "error/code") || 0,
                errmsg          => uv2void(value($count, "error/content")),
                count_vname     => $vname,
            });
    }
    #print Dumper($data);

    $sqlc->disconnect;

    # cat data\test.xml | perl -Ilib monm.pl --conf=monm.conf alertgrid server -di
    # sqlite3 "C:\Documents and Settings\minus\Local Settings\Temp\monm\alertgrid.db"
    
    return ($stt, $err);

}
sub ag_client { # Выполнение шага (чтение данных) по входным данным прочитанных с конфигурации.
    my $cfg = shift || {}; # Локальные настройки
    my ($stt, $res, $err) = (0, undef, 'Undefined error');
    
    # Основные данные
    my $type    = lc($cfg->{type} || '');
    
    # Проход по методам
    if ($type eq 'dbi' or $type eq 'oracle') {
        return ($stt, $res, "Method temporary not supported");
    } elsif ($type eq 'http') {
        return ($stt, $res, "Method temporary not supported");
    } elsif ($type eq 'command') {
        my $command = $cfg->{command} || '';
        if ($command) {
            $res = execute($command, undef, \$err);
            $res = '' unless defined $res;
            
            # Чтение данных XML
            my $xmlout;
            $stt = 1;
            try {
                $xmlout = XMLin($res, ForceArray => 1); #, KeyAttr => ['id']
            } catch {
                $stt = 0;
                $err .= "Can't load XML from input data: $_";
            };
            return ($stt, $res, $err) unless $stt;
            
            # Данные в порядке, формируем $res заного
            $res = hash($xmlout);
            #::debug($res);
        } else {
            return ($stt, $res, "Command not defined!");
        }
    } else {
        return ($stt, $res, "Unsupported method");
    }
    
    return ($stt, $res, $err);
}
sub ag_prepare { # Подготовка документа для передачи от агента -> серверу
    my $cfg = shift || {}; # Локальные настройки
    my $tbl = shift || [];
    my $name = $cfg->{name} || '';
    
    # INPUT:
    # {
    #  'count' => 'foo::resources::mem::FreePercent',
    #  'pubdate' => '1415786529',
    #  'value' => '69.26',
    #  'status' => 'OK',
    #  'errmsg' => '',
    #  'worktms' => '[7888] {TimeStamp: +0.8495 sec}',
    #  'type' => 'DIG',
    #  'errcode' => 0,
    #  'expires' => '1415786829'
    # },

    my @res;
    foreach my $count (@$tbl) {
        push @res, {
                name    => [$count->{count}],
                pubdate => {
                        date    => $count->{pubdate},
                        content => dtf("%w, %DD %MON %YYYY %hh:%mm:%ss %G",$count->{pubdate},1)
                    },
                expires => {
                        date    => $count->{expires},
                        content => dtf("%w, %DD %MON %YYYY %hh:%mm:%ss %G",$count->{expires},1)
                    },
                worktms => [$count->{worktms}],
                status  => [$count->{status}],
                error   => {
                        code    => $count->{errcode},
                        content => defined($count->{errmsg}) ? cdata($count->{errmsg}) : '',
                    },
                value   => {
                        type    => $count->{type},
                        content => defined($count->{value}) ? cdata($count->{value}) : '',
                    },
            };
    }

    # OUTPUT:
    # {
    #  'worktms' => [
    #                 '[1012] {TimeStamp: +0.8475 sec}'
    #               ],
    #  'pubdate' => {
    #                 'date' => '1415789343',
    #                 'content' => 'Wed, 12 Nov 2014 10:49:03 GMT'
    #               },
    #  'value' => {
    #               'content' => '<![CDATA[69.26]]>',
    #               'type' => 'DIG'
    #             },
    #  'status' => [
    #                'OK'
    #              ],
    #  'error' => {
    #               'content' => '<![CDATA[]]>',
    #               'code' => 0
    #             },
    #  'name' => [
    #              'foo::resources1::mem::FreePercent'
    #            ],
    #  'expires' => {
    #                 'date' => '1415789643',
    #                 'content' => 'Wed, 12 Nov 2014 10:54:03 GMT'
    #               }
    # },
    
    # DOCUMENT (XML):
    # <count>
    #    <name>foo::resources1::mem::FreePercent</name>
    #    <error code="0"><![CDATA[]]></error>
    #    <expires date="1415790264">Wed, 12 Nov 2014 11:04:24 GMT</expires>
    #    <pubdate date="1415789964">Wed, 12 Nov 2014 10:59:24 GMT</pubdate>
    #    <status>OK</status>
    #    <value type="DIG"><![CDATA[69.26]]></value>
    #    <worktms>[7412] {TimeStamp: +0.8513 sec}</worktms>
    # </count>
    
    return XMLout({
            name  => [$name],
            count => [@res],
        },
        RootName => ROOTNAME, 
        XMLDecl  => XMLDECL,
        NoEscape => 1,
    );
}

sub _replace {
    my $sqlc = shift;
    my $data = shift;
    
    my @keyfields = ($data->{ip}, $data->{alertgrid_name}, $data->{count_name});
    my $id = $sqlc->field('SELECT id FROM alertgrid WHERE `ip` = ? AND `alertgrid_name` = ? AND `count_name` = ?',
            @keyfields
        );
    my $newid = $sqlc->field('SELECT MAX(id) + 1 AS newid FROM alertgrid');
    if ($id) {
        # Меняем
        $sqlc->execute('
            UPDATE
                alertgrid 
            SET
                `ip` = ?, `alertgrid_name` = ?, `count_name` = ?,
                `type` = ? ,
                `value` = ?,
                `pubdate` = ? ,
                `expires` = ? ,
                `status` = ? ,
                `errcode` = ? ,
                `errmsg` = ?
            WHERE
                id =?
        ',
            @keyfields,
            $data->{type},
            $data->{value},
            $data->{pubdate},
            $data->{expires},
            $data->{status},
            $data->{errcode},
            $data->{errmsg},
            $id,
        );
    } else {
        # Добавляем
        $sqlc->execute('
            INSERT
                INTO alertgrid (`id`,`ip`,`alertgrid_name`,`count_name`,`type`, `value`, `pubdate`, `expires`, `status`, `errcode`, `errmsg`)
            VALUES
                ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
        ',
            ($newid || 1),
            @keyfields,
            $data->{type},
            $data->{value},
            $data->{pubdate},
            $data->{expires},
            $data->{status},
            $data->{errcode},
            $data->{errmsg},
        );
    }
    
    return 1;
}

1;
__END__

СОПУТСТВУЮЩИЙ МАНУАЛ
====================

cls && echo test | perl -Ilib bin\monm -dv alertgrid --output=c:\Temp\monm\output.xml --type=xml --stdin snap
cls && echo test | perl -Ilib bin\monm -dv alertgrid --output=c:\Temp\monm\output.xml --type=xml --stdin server


