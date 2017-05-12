package App::MonM::AlertGrid::Server; # $Id: Server.pm 24 2014-11-19 14:04:05Z abalama $
use strict;

=head1 NAME

App::MonM::AlertGrid::Server - Server of App::MonM::AlertGrid remote requests via HTTP/HTTPS

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

    none

=head1 DESCRIPTION

Server of App::MonM::AlertGrid remote requests via HTTP/HTTPS.
No public subroutines. See L<WWW::MLite>

=head1 HISTORY

See C<CHANGES> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<App::MonM>, L<WWW::MLite>

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
$VERSION = '1.00';

## VIEW
use CGI qw/-utf8/; # use CGI;

## CONTROLLER
use Encode;
use WWW::MLite::Util;
use CTK::Util qw/ :BASE :FORMAT /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Try::Tiny;

use constant {
        CONTENT_TYPE        => 'text/plain; charset=utf-8',
    };

sub handler {
    my $self = shift;
    
    # Регистрация объявленных обработчиков - использовать если их нет при конструкторе
    $self->register(qw/App::MonM::AlertGrid::Root/);

    # Все те переменные которые были ранее глобальными, теперь являются частью объекта
    my $q = new CGI;
    $self->set( 'q' => $q );
    
    # Инициализация типа обработчика и события
    my ($actObject,$actEvent) = split /[,]/, $q->param("action") || '';
    $actObject = 'default' unless $actObject && $self->ActionCheck($actObject);
    $actEvent  = $actEvent && $actEvent =~ /go/ ? 'go' : '';
    $self->set( 'actObject' => $actObject );
    $self->set( 'actEvent' => $actEvent );
    
    # Получаем атрибуты обработчика
    my $mdata = $self->getActionRecord($actObject);

    # Устанавливаем %usr, @error
    my (%usr, @error);
    %usr = (); foreach ($q->all_parameters) { $usr{$_} = $q->param($_) }

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
    binmode STDOUT, ":raw:utf8";
    
    print $q->header( -type => CONTENT_TYPE );
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
    my $data    = uv2null($self->get('data'));
    
    if (@$error) {
        printf "ERROR\n%s", join("\n", @$error);
    } else {
        print $data;
    }

    1;
}
1;
