package App::MonM::Helper; # $Id: Helper.pm 12 2014-09-23 13:16:47Z abalama $
use strict;

=head1 NAME

App::MonM::Helper - Helper for building App::MonM shared data

=head1 VIRSION

Version 1.01

=head1 SYNOPSIS

    use App::MonM::Helper;
    
    my $h = new App::MonM::Helper (
            -config => "/destination/directory/for/conf",
            -share  => "/destination/directory/for/data/share",
        );
    
    my $status = $h->build(
            PARAM1 => 'foo',
            PARAM2 => 'bar',
            # . . .
        );

=head1 DESCRIPTION

Helper for building App::MonM shared data

=head1 METHODS

=over 8

=item B<new>

    my $h = new App::MonM::Helper (
            -config => "/destination/directory/for/conf",
            -share  => "/destination/directory/for/data/share",
        );

Returns helper's object

=item B<build>

    my $status = $h->build(
            PARAM1 => 'foo',
            PARAM2 => 'bar',
            # . . .
        );

Returns status of builded

=back

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

our $DEBUG = 0;

use CTK::Util qw/ :BASE /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Try::Tiny;
use Class::C3::Adopt::NEXT; #use MRO::Compat;

use base qw/
        App::MonM::Skel::Config
        App::MonM::Skel::Share
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
    my ($conf_dir, $share_dir) = read_attributes([
        ['CONFDIR','CONFIGDIR','CONF', 'CONFIG'],
        ['SHAREDIR','SHARE'],
    ],@_) if defined $_[0];
    
    my %rplc = %{(STDRPLC)};
    return bless {
            boundary=> BOUNDARY,
            pool    => [],
            rplc    => { %rplc },
            dirs    => {
                    config => $conf_dir,
                    share  => $share_dir,
                },
            subdirs => {},
            pools   => {},
        }, $class;
}
sub build {
    my $self = shift;
    my %data = @_;
    
    # Переопределяем дерево каталогов
    $self->dirs;
    
    # Переопределяем пул данных
    $self->pool;

    my $ret = 0;
    my $bret = 0;
    
    # Передаем управление родительскому обработчику
    $ret = $self->maybe::next::method();
    return 0 unless $ret;
    
    #Возвращаем управление назад
    my $rplc = $self->{rplc};
    foreach (keys %data) {
        $rplc->{$_} = $data{$_};
    }

    # Постобработка директорий
    my $dirs = $self->{dirs};
    my $subdirs = $self->{subdirs} || {};
    foreach my $kd (keys %$subdirs) {
        my $vd = $subdirs->{$kd};
        foreach my $d (@$vd) {
            my @ds = split(/\//,_ff($d->{path},$rplc));
            my $root = uv2null(value($dirs, $kd));
            my $path = $root ? catdir($root, @ds) : catdir(@ds);
            my $mode = defined $d->{mode} ? $d->{mode} : DIRMODE;
            preparedir($path,$mode);
            printf "DIR> [%o] %s\n", $mode, $path if $DEBUG;
        }
    }
    
    # Постобработка файлов
    my $pools = $self->{pools};
    foreach my $kp (keys %$pools) {
        my $vp = $pools->{$kp};
        foreach my $p (@$vp) {
            next if $p->{type} && !isostype($p->{type});
            my $root = uv2null(value($dirs, $kp));
            my $name = $p->{name} || 'noname';
            unless ($p->{file}) {
                carp("Skipping file $name");
                next;
            }
            my @ds = split(/\//,_ff($p->{file},$rplc));
            my $file = catfile($root, @ds);
            my $mode = $p->{mode};
            my $data = _ff($p->{data},$rplc);
            printf "FIL> [%o] %s\n", $mode, $file if $DEBUG;
            fsave($file,$data);
            chmod($mode,$file) if defined($mode);
        }
        #print ">>> ", $kp, "\n";
    }
    return 1;
}
sub dirs {
    my $self = shift;
    $self->maybe::next::method();
    my $dirs = $self->{subdirs} || {};
    foreach my $kd (keys %$dirs) {
        if (ref($dirs->{$kd}) eq 'HASH') {
            $dirs->{$kd} = [$dirs->{$kd}];
        } elsif (ref($dirs->{$kd}) eq 'ARRAY') {
            # OK;
        } else {
            carp "Directories missing" if $dirs->{$kd};
        }
    }
    return 1;
}
sub pool {
    my $self = shift;
    $self->maybe::next::method();
    my $boundary = $self->{boundary};
    my $pools = $self->{pools} || {};
    foreach my $kd (keys %$pools) {
        my $buff = $pools->{$kd};
        my @pool;
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
        $pools->{$kd} = [@pool];
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
