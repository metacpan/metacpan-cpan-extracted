package CTK::Helper; # $Id: Helper.pm 193 2017-04-29 07:30:55Z minus $
use strict;

=head1 NAME

CTK::Helper - Helper for building CTK scripts

=head1 VIRSION

Version 2.68

=head1 HISTORY

=over 8

=item B<1.00>

Init version

=item B<1.01>

Added documentation

=item B<1.02>

Documentation modified

=item B<1.03>

Added new types of projects

=back

=head1 SYNOPSIS

    use CTK;
    use CTKx;
    use CTK::Helper;

    my $c = new CTK( syspaths => 1 );
    my $ctkx = CTKx->instance( c => $c );

    my $h = new CTK::Helper (
        -type           => TYPE,
        -projectname    => PROJECTNAME,
        -ctkversion     => CTK_VERSION,
    );

    my $status = $h->build();


=head1 DESCRIPTION

Helper for building CTK scripts

=head2 new

    my $h = new CTK::Helper (
        -type           => TYPE,
        -projectname    => PROJECTNAME,
        -ctkversion     => CTK_VERSION,
    );

Returns helper's object

=head2 build

    my $status = $h->build();

Building the project

=head2 backward_build

    my $status = $self->backward_build();

Second pass of building. For internal use only

=head1 SEE ALSO

L<ctklib>, L<ctklib-tiny>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

use CTKx;
use CTK::Util qw/ :BASE /;
use Cwd;
use Try::Tiny;
use Class::C3::Adopt::NEXT; #use MRO::Compat;

use constant {
    PROJECTNAME => 'foo',
    SUBCLASSES  => {
            regular => "CTK::Helper::SkelRegular",
            module  => "CTK::Helper::SkelModule",
            tiny    => "CTK::Helper::SkelTiny",
        },
    EXEMODE     => 0755,
    DIRMODE     => 0777,
    BOUNDARY    => qr/\-{5}BEGIN\s+FILE\-{5}(.*?)\-{5}END\s+FILE\-{5}/is,
    STDRPLC     => {
            PODSIG  => '=',
            DOLLAR  => '$',
            GMT     => sprintf("%s GMT", scalar(gmtime)),
            YEAR    => (gmtime)[5]+1900,
        },
};

use vars qw/$VERSION/;
$VERSION = '2.68';

sub new {
    my $class = shift;
    my ($type,$projectname,$ctkversion) = read_attributes([
        ['TYPE','TP','T'],
        ['PROJECT','PROJECTNAME','NAME'],
        ['CTKVERSION','VERSION'],
    ],@_) if defined $_[0];
    my $c = CTKx->instance->c();

    my $subclass = SUBCLASSES->{$type};
    croak "Class for $type project could not be loaded, or is an invalid name" unless $subclass;

    unless ( $subclass->can('build') ) {
        try {
            eval "require $subclass";
            die $@ if $@;
            our @ISA = ( $subclass );
        } catch {
            croak "Class $subclass could not be loaded. $_";
        };
    }

    my %rplc = %{(STDRPLC)};
    $rplc{PROJECTNAME}    = $projectname || PROJECTNAME;
    $rplc{PROJECTNAMEUCF} = ucfirst($rplc{PROJECTNAME});
    $rplc{PROJECTNAMEL}   = lc($rplc{PROJECTNAME});
    $rplc{CTKVERSION}     = $ctkversion || $c->VERSION();

    return bless {
            type    => $type,
            projectname => $projectname || PROJECTNAME,
            class   => $subclass,
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
        my $data = ($r =~ /\s*\r?\n\s*\r?\n(.+)/s) ? $1 : '';

        $mode = undef unless $mode =~ /^[0-9]{1,3}$/;
        $r = {
                name => $name,
                file => $file,
                data => lf_normalize($data),
                mode => defined $mode ? oct($mode) : undef,
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
    my $c = CTKx->instance->c();
    my $rplc = $self->{rplc};

    # Постобработка директорий
    my $dirs = $self->{dirs};
    my $cd = cwd();
    my $pdir = catdir($cd,$self->{projectname});
    foreach my $d (@$dirs) {
        my $path = CTK::catdir($cd, split(/\//,_ff($d->{path},$rplc)));
        my $mode = defined $d->{mode} ? $d->{mode} : DIRMODE;
        preparedir($path,$mode);
    }

    # Постобработка имен файлов и данных этих файлов
    my $pool = $self->{pool};
    my $overwrite = "yes";
    foreach my $f (@$pool) {
        my $name = $f->{name} || 'noname';
        unless ($f->{file}) {
            carp("Skipping file $name");
            next;
        }
        my $file = CTK::catfile($cd, split(/\//,_ff($f->{file},$rplc)));
        $overwrite = $c->cli_prompt("File \"$file\" already exists. Overwrite? :", $overwrite) if -e $file;
        if ($overwrite =~ /^y/i) {
            $overwrite = 'yes';
        } else {
            $overwrite = 'no';
            next;
        }
        my $mode = $f->{mode};
        my $data = _ff($f->{data},$rplc);
        bsave($file,$data);
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
1;
__END__
