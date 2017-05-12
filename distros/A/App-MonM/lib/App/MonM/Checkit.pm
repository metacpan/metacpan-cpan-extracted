package App::MonM::Checkit; # $Id: Checkit.pm 12 2014-09-23 13:16:47Z abalama $
use strict;

=head1 NAME

App::MonM::Checkit - App::MonM checkit functions

=head1 VIRSION

Version 1.01

=head1 SYNOPSIS

    use App::MonM::Checkit;

=head1 DESCRIPTION

App::MonM checkit functions

See C<README> file

=head1 FUNCTIONS

=over 8

=item B<readcount>

    my ($res,$err) = readcount( $count_config_node );

Function returns two values: result and error.
Result ($res) may be: OK, SKIP or ERROR. 
Error ($err) contains reason of errors.

=item B<checkcount>

    my $trueorfalse = checkcount( $old1, $old2, $old3, $current_value );

Returns 0 or 1. 1 - need run trigger.

=item B<trigger>

    my @rslt = trigger( $config,  @sequence );

@sequence -- array of hashes: ( {count, countdata, message}, ... )

@rslt -- array of arrays: ( [count, type, to, message, status], ... )

=item B<reqsimple>

    my $content = reqsimple( $url, $method, \$code, \$message );

Function returns content from URL ($url) and two values: HTTP status code and HTTP status message.

NOTE: code and message is references to scalar variables!!

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
$VERSION = '1.01';

use constant {
    TRUERX  => qr/^\s*(ok|yes)/i, # Что такое хорошо
    FALSERX => qr/^\s*(error|fault|no)/i, # Что такое плохо
    SIDPFX  => 'DBI:Oracle:',
    SIDDFLT => 'TEST',
    SQLDFLT => 'SELECT \'OK\' AS OK FROM DUAL',
    SMSSBJ  => 'MONM CHECKIT REPORT',
    QRTYPES => {
            ''  => sub { qr{$_[0]} },
            x   => sub { qr{$_[0]}x },
            i   => sub { qr{$_[0]}i },
            s   => sub { qr{$_[0]}s },
            m   => sub { qr{$_[0]}m },
            ix  => sub { qr{$_[0]}ix },
            sx  => sub { qr{$_[0]}sx },
            mx  => sub { qr{$_[0]}mx },
            si  => sub { qr{$_[0]}si },
            mi  => sub { qr{$_[0]}mi },
            ms  => sub { qr{$_[0]}sm },
            six => sub { qr{$_[0]}six },
            mix => sub { qr{$_[0]}mix },
            msx => sub { qr{$_[0]}msx },
            msi => sub { qr{$_[0]}msi },
            msix => sub { qr{$_[0]}msix },
    },
};

use base qw/Exporter/;
our @EXPORT = qw(
        readcount checkcount trigger reqsimple
    );

use CTK::DBI;
use CTK::ConfGenUtil;
use URI;
use LWP::UserAgent();
use HTTP::Request();
use CTK::Util;

sub readcount {
    # Выполнение шага (чтение данных). 
    # На вход - структура (нода) на выходе массив: результат и ошибка
    my $cdata = shift || {};
    my ($res,$err) = ('ERROR', 'Undefined error');
    my $result = ''; # Значение которое сравнивается с "что такое хорошо, а что такое плохо"
    my $type    = lc(value($cdata, 'type') || '');
    my $enabled = value($cdata, 'enable') || 0;
    my $truerx  = _qrreconstruct(value($cdata, 'istrue'));
    my $falserx = _qrreconstruct(value($cdata, 'isfalse'));
    my $orderby = value($cdata, 'orderby') || 'true,false';
    return ('SKIP', 'Skipped because of "Enable" flag is off') unless $enabled;
    
    # Установка атрибутов
    my $attr = hash($cdata, 'attr');
    my $t_attr = _get_attr($cdata) || {};
    foreach my $ak (keys %$t_attr) {
        $attr->{$ak} = $t_attr->{$ak} if exists($t_attr->{$ak});
    }
    
    # Выполнение задач
    if ($type eq 'dbi' or $type eq 'oracle') {
        my $dsn = value($cdata, 'dsn') || '';
        my $sid = value($cdata, 'sid') || SIDDFLT;
        $dsn = SIDPFX.$sid if $type eq 'oracle';
        my $user = value($cdata, 'user') || '';
        my $password = value($cdata, 'password') || '';
        my $sql = value($cdata, 'sql') || SQLDFLT;
        my $cto = value($cdata, 'connect_to');
        my $rto = value($cdata, 'request_to');
        
        # Корректировка атрибутов для нужд DBI
        $attr->{PrintError} = 0 unless exists($attr->{PrintError});
        
        # Коннект к БД
        my $db = new CTK::DBI(
            -dsn        => $dsn, 
            -user       => $user, 
            -pass       => $password, 
            -connect_to => $cto, 
            -request_to => $rto, 
            -attr       => $attr,
        );
        return ('ERROR', "Can't connect to \"$dsn\": ".($DBI::errstr || '')) unless $db && $db->{dbh};
        my $sth = $db->execute($sql);
        return ('ERROR', "Can't Preparing/Executing \"$sql\": ".($DBI::errstr || '')) unless $sth;
        my @resa = $sth->fetchrow_array;
        #use Data::Dumper; ::debug('!!!',Dumper(@resa));
        $result = join("", @resa);
        $sth->finish;
        return ('ERROR', "Can't fetching content from \"$dsn\"") unless (defined $result);
    } elsif ($type eq 'command') {
        my $command = value($cdata, 'command') || '';
        if ($command) {
            $result = execute($command) || '';
            #::debug($result);
        } else {
            return ('ERROR', "Command not defined!");
        }
    } else {
        my $url = value($cdata, 'url') || '';
        return ('ERROR', "URL not defined!") unless $url;
        my $errcode = '';
        my $errstatus = '';
        my $content = reqsimple( $url, uc(value($cdata, 'method') || 'GET'), \$errcode, \$errstatus );
        my $ht = lc(value($cdata, 'target') || value($cdata, 'httptarget') || '');
        if ($ht eq 'code') {
            $result = $errcode;
        } elsif ($ht eq 'status') {
            $result = $errstatus;
        } else {
            return ('ERROR', "Can't get content from \"$url\": $errstatus") unless (defined $content);
            $result = $content;
        }
    }

    # Cекция проверки "что такое хорошо, а что такое плохо"
    my $rtt = (defined($truerx) && ref($truerx)) ? ref($truerx) : 'String';
    my $rtf = (defined($falserx) && ref($falserx)) ? ref($falserx) : 'String';
    if (($orderby =~ /false\s*\,\s*true/i) || ($orderby =~ /desc/i)) {
        # Обратный порядок
        if (defined $falserx) {
            $res = _cmp($result, $falserx, [qw/ERROR OK/]);
            $err = "RESULT == FALSE (DEC ORDERED) [AS $rtf]" if $res eq 'ERROR';
        } elsif (defined $truerx) {
            $res = _cmp($result, $truerx, [qw/OK ERROR/]);
            $err = "RESULT != TRUE (DEC ORDERED) [AS $rtt]" if $res eq 'ERROR';
        } else {
            $res = _cmp($result, FALSERX, [qw/ERROR OK/]);
            $err = "RESULT == FALSE-DEFAULT (DEC ORDERED) [AS Regexp (DEFAULT)]" if $res eq 'ERROR';
        }
    } else {
        # прямой порядок
        if (defined $truerx) {
            $res = _cmp($result, $truerx, [qw/OK ERROR/]);
            $err = "RESULT != TRUE (ASC ORDERED) [AS $rtt]" if $res eq 'ERROR';
        } elsif (defined $falserx) {
            $res = _cmp($result, $falserx, [qw/ERROR OK/]);
            $err = "RESULT == FALSE (ASC ORDERED) [AS $rtf]" if $res eq 'ERROR';
        } else {
            $res = _cmp($result, TRUERX, [qw/OK ERROR/]);
            $err = "RESULT != TRUE-DEFAULT (ASC ORDERED) [AS Regexp (DEFAULT)]" if $res eq 'ERROR';
        }
    }
    $err = '' if $res eq 'OK';
    
    return ($res,$err);
}
sub checkcount {
    # проверка данных (анализ). Нужно ли срабатывать триггеру?
    my @inp = @_;
    my $vcorr   = shift;
    my $v0      = shift;
    my $v1      = shift;
    my $vok     = shift;

    # 0-0-0   -- PROBLEM
    # 0-0-1   -- OK?
    # 1-1-1   -- OK
    # 1-1-0   -- PROBLEM?
    # 0-1-0   -- CORR
    # 0-0-1-1 -- ALARM
    # 1-0-1-1 -- CORR
    my $inps = " [".join("-",@inp)."]";
    
    my $stat = 0;
    if ($v1 != $vok) {
        # Ситуация: произошло изменение счетчика (0-0-1)
        if (($v0 == $v1) || ($v0 == $vok)) {
            # Ситуация: Было разовое "помешательство" (0-1-0)
            #debug "   STATUS CORR: 0-1-0 / 1-0-1", $inps;
        } else {
            # Ситуация: Ситуация изменения счетчика подтверждается, аларм! (0-1-1)
            #debug "   STATUS ALARM1: $v0 -> $vok: ", $vok ? 'OK' : 'ERROR', $inps;
            $stat = 1;
        }
    } else {
        # Ситуация: произошло подтверждение изменения счетчика (0-1-1) или не произошло ничего
        if (($v0 != $v1) && ($v1 == $vok) && ($vcorr != $vok)) {
            # Ситуация: Ситуация изменения счетчика подтверждается, аларм! (0-0-1-1)
            #debug "   STATUS ALARM2: $v0 -> $vok: ", $vok ? 'OK' : 'ERROR', $inps;
            $stat = 1;
        } else {
            #debug "   STATUS OK: 1-1-1", $inps if $vok;
            #debug "   STATUS PROBLEM: 0-0-0", $inps unless $vok;
        }
    }
    
    return $stat; # 0 - триггер срабатывать недолжен / 1 - триггер срабатывать должен !!! 
}
sub trigger {
    my $config   = shift || {}; # Конфигурация
    my @sequence = @_; # ВХОД  ( {count, countdata, message}, ... )
    my @rslt;          # ВЫХОД ( [count, type, to, message, status], ... )

    foreach my $act (@sequence) {
        my $name    = $act->{count} || '';     # Имя счетчика
        my $data    = $act->{countdata} || {}; # Данные конфигурации, нода (структура)
        my $message = $act->{message} || '';   # Сообщение для 
        
        # Принимаем секцию данных
        my $smsgw = value($data, 'smsgw') || value($config, 'smsgw') || '';
        my $emailalerts = array($data,'triggers/emailalert');
        my $smsalerts = array($data,'triggers/smsalert');
        my $commands = array($data,'triggers/command');
        
        # Отправляем сначала письма
        foreach my $email (@$emailalerts) {
            my $sent = sendmail(
                -to          => $email,
                -cc          => value($config, 'sendmail/cc'),
                -from        => value($config, 'sendmail/from'),
                -smtp        => value($config, 'sendmail/smtp'),
                -sendmail    => value($config, 'sendmail/sendmail'),
                -flags       => value($config, 'sendmail/flags'),
                -subject     => $message,
                -message     => sprintf(""
                        ."Count name  : %s\n"
                        ."Message     : %s\n"
                        ."\n---\n"
                        ."SMS GateWay : %s\n"
                        ."SMS         : %s\n"
                        ."E-Mail      : %s\n"
                        ."commands    : \n%s\n",
                        
                        $name, $message, $smsgw,
                        join(", ", @$smsalerts),
                        join(", ", @$emailalerts),
                        join("\n", @$commands),
                    ),
            );

            push @rslt, [
                    $name,
                    'email',
                    $email,
                    $message,
                    ($sent ? 'SENT' : 'ERROR'),
                ];
        }
        
        # Теперь отправляем SMS
        foreach my $phone (@$smsalerts) {
            my $smss = '';
            if ($smsgw) {
                my $cmd = dformat($smsgw, {
                        PHONE       => $phone,
                        NUM         => $phone,
                        TEL         => $phone,
                        PHONE       => $phone,
                        NUM         => $phone,
                        NUMBER      => $phone,
                        SUBJECT     => SMSSBJ,
                        SUBJ        => SMSSBJ,
                        MSG         => $message,
                        MESSAGE     => $message,
                    });
                my $sct = execute($cmd) || '';
                $sct =~ s/\r*\n/ /;
                $smss = $sct || 'SENT';
            } else {
                $smss = "ERROR: SMSGW UNDEFINED";
            }
            push @rslt, [
                    $name,
                    'sms',
                    $phone,
                    $message,
                    $smss,
                ];
        }
        
        # Теперь выполняем команду
        foreach my $acmd (grep {$_} @$commands) {
            my $cmd = dformat($acmd, {
                    SUBJECT     => SMSSBJ,
                    SUBJ        => SMSSBJ,
                    MSG         => $message,
                    MESSAGE     => $message,
                });
            my $cct = execute($cmd) || '';
            $cct =~ s/\r*\n/ /;
            push @rslt, [
                    $name,
                    'command',
                    $cmd,
                    $message,
                    ($cct || 'DONE'),
                ];
        }
    }

    return [@rslt];
}
sub reqsimple {
    my $url = shift || '';
    my $meth = shift || 'GET';
    my $errref = shift; # Код
    my $msgref = shift; # Сообщение
    
    my $ua = LWP::UserAgent->new;  # we create a global UserAgent object
    $ua->agent(__PACKAGE__."/$VERSION");
    $ua->env_proxy;
    my $request = HTTP::Request->new(uc($meth) => new URI($url));
    my $response = $ua->request($request);
    my $sc = $response->code || 0;
    my $sl = $response->status_line || '';
    
    $$errref = $sc if $errref && ref($errref) eq 'SCALAR';
    $$msgref = $sl if $msgref && ref($msgref) eq 'SCALAR';
        
    return $response->decoded_content if $response->is_success;
    return undef;
}
sub _get_attr {
    my $in = shift;
    my $attr = array($in => "set");
    my %attrs;
    foreach (@$attr) {
        $attrs{$1} = $2 if $_ =~ /^\s*(\S+)\s+(.+)$/;
    }
    #if ($in && ref($in) eq 'HASH') { $in->{attr} = {%attrs} } 
    return {%attrs};
}
sub _cmp {
    # Сравнивалка
    my $s = shift || ''; # текст
    my $x = shift || ''; # регулярка
    my $r = shift || ['OK', 'ERROR']; # выбор [OK, ERROR]
    
    if (ref($x) eq 'Regexp') {
        return $r->[0] if $s =~ $x;
    } else {
        return $r->[0] if $s eq $x;
    }
    return $r->[1];
}
sub _qrreconstruct {
    # Возвращает регулярное выражение (QR-строку)
    # Функция позаимствованая из YAML::Type::regexp пакета YAML::Types, немного переделанная для 
    # адаптации нужд!!
    # На вход подается примерно следующее:
    #    !!perl/regexp (?i-xsm:^\s*(error|fault|no))
    # это является регуляркой вида:
    #    qr/^\s*(error|fault|no)/i
    my $node = shift;
    return undef unless defined $node;
    return $node unless $node =~ /^\s*\!\!perl\/regexp\s*/i;
    $node =~ s/\s*\!\!perl\/regexp\s*//i;
    return qr{$node} unless $node =~ /^\(\?([\^\-xism]*):(.*)\)\z/s;
    my ($flags, $re) = ($1, $2);
    $flags =~ s/-.*//;
    $flags =~ s/^\^//;
    my $sub = QRTYPES->{$flags} || sub { qr{$_[0]} };
    return $sub->($re);
}
1;
__END__


