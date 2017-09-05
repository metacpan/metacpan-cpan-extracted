package App::DistSync; # $Id: DistSync.pm 25 2017-08-29 09:21:01Z abalama $
use strict;

=head1 NAME

App::DistSync - Utility synchronization of the mirror distribution-sites

=head1 VERSION

Version 1.05

=head1 SYNOPSIS

    use App::DistSync;
    
    my $ds = new App::DistSync(
            dir => "/var/www/www.example.com/dist",
            pid => $$,
        );

    $ds->init or die ("Initialization error");
    
    $ds->sync or die ("Sync error");

=head1 DESCRIPTION

Utility synchronization of the mirror distribution-sites

=head2 METHODS

=over 8

=item new

    my $ds = new App::DistSync(
            dir => "/var/www/www.example.com/dist",
            pid => $$,
        );

Returns the object

=item init

    $ds->init or die ("Initialization error");

Initializing the mirror in the specified directory

=item sync

    $ds->sync or die ("Sync error");

Synchronization of the specified directory with the remote resources (mirrors)

=back

=head2 SHARED FUNCTIONS

=over 8

=item fdelete

    my $status = fdelete( $file );

Deleting a file if it exists

=item fetch

    my $struct = fetch( $URI_STRING, "path/to/file.txt", "/tmp/file.txt" );
    
Fetching file from remote resource by URI and filename. 
The result will be written to the specified file. For example: "/tmp/file.txt"

Function returns structure, contains:

    {
        status  => 1,         # Status. 0 - Errors; 1 - OK
        mtime   => 123456789, # Last-Modified in ctime format or 0 in case of errors
        size    => 123,       # Content-length
        code    => 200,       # HTTP Status code
    };

=item touch

    my $status = touch( $file );

Makes files exist, with current timestamp. 
See original in L<ExtUtils::Command/touch>

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<LWP>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<LWP>, L<ExtUtils::Manifest>

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
$VERSION = '1.05';

use Carp;
use File::Basename;
use File::Copy qw/ mv /;
use File::Spec;
use File::Find;
use File::Path;
use YAML::Tiny;
use URI;
use LWP::Simple qw/$ua head mirror/;

use base qw/Exporter/;
our @EXPORT = qw/
        debug
    /; # Auto
our @EXPORT_OK = qw/
        debug
        touch
        fdelete
        read_yaml
        write_yaml
        maniread
        maniwrite
        fetch
    /; # Manual

use constant {
    TEMPFILE    => sprintf("distsync_%s.tmp", $$),
    TIMEOUT     => 30,
    METAFILE    => 'META',
    MANIFEST    => 'MANIFEST',
    MANISKIP    => 'MANIFEST.SKIP',
    MANITEMP    => 'MANIFEST.TEMP',
    MANILOCK    => 'MANIFEST.LOCK',
    MANIDEL     => 'MANIFEST.DEL',
    MIRRORS     => 'MIRRORS',
    README      => 'README',
    SKIPFILES   => [qw/
            META
            MANIFEST
            MANIFEST.SKIP
            MANIFEST.LOCK
            MANIFEST.TEMP
            MANIFEST.DEL
            MIRRORS
            README
        /],
    SKIPMODE    => 1,
    LIMIT       => '+1m', # '+1m' Limit gt and lt
    EXPIRE      => '+3d', # '+3d' For deleting
    FREEZE      => '+1d', # '+1d' For META test
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

our $DEBUG = 0;

# Methods
sub new {
    my $class = shift;
    my %props = @_;
    
    $props{stamp} = time;
    $props{pid} ||= $$;
    $props{timeout} //= TIMEOUT;
    
    # Directories check
    my $dir = $props{dir};
    carp("Can't select directory") && return unless defined $dir;
    $props{file_meta}       = File::Spec->catfile($dir, METAFILE);
    $props{file_manifest}   = File::Spec->catfile($dir, MANIFEST);
    $props{file_maniskip}   = File::Spec->catfile($dir, MANISKIP);
    $props{file_manilock}   = File::Spec->catfile($dir, MANILOCK);
    $props{file_manitemp}   = File::Spec->catfile($dir, MANITEMP);
    $props{file_manidel}    = File::Spec->catfile($dir, MANIDEL);
    $props{file_mirrors}    = File::Spec->catfile($dir, MIRRORS);
    $props{file_readme}     = File::Spec->catfile($dir, README);
    $props{file_temp}       = File::Spec->catfile(File::Spec->tmpdir(), TEMPFILE);
    
    # Read META file as YAML
    my $meta = read_yaml($props{file_meta});
    $props{meta} = $meta;
    
    # Create current static dates
    $props{mtime_manifest} = (-e $props{file_manifest}) && -s $props{file_manifest}
        ? (stat($props{file_manifest}))[9] 
        : 0;
    $props{mtime_manidel}  = (-e $props{file_manidel}) && -s $props{file_manidel}
        ? (stat($props{file_manidel}))[9] 
        : 0;
    $props{mtime_mirrors}  = (-e $props{file_mirrors}) && -s $props{file_mirrors}
        ? (stat($props{file_mirrors}))[9] 
        : 0;
    
    # Read MANIFEST, MANIFEST.SKIP, MANIFEST.DEL files
    $props{manifest} = maniread($props{file_manifest});
    $props{maniskip} = maniread($props{file_maniskip}, SKIPMODE);
    $props{manidel}  = maniread($props{file_manidel});
    $props{mirrors}  = maniread($props{file_mirrors});
    
    # TimeOut
    my $to = $props{timeout};
    if ($to && $to =~ /^[0-9]{1,11}$/) {
        $ua->timeout($to);
    } else {
        croak(sprintf("Can't use specified timeout value: %s", $to));
    }
    
    my $self = bless({%props}, $class);
    return $self;
}
sub init { # Initialization
    my $self = shift;
    my $stamp = scalar(localtime($self->{stamp}));
    
    # MANIFEST.SKIP
    touch($self->{file_maniskip}) or return 0;
    if (-e $self->{file_maniskip} && -z $self->{file_maniskip}) {
        open FILE, ">", $self->{file_maniskip} or return 0;
        printf FILE join("\n",
            "# Generated on %s",
            "# List of files that should not be synchronized",
            "#",
            "# Format of file:",
            "#",
            "# dir1/dir2/.../dirn/foo.txt        any comment, for example blah-blah-blah",
            "# bar.txt                           any comment, for example blah-blah-blah",
            "# baz.txt",
            "# 'spaced dir1/foo.txt'             any comment, for example blah-blah-blah",
            "# 'spaced dir1/foo.txt'             any comment, for example blah-blah-blah",
            "# !!perl/regexp (?i-xsm:\\.bak\$)     avoid all bak files",
            "#",
            "# See also MANIFEST.SKIP file of ExtUtils::Manifest v1.68 or later",
            "#",
            "",
            "# Avoid version control files.",
            "!!perl/regexp (?i-xsm:\\bRCS\\b)",
            "!!perl/regexp (?i-xsm:\\bCVS\\b)",
            "!!perl/regexp (?i-xsm:\\bSCCS\\b)",
            "!!perl/regexp (?i-xsm:,v\$)",
            "!!perl/regexp (?i-xsm:\\B\\.svn\\b)",
            "!!perl/regexp (?i-xsm:\\B\\.git\\b)",
            "!!perl/regexp (?i-xsm:\\B\\.gitignore\\b)",
            "!!perl/regexp (?i-xsm:\\b_darcs\\b)",
            "!!perl/regexp (?i-xsm:\\B\\.cvsignore\$)",
            "",
            "# Avoid temp and backup files.",
            "!!perl/regexp (?i-xsm:~\$)",
            "!!perl/regexp (?i-xsm:\\.(old|bak|tmp|rej)\$)",
            "!!perl/regexp (?i-xsm:\\#\$)",
            "!!perl/regexp (?i-xsm:\\b\\.#)",
            "!!perl/regexp (?i-xsm:\\.#)",
            "!!perl/regexp (?i-xsm:\\..*\\.sw.?\$)",
            "",
            "# Avoid prove files",
            "!!perl/regexp (?i-xsm:\\B\\.prove\$)",
            "",
            "# Avoid MYMETA files",
            "!!perl/regexp (?i-xsm:^MYMETA\\.)",
            "",
            "# Avoid Apache and building files",
            "!!perl/regexp (?i-xsm:\\B\\.ht.+\$)",
            "!!perl/regexp (?i-xsm:\\B\\.exists\$)",
            "\n",
            ), $stamp;
        close FILE;
    }
    
    # MANIFEST.DEL
    touch($self->{file_manidel}) or return 0;
    if (-e $self->{file_manidel} && -z $self->{file_manidel}) {
        open FILE, ">", $self->{file_manidel} or return 0;
        printf FILE join("\n",
            "# Generated on %s",
            "# List of files that must be deleted. By default, the files will be",
            "# deleted after 3 days.",
            "#",
            "# Format of file:",
            "#",
            "# dir1/dir2/.../dirn/foo.txt        1d",
            "# bar.txt                           2M",
            "# baz.txt",
            "# 'spaced dir1/foo.txt'             1m",
            "# 'spaced dir1/foo.txt'             2y",
            "#",
            "\n",
            ), $stamp;
        close FILE;
    }
    
    # MIRRORS
    touch($self->{file_mirrors}) or return 0;
    if (-e $self->{file_mirrors} && -z $self->{file_mirrors}) {
        open FILE, ">", $self->{file_mirrors} or return 0;
        printf FILE join("\n",
            "# Generated on %s",
            "# List of addresses (URIs) of remote storage (mirrors).",
            "# Must be specified at least two mirrors",
            "#",
            "# Format of file:",
            "#",
            "# http://www.example.com/dir1       any comment, for example blah-blah-blah",
            "# http://www.example.com/dir2       any comment, for example blah-blah-blah",
            "# 'http://www.example.com/dir2'     any comment, for example blah-blah-blah",
            "#",
            "\n",
            ), $stamp;
        close FILE;
    }
    
    # README
    touch($self->{file_readme}) or return 0;
    if (-e $self->{file_readme} && -z $self->{file_readme}) {
        open FILE, ">", $self->{file_readme} or return 0;
        printf FILE join("\n",
            "# This file contains information about the resource (mirror) in the free form.",
            "#",
            "# Initialization date  : %s",
            "# Resource's directory : %s",
            "#",
            "\n",
            ), $stamp, $self->{dir};
        close FILE;
    }
    
    return 1;
}
sub sync { # Synchronization. Main proccess
    my $self = shift;
    my $status = 0; # Статус операции для META
    
    # Создаем список исключений на базе прочитанного ранее SKIP + системные файлы
    my @skip_keys = @{(SKIPFILES)};
    push @skip_keys, keys %{($self->{maniskip})} if ref($self->{maniskip}) eq 'HASH';
    my %skips; for (@skip_keys) {$skips{$_} = _qrreconstruct($_)}
    #debug(Data::Dumper::Dumper(\%skips)) && return 0;
    
    # Удяляем файлы перечисленные в .DEL
    debug("Deleting of declared files");
    my $dellist = $self->{manidel};
    my $expire = _expire(0);
    if ($dellist && ref($dellist) eq 'HASH') {
        foreach (values %$dellist) {
            my $dt = _expire($_->[0] || 0);
            $_ = [$dt];
            $expire = $dt if $dt > $expire;
        }
        #debug(Data::Dumper::Dumper($dellist));
    }
    $expire = _expire(EXPIRE) unless $expire > 0;
    debug(sprintf("Expires at %s", scalar(localtime(time + $expire))));
    my $delfile = $self->{file_manidel};
    my $deltime = $self->{mtime_manidel};
    if ($deltime && (time - $deltime) > $expire) {
    
        # Удаляем файлы физически, если они есть физически и их нет в SKIP файле!
        foreach my $k (keys %$dellist) {
            if (_skipcheck(\%skips, $k)) { # Файл есть в списке исклюений
                debug(sprintf("> [SKIPPED] %s", $k));
            } else {
                my $f = File::Spec->canonpath(File::Spec->catfile($self->{dir}, $k));
                if (-e $f) {
                    fdelete($f);
                    debug(sprintf("> [DELETED] %s", $k));
                } else {
                    debug(sprintf("> [MISSING] %s (%s)", $k, $f));
                }
            }
        }
        
        fdelete($delfile); # Удаляем файл MANIFEST.DEL
        touch($delfile); # Создаем новый файл MANIFEST.DEL
    } else {
        if ($deltime) {
            debug(sprintf("Deleting is skipped. File %s\n\tcreated\t%s;\n\tnow\t%s;\n\texpires\t%s",
                    MANIDEL,
                    scalar(localtime($deltime)),
                    scalar(localtime(time)),
                    scalar(localtime($deltime + $expire)),
                ));
        } else {
            debug(sprintf("Deleting is skipped. Missing file %s",  MANIDEL))
        }
    }
    
    # Добавляем в список исключений на базе прочитанного ранее SKIP - DEL файлы
    my @del_keys = keys %$dellist if ref($dellist) eq 'HASH';
    for (@del_keys) {$skips{$_} = _qrreconstruct($_)}
    
    ################
    # Синхронизация
    ################
    my %sync_list;      # Синхронизационный список
    my %delete_list;    # Список на удаление
    
    # Чтение MIRRORS и принятие решения - делать синхронизацию или нет
    debug("Synchronization");
    my $mirror_list = $self->{mirrors};
    my @mirrors = sort {$a cmp $b} keys %$mirror_list if ref($mirror_list) eq 'HASH';
    if (@mirrors) {
        foreach my $url (@mirrors) {
            debug(sprintf("\nRESOURCE %s",$url));
            
            # Получение .LOCK файла, пропуск если он имеется
            debug(sprintf("Fetching %s file", MANILOCK));
            my $fetch_lock = fetch($url, MANILOCK, $self->{file_manitemp});
            if ($fetch_lock->{status}) {
                if ($self->check_lock($self->{file_manitemp})) {
                    $self->{uri} = $url;
                    debug("> [SKIPPED] Current resource SHOULD NOT update itself");
                } else {
                    debug("> [SKIPPED] Remote resource is in a state of updating. Please wait");
                }
                next;
            }
            #debug(Data::Dumper::Dumper($fetch_data));
            
            # Получение удаленного META и анализ его на status = 1. Иначе, пропуск данного ресурса
            debug(sprintf("Fetching %s file", METAFILE));
            my $fetch_meta = fetch($url, METAFILE, $self->{file_manitemp});
            if ($fetch_meta->{status}) {
                my $remote_meta = read_yaml($self->{file_manitemp});
                if ($remote_meta && ((ref($remote_meta) eq 'ARRAY') || ref($remote_meta) eq 'YAML::Tiny')) {
                    $remote_meta = $remote_meta->[0] || {};
                } elsif ($remote_meta && ref($remote_meta) eq 'HASH') {
                    # OK
                } else {
                    debug(Data::Dumper::Dumper(ref($remote_meta),$remote_meta));
                    debug("> [SKIPPED] Remote resource is unreadable. Please contact the administrator of this resource");
                    next;
                }
                #debug(Data::Dumper::Dumper($remote_meta));
                if ($remote_meta && $remote_meta->{status}) {
                    my $remote_uri  = $remote_meta->{uri} || 'localhost';
                    my $remote_date = $fetch_meta->{mtime} || 0;
                    my $remote_ok = (time - $remote_date) > _expire(FREEZE) ? 0 : 1;
                    debug(sprintf("REMOTE RESOURCE:"
                        ."\n\tResource:\t%s"
                        ."\n\tDate:\t\t%s"
                        ."\n\tModified:\t%s"
                        ."\n\tStatus:\t\t%s", 
                            $remote_uri, 
                            defined $remote_meta->{date} ? $remote_meta->{date} : 'UNKNOWN', 
                            $remote_date ? scalar(localtime($remote_date)) : 'UNKNOWN', 
                            $remote_ok ? "OK" : "EXPIRED"
                        ));
                    unless ($remote_ok) {
                        debug(sprintf("> [SKIPPED] Remote resource is expired. Last updated: %s", 
                                $remote_date ? scalar(localtime($remote_date)) : 'UNKNOWN'
                            ));
                        next
                    }
                } else {
                    debug("> [SKIPPED] Remote resource is in negative state. Please contact the administrator of this resource");
                    next;
                }
            }
            
            # Получение удаленного MANIFEST
            debug(sprintf("Fetching %s file", MANIFEST));
            my $fetch_mani = fetch($url, MANIFEST, $self->{file_manitemp});
            if ($fetch_mani->{status}) {
                # Читаем файл в отдельную структуру
                my $remote_manifest = maniread($self->{file_manitemp});
                my $local_manifest = $self->{manifest};
                my %mtmp;
                
                # Два списка объединяются во временную структуру
                foreach my $k (keys(%$local_manifest), keys(%$remote_manifest)) {
                    if ($mtmp{$k}) {
                        my $mt_l = $local_manifest->{$k}[0] || 0;
                        my $mt_r = $remote_manifest->{$k}[0] || 0;
                        $mtmp{$k}++ if $mt_l && $mt_r && $mt_l == $mt_r;
                    } else {
                        $mtmp{$k} = 1
                    }
                    #debug(Data::Dumper::Dumper($mt_l,$mt_r));
                }
                
                # Полуаем разницумоих и удаленных файлов
                # [<] Есть строка в левом файле
                # [>] есть строка в правом файле
                # [{] Более "свежий" в левом файле
                # [}] Более "свежий" в првом файле
                # [~] Отличаются размеры файлов в строке. Просто вывод информации об этом,
                #     т.к. более приоритетными являются даты модификации и наличие.
                #
                # Сравнение делается так:
                # пробегамся по полученному хэшу и смотрим где инкремент равен 1!
                # Там где 1 - значит данный файл есть в одном из файлов, в каком? если 
                # в левом, помечается что в левом, иначе в правом
                foreach my $k (keys %mtmp) {
                    next unless $mtmp{$k} && $mtmp{$k} == 1;
                    if ($local_manifest->{$k} && $remote_manifest->{$k}) {
                        my $mt_l = $local_manifest->{$k}[0] || 0;
                        my $mt_r = $remote_manifest->{$k}[0] || 0;
                        if (($mt_l > $mt_r) && ($mt_l - $mt_r) > _expire(LIMIT)) {
                            # debug(sprintf("> [{] %s", $k));
                        } if (($mt_l < $mt_r) && ($mt_r - $mt_l) > _expire(LIMIT)) {
                            debug(sprintf("> [}] %s (LOC: %s < RMT: %s)", $k, 
                                    scalar(localtime($mt_l)),
                                    scalar(localtime($mt_r)),
                                ));
                            # Скачиваем т.к. там свежее
                            unless (_skipcheck(\%skips, $k)) {
                                my $ar = $sync_list{$k} || [];
                                push @$ar, {
                                    uri     => $url,
                                    mtime   => $remote_manifest->{$k}[0],
                                    size   => $remote_manifest->{$k}[1],
                                };
                                $sync_list{$k} = $ar;
                            }
                        } else {
                            #debug(sprintf("> [=] %s", $k));
                        }
                    } elsif ($local_manifest->{$k}) {
                        # debug(sprintf("> [<] %s", $k));
                    } elsif ($remote_manifest->{$k}) {
                        debug(sprintf("> [>] %s", $k));
                        # Скачиваем, т.к. у нас такого нет
                        unless (_skipcheck(\%skips, $k)) {
                            my $ar = $sync_list{$k} || [];
                            push @$ar, {
                                uri     => $url,
                                mtime   => $remote_manifest->{$k}[0],
                                size    => $remote_manifest->{$k}[1],
                            };
                            $sync_list{$k} = $ar;
                        }
                    } else {
                        debug(sprintf("> [!] %s", $k));
                    }
                }
                $status = 1; # Удалось связаться с ресурсом, значит он доступен
            } else {
                debug(sprintf("> [MISSING] File %s not fetched. Status code: %s", 
                        MANIFEST,
                        $fetch_mani->{code} || 'UNDEFINED',
                    ));
                #debug(Data::Dumper::Dumper($fetch_mani));
                next;
            }
            
            # Пробегаемся по MIRRORS удаленным файлам и добавляем его к общему списку на обновление
            debug(sprintf("Fetching %s file", MIRRORS));
            my $fetch_mirr = fetch($url, MIRRORS, $self->{file_manitemp});
            if ($fetch_mirr->{status} && ((-z $self->{file_mirrors}) || $fetch_mirr->{mtime} > $self->{mtime_mirrors})) {
                # Читаем файл в отдельную структуру
                my $remote_mirr = maniread($self->{file_manitemp});
                # Добаляем файл на скачку, если там есть два или более зеркал
                my $mcnt = scalar(keys %$remote_mirr) || 0;
                if ($mcnt && $mcnt > 1) {
                    my $k = MIRRORS;
                    my $ar = $sync_list{$k} || [];
                    push @$ar, {
                        uri     => $url,
                        mtime   => $fetch_mirr->{mtime},
                        size    => $fetch_mirr->{size},
                    };
                    $sync_list{$k} = $ar;
                } else {
                    debug(sprintf("> [SKIPPED] File %s on %s contains too few mirrors", MIRRORS, $url));
                }
            }
            
            # Пробегаемся по .DEL удаленным файлам и получаем список для принудительного удаления
            debug(sprintf("Fetching %s file", MANIDEL));
            my $fetch_dir = fetch($url, MANIDEL, $self->{file_manitemp});
            if ($fetch_dir->{status}) {
                # Читаем файл в отдельную структуру
                my $remote_manidel = maniread($self->{file_manitemp});
                foreach my $k (keys %$remote_manidel) {
                    unless (_skipcheck(\%skips, $k)) {
                        $delete_list{$k} ? ($delete_list{$k}++) : ($delete_list{$k} = 1)
                    }
                }
            }
        } continue {
            fdelete($self->{file_manitemp});
        }
    } else {
        carp(sprintf("File %s is empty", MIRRORS));
        $status = 1; # Факт невозможности получить зеркала не является признаком того что ресурс
                     # отработал с ошибками
    }
    
    # Удаляем принудительно файлы полученного списка
    #debug(Data::Dumper::Dumper(\%delete_list));
    debug("Deleting files");
    foreach my $k (keys %delete_list) {
        my $f = File::Spec->canonpath(File::Spec->catfile($self->{dir}, $k));
        if (-e $f) {
            fdelete($f);
            debug(sprintf("> [DELETED] %s", $k));
        } else {
            debug(sprintf("> [MISSING] %s (%s)", $k, $f));
        }
    }
    
    # Проходим по sync_list и скачиваем файлы, но которых НЕТ в списке на удаление
    debug("Downloading files");
    #debug(Data::Dumper::Dumper(\%sync_list));
    my $total = 0;
    my $cnt = 0;
    my $all = scalar(keys %sync_list);
    foreach my $k (sort {lc $a cmp lc $b} keys %sync_list) {$cnt++;
        debug(sprintf("%03d/%03d %s", $cnt, $all, $k));
        my $list = $sync_list{$k};
        if ($list && ref($list) eq 'ARRAY') {
            my $mt_l = $self->{manifest}{$k}[0] || 0;
            my $dwldd = 0;
            my $skipped = 0;
            foreach my $job (sort {($b->{mtime} || 0)  <=> ($a->{mtime} || 0)} @$list) {
                last if $dwldd; # Выход, если скачали!
                my $mt_r = $job->{mtime};
                my $url  = $job->{uri};
                my $size = $job->{size};
                unless ($url) {
                    debug(sprintf("\t[SKIPPED] No URI"));
                    next;
                }
                unless ($size) {
                    debug(sprintf("\t[SKIPPED] No data, %s", $url));
                    next;
                }
                unless ($mt_r || !$mt_l) {
                    debug(sprintf("\t[SKIPPED] The remote file have undefined modified date, %s", $url));
                    next;
                }
                if ($mt_l >= $mt_r) {
                    debug(sprintf("\t[SKIPPED] File is up to date, %s", $url));
                    $skipped = 1;
                    next;
                }
                
                # Все проверки прошли, скачиваем
                my $fetch_file = fetch($url, $k, $self->{file_temp});
                if ($fetch_file->{status}) {
                    my $size_fact = $fetch_file->{size} || 0;
                    if ($size_fact && $size_fact == $size) {
                        debug(sprintf("\t[  OK   ] Received %d bytes, %s", $size_fact, $url));
                        $total += $size_fact;
                        $dwldd = 1;
                    } else {
                        debug(sprintf("\t[ ERROR ] Can't fetch file [%s], %s", 
                                $url
                            ));
                    }
                } else {
                    debug(sprintf("\t[ ERROR ] Can't fetch file [%s], %s", 
                            $fetch_file->{code} ? $fetch_file->{code} : 'UNDEFINED',
                            $url
                        ));
                }
                
            }
            
            if ($dwldd) { # Файл скачен и лежит во временном файле
                # Откуда : $self->{file_temp}
                # Куда   : $k
                my $src = $self->{file_temp};
                my $dst = File::Spec->canonpath(File::Spec->catfile($self->{dir}, $k));
                
                # Создаем директорию азначения
                my $dir = dirname($dst); # See File::Basename
                my $mkerr;
                mkpath($dir, {
                        verbose => 1,
                        mode => 0777,
                        error => \$mkerr,
                });
                if ($mkerr && (ref($mkerr) eq 'ARRAY') && @$mkerr) {
                    foreach my $e (@$mkerr) {
                        next unless $e && ref($e) eq 'HASH';
                        while (my ($_k, $_v) = each %$e) {
                            carp(sprintf("%s: %s", $_k, $_v));
                        }
                    }
                    #debug(Data::Dumper::Dumper($mkerr));
                }
                #debug(sprintf("--> %s >>> %s", $src, $dst));
                #debug(sprintf("--> %s >>> %s", $dst, $dir));
                
                # Переносим файлы по назначению
                fdelete($dst);
                unless (mv($src, $dst)) {
                    debug(sprintf("\t[ ERROR ] Can't move file %s to %s", $src, $dst));
                    carp($!);
                }
            } else {
                debug(sprintf("\t[FAILED ] Can't fetch file %s", $k)) unless $skipped;
            }
            
            #debug($mt_l);
        } else {
            debug(sprintf("\t[SKIPPED] Nothing to do for %s", $k));
        }
    }
    debug(sprintf("Received %d bytes", $total));
    
    # Формируем новый MANIFEST
    debug("Creating new manifest");
    my $new_manifest = manifind($self->{dir});
    
    # Отбираем файлы исключая исключения
    foreach my $k (keys %$new_manifest) {
        my $nskip = _skipcheck(\%skips, $k);
        delete $new_manifest->{$k} if $nskip;
        debug(sprintf("> [%s] %s", $nskip ? "SKIPPED" : " ADDED ", $k));
    }
    #debug(Data::Dumper::Dumper($new_manifest));
    
    # Пишем сам файл
    debug("Saving manifest to file ".MANIFEST);
    return 0 unless maniwrite($self->{file_manifest}, $new_manifest);
    
    # Формируем новый META
    debug("Creating new META file");
    my $new_meta = {
            last_start  => $self->{stamp},
            last_finish => time,
            last_pid    => $self->{pid},
            uri         => $self->{uri} || 'localhost',
            date        => scalar(localtime(time)),
            status      => 1, # $status,
                            # статус META выставляется только по факту успешного формирования итоговой структуры
                            # катаклога. Это изменение отличает мета-файл от только что инициализированного.
                            # Внесенные изменения см. #468
        };
    return 0 unless write_yaml($self->{file_meta}, $new_meta);
    
    return $status;
}
sub check_lock { # Проверка факта, что файл является собственным
    my $self = shift;
    my $file = shift;
    return 0 unless $file && -e $file;
    
    local *RD_LOCK_FILE;
    unless (open(RD_LOCK_FILE, "<", $file)) {
        carp(sprintf("Can't open file %s to read: %s", $file, $!));
        return 0;
    }
    
    my $l;
    chomp($l = <RD_LOCK_FILE>); $l = "" unless defined $l;
    unless (close RD_LOCK_FILE) {
        carp(sprintf("Can't close file %s: %s", $file, $!));
        return 0;
    }
        
    my ($r_pid, $r_stamp, $r_name) = split(/#/, $l);
    if ($r_pid && ($r_pid =~ /^[0-9]{1,11}$/) && kill(0, $r_pid)) {
        return 1 if $self->{pid} == $r_pid;
    }
    return 0;
}

# Functions
sub debug { 
    print STDOUT @_ ? @_ : '',"\n" if $DEBUG;
    1;
}
sub touch {
    my $file = shift;
    return 0 unless defined $file;
    local *FILE;
    unless (open(FILE, ">>", $file)) {
        carp(sprintf("Can't write file %s: %s",$file, $!));
        return 0;
    }
    unless (close(FILE)) {
        carp(sprintf("Can't close file %s: %s",$file, $!));
        return 0;
    }
    my $t = time;
    unless (utime($t,$t,$file)) {
        carp(sprintf("Can't touch file %s: %s",$file, $!));
        return 0;
    }
    return 1;
}
sub fdelete {
    my $file = shift;
    return 0 unless defined $file && -e $file;
    unless (unlink($file)) {
        carp(sprintf("Can't delete file %s: %s",$file, $!)) ;
        return 0;
    }
    return 1;
}
sub read_yaml {
    my $file = shift;
    return [] unless defined $file;
    return [] unless (-e $file) && -r $file;
    my $yaml = new YAML::Tiny;
    my $data = $yaml->read($file);
    return [] unless $data;
    return $data;
}
sub write_yaml {
    my $file = shift;
    my $data = shift;
    return 0 unless defined $file;
    return 0 unless defined $data;
    my $yaml = new YAML::Tiny( $data );
    $yaml->write( $file );
    return 1;
}
sub maniread { # Reading data from MANEFEST, MIRRORS and MANEFEST.* files
    # Original see Ext::Utils::maniread
    my $mfile = shift;
    my $skipflag = shift;
    
    my $read = {};
    return $read unless defined($mfile) && (-e $mfile) && (-r $mfile) && (-s $mfile);
    local *M;
    unless (open M, "<", $mfile){
        carp("Problem opening $mfile: $!");
        return $read;
    }
    local $_;
    while (<M>){
        chomp;
        next if /^\s*#/;
        my($file, $args);
        
        if ($skipflag && $_ =~ /^\s*\!\!perl\/regexp\s*/i) { # Working in SkipMode
            #s/\r//;
            #$_ =~ qr{^\s*\!\!perl\/regexp\s*(?:(?:'([^\\']*(?:\\.[^\\']*)*)')|([^#\s]\S*))?(?:(?:\s*)|(?:\s+(.*?)\s*))$};
            #$args = $3;
            #my $file = $2;
            #if ( defined($1) ) {
            #    $file = $1;
            #    $file =~ s/\\(['\\])/$1/g;
            #}
            unless (($file, $args) = /^'(\\[\\']|.+)+'\s*(.*)/) {
                ($file, $args) = /^(^\s*\!\!perl\/regexp\s*\S+)\s*(.*)/;
            }
        } else {
            # filename may contain spaces if enclosed in ''
            # (in which case, \\ and \' are escapes)
            if (($file, $args) = /^'(\\[\\']|.+)+'\s*(.*)/) {
                $file =~ s/\\([\\'])/$1/g;
            } else {
                ($file, $args) = /^(\S+)\s*(.*)/;
            }
        }
        next unless $file;
        $read->{$file} = [defined $args ? split(/\s+/,$args) : ""];
    }
    close M;
    return $read;
}
sub manifind {
    my $dir = shift;
    carp("Can't specified directory") && return {} unless defined($dir) && -e $dir;
    
    my $found = {};
    my $base = File::Spec->canonpath($dir);
    #my ($volume,$sdirs,$sfile) = File::Spec->splitpath( $base );

    my $wanted = sub {
        my $path = File::Spec->canonpath($_);
        my $name = File::Spec->abs2rel( $path, $base );
        my $fdir = File::Spec->canonpath($File::Find::dir);
        return if -d $_;
        
        my $key = join("/", File::Spec->splitdir(File::Spec->catfile($name)));
        $found->{$key} = {
                mtime   => (stat($_))[9] || 0,
                size    => (-s $_) || 0,
                dir     => $fdir,
                path    => $path,
                file    => File::Spec->abs2rel( $path, $fdir ), 
            };
    };

    # We have to use "$File::Find::dir/$_" in preprocess, because 
    # $File::Find::name is unavailable.
    # Also, it's okay to use / here, because MANIFEST files use Unix-style 
    # paths.
    find({
            wanted      => $wanted,
            no_chdir    => 1,
        }, $dir);

    return $found;
}
sub maniwrite {
    my $file = shift;
    my $mani = shift;
    carp("Can't specified file") && return 0 unless defined($file);
    carp("Can't specified manifest-hash") && return 0 unless defined($mani) && ref($mani) eq 'HASH';
    my $file_bak = $file.".bak";
    
    rename $file, $file_bak;
    local *M;
    
    unless (open M, ">", $file){
        carp("Can't open file $file: $!");
        rename $file_bak, $file;
        return 0;
    }
    
    # Stamp
    print  M "###########################################\n";
    printf M "# File created at %s\n", scalar(localtime(time()));
    print  M "# Please, do NOT edit this file directly!!\n";
    print  M "###########################################\n\n";
    
    foreach my $f (sort { lc $a cmp lc $b } keys %$mani) {
        my $d = $mani->{$f};
        my $text = sprintf("%s\t%s\t%s", 
                $d->{mtime} || 0, 
                $d->{size} || 0,
                $d->{mtime} ? scalar(localtime($d->{mtime})) : 'UNKNOWN',
            );
        my $tabs = (8 - (length($f)+1)/8);
        $tabs = 1 if $tabs < 1;
        $tabs = 0 unless $text;
        if ($f =~ /\s/) {
            $f =~ s/([\\'])/\\$1/g;
            $f = "'$f'";
        }
        print M $f, "\t" x $tabs, $text, "\n";
    }
    close M;
    
    unlink $file_bak;
    
    return 1;
}
sub fetch($$$) { # Returns structire
    my $url = shift;
    my $obj = shift;
    my $file = shift;
    
    my $ret = {
            status  => 0, # Status
            mtime   => 0, # Last-Modified in ctime format or 0 
            size    => 0, # tContent-length
            code    => 0, # Status code
        };
    
    # Форирование URI
    my $uri = new URI($url);
    my $curpath = $uri->path();
    my $newpath = $curpath . (defined $obj ? "/$obj" : ''); $newpath =~ s/\/{2,}/\//;
    $uri->path($newpath);
    $ret->{uri} = $uri->as_string;
    
    # Проверка на файл
    unless (defined $file) {
        carp(sprintf("File to store is not defined"));
        return $ret;
    }
    
    # Первоначальный запрос на существование
    my ($content_type, $document_length, $modified_time, $expires, $server) = head($uri);
    debug(sprintf("HEAD Response:"
        ."\n\tContent-type:\t%s"
        ."\n\tContent-length:\t%s"
        ."\n\tModified:\t%s"
        ."\n\tServer:\t\t%s", 
            defined $content_type ? $content_type : '', 
            defined $document_length ? $document_length : 0, 
            defined $modified_time ? scalar(localtime($modified_time)) : '', 
            defined $server ? $server : ''
        ));
    
    # Анализ. Если всё плохо, выход
    if ($document_length) {
        $ret->{size} = $document_length;
    } else {
        return $ret;
    }
    if ($modified_time) {
        $ret->{mtime} = $modified_time;
    } else {
        carp(sprintf("Can't fetch resource %s. Header Last-Modified not returned", $uri->as_string));
        return $ret;
    }

    # Принимаем файл
    fdelete($file);
    my $code = mirror($uri, $file);
    $ret->{code} = $code;
    if (($code >= 200) && ($code < 400)) {
        if (-e $file && -s $file) {
            $ret->{status} = 1;
        }
    }
    
    return $ret;
}
sub _expire { # Перевод в expires
    my $str = shift || 0;

    return 0 unless defined $str;
    return $1 if $str =~ m/^[-+]?(\d+)$/;

    my %_map = (
        s       => 1,
        m       => 60,
        h       => 3600,
        d       => 86400,
        w       => 604800,
        M       => 2592000,
        y       => 31536000
    );

    my ($koef, $d) = $str =~ m/^([+-]?\d+)([smhdwMy])$/;
    unless ( defined($koef) && defined($d) ) {
        carp "expire(): couldn't parse '$str' into \$koef and \$d parts. Possible invalid syntax";
        return 0;
    }
    return $koef * $_map{ $d };
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
sub _skipcheck {
    my $sl = shift; # Link to %skip
    my $st = shift; # Test string
    return 0 unless $sl && defined($st) && ref($sl) eq 'HASH';
    return 1 if exists $sl->{$st} && defined $sl->{$st}; # Исключение нашли! Т.к. нашлось прямое соответствие
    
    # Пробегаемся по всем значениям и ищем среди них только регулярки
    if (grep {(ref($_) eq 'Regexp') && $st =~ $_} values %$sl) {
        $sl->{$st} = 1; # Для очередной проверки данные проверки будут уже излишними. Оптимизация производительности
        return 1 
    }

    return 0; # Not Found
}
1;
__END__
