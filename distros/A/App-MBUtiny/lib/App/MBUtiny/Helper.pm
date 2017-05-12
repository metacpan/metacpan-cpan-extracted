package App::MBUtiny::Helper; # $Id: Helper.pm 73 2014-09-20 20:30:17Z abalama $
use strict;

=head1 NAME

App::MBUtiny::Helper - Helper for building App::MBUtiny shared data

=head1 VIRSION

Version 1.01

=head1 SYNOPSIS

    use App::MBUtiny::Helper;
   
    my $h = new App::MBUtiny::Helper ( "/destination/directory" );
    
    my $status = $h->build();

=head1 DESCRIPTION

Helper for building App::MBUtiny shared data

=head1 HISTORY

See C<CHANGES> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK::Helper>

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

use CTK::Util qw/ :BASE /;
use Class::C3::Adopt::NEXT; #use MRO::Compat;

use base qw/
        App::MBUtiny::Skel::Config
    /;

use constant {
    EXEMODE     => 0755,
    DIRMODE     => 0777,
    BOUNDARY    => qr/\-{5}BEGIN\s+FILE\-{5}(.*?)\-{5}END\s+FILE\-{5}/is,
    STDRPLC     => {
            PODSIG  => '=',
            DOLLAR  => '$',
            GMT     => sprintf("%s GMT", scalar(gmtime)),
        },
};

sub new {
    my $class = shift;
    my $dir   = shift;
    
    my %rplc = %{(STDRPLC)};
    return bless {
            dir     => $dir,
            boundary=> BOUNDARY,
            pool    => [],
            rplc    => { %rplc },
            dirs    => [],
        }, $class;
}
sub build {
    my $self = shift;
    
    # Переопределяем дерево каталогов
    my @dirs = $self->dirs() if $self->can('dirs');
    
    if (@dirs && ref($dirs[0]) eq 'HASH') {
        $self->{dirs} = [@dirs];
    } elsif (@dirs && ref($dirs[0]) eq 'ARRAY') {
        $self->{dirs} = $dirs[0];
    } else {
        carp "Directories missing" if @dirs;
    }

    # Преобразуем пул в структуру @pool
    my @pool;
    my $boundary = $self->{boundary};
    my $buff = $self->can('pool') ? $self->pool() : '';
    $buff =~ s/$boundary/_bcut($1,\@pool)/ge;
    foreach my $r (@pool) {
        my $name = ($r =~ /^\s*name\s*\:\s*(.+?)\s*$/mi) ? $1 : '';
        my $file = ($r =~ /^\s*file\s*\:\s*(.+?)\s*$/mi) ? $1 : '';
        my $mode = ($r =~ /^\s*mode\s*\:\s*(.+?)\s*$/mi) ? $1 : '';
        my $type = ($r =~ /^\s*type\s*\:\s*(.+?)\s*$/mi) ? $1 : '';
        my $data = ($r =~ /\s*\r?\n\s*\r?\n(.+)/s) ? $1 : '';
        # CRLF correct
        my $crlf = _crlf();
        $data =~ s/\r?\n/_to_crlf($crlf)/gem;
        
        $mode = undef unless $mode =~ /^[0-9]{1,3}$/;
        $r = {
                name => $name,
                file => $file,
                data => $data,
                mode => defined $mode ? oct($mode) : undef,
                type => $type,
            };
    }
    $self->{pool} = [@pool];
    
    my $ret = 0;
    my $bret = 0;
    
    # Передаем управление родительскому обработчику
    $ret = $self->maybe::next::method();
    return 0 unless $ret;
    
    #Возвращаем управление назад
    $bret = $self->backward_build();
    return $bret;
}
sub backward_build {
    my $self = shift;
    my $rplc = $self->{rplc};
    
    # Постобработка директорий
    my $dirs = $self->{dirs};
    my $dir  = $self->{dir};
    foreach my $d (@$dirs) {
        my $path = CTK::catdir($dir, $d->{path});
        my $mode = defined $d->{mode} ? $d->{mode} : DIRMODE;
        preparedir($path,$mode);
    }
    
    # Постобработка имен файлов и данных этих файлов
    my $pool = $self->{pool};
    foreach my $f (@$pool) {
        next if $f->{type} && !isostype($f->{type});
        my $name = $f->{name} || 'noname';
        unless ($f->{file}) {
            carp("Skipping file $name");
            next;
        }
        my $file = CTK::catfile($dir, $f->{file});
        my $mode = $f->{mode};
        my $data = _ff($f->{data},$rplc);
        fsave($file,$data);
        chmod($mode,$file) if defined($mode);
    }

    return 1;
}
sub _bcut {
    my $s = shift;
    my $a = shift;
    push @$a, $s;
    return '';
}
sub _ff {
    # Маленький шаблонизатор
    my $d = shift || ''; # данные
    my $h = shift || {}; # массив
    $d =~ s/\%(\w+?)\%/(defined $h->{$1} ? $h->{$1} : '')/eg;
    return $d
}
sub _crlf {
    # Original: CGI::Simple
    return "\n" if isostype('Windows') or isostype('Unix');
    my $OS = $^O || do { require Config; $Config::Config{'osname'} };
    return
        ( $OS =~ m/VMS/i )   ? "\n"
        : ( "\t" ne "\011" ) ? "\r\n"
        :                      "\015\012";
}
sub _to_crlf {shift}
1;
