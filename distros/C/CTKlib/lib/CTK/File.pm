package CTK::File; # $Id: File.pm 201 2017-05-02 10:37:04Z minus $
use Moose::Role; # use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::File - Files and direcries working

=head1 VERSION

Version 1.71

=head1 SYNOPSIS

    $c->fjoin(
            -in     => catdir($DATADIR,'in'),  # Source directory
            -out    => catdir($DATADIR,'out'), # Destination directory (for joined file)
            -list   => qr/txt$/, # Source mask (regular expression, filename or ArrayRef of files)
            -fout   => 'foo.txt', # Output file name
        );

    $c->fsplit(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (big files)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory (splitted files)
            -n      => 100, # Lines count
            -format => '[FILENAME]_%03d.[FILEEXT]', # Format
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );

    $c->fcopy(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (source files)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory
            -format => '[FILE].copy', # Format
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );

    $c->fmv(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (source files)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory
            -format => '[FILE].copy', # Format
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );

    $c->frm(
            -in     => CTK::catfile($CTK::DATADIR,'in'), # Source directory (source files)
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );

=head1 DESCRIPTION

=head2 KEYS

=over 8

=item B<FILE>

Path and filename

=item B<FILENAME>

Filename only

=item B<FILEEXT>

File extension only

=item B<COUNT>

Current number of file in sequence (for fcopy and fmove methods)

Gor fsplit method please use perl mask %i

=item B<Time>

Current time value (time())

=back

=head2 NOTES

For copying paths: use File::Copy::Recursive qw(dircopy dirmove);

For TEMP dirs/files working: use File::Temp qw/tempfile tempdir/;

=head2 METHODS

=head3 fjoin

    $c->fjoin(
            -in     => catdir($DATADIR,'in'),  # Source directory
            -out    => catdir($DATADIR,'out'), # Destination directory (for joined file)
            -list   => qr/txt$/, # Source mask (regular expression, filename or ArrayRef of files)
            -fout   => 'foo.txt', # Output file name
        );

Join group of files (by mask from source directory) to one big file (concatenate).
File writes to destination directory by output file name (fout)

    perl -MCTK::File -e "CTK::File::fjoin(-cmdmode=>1, -mask=>qr/txt$/, -fout => 'foo.txt')" -- *

This is new features, added since CTK 1.18.

=head3 fsplit

    $c->fsplit(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (big files)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory (splitted files)
            -n      => 100, # Lines count
            -format => '[FILENAME]_%03d.[FILEEXT]', # Format
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );

Split group of files to parts

=head3 fcopy, fcp

    $c->fcopy(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (source files)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory
            -format => '[FILE].copy', # Format
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );

Copying files from the source directory to the destination directory

=head3 fmove, fmv

    $c->fmv(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (source files)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory
            -format => '[FILE].copy', # Format
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );

Moving files from the source directory to the destination directory

=head3 fdelete, fdel, frm

    $c->frm(
            -in     => CTK::catfile($CTK::DATADIR,'in'), # Source directory (source files)
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );

Deleting files from the source directory

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

use vars qw/$VERSION/;
$VERSION = '1.71';

use CTK::Util qw/ :API :FORMAT :ATOM /;
use File::Copy;
use File::Find;
use Fcntl qw/ :flock /;
use Symbol;

use constant {
    BUFFER_SIZE => 1 * 1024, # 32 kB
};

sub fsplit {
    # Разделение файлов dirin и сохранение их в каталог dirproc по списку или маске с учетом
    # кол-ва строк в одном файле и форматом вывода (sprintf)
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');

    my @args = @_;
    my ($dirin, $dirout, $listmsk, $limit, $format);
       ($dirin, $dirout, $listmsk, $limit, $format) =
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['LIMIT','STRINGS','ROWS','MAX','ROWMAX','N','LIM'],
                ['FORMAT','FMT'],
            ],@args) if defined $args[0];

    $dirin    ||= ''; # Входная директория
    $dirout   ||= ''; # Директория обработки
    $listmsk  ||= ''; # Список имен файлов для процесса или маска
    $limit    ||=  0; # Лимит строк в файле
    $format   ||= ''; # Формат выводимого файла (sprintf) например: [FILENAME]_%03d.[FILEEXT]
    my $list;

    if (ref($listmsk) eq 'ARRAY') {
        # Список
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # Все файлы по его Маске
        $list = getlist($dirin,$listmsk);
    } else {
        # Конкретный файл но все равно как маска или же все файлы
        $list = getlist($dirin,qr/$listmsk/);
    }


    # На этом этапе имеем линейный список фалов
    my $c = scalar(@$list) || 0;
    my $i = 0;
    #CTK::debug("Разбиение файлов каталога \"$dirin\" по ".correct_number($limit)." строк...");
    foreach my $fnin (@$list) {$i++;
        #CTK::debug("   Разбивается файл $i/$c $fnin...");
        my $filein = $dirin ? catfile($dirin,$fnin) : $fnin;
        open FIN, "<",$filein or _error("SPLIT ERROR: Can't open file $filein: $!") && next;
            my $fpart = 0; # Части
            my $fline = $limit; # строка, номер (условная!!!)
            open FOUT, ">-";
            while (<FIN>) { # chomp
                if ($fline >= $limit) {
                    # Достигнут лимит, Увеличиваем счетчик
                    $fline = 1;
                    $fpart++;
                    my $fformat  = fformat($format,$fnin);
                    my $fnproc   = sprintf($fformat,$fpart); # Выходной файл (имя)
                    my $fileproc = $dirout ? catfile($dirout,$fnproc) : $fnproc; #  Выходной файл
                    #CTK::debug("   - Сохраняется часть $fpart в файл $fnproc...");
                    close FOUT;
                    open FOUT, ">", $fileproc or _error("SPLIT ERROR: Can't open file $fileproc: $!") && next;
                } else {
                    # Читается факл
                    $fline++;
                }
                print FOUT; # print FOUT "\n";
            }
            close FOUT;
        close FIN or _error("SPLIT ERROR: Can't close file $filein: $!");
    }

    return 1;
}
sub fjoin {
    # Склеивание (обЪединение) нескольких файлов в один. Два режима работы:
    #  - командный: perl -MCTK::File -e "CTK::File::fjoin(-cmdmode=>1, -mask=>qr/txt$/)" -- *
    #  - классический: по общему сценарию
    #
    # -dirin    -- Каталог для поиска файлов (опционально)
    # -dirout   -- Каталог для результирующего файла (опционально)
    # -mask     -- Список файлов (анонимный массив) или маска файлов
    # -fileout  -- Имя результирующего файла
    # -cmdmode  -- Режим командной строки. Список исходных файлов берется исходя их glob-маски ARGV
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');

    my @args = @_;
    my ($dirin, $dirout, $listmsk, $fileout, $wmode);
       ($dirin, $dirout, $listmsk, $fileout, $wmode) =
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['FILEOUT','FILEDST','FOUT','NAME','FILE','FILENAME'],
                ['MODE','CMD','CMDMODE','MODECMD'],
            ],@args) if defined $args[0];

    $dirin    //= curdir(); # Входная директория
    $dirout   //= ''; # Директория обработки
    $listmsk  //= ''; # Список имен файлов для процесса или маска
    $fileout  //= 'fjoin.bin';
    my $cmd_mode = $wmode ? _expand_wildcards() : 0;

    # Name of the FileOut building
    my $file = catfile((defined($dirout) && length($dirout)) ? $dirout : curdir(), $fileout);
    my $fh_out = gensym;
    if (open($fh_out, ">", $file)) {
        if (flock($fh_out, LOCK_EX)) {
            unless (binmode($fh_out)) {
                _error(sprintf("Can't call binmode() for file \"%s\" to writing: %s,%s"), $file, $!, $^E);
                close($fh_out) or _error(sprintf("Can't close file \"%s\" before writing: %s"), $file, $!);
                return 0;
            }
        } else {
            _error(sprintf("Can't lock [%d] file \"%s\" to writing: %s"), LOCK_SH, $file, $!);
            close($fh_out) or _error(sprintf("Can't close file \"%s\" before writing: %s"), $file, $!);
            return 0;
        }
    } else {
        _error(sprintf("Can't open file \"%s\" to writing: %s"), $file, $!);
        return 0;
    }

    my $wanted = sub {
        my $f = $_;
        return if -d $f;
        return unless -r _;
        return if -z _;

        # Filtering by list or mask
        if (ref($listmsk) eq 'ARRAY') { # List (array)
            return unless grep {$_ eq $f} @$listmsk;
        } elsif (ref($listmsk) eq 'Regexp') { # Regexp
            return unless $f =~ $listmsk;
        } else {
            if (defined($listmsk) && $listmsk ne '') {
                return unless $f =~ qr/$listmsk/;
            }
        }

        # Handler define
        my $f_in = catfile($File::Find::dir, $f);
        my $fh_in = gensym;

        #printf("Joining file %s -> %s... \n", $f_in, $file);

        if (open($fh_in, "<", $f)) {
            if (flock($fh_in, LOCK_SH)) {
                unless (binmode($fh_in)) {
                    _error(sprintf("Can't call binmode() for file \"%s\" to reading: %s,%s"), $f_in, $!, $^E);
                    close($fh_in) or _error(sprintf("Can't close file \"%s\" before reading: %s"), $f_in, $!);
                    return;
                }
                while (1) {
                    my $buf;
                    my ($r, $w);
                    $r = sysread($fh_in, $buf, BUFFER_SIZE);
                    last unless $r;
                    $w = syswrite($fh_out, $buf, $r) or last;
                    #printf "Readed: %d bytes; Writed: %d bytes\n", $r, $w;
                }
                close($fh_in) or _error(sprintf("Can't close file \"%s\" after reading: %s"), $f_in, $!);
            } else {
                close($fh_in) or _error(sprintf("Can't close file \"%s\" before reading: %s"), $f_in, $!);
                _error(sprintf("Can't lock [%d] file \"%s\" to reading: %s"), LOCK_SH, $f_in, $!);
            }
        } else {
            _error(sprintf("Can't open file \"%s\" to reading: %s"), $f_in, $!);
        }
    };

    if ($cmd_mode) {
        find({ wanted => $wanted}, @ARGV);
    } else {
        find({ wanted => $wanted}, $dirin);
    }

    close($fh_out) or _error(sprintf("Can't close file \"%s\" after writing: %s"), $file, $!);
    unlink($file) if defined($file) && (-e $file) && (-z $file);

    return 1;
}
sub fcopy {
    # копирование файлов с одной папки в другую по маске или списку
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');

    my @args = @_;
    my ($dirin, $dirout, $listmsk, $format);
       ($dirin, $dirout, $listmsk, $format) =
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['FORMAT','FMT'],
            ],@args) if defined $args[0];

    $dirin    ||= '';     # Директория-источник
    $dirout   ||= '';     # Директория-приемник
    $listmsk  ||= '';     # Список имен файлов для копирования/переноса или маска
    $format   ||= '[FILE]'; # Формат выходного файла (sprintf). По умолчанию [FILE]
    my $list;

    if (ref($listmsk) eq 'ARRAY') {
        # Список
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # Все файлы по его Маске
        $list = getlist($dirin,$listmsk);
    } else {
        # Конкретный файл но все равно как маска или же все файлы
        $list = getlist($dirin,qr/$listmsk/);
    }

    # На этом этапе имеем линейный список фалов
    my $c = scalar(@$list) || 0;
    my $i = 0;
    #CTK::debug("Копирование файлов каталога \"$dirin\" в \"$dirout\"...");
    foreach my $fn (@$list) {$i++;
        #CTK::debug("   Копируется файл $i/$c $fn...");
        my $dfd = dformat($format,{
                FILE  => $fn,
                COUNT => $i,
                TIME  => time()
            });
        copy(
                $dirin ? catfile($dirin,$fn) : $fn,
                $dirout ? catfile($dirout,$dfd) : $dfd,
            );
    }

    return 1;
}
sub fcp { fcopy(@_) }
sub fmove {
    # Перенос файлов с одной папки в другую по маске или списку
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');

    my @args = @_;
    my ($dirin, $dirout, $listmsk, $format);
       ($dirin, $dirout, $listmsk, $format) =
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['FORMAT','FMT'],
            ],@args) if defined $args[0];

    $dirin    ||= '';     # Директория-источник
    $dirout   ||= '';     # Директория-приемник
    $listmsk  ||= '';     # Список имен файлов для копирования/переноса или маска
    $format   ||= '[FILE]'; # Формат выходного файла (sprintf). По умолчанию [FILE]
    my $list;

    if (ref($listmsk) eq 'ARRAY') {
        # Список
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # Все файлы по его Маске
        $list = getlist($dirin,$listmsk);
    } else {
        # Конкретный файл но все равно как маска или же все файлы
        $list = getlist($dirin,qr/$listmsk/);
    }

    # На этом этапе имеем линейный список фалов  ::debug(join "; ", @$list);
    my $c = scalar(@$list) || 0;
    my $i = 0;
    #CTK::debug("Перенос файлов каталога \"$dirin\" в \"$dirout\"...");
    foreach my $fn (@$list) {$i++;
        #CTK::debug("   Переносится файл $i/$c $fn...");
        my $dfd = dformat($format,{
                FILE  => $fn,
                COUNT => $i,
                TIME  => time()
            });
        move(
                $dirin ? catfile($dirin,$fn) : $fn,
                $dirout ? catfile($dirout,$dfd) : $dfd,
            );
    }

    return 1;
}
sub fmv { fmove(@_) }
sub fdelete {
    # удаление файлов из папки по маске или списку
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');

    my @args = @_;
    my ($dirin, $listmsk);
       ($dirin, $listmsk) =
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
            ],@args) if defined $args[0];

    $dirin    ||= '';     # Директория-источник
    $listmsk  ||= '';     # Список имен файлов для удаления или маска
    my $list;

    if (ref($listmsk) eq 'ARRAY') {
        # Список
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # Все файлы по его Маске
        $list = getlist($dirin,$listmsk);
    } else {
        # Конкретный файл но все равно как маска или же все файлы
        $list = getlist($dirin,qr/$listmsk/);
    }

    # На этом этапе имеем линейный список фалов
    my $c = scalar(@$list) || 0;
    my $i = 0;
    #CTK::debug("Удаление файлов каталога \"$dirin\"...");
    foreach my $fn (@$list) {$i++;
        #CTK::debug("   удаляется файл $i/$c $fn...");
        unlink( $dirin ? catfile($dirin,$fn) : $fn);
    }
}
sub fdel { fdelete(@_) }
sub frm { fdelete(@_) }
sub _expand_wildcards {
    # Original in package ExtUtils::Command
    return 0 unless @ARGV;
    @ARGV = map(/[*?]/o ? glob($_) : $_, @ARGV);
    return 1;
}
sub _error {
    #CTK::debug(@_);
    carp(@_); # unless CTK::debugmode();
}

1;
__END__
