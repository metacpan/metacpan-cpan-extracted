package CTK::Arc; # $Id: Arc.pm 193 2017-04-29 07:30:55Z minus $
use Moose::Role; # use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::Arc - Archives working

=head1 VERSION

Version 1.71

=head1 SYNOPSIS

    # External extracting
    $c->fextract(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (archives)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory (files)
            -method => 'ext',
            -list   => qr/rar/, # Source mask (regular expression, filename or ArrayRef of files)
            -arcdef => $config->{arc}, # Archive attributes (Hashref)
        );

    # Internal extracting
    $c->fextract(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (archives)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory (files)
            -method => 'zip', # Zip archive
            -list   => qr/zip/, # Source mask (regular expression, filename or ArrayRef of files)
            -arcdef => $config->{arc}, # Archive attributes (Hashref)
        );

    # External files compressing
    $c->fcompress(
            -in     => CTK::catfile($CTK::DATADIR,'in'), # Source directory (files)
            -out    => CTK::catfile($CTK::DATADIR,'out','ttt.rar'), # Archive name (filename)
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
            -arcdef => $config->{arc}, # Archive attributes (Hashref)
        );

=head1 DESCRIPTION

Sample of $config->{arc} records:

    ARC => {
        tgz   =>  {
            "type"       => "tar", # name
            "ext"        => "tgz", # extension
            "create"     => "tar -zcpf [FILE] [LIST]", # create command
            "extract"    => "tar -zxpf [FILE] [DIRDST]", # extract command
            "exclude"    => "--exclude-from ",
            "list"       => "tar -ztf [FILE]",
            "nocompress" => "tar -cpf [FILE]"
        },
        ...
    }

=head2 KEYS

=over 8

=item B<FILE>

Path and filename

=item B<FILENAME>

Filename only

=item B<DIRSRC>

Source directory. Path only

=item B<DIRIN>

See DIRSRC

=item B<DIRDST>

Destination directory. Path only

=item B<DIROUT>

See DIRDST

=item B<EXC>

Reserved

=item B<LIST>

Reserved

=back

=head2 METHODS

=head3 fextract

    # External extracting
    $c->fextract(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (archives)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory (files)
            -method => 'ext',
            -list   => qr/rar/, # Source mask (regular expression, filename or ArrayRef of files)
            -arcdef => $config->{arc}, # Archive attributes (Hashref)
        );

    # Internal extracting
    $c->fextract(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (archives)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory (files)
            -method => 'zip', # Zip archive
            -list   => qr/zip/, # Source mask (regular expression, filename or ArrayRef of files)
            -arcdef => $config->{arc}, # Archive attributes (Hashref)
        );

Extracting the files group

=head3 fcompress

    # External files compressing
    $c->fcompress(
            -in     => CTK::catfile($CTK::DATADIR,'in'), # Source directory (files)
            -out    => CTK::catfile($CTK::DATADIR,'out','ttt.rar'), # Archive name (filename)
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
            -arcdef => $config->{arc}, # Archive attributes (Hashref)
        );

Compressing the files group

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

use constant {
    ARC       => {
        tgz   =>  {
            "type"       => "tar",
            "ext"        => "tgz",
            "create"     => "tar -zcpf [FILE] [LIST]",
            "extract"    => "tar -zxpf [FILE] [DIRDST]",
            "exclude"    => "--exclude-from ",
            "list"       => "tar -ztf [FILE]",
            "nocompress" => "tar -cpf [FILE]"
        },
        gz   =>  {
            "type"       => "tar",
            "ext"        => "gz",
            "create"     => "tar -zcpf [FILE] [LIST]",
            "extract"    => "tar -zxpf [FILE] -C [DIRDST]",
            "exclude"    => "--exclude-from ",
            "list"       => "tar -ztf [FILE]",
            "nocompress" => "tar -cpf [FILE]"
        },
        zip   => {
            "type"       => "zip",
            "ext"        => "zip",
            "create"     => $^O =~ /mswin/i ? "zip -rqq [FILE] [LIST]" : "zip -rqqy [FILE] [LIST]",
            "extract"    => $^O =~ /mswin/i ? "unzip -uqqoX [FILE] -d [DIRDST]" : "unzip -uqqoX [FILE] [DIRDST]",
            "exclude"    => "-x\@",
            "list"       => "unzip -lqq",
            "nocompress" => "zip -qq0"
        },
        rar   => {
            "type"       => "rar",
            "ext"        => "rar",
            "create"     => $^O =~ /mswin/i ? "rar a -r -y [FILE] [LIST]" : "rar a -r -ol -y [FILE] [LIST]",
            "extract"    => "rar x -y [FILE] [DIRDST]",
            "exclude"    => "-x\@",
            "list"       => "rar vb",
            "nocompress" => "rar a -m0"
        }
    },
};

use vars qw/$VERSION/;
$VERSION = '1.71';

use CTK::Util qw(:API :FORMAT :ATOM);
use Archive::Tar;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Archive::Extract;

sub fextract {
    # Разархивирование содержимого указанного списка архива
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');

    my @args = @_;
    my ($method, $dirin, $dirout, $listmsk, $arcdef);
       ($method, $dirin, $dirout, $listmsk, $arcdef) =
            read_attributes([
                ['METHOD','METH','TYPE'],
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['ARC','ARCDEF','ARCSET','SET','DEF'],

            ],@args) if defined $args[0];

    $method   ||= 'ext'; # Метод извлечение файлов zip / tar / ext
    $dirin    ||= ''; # Входная директория
    $dirout   ||= ''; # Директория обработки
    $listmsk  ||= ''; # Список имен файлов для процесса или маска
    $arcdef   ||= ''; # Секция (ссылка на хэш) для ручного опредления параметра arc (поиск по расширению)
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
    if ($method eq 'tar') {
        #CTK::debug("Извлечение TAR-архивов каталога \"$dirin\" в каталог \"$dirout\"...");
        my $tar = Archive::Tar->new;
        my $i = 0;
        my $c = scalar(@$list) || 0;
        foreach my $fn (@$list) {$i++;
            my $fin = $dirin ? catfile($dirin,$fn) : $fn;
            my $fs   = -e $fin ? (-s $fin) : 0; # Размер файла архива
            #CTK::debug("   Разархивируется файл $i/$c $fn [".correct_number($fs)." b]...");
            $tar->read($fin);
            foreach my $fan ( $tar->list_files() ) {
                #CTK::debug("   --- Extracting \"$fan\"...");
                $tar->extract_file( $fan, $dirout ? catfile($dirout,$fan) : $fan );
            }

        }
    } elsif ($method eq 'zip') {
        #CTK::debug("Извлечение ZIP-архивов каталога \"$dirin\" в каталог \"$dirout\"...");
        my $i = 0;
        my $c = scalar(@$list) || 0;
        foreach my $fn (@$list) {$i++;
            my $fin = $dirin ? catfile($dirin,$fn) : $fn;
            my $fs   = -e $fin ? (-s $fin) : 0; # Размер файла архива
            #CTK::debug("   Разархивируется файл $i/$c $fn [".correct_number($fs)." b]...");
            my $ae = Archive::Extract->new( archive => $fin );
            my $ok = $ae->extract( to => $dirout );
            if ( $ok ) {
                #my $filesok = $ae->files;
                #foreach (@$filesok) {CTK::debug("   --- File \"$_\": OK")};
            } else {
                #CTK::debug("   --- ERROR: File extract FAILED: ".$ae->error);
                carp("ZIP EXTRACTION ERROR: File extract FAILED: ".$ae->error); # unless CTK::debugmode();
            }
        }
    } elsif ($method eq 'ext') {
        #CTK::debug("Внешнее извлечение \"$dirin\" в каталог \"$dirout\"...");
        my $i = 0;
        my $c = scalar(@$list) || 0;
        foreach my $fn (@$list) {$i++;
            my $fin = $dirin ? catfile($dirin,$fn) : $fn;
            my $fs   = -e $fin ? (-s $fin) : 0; # Размер файла архива
            #CTK::debug("   Разархивируется файл $i/$c $fn [".correct_number($fs)." b]...");
            my $arc = _getarc(
                    FILE     => $fin,
                    FILENAME => $fn,
                    DIRSRC   => $dirin,
                    DIRIN    => $dirin,
                    DIRDST   => $dirout,
                    DIROUT   => $dirout,
                    # EXC    => 'exclude file', # Зарезервировано!!!
                    LIST     => '',
                    ARCDEF   => $arcdef,
                );
            if ($arc) {
                my @C;
                push @C, $arc->{extract};
                #push @C, $fin;
                #push @C, ::WIN &&  $arc->{type} eq 'zip' ? "-d $dirproc" : $dirproc;
                procexec(\@C);
            } else {
                #CTK::debug("   --- ERROR: Неудалось определить формат архива по расширению: $fn");
                carp("EXTERNAL EXTRACTION ERROR: Unknow format $fn"); #unless CTK::debugmode();
            }
        }

    } else {
        #CTK::debug("ERROR: Неизвестный формат (метод) архива: $method");
        carp("ERROR: Unknow archive's format or method: $method"); #unless CTK::debugmode();
    }
}
sub fcompress {
    # Архивирование содержимого указанного списка директории
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');

    my @args = @_;
    my ($dirin, $fout, $listmsk, $arcdef);
       ($dirin, $fout, $listmsk, $arcdef) =
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['FILEOUT','OUT','OUTPUT','FILEDST','DST','FOUT','NAME','ARCHIVE'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['ARC','ARCDEF','ARCSET','SET','DEF'],

            ],@args) if defined $args[0];


    $dirin    ||= ''; # Входная директория (архивируются объекты внутри!!! - файлы и папки)
    $fout     ||= ''; # Файл выходного архива (полный путь)
    $listmsk  ||= ''; # Список имен файлов и каталогов для процесса или маска поиска
    $arcdef   ||= ''; # Секция (ссылка на хэш) для ручного опредления параметра arc (поиск по расширению)
    my $list;
    my $dlist;

    if (ref($listmsk) eq 'ARRAY') {
        # Список
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # Все файлы по его Маске
        $list = getlist($dirin,$listmsk);
        $dlist = getdirlist($dirin,$listmsk);
    } else {
        # Конкретный файл но все равно как маска или же все файлы
        $list = getlist($dirin,qr/$listmsk/);
        $dlist = getdirlist($dirin,qr/$listmsk/);
    }
    $list   ||= [];
    $dlist  ||= [];


    # На этом этапе имеем линейный список фалов  ::debug(join "; ", @$list);

    #
    # Сжимаем:
    # $arc{create} $bfile ".join(" ",@dirlist)." $exclude ";
    #
    #CTK::debug("Внешнее сжатие \"$dirin\" в файл \"$fout\"...");
    my @reallist;
    foreach (@$list,@$dlist) {
        push @reallist, $dirin ? catfile($dirin,$_) : $_;
    }

    my $arc = _getarc(
            FILE     => $fout,
            DIRSRC   => $dirin,
            DIRIN    => $dirin,
            # EXC    => 'exclude file', # Зарезервировано!!!
            LIST     => join(" ",@reallist),
            ARCDEF   => $arcdef,
        );
    #use Data::Dumper; ::debug(Dumper($arc)); return 1;

    if ($arc) {
        my @C;
        push @C, $arc->{create};
        procexec(\@C);
    } else {
        #CTK::debug("   ERROR: Неудалось определить формат архива по расширению: $fout");
        carp("EXTERNAL COMPRESSING ERROR: Format undefined by $fout"); # unless CTK::debugmode();
    }
}
sub _getarc {
    # Получение предполагаемого типа архива по имени файла или undef
    # Данные маскрируются как в случае _splitformat
    my %dn = @_;
	my $file = $dn{FILE} || '';
    my $def  = $dn{ARCDEF} || '';

    my $ext = '';
	$ext = $1 if ($file && $file =~ /\.(\w+)$/);

    my $sec;
    if ($def && $def->{$ext}) {
        $sec = $def->{$ext};
    } else {
        $sec = ARC->{$ext} || undef;
    }

    unless( $sec ) {
        #CTK::debug( "Error: unknown archive format of file \"$file\": $ext" );
        carp("ERROR: Unknown archive format of file \"$file\": $ext"); # unless CTK::debugmode();
        return undef;
    }
    my %arc = %$sec;

    # Пробегаемся по всем ключам найднного типа
    foreach (values %arc) {
        $_ =~ s/\[(.+?)\]/($dn{uc($1)} || '')/eg;
    }

	return {%arc}; # ссылка на анонимный хэш
}

1;
__END__
