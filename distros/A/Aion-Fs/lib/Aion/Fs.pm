package Aion::Fs;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.1.2";

use Exporter qw/import/;
use File::Spec     qw//;
use Scalar::Util   qw//;
use List::Util     qw//;
use Time::HiRes    qw//;

our @EXPORT = our @EXPORT_OK = grep {
	ref \$Aion::Fs::{$_} eq "GLOB" && *{$Aion::Fs::{$_}}{CODE} && !/^(?:_|(NaN|import)\z)/
} keys %Aion::Fs::;


# Список ОС с различающимся синтаксисом файловых путей (должен быть в нижнем регистре)
use constant {
	UNIX    => 'unix',
	AMIGAOS => 'amigaos',
	CYGWIN  => 'cygwin',
	MSYS    => 'msys',
	MSYS2   => 'msys2',
	MSWIN32 => 'mswin32',
	DOS     => 'dos',
	OS2     => 'os2',
	SYMBIAN => 'symbian',
	VMS     => 'vms',
	VOS     => 'vos',
	RISCOS  => 'riscos',
	MACOS   => 'macos',
	VMESA   => 'vmesa',
};

sub _fs();
sub _match($$) {
	my ($match, $fs) = @_;
	my @res; my @remove;
	my $trans = $fs->{before_split} // sub {$_[0]};
	for my $key (@$match) {
		next unless exists $_->{$key};
		
		push @remove, $key unless defined $_->{$key};
		
		my $regexp = ($key eq "path"? $fs->{regexp}: $fs->{group}{$key});
		my $val = $trans->($_->{$key});
		push @res, $val =~ $regexp
			? %+
			: die "`$key` is in the wrong format `$val`. Has been used regexp: $regexp";
	}

	my %res = @res;
	delete @res{keys %{$fs->{remove}->{$_}}} for @remove;
	
	return %res, %$_;
}

sub _join(@) {
	my ($match, @format) = @_;
	my $fs = _fs;
	my $trans = $fs->{before_split} // sub {$_[0]};
	my %f = _match $match, $fs;
	join "", List::Util::pairmap {
		my @keys = ref $a? @$a: $a;
		my $is = List::Util::first {defined $f{$_}} @keys;
		defined $is? do {
			my ($if, $format) = ref $b? @$b: (undef, $b);
			
			my @val = map $trans->($f{$_}), @keys;
			defined $if && $val[0] eq $if? $if:
				$format !~ /%s/? $format:
					sprintf($format, @val)
		}: () 
	} @format
}

# Синтаксисы файловых путей в разных ОС
my %FS;
my @FS = (
	{
		name   => UNIX,
		symdir => '/',
		symext => '.',
		regexp => qr!^
			(
				(?<dir> / ) | (?<dir> .* ) /
			)?
			(?<file>
				(?<name> \.? [^/.]* )
				( \. (?<ext> [^/]* ) )?
			)
		\z!xsn,
		join => sub {
			_join [qw/path file/],
				dir    => ["/", "%s/"],
				name   => "%s",
				ext    => ".%s",
		},
	},
	{
		name   => AMIGAOS,
		symdir => '/',
		symext => '.',
		regexp => qr!^
			(?<dir>
				( (?<volume> [^/:]+) : )?
				(?<folder> .* ) /
			)?
			(?<file>
				(?<name> \.? [^/.]* )
				( \. (?<ext> [^/]* ) )?
			)
		\z!xsn,
		join => sub {
			_join [qw/path dir file/],
				volume => "%s:",
				folder => "%s/",
				name   => "%s",
				ext    => ".%s",
		},
	},
	{
		name   => CYGWIN,
		symdir => '/',
		symext => '.',
		regexp => qr!^
			(?<dir>
				( /cygdrive/ (?<volume> [^/]+ ) /? )?
				( (?<folder> .* ) / )?
			)
			(?<file>
				(?<name> \.? [^/.]* )
				( \. (?<ext> [^/]* ) )?
			)
		\z!xsn,
		join => sub {
			_join [qw/path dir file/],
				volume => "/cygdrive/%s/",
				folder => "%s/",
				name   => "%s",
				ext    => ".%s",
		},
	},
	{
		name   => [MSYS, MSYS2],
		symdir => '/',
		symext => '.',
		regexp => qr!^
			(?<dir>
				( / (?<volume> [^/]+ )? /? )
				( (?<folder> .* ) / )?
			)?
			(?<file>
				(?<name> \.? [^/.]* )
				( \. (?<ext> [^/]* ) )?
			)
		\z!xsn,
		join => sub {
			_join [qw/path dir file/],
				volume => "/%s/",
				folder => "%s/",
				name   => "%s",
				ext    => ".%s",
		},
	},
	{
		name   => [DOS, OS2, MSWIN32, SYMBIAN],
		symdir => '\\',
		symext => '.',
		before_split => sub { $_[0] =~ s!/!\\!gr },
		regexp => qr!^
			(?<dir>
				( (?<volume> [^\\:]+) : | \\\\ (?<server> [^\\]+ )? )?
				( (?<folder> \\ ) | (?<folder> .* ) \\ )?
			)
			(?<file>
				(?<name> \.? [^\\.]* )
				( \. (?<ext> [^\\]* ) )?
			)
		\z!xsn,
		join => sub {
			_join [qw/path dir file/],
				volume => "%s:",
				server => "\\\\%s",
				folder => ["\\", "%s\\"],
				name   => "%s",
				ext    => ".%s",
		},
	},
	{
		name   => VMS,
		symdir => '.',
		symext => '.',
		regexp => qr!^
			(?<dir>
				( 
					(?<node> [^:\[\]]* )
					( \[" (?<accountname> [^\s:\[\]]+ ) \s+ (?<password> [^\s:\[\]]+ ) "\] )?
				:: )?
				(?<volume>
						(?<disk> [^\$:\[\]]* )
						( \$ (?<user> [^\$:\[\]]* ) )?
					: )?
				( \[ (?<folder> [^\[\]]* ) \] )?
			)
			(?<card>
			    (?<file>
					(?<name> \.? [^.;\[\]]*? )
					( \. (?<ext> [^;\[\]]* ) )?
				)
				( ; (?<version> [^;\[\]]* ) )?
			)
		\z!xsn,
		join => sub {
			_join [qw/path dir volume file/],
				node            => "%s",
				[qw/accountname password/] => '["%s %s"]',
				[qw/node accountname password/] => "::",
				disk            => "%s",
				user            => "\$%s",
				[qw/disk user/] => ':',
				folder          => "[%s]",
				name            => "%s",
				ext             => ".%s",
				version         => ";%s",
		},
	},
	{
		name   => VOS,
		symdir => '>',
		symext => '.',
		regexp => qr!^
			(?<dir>
				(?<volume>
					% (?<sysname> [^>\#]* ) \# (?<module> [^>\#]* ) >
				)?
				( (?<folder> .* ) > )?
			)
			(?<file>
				(?<name> \.? [^.]*? )
				( \. (?<ext> .* ) )?
			)
		\z!xsn,
		join => sub {
			_join [qw/path dir volume file/],
				[qw/sysname module/] => "%%%s#%s>",
				folder => "%s>",
				name   => "%s",
				ext    => ".%s",
		},
	},
	{
		name   => RISCOS,
		symdir => '.',
		symext => '/',
		regexp => qr!^
			(?<dir>
				(?<volume>
					(
						(?<fstype> [^\$\#:.]* )
						( \# (?<option> [^\$\#:.]* ) )?
					: )?
					( : (?<disk> [^\$\#:.]* ) \. )?
				)
				( (?<folder> .* ) \. )?
			)
			(?<file>
				(?<name> [^./]*? )
				( / (?<ext> [^.]* ) )?
			)
		\z!xsn,
		join => sub {
			_join [qw/path dir volume file/],
				fstype => "%s",
				option => "#%s",
				[qw/fstype option/] => ":",
				disk   => ":%s.",
				folder => "%s.",
				name   => "%s",
				ext    => "/%s",
		},
	},
	{
		name   => MACOS,
		symdir => ':',
		symext => '.',
		regexp => qr!^
			(?<dir>
				( (?<volume> [^:]* ) : )?
				( (?<folder>    .* ) : )?
			)
			(?<file>
				(?<name> [^.:]*? )
				( \. (?<ext> [^:]* ) )?
			)
		\z!xsn,
		join => sub {
			_join [qw/path dir file/],
				volume => "%s:",
				folder => "%s:",
				name   => "%s",
				ext    => ".%s",
		},
	},
	{
		name   => VMESA,
		symdir => '/',
		symext => '.',
		regexp => qr!^
			\s* (?<userid> \S+ )
			\s+ (?<file>
				    (?<name> \S+ )
				\s+ (?<ext>  \S+ )
			)
			\s+ (?<volume> \S+ )
			\s*
		\z!xsn,
		join => sub {
			_join [qw/path/],
				[qw/userid file ext volume/] => "%s %s %s %s",
		},
	},
	
);

# Инициализация по имени
%FS = map {
	$_->{symdirquote} = quotemeta $_->{symdir};
	$_->{symextquote} = quotemeta $_->{symext};
	
	my @S;
	while($_->{regexp} =~ m{
		\\ .
		| (?<open> \( ( \?<(?<group> \w+ )> )? )
		| (?<close> \) )
	}gx) {
		if($+{open}) {
			my $group = $+{group};

			if ($group && @S) {
				my $curgroup;
				for(my $i = $#S; $i>=0; --$i) { $curgroup = $S[$i][1], last if defined $S[$i][1] }
				
				$_->{remove}{$curgroup}{$group}++ if defined $curgroup;
			}
		
			push @S, [length($`) + length $&, $group];
		}
		elsif($+{close}) {
			my ($pos, $group, $g2) = @{pop @S};
			
			$S[$#S][2] //= $group if $_->{group}{$group} && @S;
			
			$group //= $g2;
			$_->{group}{$group} = do {
				my $x = substr $_->{regexp}, $pos, length($`) - $pos;
				qr/()^$x\z/xsn
			} if defined $group;
		}
	}
	
	my $x = $_;
	ref $_->{name}? (map { ($_ => $x) } @{$_->{name}}): ($_->{name} => $_)
} @FS;

sub _fs() { $FS{lc $^O} // $FS{unix} }

# Мы находимся в ОС семейства UNIX
sub isUNIX() { _fs->{name} eq "unix" }

# Разбивает директорию на составляющие
sub splitdir(;$) {
	my ($dir) = @_ == 0? $_: @_;
	($dir) = @$dir if ref $dir;
	my $fs = _fs;
	$dir = $fs->{before_split}->($dir) if exists $fs->{before_split};
	split $fs->{symdirquote}, $dir, -1
}

# Объединяет директорию из составляющих
sub joindir(@) {
	join _fs->{symdir}, @_
}

# Разбивает расширение (тип файла) на составляющие
sub splitext(;$) {
	my ($ext) = @_ == 0? $_: @_;
	($ext) = @$ext if ref $ext;
	split _fs->{symextquote}, $ext, -1
}

# Объединяет расширение (тип файла) из составляющих
sub joinext(@) {
	join _fs->{symext}, @_
}


# Выделяет в пути составляющие, а если получает хеш, то объединяет его в путь
sub path(;$) {
	my ($path) = @_ == 0? $_: @_;
	
	my $fs = _fs;
	
	if(ref $path eq "HASH") {
		local $_ = $path;
		return $fs->{join}->();
	}
	
	($path) = @$path if ref $path;
	
	$path = $fs->{before_split}->($path) if exists $fs->{before_split};
	
	+{
		$path =~ $fs->{regexp}? (map { $_ ne "ext" && $+{$_} eq ""? (): ($_ => $+{$_}) } keys %+): (error => 1),
		path => $path,
	}
}

# Переводит путь из формата одной ОС в другую
sub transpath ($$;$) {
	my ($path, $from, $to) = @_ == 2? ($_, @_): @_;
	my (@dir, @folder, @ext);
	{ local $^O = $from;
		$path = path $path;

		@dir = splitdir $path->{dir} if exists $path->{dir} && !exists $path->{folder};
		@folder = splitdir $path->{folder} if exists $path->{folder};
		@ext = splitext $path->{ext} if exists $path->{ext};
	}

	delete $path->{path};
	delete $path->{dir} if exists $path->{folder};
	delete $path->{file};
	
	{ local $^O = $to;
		@dir = @folder, @folder = () if !_fs->{group}{folder};
		
		$path->{dir} = joindir @dir if scalar @dir;
		$path->{folder} = joindir @folder if scalar @folder;
		$path->{ext}    = joinext @ext if scalar @ext;
		path $path;
	}
}

# как mkdir -p
use constant FILE_EXISTS => 17;
use config   DIR_DEFAULT_PERMISSION => 0755;
sub mkpath (;$) {
	my ($path) = @_ == 0? $_: @_;
	
	my $permission;
	($path, $permission) = @$path if ref $path;
	$permission = DIR_DEFAULT_PERMISSION unless Scalar::Util::looks_like_number $permission;
	
	local $!;
	
	if(isUNIX) {
		while($path =~ m!/!g) {
			mkdir $`, $permission
				or ($! != FILE_EXISTS? die "mkpath $`: $!": ())
					if $` ne '';
		}
	}
	else {
		my $part = path $path;
		
		return $path unless exists $part->{folder};
		
		my @dirs = splitdir $part->{folder};
		
		# Если волюм или первый dirs пуст - значит путь относительный
		my $cat = $part->{volume};
		for(my $i=0; $i<@dirs; $i++) {
			
			next if $dirs[$i] eq "";
			
			my $cat = path +{
				$part->{volume}? (volume => $part->{volume}): (),
				folder => joindir(@dirs[0..$i]),
			};
			
			mkdir $cat, $permission or ($! != FILE_EXISTS? die "mkpath $cat: $!": ());
		}
	}
	
	$path
}

# Считывает файл
sub cat(;$) {
    my ($file) = @_ == 0? $_: @_;
	my $layer = ":utf8";
	($file, $layer) = @$file if ref $file;
	open my $f, "<$layer", $file or die "cat $file: $!";
	read $f, my $x, -s $f;
	close $f;
	$x
}

# записать файл
sub lay ($;$) {
	my ($file, $s) = @_ == 1? ($_, @_): @_;
	my $layer = ":utf8";
	($file, $layer) = @$file if ref $file;
	open my $f, ">$layer", $file or die "lay $file: $!";
	local $\;
	print $f $s;
	close $f;
	$file
}

# считать файл, если он ещё не был считан
our %FILE_INC;
sub catonce (;$) {
	my ($file) = @_ == 0? $_: @_;
	die "catonce not use ref path!" if ref $file;
	return undef if exists $FILE_INC{$file};
	$FILE_INC{$file} = 1;
	cat $file
}

use constant {
	DEV_NO		=> 0,	# Номер устройства
	INO_NO		=> 1,	# Номер inode
	MODE_NO		=> 2,	# Режим файла (права доступа)
	NLINK_NO	=> 3,	# Количество жестких ссылок
	UID_NO		=> 4,	# Идентификатор пользователя-владельца
	GID_NO		=> 5,	# Идентификатор группы-владельца
	RDEV_NO		=> 6,	# Номер устройства (если это специальный файл)
	SIZE_NO		=> 7,	# Размер файла в байтах
	ATIME_NO	=> 8,	# Время последнего доступа
	MTIME_NO	=> 9,	# Время последнего изменения
	CTIME_NO	=> 10,	# Время последнего изменения inode
	BLKSIZE_NO	=> 11,	# Размер блока ввода-вывода
	BLOCKS_NO	=> 12,	# Количество выделенных блоков
};

# Вернуть время модификации файла
sub mtime(;$) {
	my ($file) = @_ == 0? $_: @_;
	($file) = @$file if ref $file;
	(Time::HiRes::stat $file)[MTIME_NO] // die "mtime $file: $!"
}

# Информация о файле в виде хеша
sub sta(;$) {
	my ($path) = @_ == 0? $_: @_;
	($path) = @$path if ref $path;
	
	my %sta = (path => $path);
	@sta{qw/dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks/} = Time::HiRes::stat $path or die "sta $path: $!";
# 	@sta{qw/
# 		 user_can_exec user_can_read   user_can_write
# 		group_can_exec group_can_read group_can_write
# 		other_can_exec other_can_read other_can_write
# 	/} = (
# 		
# 	);
	\%sta
}

# Файловые фильтры
sub _filters(@) {
	map {
		if(ref $_ eq "CODE") {$_}
		elsif(ref $_ eq "Regexp") { my $re = $_; sub { $_ =~ $re } }
		elsif(/^-([a-z]+)$/) {
			eval join "", "sub { ", (join " && ", map "-$_()", split //, $1), " }"
		}
		else { my $re = wildcard(); sub { $_ =~ $re } }
	} @_
}

# Найти файлы
sub find(;@) {
	my $file = @_? shift: $_;
    $file = [$file] unless ref $file;

	my @noenters; my $errorenter = sub {};
	my $ex = @_ && ref($_[$#_]) =~ /^Aion::Fs::(noenter|errorenter)\z/ ? pop: undef;

	if($ex) {
		if($1 eq "errorenter") {
			$errorenter = $ex;
		} else {
			$errorenter = pop @$ex if ref $ex->[$#$ex] eq "Aion::Fs::errorenter";
			push @noenters, _filters @$ex;
		}
	}
	
	my @filters = _filters @_;
	my $wantarray = wantarray;

	my @ret; my $count;

	eval {
		local $_;
		
	    FILE: while(@$file) {
			my $path = shift @$file;

			for my $filter (@filters) {
				local $_ = $path;
				goto DIR unless $filter->();
			}

			# Не держим память, если это не нужно
			if($wantarray) { push @ret, $path } else { $count++ }

			DIR: if(-d $path) {
				for my $noenter (@noenters) {
					local $_ = $path;
					next FILE if $noenter->();
				}

				opendir my $dir, $path or do { local $_ = $path; $errorenter->(); next FILE };
				my @file;
				while(my $f = readdir $dir) {
					push @file, File::Spec->join($path, $f) if $f !~ /^\.{1,2}\z/;
				}
				push @$file, sort @file;
				closedir $dir;
			}
		}
		
	};
	
	if($@) {
		die if ref $@ ne "Aion::Fs::stop";
	}

	wantarray? @ret: $count
}

# Не входить в подкаталоги
sub noenter(@) {
	bless [@_], "Aion::Fs::noenter"
}

# Вызывается для всех ошибок ввода-вывода
sub errorenter(&) {
	bless shift, "Aion::Fs::errorenter"
}

# Останавливает find будучи вызван с одного из его фильтров, errorenter или noenter
sub find_stop() {
	die bless {}, "Aion::Fs::stop"
}

# Производит замену во всех указанных файлах. Возвращает файлы в которых замен не было
sub replace(&@) {
    my $fn = shift;
	my @noreplace; local $_; my $pkg = caller;
	my $aref = "${pkg}::a";	my $bref = "${pkg}::b";
    for $$aref (@_) {
		if(ref $$aref) { ($$aref, $$bref) = @$$aref } else { $$bref = ":utf8" }
        my $file = $_ = cat [$$aref, $$bref];
        $fn->();
		if($file ne $_) { lay [$$aref, $$bref], $_ } else { push @noreplace, $$aref if defined wantarray }
    }
	@noreplace
}

# Стирает все указанные файлы. Возвращает переданные файлы
sub erase(@) {
    -d? rmdir: unlink or die "erase ${\(-d? 'dir': 'file')} $_: $!" for @_;
	@_
}

# Переводит вилдкард в регулярку
sub wildcard(;$) {
	my ($wildcard) = @_;
	$wildcard = $_ if @_ == 0;
	$wildcard =~ s{
		(?<file> \*\*)
		| (?<path> \*)
		| (?<anyn> \?\? )
		| (?<any> \? )
		| (?<w1> \{ )
		| (?<w2> \} )
		| (?<comma> , )
		| .
	}{
		exists $+{file}? "[^/]*?":
		exists $+{path}? ".*?":
		exists $+{anyn}? "[^/]":
		exists $+{any}? ".":
		exists $+{w1}? "(":
		exists $+{w2}? ")":
		exists $+{comma}? "|":
		quotemeta $&
	}gxe;
	qr/^$wildcard$/ns
}

# Открывает файл на указанной строке в редакторе
use config EDITOR => "vscodium %p:%l";
sub goto_editor($$) {
	my ($path, $line) = @_;
	my $p = EDITOR;
	$p =~ s!%p!$path!;
	$p =~ s!%l!$line!;
	my $status = system $p;
	die "$path:$line --> $status" if $status;
	return;
}

# Из пакета в файловый путь
sub from_pkg(;$) {
	my ($pkg) = @_ == 0? $_: @_;
	$pkg =~ s!::!/!g;
	"$pkg.pm"
}

# Из файлового пути в пакет
sub to_pkg(;$) {
	my ($path) = @_ == 0? $_: @_;
	$path =~ s!\.\w+$!!;
	$path =~ s!/!::!g;
	$path
}

# Подключает модуль, если он ещё не подключён, и возвращает его
sub include(;$) {
	my ($pkg) = @_ == 0? $_: @_;
	return $pkg if $pkg->can("new") || $pkg->can("has");
	my $path = from_pkg $pkg;
	return $pkg if exists $INC{$path};
	require $path;
	$pkg
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Fs - утилиты для файловой системы: чтение, запись, поиск, замена файлов и т.д.

=head1 VERSION

0.1.2

=head1 SYNOPSIS

	use Aion::Fs;
	
	lay mkpath "hello/world.txt", "hi!";
	lay mkpath "hello/moon.txt", "noreplace";
	lay mkpath "hello/big/world.txt", "hellow!";
	lay mkpath "hello/small/world.txt", "noenter";
	
	mtime "hello"  # ~> ^\d+(\.\d+)?$
	
	[map cat, grep -f, find ["hello/big", "hello/small"]]  # --> [qw/ hellow! noenter /]
	
	my @noreplaced = replace { s/h/$a $b H/ }
	    find "hello", "-f", "*.txt", qr/\.txt$/, sub { /\.txt$/ },
	        noenter "*small*",
	            errorenter { warn "find $_: $!" };
	
	\@noreplaced # --> ["hello/moon.txt"]
	
	cat "hello/world.txt"       # => hello/world.txt :utf8 Hi!
	cat "hello/moon.txt"        # => noreplace
	cat "hello/big/world.txt"   # => hello/big/world.txt :utf8 Hellow!
	cat "hello/small/world.txt" # => noenter
	
	[find "hello", "*.txt"]  # --> [qw!  hello/moon.txt  hello/world.txt  hello/big/world.txt  hello/small/world.txt  !]
	[find "hello", "-d"]  # --> [qw!  hello  hello/big hello/small  !]
	
	erase reverse find "hello";
	
	-e "hello"  # -> undef

=head1 DESCRIPTION

Этот модуль облегчает использование файловой системы.

Модули C<File::Path>, C<File::Slurper> и
C<File::Find> обременены различными возможностями, которые используются редко, но требуют времени на ознакомление и тем самым повышают порог входа.

В C<Aion::Fs> же использован принцип программирования KISS - чем проще, тем лучше!

Супермодуль C<IO::All> не является конкурентом C<Aion::Fs>, т.к. использует ООП подход, а C<Aion::Fs> – ФП.

=over

=item * ООП — объектно-ориентированное программирование.

=item * ФП — функциональное программирование.

=back

=head1 SUBROUTINES/METHODS

=head2 cat ($file)

Считывает файл. Если параметр не указан, использует C<$_>.

	cat "/etc/passwd"  # ~> root

C<cat> читает со слоем C<:utf8>. Но можно указать другой слой следующим образом:

	lay "unicode.txt", "↯";
	length cat "unicode.txt"            # -> 1
	length cat["unicode.txt", ":raw"]   # -> 3

C<cat> вызывает исключение в случае ошибки операции ввода-вывода:

	eval { cat "A" }; $@  # ~> cat A: No such file or directory

=head3 See also

=over

=item * L<autodie> – C<< open $f, "r.txt"; $s = join "", E<lt>$fE<gt>; close $f >>.

=item * L<File::Slurp> — C<read_file('file.txt')>.

=item * L<File::Slurper> — C<read_text('file.txt')>, C<read_binary('file.txt')>.

=item * L<File::Util> — C<< File::Util-E<gt>new-E<gt>load_file(file =E<gt> 'file.txt') >>.

=item * L<IO::All> — C<< io('file.txt') E<gt> $contents >>.

=item * L<IO::Util> — C<$contents = ${ slurp 'file.txt' }>.

=item * L<Mojo::File> – C<< path($file)-E<gt>slurp >>.

=back

=head2 lay ($file?, $content)

Записывает C<$content> в C<$file>.

=over

=item * Если указан один параметр, использует C<$_> вместо C<$file>.

=item * C<lay>, использует слой C<:utf8>. Для указания иного слоя используется массив из двух элементов в параметре C<$file>:

=back

	lay "unicode.txt", "↯"  # => unicode.txt
	lay ["unicode.txt", ":raw"], "↯"  # => unicode.txt
	
	eval { lay "/", "↯" }; $@ # ~> lay /: Is a directory

=head3 See also

=over

=item * L<autodie> – C<< open $f, "E<gt>r.txt"; print $f $contents; close $f >>.

=item * L<File::Slurp> — C<write_file('file.txt', $contents)>.

=item * L<File::Slurper> — C<write_text('file.txt', $contents)>, C<write_binary('file.txt', $contents)>.

=item * L<IO::All> — C<< io('file.txt') E<lt> $contents >>.

=item * L<IO::Util> — C<slurp \$contents, 'file.txt'>.

=item * L<File::Util> — C<< File::Util-E<gt>new-E<gt>write_file(file =E<gt> 'file.txt', content =E<gt> $contents, bitmask =E<gt> 0644) >>.

=item * L<Mojo::File> – C<< path($file)-E<gt>spew($chars, 'UTF-8') >>.

=back

=head2 find (;$path, @filters)

Рекурсивно обходит и возвращает пути из указанного пути или путей, если C<$path> является ссылкой на массив. Без параметров использует C<$_> как C<$path>.

Фильтры могут быть:

=over

=item * Подпрограммой — путь к текущему файлу передаётся в C<$_>, а подпрограмма должна вернуть истину или ложь, как они понимаются perl-ом.

=item * Regexp — тестирует каждый путь регулярным выражением.

=item * Строка в виде "-Xxx", где C<Xxx> — один или несколько символов. Аналогична операторам perl-а для тестирования файлов. Пример: C<-fr> проверяет путь файловыми тестировщиками LLL<https://perldoc.perl.org/functions/-X>.

=item * Остальные строки превращаются функцией C<wildcard> (см. ниже) в регулярное выражение для проверки каждого пути.

=back

Пути, не прошедшие проверку C<@filters>, не возвращаются.

Если фильтр -X не является файловой функцией perl, то выбрасывается исключение:

	eval { find "example", "-h" }; $@   # ~> Undefined subroutine &Aion::Fs::h called

В этом примере C<find> не может войти в подкаталог и передаёт ошибку в функцию C<errorenter> (см. ниже) с установленными переменными C<$_> и C<$!> (путём к каталогу и сообщением ОС об ошибке).

B<Внимание!> Если C<errorenter> не указана, то все ошибки B<игнорируются>!

	mkpath ["example/", 0];
	
	[find "example"]                  # --> ["example"]
	[find "example", noenter "-d"]    # --> ["example"]
	
	eval { find "example", errorenter { die "find $_: $!" } }; $@   # ~> find example: Permission denied
	
	mkpath for qw!ex/1/11 ex/1/12 ex/2/21 ex/2/22!;
	
	my $count = 0;
	find "ex", sub { find_stop if ++$count == 3; 1}  # -> 2

=head3 See also

=over

=item * L<AudioFile::Find> — ищет аудиофайлы в указанной директории. Позволяет фильтровать их по атрибутам: названию, артисту, жанру, альбому и трэку.

=item * L<Directory::Iterator> — C<< $it = Directory::Iterator-E<gt>new($dir, %opts); push @paths, $_ while E<lt>$itE<gt> >>.

=item * L<IO::All> — C<< @paths = map { "$_" } grep { -f $_ && $_-E<gt>size E<gt> 10*1024 } io(".")-E<gt>all(0) >>.

=item * L<IO::All::Rule> — C<< $next = IO::All::Rule-E<gt>new-E<gt>file-E<gt>size("E<gt>10k")-E<gt>iter($dir1, $dir2); push @paths, "$f" while $f = $next-E<gt>() >>.

=item * L<File::Find> — C<find( sub { push @paths, $File::Find::name if /\.png/ }, $dir )>.

=item * L<File::Find::utf8> — как L<File::Find>, только пути файлов в I<utf8>.

=item * L<File::Find::Age> — сортирует файлы по времени модификации (наследует L<File::Find::Rule>): C<< File::Find::Age-E<gt>in($dir1, $dir2) >>.

=item * L<File::Find::Declare> — C<< @paths = File::Find::Declare-E<gt>new({ size =E<gt> 'E<gt>10K', perms =E<gt> 'wr-wr-wr-', modified =E<gt> 'E<lt>2010-01-30', recurse =E<gt> 1, dirs =E<gt> [$dir1] })-E<gt>find >>.

=item * L<File::Find::Iterator> — имеет ООП интерфейс с итератором и функции C<imap> и C<igrep>.

=item * L<File::Find::Match> — вызывает обработчик на каждый подошедший фильтр. Похож на C<switch>.

=item * L<File::Find::Node> — обходит иерархию файлов параллельно несколькими процессами: C<< tie @paths, IPC::Shareable, { key =E<gt> "GLUE STRING", create =E<gt> 1 }; File::Find::Node-E<gt>new(".")-E<gt>process(sub { my $f = shift; $f-E<gt>fork(5); tied(@paths)-E<gt>lock; push @paths, $f-E<gt>path; tied(@paths)-E<gt>unlock })-E<gt>find; tied(@paths)-E<gt>remove >>.

=item * L<File::Find::Fast> — C<@paths = @{ find($dir) }>.

=item * L<File::Find::Object> — имеет ООП интерфейс с итератором.

=item * L<File::Find::Parallel> — умеет сравнивать два каталога и возвращать их объединение, пересечение и количественное пересечение.

=item * L<File::Find::Random> — выбирает файл или директорию наугад из иерархии файлов.

=item * L<File::Find::Rex> — C<< @paths = File::Find::Rex-E<gt>new(recursive =E<gt> 1, ignore_hidden =E<gt> 1)-E<gt>query($dir, qr/^b/i) >>.

=item * L<File::Find::Rule> — C<< @files = File::Find::Rule-E<gt>any( File::Find::Rule-E<gt>file-E<gt>name('*.mp3', '*.ogg')-E<gt>size('E<gt>2M'), File::Find::Rule-E<gt>empty )-E<gt>in($dir1, $dir2); >>. Имеет итератор, процедурный интерфейс и расширения L<File::Find::Rule::ImageSize> и L<File::Find::Rule::MMagic>: C<< @images = find(file =E<gt> magic =E<gt> 'image/*', '!image_x' =E<gt> 'E<gt>20', in =E<gt> '.') >>.

=item * L<File::Find::Wanted> — C<@paths = find_wanted( sub { -f && /\.png/ }, $dir )>.

=item * L<File::Hotfolder> — C<< watch( $dir, callback =E<gt> sub { push @paths, shift } )-E<gt>loop >>. Работает на C<AnyEvent>. Настраиваемый. Есть распараллеливание на несколько процессов.

=item * L<File::Mirror> — формирует так же параллельный путь для копирования файлов: C<recursive { my ($src, $dst) = @_; push @paths, $src } '/path/A', '/path/B'>.

=item * L<File::Set> — C<< $fs = File::Set-E<gt>new; $fs-E<gt>add($dir); @paths = map { $_-E<gt>[0] } $fs-E<gt>get_path_list >>.

=item * L<File::Wildcard> — C<< $fw = File::Wildcard-E<gt>new(exclude =E<gt> qr/.svn/, case_insensitive =E<gt> 1, sort =E<gt> 1, path =E<gt> "src///*.cpp", match =E<gt> qr(^src/(.*?)\.cpp$), derive =E<gt> ['src/$1.o','src/$1.hpp']); push @paths, $f while $f = $fw-E<gt>next >>.

=item * L<File::Wildcard::Find> — C<findbegin($dir); push @paths, $f while $f = findnext()> или  C<findbegin($dir); @paths = findall()>.

=item * L<File::Util> — C<< File::Util-E<gt>new-E<gt>list_dir($dir, qw/ --pattern=\.txt$ --files-only --recurse /) >>.

=item * L<Mojo::File> – C<< say for path($path)-E<gt>list_tree({hidden =E<gt> 1, dir =E<gt> 1})-E<gt>each >>.

=item * L<Path::Find> — C<@paths = path_find( $dir, "*.png" )>. Для сложных запросов использует I<matchable>: C<< my $sub = matchable( sub { my( $entry, $directory, $fullname, $depth ) = @_; $depth E<lt>= 3 } >>.

=item * L<Path::Extended::Dir> — C<< @paths = Path::Extended::Dir-E<gt>new($dir)-E<gt>find('*.txt') >>.

=item * L<Path::Iterator::Rule> — C<< $i = Path::Iterator::Rule-E<gt>new-E<gt>file; @paths = $i-E<gt>clone-E<gt>size("E<gt>10k")-E<gt>all(@dirs); $i-E<gt>size("E<lt>10k")... >>.

=item * L<Path::Class::Each> — C<< dir($dir)-E<gt>each(sub { push @paths, "$_" }) >>.

=item * L<Path::Class::Iterator> — C<< $i = Path::Class::Iterator-E<gt>new(root =E<gt> $dir, depth =E<gt> 2); until ($i-E<gt>done) { push @paths, $i-E<gt>next-E<gt>stringify } >>.

=item * L<Path::Class::Rule> — C<< @paths = Path::Class::Rule-E<gt>new-E<gt>file-E<gt>size("E<gt>10k")-E<gt>all($dir) >>.

=back

=head2 noenter (@filters)

Говорит C<find> не входить в каталоги соответствующие фильтрам за ним.

=head2 errorenter (&block)

Вызывает C<&block> для каждой ошибки возникающей при невозможности войти в какой-либо каталог.

=head2 find_stop ()

Останавливает C<find> будучи вызван в одном из его фильтров, C<errorenter> или C<noenter>.

	my $count = 0;
	find "ex", sub { find_stop if ++$count == 3; 1}  # -> 2

=head2 erase (@paths)

Удаляет файлы и пустые каталоги. Возвращает C<@paths>. При ошибке ввода-вывода выбрасывает исключение.

	eval { erase "/" }; $@  # ~> erase dir /: Device or resource busy
	eval { erase "/dev/null" }; $@  # ~> erase file /dev/null: Permission denied

=head3 See also

=over

=item * C<unlink> + C<rmdir>.

=item * L<File::Path> — C<remove_tree("dir")>.

=item * L<File::Path::Tiny> — C<File::Path::Tiny::rm($path)>. Не выбрасывает исключений.

=item * L<Mojo::File> – C<< path($file)-E<gt>remove >>.

=back

=head2 replace (&sub, @files)

Заменяет каждый файл на C<$_>, если его изменяет C<&sub>. Возвращает файлы, в которых не было замен.

C<@files> может содержать массивы из двух элементов. Первый рассматривается как путь, а второй — как слой. Слой по умолчанию — C<:utf8>.

C<&sub> вызывается для каждого файла из C<@files>. В неё передаются:

=over

=item * C<$_> — содержимое файла.

=item * C<$a> — путь к файлу.

=item * C<$b> — слой которым был считан файл и которым он будет записан.

=back

В примере ниже файл "replace.ex" считывается слоем C<:utf8>, а записывается слоем C<:raw> в функции C<replace>:

	local $_ = "replace.ex";
	lay "abc";
	replace { $b = ":utf8"; y/a/¡/ } [$_, ":raw"];
	cat  # => ¡bc

=head3 See also

=over

=item * L<File::Edit> – C<< File::Edit-E<gt>new($file)-E<gt>replace('x', 'y')-E<gt>save >>.

=item * L<File::Edit::Portable> – C<< File::Edit::Portable-E<gt>new-E<gt>splice(file =E<gt> $file, line =E<gt> 10, contens =E<gt> ["line1", "line2"]) >>.

=item * L<File::Replace> – C<< ($infh,$outfh,$repl) = replace3($file); while (E<lt>$infhE<gt>) { print $outfh "X: $_" } $repl-E<gt>finish >>.

=item * L<File::Replace::Inplace>.

=back

=head2 mkpath (;$path)

Как B<mkdir -p>, но считает последнюю часть пути (после последней косой черты) именем файла и не создаёт её каталогом. Без параметра использует C<$_>.

=over

=item * Если C<$path> не указан, использует C<$_>.

=item * Если C<$path> является ссылкой на массив, тогда используется путь в качестве первого элемента и права в качестве второго элемента.

=item * Права по умолчанию — C<0755>.

=item * Возвращает C<$path>.

=back

	local $_ = ["A", 0755];
	mkpath   # => A
	
	eval { mkpath "/A/" }; $@   # ~> mkpath /A: Permission denied
	
	mkpath "A///./file";
	-d "A"  # -> 1

=head3 See also

=over

=item * L<File::Path> — C<mkpath("dir1/dir2")>.

=item * L<File::Path::Tiny> — C<File::Path::Tiny::mk($path)>. Не выбрасывает исключений.

=back

=head2 mtime (;$path)

Время модификации C<$path> в unixtime с дробной частью (из C<Time::HiRes::stat>). Без параметра использует C<$_>.

Выбрасывает исключение, если файл не существует или нет прав:

	local $_ = "nofile";
	eval { mtime }; $@  # ~> mtime nofile: No such file or directory
	
	mtime ["/"]   # ~> ^\d+(\.\d+)?$

=head3 See also

=over

=item * C<-M> — C<-M "file.txt">, C<-M _> в днях от текущего времени.

=item * L<stat> — C<(stat "file.txt")[9]> в секундах (unixtime).

=item * L<Time::HiRes> — C<(Time::HiRes::stat "file.txt")[9]> в секундах с дробной частью.

=item * L<Mojo::File> — C<< path($file)-E<gt>stat-E<gt>mtime >>.

=back

=head2 sta (;$path)

Возвращает статистику о файле. Без параметра использует C<$_>.

Чтобы можно было использовать с другими файловыми функциями, может получать ссылку на массив из которого берёт первый элемент в качестве файлового пути.

Выбрасывает исключение, если файл не существует или нет прав:

	local $_ = "nofile";
	eval { sta }; $@  # ~> sta nofile: No such file or directory
	
	sta(["/"])->{ino} # ~> ^\d+$
	sta(".")->{atime} # ~> ^\d+(\.\d+)?$

=head3 See also

=over

=item * L<Fcntl> – содержит константы для распознавания режима.

=item * L<BSD::stat> – дополнительно возвращает atime, ctime и mtime в наносекундах, флаги пользователя и номер генерации файла. Имеет ООП-интерфейс.

=item * L<File::chmod> – C<chmod("o=,g-w","file1","file2")>, C<@newmodes = getchmod("+x","file1","file2")>.

=item * L<File::stat> – предоставляет ООП-интерфейс к stat.

=item * L<File::Stat::Bits> – аналогичен L<Fcntl>.

=item * L<File::stat::Extra> – расширяет L<File::stat> методами для получения информации о режиме, а так же перезагружает B<-X>, B<< <=> >>, B<cmp> и B<~~> операторы и стрингифицируется.

=item * L<File::Stat::Ls> – возвращает режим в формате утилиты ls.

=item * L<File::Stat::Moose> – ООП интерфейс на Moose.

=item * L<File::Stat::OO> – предоставляет ООП-интерфейс к stat. Может возвращать atime, ctime и mtime сразу в C<DateTime>.

=item * L<File::Stat::Trigger> – следилка за изменением атрибутов файла.

=item * L<Linux::stat> – парсит /proc/stat и возвращает доп-информацию. Однако в других ОС не работает.

=item * L<Stat::lsMode> – возвращает режим в формате утилиты ls.

=item * L<VMS::Stat> – возвращает списки VMS ACL.

=back

=head2 path (;$path)

Разбивает файловый путь на составляющие или собирает его из составляющих.

=over

=item * Если получает ссылку на массив, то воспринимает его первый элемент как путь.

=item * Если получает ссылку на хэш, то собирает из него путь. Незнакомые ключи просто игнорирует. Набор ключей для каждой ФС – разный.

=item * ФС берётся из системной переменной C<$^O>.

=item * К файловой системе не обращается.

=back

	{
	    local $^O = "freebsd";
	
	    path "."        # --> {path => ".", file => ".", name => "."}
	    path ".bashrc"  # --> {path => ".bashrc", file => ".bashrc", name => ".bashrc"}
	    path ".bash.rc"  # --> {path => ".bash.rc", file => ".bash.rc", name => ".bash", ext => "rc"}
	    path ["/"]      # --> {path => "/", dir => "/"}
	    local $_ = "";
	    path            # --> {path => ""}
	    path "a/b/c.ext.ly"   # --> {path => "a/b/c.ext.ly", dir => "a/b", file => "c.ext.ly", name => "c", ext => "ext.ly"}
	
	    path +{dir  => "/", ext => "ext.ly"}    # => /.ext.ly
	    path +{file => "b.c", ext => "ly"}      # => b.ly
	    path +{path => "a/b/f.c", dir => "m"}   # => m/f.c
	
	    local $_ = +{path => "a/b/f.c", dir => undef, ext => undef};
	    path # => f
	    path +{path => "a/b/f.c", volume => "/x", dir => "m/y/", file => "f.y", name => "j", ext => "ext"} # => m/y//j.ext
	    path +{path => "a/b/f.c", volume => "/x", dir => "/y", file => "f.y", name => "j", ext => "ext"} # => /y/j.ext
	}
	
	{
	    local $^O = "MSWin32"; # also os2, symbian and dos
	
	    path "."        # --> {path => ".", file => ".", name => "."}
	    path ".bashrc"  # --> {path => ".bashrc", file => ".bashrc", name => ".bashrc"}
	    path "/"        # --> {path => "\\", dir => "\\", folder => "\\"}
	    path "\\"       # --> {path => "\\", dir => "\\", folder => "\\"}
	    path ""         # --> {path => ""}
	    path "a\\b\\c.ext.ly"   # --> {path => "a\\b\\c.ext.ly", dir => "a\\b\\", folder => "a\\b", file => "c.ext.ly", name => "c", ext => "ext.ly"}
	
	    path +{dir  => "/", ext => "ext.ly"}    # => \\.ext.ly
	    path +{dir  => "\\", ext => "ext.ly"}   # => \\.ext.ly
	    path +{file => "b.c", ext => "ly"}      # => b.ly
	    path +{path => "a/b/f.c", dir => "m/r/"}   # => m\\r\\f.c
	
	    path +{path => "a/b/f.c", dir => undef, ext => undef} # => f
	    path +{path => "a/b/f.c", volume => "x", dir => "m/y/", file => "f.y", name => "j", ext => "ext"} # \> x:m\y\j.ext
	    path +{path => "x:/a/b/f.c", volume => undef, dir =>  "/y/", file => "f.y", name => "j", ext => "ext"} # \> \y\j.ext
	}
	
	{
	    local $^O = "amigaos";
	
	    my $path = {
	        path   => "Work1:Documents/Letters/Letter1.txt",
	        dir    => "Work1:Documents/Letters/",
	        volume => "Work1",
	        folder => "Documents/Letters",
	        file   => "Letter1.txt",
	        name   => "Letter1",
	        ext    => "txt",
	    };
	
	    path "Work1:Documents/Letters/Letter1.txt" # --> $path
	
	    path {volume => "Work", file => "Letter1.pm", ext => "txt"} # => Work:Letter1.txt
	}
	
	{
	    local $^O = "cygwin";
	
	    my $path = {
	        path   => "/cygdrive/c/Documents/Letters/Letter1.txt",
	        dir    => "/cygdrive/c/Documents/Letters/",
	        volume => "c",
	        folder => "Documents/Letters",
	        file   => "Letter1.txt",
	        name   => "Letter1",
	        ext    => "txt",
	    };
	
	    path "/cygdrive/c/Documents/Letters/Letter1.txt" # --> $path
	
	    path {volume => "c", file => "Letter1.pm", ext => "txt"} # => /cygdrive/c/Letter1.txt
	}
	
	{
	    local $^O = "dos";
	
	    my $path = {
	        path   => 'c:\Documents\Letters\Letter1.txt',
	        dir    => 'c:\Documents\Letters\\',
	        volume => 'c',
	        folder => '\Documents\Letters',
	        file   => 'Letter1.txt',
	        name   => 'Letter1',
	        ext    => 'txt',
	    };
	
	    path 'c:\Documents\Letters\Letter1.txt' # --> $path
	
	    path {volume => "c", file => "Letter1.pm", ext => "txt"} # \> c:Letter1.txt
	    path {dir => 'r\t\\',  file => "Letter1",    ext => "txt"} # \> r\t\Letter1.txt
	}
	
	{
	    local $^O = "VMS";
	
	    my $path = {
	        path   => "DISK:[DIRECTORY.SUBDIRECTORY]FILENAME.EXTENSION",
	        dir    => "DISK:[DIRECTORY.SUBDIRECTORY]",
	        volume => "DISK:",
	        disk   => "DISK",
	        folder => "DIRECTORY.SUBDIRECTORY",
	        card   => "FILENAME.EXTENSION",
	        file   => "FILENAME.EXTENSION",
	        name   => "FILENAME",
	        ext    => "EXTENSION",
	    };
	
	    path "DISK:[DIRECTORY.SUBDIRECTORY]FILENAME.EXTENSION" # --> $path
	
	    $path = {
	        path        => 'NODE["account password"]::DISK$USER:[DIRECTORY.SUBDIRECTORY]FILENAME.EXTENSION;7',
	        dir         => 'NODE["account password"]::DISK$USER:[DIRECTORY.SUBDIRECTORY]',
	        node        => "NODE",
	        accountname => "account",
	        password    => "password",
	        volume      => 'DISK$USER:',
	        disk        => 'DISK',
	        user        => 'USER',
	        folder      => "DIRECTORY.SUBDIRECTORY",
	        card        => "FILENAME.EXTENSION;7",
	        file        => "FILENAME.EXTENSION",
	        name        => "FILENAME",
	        ext         => "EXTENSION",
	        version     => 7,
	    };
	
	    path 'NODE["account password"]::DISK$USER:[DIRECTORY.SUBDIRECTORY]FILENAME.EXTENSION;7' # --> $path
	
	    path {volume => "DISK:", file => "FILENAME.pm", ext => "EXTENSION"} # => DISK:FILENAME.EXTENSION
	    path {user => "USER", folder => "DIRECTORY.SUBDIRECTORY", file => "FILENAME.pm", ext => "EXTENSION"} # \> $USER:[DIRECTORY.SUBDIRECTORY]FILENAME.EXTENSION
	}
	
	{
	    local $^O = "VOS";
	
	    my $path = {
	        path    => "%sysname#module1>SubDir>File.txt",
	        dir     => "%sysname#module1>SubDir>",
	        volume  => "%sysname#module1>",
	        sysname => "sysname",
	        module  => "module1",
	        folder  => "SubDir",
	        file    => "File.txt",
	        name    => "File",
	        ext     => "txt",
	    };
	
	    path $path->{path} # --> $path
	
	    path {volume => "%sysname#module1>", file => "File.pm", ext => "txt"} # => %sysname#module1>File.txt
	    path {module => "module1", file => "File.pm"} # => %#module1>File.pm
	    path {sysname => "sysname", file => "File.pm"} # => %sysname#>File.pm
	    path {dir => "dir>subdir>", file => "File.pm", ext => "txt"} # => dir>subdir>File.txt
	}
	
	{
	    local $^O = "riscos";
	
	    my $path = {
	        path   => 'Filesystem#Special_Field::DiskName.$.Directory.Directory.File/Ext/Ext',
	        dir    => 'Filesystem#Special_Field::DiskName.$.Directory.Directory.',
	        volume => 'Filesystem#Special_Field::DiskName.',
	        fstype => "Filesystem",
	        option => "Special_Field",
	        disk   => "DiskName",
	        folder => '$.Directory.Directory',
	        file   => "File/Ext/Ext",
	        name   => "File",
	        ext    => "Ext/Ext",
	    };
	
	    path $path->{path} # --> $path
	
	    $path = {
	        path => '.$.Directory.Directory.',
	        dir => '.$.Directory.Directory.',
	        folder => '.$.Directory.Directory',
	    };
	
	    path '.$.Directory.Directory.' # --> $path
	
	    path {volume => "ADFS::HardDisk.", file => "File"} # => ADFS::HardDisk.$.File
	    path {folder => "x"}  # => x.
	    path {dir    => "x."} # => x.
	}
	
	{
	    local $^O = "MacOS";
	
	    my $path = {
	        path   => '::::mix:report.doc',
	        dir    => "::::mix:",
	        folder => ":::mix",
	        file   => "report.doc",
	        name   => "report",
	        ext    => "doc",
	    };
	
	    path $path->{path} # --> $path
	    path $path         # => $path->{path}
	
	    path 'report' # --> {path => 'report', file => 'report', name => 'report'}
	
	    path {volume => "x", file => "f"} # => x:f
	    path {folder => "x"} # => x:
	}
	
	{
	    local $^O = "vmesa";
	
	    my $path = {
	        path   => ' USERID   FILE EXT   VOLUME ',
	        userid => "USERID",
	        file   => "FILE EXT",
	        name   => "FILE",
	        ext    => "EXT",
	        volume => "VOLUME",
	    };
	
	    path $path->{path} # --> $path
	
	    path {volume => "x", file => "f"} # -> ' f  x'
	}
	

=head3 See also

=over

=item * https://en.wikipedia.org/wiki/Path_(computing)

=back

Модули для определения ОС, а значит и определения, какие в ОС файловые пути:

=over

=item * C<$^O> – суперглобальная переменная с названием текущей ОС.

=item * L<Devel::CheckOS>, L<Perl::OSType> – определяют ОС.

=item * L<Devel::AssertOS> – запрещает использовать модуль вне указанных ОС.

=item * L<System::Info> – информация об ОС, её версии, дистрибутиве, CPU и хосте.

=back

Выделяют части файловых путей:

=over

=item * L<File::Spec> – C<< ($volume, $directories, $file) = File::Spec-E<gt>splitpath($path) >>. Поддерживает только unix, win32, os/2, vms, cygwin и amigaos.

=item * L<File::Spec::Functions> – C<($volume, $directories, $file) = splitpath($path)>.

=item * L<File::Spec::Mac> – входит в L<File::Spec>, но не определяется им, поэтому приходится использовать отдельно. Для mac os по 9-ю версию.

=item * L<File::Basename> – C<($name, $path, $suffix) = fileparse($fullname, @suffixlist)>.

=item * L<Path::Class::File> – C<< file('foo', 'bar.txt')-E<gt>is_absolute >>.

=item * L<Path::Extended::File> – C<< Path::Extended::File-E<gt>new($file)-E<gt>basename >>.

=item * L<Mojo::File> – C<< path($file)-E<gt>extname >>.

=item * L<Path::Util> – C<$filename = basename($dir)>.

=item * L<Parse::Path> – C<< Parse::Path-E<gt>new(path =E<gt> 'gophers[0].food.count', style =E<gt> 'DZIL')-E<gt>push("chunk") >>. Работает с путями как с массивами (C<push>, C<pop>, C<shift>, C<splice>). Так же перегружает операторы сравнения. У него есть стили: C<DZIL>, C<File::Unix>, C<File::Win32>, C<PerlClass> и C<PerlClassUTF8>.

=back

=head2 transpath ($path?, $from, $to)

Переводит путь из формата одной ОС в другую.

Если C<$path> не указан, то используется C<$_>.

Перечень поддерживаемых ОС смотрите в примерах подпрограммы C<path> чуть выше или так: C<keys %Aion::Fs::FS>.

Названия ОС – регистронезависимы.

	local $_ = ">x>y>z.doc.zip";
	transpath "vos", "unix"       # \> /x/y/z.doc.zip
	transpath "vos", "VMS"        # \> [.x.y]z.doc.zip
	transpath $_, "vos", "RiscOS" # \> .x.y.z/doc/zip

=head2 splitdir (;$dir)

Разбивает директорию на составляющие. Директорию следует вначале получить из C<< path-E<gt>{dir} >>.

	local $^O = "unix";
	[ splitdir "/x/" ]    # --> ["", "x", ""]

=head2 joindir (;$dirparts)

Объединяет директорию из составляющих. Затем полученную директорию следует включить в C<< path +{dir =E<gt> $dir} >>.

	local $^O = "unix";
	joindir qw/x y z/    # => x/y/z
	
	path +{ dir => joindir qw/x y z/ } # => x/y/z/

=head2 splitext (;$ext)

Разбивает расширение на составляющие. Расширение следует вначале получить из C<< path-E<gt>{ext} >>.

	local $^O = "unix";
	[ splitext ".x." ]    # --> ["", "x", ""]

=head2 joinext (;$extparts)

Объединяет расширение из составляющих. Затем полученное расширение следует включить в C<< path +{ext =E<gt> $ext} >>.

	local $^O = "unix";
	joinext qw/x y z/    # => x.y.z
	
	path +{ ext => joinext qw/x y z/ } # => .x.y.z

=head2 include (;$pkg)

Подключает C<$pkg> (если он ещё не был подключён через C<use> или C<require>) и возвращает его. Без параметра использует C<$_>.

Файл lib/A.pm:

	package A;
	sub new { bless {@_}, shift }
	1;

Файл lib/N.pm:

	package N;
	sub ex { 123 }
	1;



	use lib "lib";
	include("A")->new               # ~> A=HASH\(0x\w+\)
	[map include, qw/A N/]          # --> [qw/A N/]
	{ local $_="N"; include->ex }   # -> 123

=head2 catonce (;$file)

Считывает файл в первый раз. Любая последующая попытка считать этот файл возвращает C<undef>. Используется для вставки модулей js и css в результирующий файл. Без параметра использует C<$_>.

=over

=item * C<$file> может содержать массивы из двух элементов. Первый рассматривается как путь, а второй — как слой. Слой по умолчанию — C<:utf8>.

=item * Если C<$file> не указан – использует C<$_>.

=back

	local $_ = "catonce.txt";
	lay "result";
	catonce  # -> "result"
	catonce  # -> undef
	
	eval { catonce[] }; $@ # ~> catonce not use ref path!

=head2 wildcard (;$wildcard)

Переводит файловую маску в регулярное выражение. Без параметра использует C<$_>.

=over

=item * C<**> - C<[^/]*>

=item * C<*> - C<.*>

=item * C<?> - C<.>

=item * C<??> - C<[^/]>

=item * C<{> - C<(>

=item * C<}> - C<)>

=item * C<,> - C<|>

=item * Остальные символы экранируются с помощью C<quotemeta>.

=back

	wildcard "*.{pm,pl}"  # \> (?^usn:^.*?\.(pm|pl)$)
	wildcard "?_??_**"  # \> (?^usn:^._[^/]_[^/]*?$)

Используется в фильтрах функции C<find>.

=head3 See also

=over

=item * L<File::Wildcard>.

=item * L<String::Wildcard::Bash>.

=item * L<Text::Glob> — C<glob_to_regex("*.{pm,pl}")>.

=back

=head2 goto_editor ($path, $line)

Открывает файл в редакторе из .config на указанной строке. По умолчанию использует C<vscodium %p:%l>.

Файл .config.pm:

	package config;
	
	config_module 'Aion::Fs' => {
	    EDITOR => 'echo %p:%l > ed.txt',
	};
	
	1;



	goto_editor "mypath", 10;
	cat "ed.txt"  # => mypath:10\n
	
	eval { goto_editor "`", 1 }; $@  # ~> `:1 --> 512

=head2 from_pkg (;$pkg)

Переводит пакет в путь ФС. Без параметра использует C<$_>.

	from_pkg "Aion::Fs"  # => Aion/Fs.pm
	[map from_pkg, "Aion::Fs", "A::B::C"]  # --> ["Aion/Fs.pm", "A/B/C.pm"]

=head2 to_pkg (;$path)

Переводит путь из ФС в пакет. Без параметра использует C<$_>.

	to_pkg "Aion/Fs.pm"  # => Aion::Fs
	[map to_pkg, "Aion/Fs.md", "A/B/C.md"]  # --> ["Aion::Fs", "A::B::C"]

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Fs is copyright © 2023 by Yaroslav O. Kosmina. Rusland. All rights reserved.
