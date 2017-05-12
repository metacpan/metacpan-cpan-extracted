package App::MBUtiny::Collector; # $Id: Collector.pm 49 2014-09-03 07:01:04Z abalama $
use strict;

=head1 NAME

App::MBUtiny::Collector - Collector Server for data App::MBUtiny

=head1 VIRSION

Version 1.01

=head1 SYNOPSIS

    none

=head1 DESCRIPTION

Collector Server for data App::MBUtiny. No public subroutines. See L<WWW::MLite>

=head1 HISTORY

See C<CHANGES> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<App::MBUtiny>, L<WWW::MLite>

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

## MODEL
use DBI;
use WWW::MLite::Store::DBI;

## VIEW
use CGI qw/-utf8/; # use CGI;

## CONTROLLER
use Encode;
use WWW::MLite::Util;
use CTK::Util qw/ :BASE :FORMAT /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use XML::Simple;
use Try::Tiny;

use constant {
        # API
        XMLDECL             => '<?xml version="1.0" encoding="utf-8"?>',
        ROOTNAME            => 'response',
        REQ_ROOTNAME        => 'request',
        RES_ROOTNAME        => 'response',
        DEFAULT_EXT         => 'xml',
        CONTENT_TYPE        => 'text/xml; charset=utf-8',
    };

sub handler {
    my $self = shift;
    
    # Регистрация объявленных обработчиков - использовать если их нет при конструкторе
    #$self->register(qw/Handlers::Foo/);
    
    #$self->config->set(debug => 1);
    #$self->config->set(loglevel => 0);
    #$self->config->set(syslog => 1);
    #$self->config->set(logfile => 'qqq.log');

    # Все те переменные которые были ранее глобальными, теперь являются частью объекта
    my $q = new CGI;
    $self->set( 'q' => $q );
    
    # Инициализация типа обработчика и события
    my ($actObject,$actEvent) = split /[,]/, $q->param("action") || '';
    $actObject = 'default' unless $actObject && $self->ActionCheck($actObject);
    $actEvent  = $actEvent && $actEvent =~ /go/ ? 'go' : '';
    $self->set( 'actObject' => $actObject );
    $self->set( 'actEvent' => $actEvent );
    
    # Проверка на возможные особые случаи метода POST
    if ($ENV{QUERY_STRING} && ($ENV{REQUEST_METHOD} eq 'POST') && $actObject eq 'default') {
        $actObject = "upload" if $ENV{QUERY_STRING} eq 'action=upload';
        $actObject = "fixup"  if $ENV{QUERY_STRING} eq 'action=fixup';
    }
    
    # Получаем атрибуты обработчика
    my $mdata = $self->getActionRecord($actObject);

    # Устанавливаем коннекты к БД
    if (value($mdata => "bd_enable")) {
        #$WWW::MLite::Store::DBI::DEBUG_FORCE = 1;
        my $db_cfg = node($self->config->collector, "dbi");
        my $db_attr = array($db_cfg => "set");
        my %db_attrs;
        foreach (@$db_attr) {
            $db_attrs{$1} = $2 if $_ =~ /^\s*(\S+)\s+(.+)$/;
        }
        # require Data::Dumper; warn(Data::Dumper::Dumper(\%db_attrs));
        my $dsn = value($db_cfg => "dsn");
        if ($dsn) {
            $self->set( 'db' => new WWW::MLite::Store::DBI (
                -dsn      => $dsn,
                -user     => value($db_cfg => "user"),
                -password => value($db_cfg => "password"),
                -attr     => { %db_attrs },
            ));
        } else {
            $self->set( 'db' => 0 );
        }
    }

    # Устанавливаем %usr, @error
    my (%usr, @error);
    %usr = (); foreach ($q->all_parameters) { $usr{$_} = $q->param($_) }
    
    # Устанавливаем флаг UTF8 для входных данных %usr по списку если заданы исключения!!
    # Данный эффект включается атрибутом utf8exclude но использовать его не советуем!!!
    if (value($mdata => "utf8exclude")) {
        my $tke = value($mdata => "utf8exclude");
        foreach my $k ($q->all_parameters) {
            Encode::_utf8_on($usr{$k}) unless grep {$_ eq $k} @$tke;
        }
    }
    $self->set( 'usr' => \%usr );
    $self->set( 'error' => \@error );
    $self->set( 'status' => 0 );

    # Запуск транзакции
    my $status = $self->ActionTransaction($actObject,$actEvent);
    #return $status if $status > 1;

    1;
}

sub before_view { # Крючок ДО основного
    my $self = shift;
    my $q           = $self->q;
    my $actObject   = $self->actObject();
    my $actEvent    = $self->actEvent();
    my $mdata = $self->getActionRecord($actObject);
    binmode STDOUT, ":raw:utf8";
    
    print $q->header( -type => CONTENT_TYPE );
    1;
}
sub before_view_406 { # Крючок ДО основного 406
    my $self = shift;
    my $q           = $self->q;
    my $actObject   = $self->actObject();
    my $actEvent    = $self->actEvent();
    my $mdata = $self->getActionRecord($actObject);
    binmode STDOUT, ":raw:utf8";
    
    print $q->header( 
            -type   => CONTENT_TYPE,
            -status => 406,
        );
    1;
}
sub after_view { # Крючок ПОСЛЕ основного
    my $self = shift;
    my $q           = $self->q;
    my $actObject   = $self->actObject();
    my $actEvent    = $self->actEvent();
    my $usr         = $self->usr;
    my $error       = $self->error;
    my $status      = $self->status;
    my $mdata   = $self->getActionRecord($actObject);
    my $data    = uv2null($self->get('data'));
    my $output  = '';
    
    # Основные данные, общие для ответов
    my $debug_time = sprintf "%.3f", (getHiTime() - $self->config->hitime);
    my $remote_addr = $self->config->remote_addr;
    my $query_string = fv2null($self->config->query_string);
    
    my %wrap = (
                debug_time  => [$debug_time],
                remote_addr => [$remote_addr],
                query_string=> [$query_string],
                object      => [$actObject],
                status      => [$status],
                error       => @$error ? $error : [''],
                data        => [''],
        );
        
    # Корректировка вывода в зависимости от типа данных
    if (ref($data) eq 'HASH') {
        $wrap{data} = $data;
    } elsif (ref($data) eq 'ARRAY') {
        $wrap{data} = $data;
    } else {
        $wrap{data} = [$data];
    }

    # Корректировка вывода
    $output = XMLout(
        \%wrap,
        RootName   => RES_ROOTNAME,
        XMLDecl    => XMLDECL,
    );
    
    print $output;

    1;
}
sub read_api_xml {
    my $request = uv2null(shift);
    my $xml;
    
    unless ($request) {
        return (
                object  => '',
                data    => undef,
                status  => 0,
                error   => "Bad XML format. No response data",
            );
    }
    
    try {
        $xml = XMLin($request);
        if ($xml && ref($xml) eq 'HASH') {
            $xml->{status} = 1;
            $xml->{error} = '';
        } else {
            $xml = {
                object  => '',
                data    => undef,
                status  => 0,
                error   => "Bad XML format",
            };
        }
    } catch {
        $xml = {
            object  => '',
            data    => undef,
            status  => 0,
            error   => sprintf("Can't load XML from request \"%s\": %s", $request, $_),
        };
    };
    return %$xml;
}

1;
