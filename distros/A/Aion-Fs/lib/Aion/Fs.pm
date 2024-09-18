package Aion::Fs;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.7";

use Exporter qw/import/;
use File::Spec     qw//;
use Scalar::Util   qw//;
use Time::HiRes    qw//;

our @EXPORT = our @EXPORT_OK = grep {
	ref \$Aion::Fs::{$_} eq "GLOB" && *{$Aion::Fs::{$_}}{CODE} && !/^(?:_|(NaN|import)\z)/
} keys %Aion::Fs::;


use constant UNIX => $^O =~ /^(?:aix|bsdos|darwin|dynixptx|freebsd|haiku|linux|hpux|irix|next|openbsd|dec_osf|svr4|sco_sv|unicos|unicosmk|unicos|solaris|sunos)\z/;

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

# как mkdir -p
use constant FILE_EXISTS => 17;
use config   DIR_DEFAULT_PERMISSION => 0755;
sub mkpath (;$) {
	my ($path) = @_ == 0? $_: @_;
	
	my $permission;
	($path, $permission) = @$path if ref $path;
	$permission = DIR_DEFAULT_PERMISSION unless Scalar::Util::looks_like_number $permission;
	
	local $!;
	
	if(UNIX) {
		while($path =~ m!/!g) {
			mkdir $`, $permission
				or ($! != FILE_EXISTS? die "mkpath $`: $!": ())
					if $` ne '';
		}
	}
	else {
		my ($volume, $dirs, $file) = File::Spec->splitpath($path);
		
		my @dirs = File::Spec->splitdir($dirs);
		
		# Если волюм или первый dirs пуст - значит путь относительный
		my $cat = $dirs[0] eq ""? $volume: undef;
		for(my $i = 0; $i < @dirs; $i++) {
			$cat = defined($cat)? File::Spec->catdir($cat, $dirs[$i]): $dirs[$i];
			
			mkdir $cat, $permission or ($! != FILE_EXISTS? die "mkpath $cat: $!": ()) if $dirs[$i] ne '';
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
	\%sta
}

# Выделяет в пути составляющие, а если получает хеш, то объединяет его в путь
sub path(;$);
sub path(;$) {
	my ($path) = @_ == 0? $_: @_;
	if(ref $path eq "HASH") {
		my ($path, $volume, $dir, $file, $name, $ext) = @$path{qw/path volume dir file name ext/};
		
		if(defined $path) {
			my $p = path $path;
			$volume //= $p->{volume};
			$dir    //= $p->{dir};
			$file   //= $p->{file};
			$name   //= $p->{name};
			$ext    //= $p->{ext};
		}

		if(defined $file and (defined $name or defined $ext)) {
			my ($n, $e) = $file =~ /\./? ($`, $'): $file;
			$name //= $n;
			$ext //= $e;
		}
		
		$file = defined($ext)? "$name.$ext": $name;
		
		if(UNIX) {
			return defined($dir)? join("", $dir, $dir =~ /\/\z/? (): "/", $file): $file;
		}
		
		return File::Spec->catpath($volume, $dir, $file);
	}
	
	($path) = @$path if ref $path;
	
	my $und = sub { $_[0] eq ""? undef: $_[0] };
	
	+{
		path => $path,
		UNIX? do {
			my ($dir, $file, $name, $ext);
			
			if($path =~ m!/([^/]*)\z!) { $dir = length($`)? $`: "/"; $file = $1 } else { $file = $path }
			
			if($file =~ /\./) { ($name, $ext) = ($`, $') } else { $name = $file }
			
			(volume => undef, dir => $und->($dir), file => $und->($file), name => $und->($name), ext => $und->($ext))
		}: do {
			my ($volume, $dir, $file) = File::Spec->splitpath($path);
			my ($name, $ext) = $file =~ /\./? ($`, $'): $file;
			
			my @dirs = File::Spec->splitdir($dir);
			pop @dirs;
			$dir = File::Spec->catdir(@dirs);

			(volume => $und->($volume), dir => $und->($dir), file => $und->($file), name => $und->($name), ext => $und->($ext))
		},
	}
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
					#use DDP; p my $x=["hi!", $path, $f, File::Spec->join($path, $f)];
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

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Fs - utilities for the file system: reading, writing, searching, replacing files, etc.

=head1 VERSION

0.0.7

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

This module makes it easier to use the file system.

Modules C<File::Path>, C<File::Slurper> and
C<File::Find> is burdened with various features that are rarely used, but require time to become familiar with and thereby increase the barrier to entry.

C<Aion::Fs> uses the KISS programming principle - the simpler the better!

The C<IO::All> supermodule is not a competitor to C<Aion::Fs>, because uses an OOP approach, and C<Aion::Fs> is FP.

=over

=item * OOP - object-oriented programming.

=item * FP - functional programming.

=back

=head1 SUBROUTINES/METHODS

=head2 cat ($file)

Reads the file. If no parameter is specified, use C<$_>.

	cat "/etc/passwd"  # ~> root

C<cat> reads with layer C<:utf8>. But you can specify another layer like this:

	lay "unicode.txt", "↯";
	length cat "unicode.txt"            # -> 1
	length cat["unicode.txt", ":raw"]   # -> 3

C<cat> throws an exception if the I/O operation fails:

	eval { cat "A" }; $@  # ~> cat A: No such file or directory

B<Cm. Also:>

=over

=item * <File::Slurp> - C<read_file('file.txt')>.

=item * <File::Slurper> - C<read_text('file.txt')>, C<read_binary('file.txt')>.

=item * <IO::All> - C<< io('file.txt') E<gt> $contents >>.

=item * <IO::Util> - C<$contents = ${ slurp 'file.txt' }>.

=item * <File::Util> - C<< File::Util-E<gt>new-E<gt>load_file(file =E<gt> 'file.txt') >>.

=back

=head2 lay ($file?, $content)

Writes C<$content> to C<$file>.

=over

=item * If one parameter is specified, use C<$_> instead of C<$file>.

=item * C<lay>, uses the C<:utf8> layer. To specify a different layer, use an array of two elements in the C<$file> parameter:

=back

	lay "unicode.txt", "↯"  # => unicode.txt
	lay ["unicode.txt", ":raw"], "↯"  # => unicode.txt
	
	eval { lay "/", "↯" }; $@ # ~> lay /: Is a directory

B<Cm. Also:>

=over

=item * <File::Slurp> - C<write_file('file.txt', $contents)>.

=item * <File::Slurper> - C<write_text('file.txt', $contents)>, C<write_binary('file.txt', $contents)>.

=item * <IO::All> - C<< io('file.txt') E<lt> $contents >>.

=item * <IO::Util> - C<slurp \$contents, 'file.txt'>.

=item * <File::Util> - C<< File::Util-E<gt>new-E<gt>write_file(file =E<gt> 'file.txt', content =E<gt> $contents, bitmask =E<gt> 0644) >>.

=back

=head2 find (;$path, @filters)

Recursively traverses and returns paths from the specified path or paths if C<$path> is an array reference. Without parameters, uses C<$_> as C<$path>.

Filters can be:

=over

=item * By subroutine - the path to the current file is passed to C<$_>, and the subroutine must return true or false, as understood by Perl.

=item * Regexp - tests each path with a regular expression.

=item * String in the form "-Xxx", where C<Xxx> is one or more characters. Similar to Perl operators for testing files. Example: C<-fr> checks the path with file testers LLL<https://perldoc.perl.org/functions/-X>.

=item * The remaining lines are turned by the C<wildcard> function (see below) into a regular expression to test each path.

=back

Paths that fail the C<@filters> check are not returned.

If the -X filter is not a perl file function, an exception is thrown:

	eval { find "example", "-h" }; $@   # ~> Undefined subroutine &Aion::Fs::h called

In this example, C<find> cannot enter the subdirectory and passes an error to the C<errorenter> function (see below) with the C<$_> and C<$!> variables set (to the directory path and the OS error message).

B<Attention!> If C<errorenter> is not specified, then all errors are B<ignored>!

	mkpath ["example/", 0];
	
	[find "example"]                  # --> ["example"]
	[find "example", noenter "-d"]    # --> ["example"]
	
	eval { find "example", errorenter { die "find $_: $!" } }; $@   # ~> find example: Permission denied
	
	mkpath for qw!ex/1/11 ex/1/12 ex/2/21 ex/2/22!;
	
	my $count = 0;
	find "ex", sub { find_stop if ++$count == 3; 1}  # -> 2

B<Cm. Also:>

=over

=item * <AudioFile::Find> - searches for audio files in the specified directory. Allows you to filter them by attributes: title, artist, genre, album and track.

=item * <Directory::Iterator> - C<< $it = Directory::Iterator-E<gt>new($dir, %opts); push @paths, $_ while E<lt>$itE<gt> >>.

=item * <IO::All> - C<< @paths = map { "$_" } grep { -f $_ && $_-E<gt>size E<gt> 10*1024 } io(".")-E<gt>all(0) >>.

=item * <IO::All::Rule> - C<< $next = IO::All::Rule-E<gt>new-E<gt>file-E<gt>size("E<gt>10k")-E<gt>iter($dir1, $dir2); push @paths, "$f" while $f = $next-E<gt>() >>.

=item * <File::Find> - C<find( sub { push @paths, $File::Find::name if /\.png/ }, $dir )>.

=item * <File::Find::utf8> - like <File::Find>, only file paths are in I<utf8>.

=item * <File::Find::Age> - sorts files by modification time (inherits <File::Find::Rule>): C<< File::Find::Age-E<gt>in($dir1, $dir2) >>.

=item * <File::Find::Declare> — C<< @paths = File::Find::Declare-E<gt>new({ size =E<gt> 'E<gt>10K', perms =E<gt> 'wr-wr-wr-', modified =E<gt> 'E<lt>2010-01-30', recurse =E<gt> 1, dirs =E<gt> [$dir1] })-E<gt>find >>.

=item * <File::Find::Iterator> - has an OOP interface with an iterator and the C<imap> and C<igrep> functions.

=item * <File::Find::Match> - calls a handler for each matching filter. Similar to C<switch>.

=item * <File::Find::Node> - traverses the file hierarchy in parallel by several processes: C<< tie @paths, IPC::Shareable, { key =E<gt> "GLUE STRING", create =E<gt> 1 }; File::Find::Node-E<gt>new(".")-E<gt>process(sub { my $f = shift; $f-E<gt>fork(5); tied(@paths)-E<gt>lock; push @paths, $ f-E<gt>path; tied(@paths)-E<gt>unlock })-E<gt>find; tied(@paths)-E<gt>remove >>.

=item * <File::Find::Fast> - C<@paths = @{ find($dir) }>.

=item * <File::Find::Object> - has an OOP interface with an iterator.

=item * <File::Find::Parallel> - can compare two directories and return their union, intersection and quantitative intersection.

=item * <File::Find::Random> - selects a file or directory at random from the file hierarchy.

=item * <File::Find::Rex> - C<< @paths = File::Find::Rex-E<gt>new(recursive =E<gt> 1, ignore_hidden =E<gt> 1)-E<gt>query($dir, qr/^b/i) >>.

=item * <File::Find::Rule> — C<< @files = File::Find::Rule-E<gt>any( File::Find::Rule-E<gt>file-E<gt>name('*.mp3', '*.ogg ')-E<gt>size('E<gt>2M'), File::Find::Rule-E<gt>empty )-E<gt>in($dir1, $dir2); >>. Has an iterator, procedural interface, and L<File::Find::Rule::ImageSize> and L<File::Find::Rule::MMagic> extensions: C<< @images = find(file =E<gt> magic =E<gt> 'image/*', '!image_x' =E<gt> 'E<gt>20', in =E<gt> '.') >>.

=item * <File::Find::Wanted> - C<@paths = find_wanted( sub { -f && /\.png/ }, $dir )>.

=item * <File::Hotfolder> - C<< watch( $dir, callback =E<gt> sub { push @paths, shift } )-E<gt>loop >>. Powered by C<AnyEvent>. Customizable. There is parallelization into several processes.

=item * <File::Mirror> - also forms a parallel path for copying files: C<recursive { my ($src, $dst) = @_; push @paths, $src } '/path/A', '/path/B'>.

=item * <File::Set> - C<< $fs = File::Set-E<gt>new; $fs-E<gt>add($dir); @paths = map { $_-E<gt>[0] } $fs-E<gt>get_path_list >>.

=item * <File::Wildcard> — C<< $fw = File::Wildcard-E<gt>new(exclude =E<gt> qr/.svn/, case_insensitive =E<gt> 1, sort =E<gt> 1, path =E<gt> "src///*.cpp ", match =E<gt> qr(^src/(.*?)\.cpp$), derive =E<gt> ['src/$1.o','src/$1.hpp']); push @paths, $f while $f = $fw-E<gt>next >>.

=item * <File::Wildcard::Find> - C<findbegin($dir); push @paths, $f while $f = findnext()> or C<findbegin($dir); @paths = findall()>.

=item * <File::Util> - C<< File::Util-E<gt>new-E<gt>list_dir($dir, qw/ --pattern=\.txt$ --files-only --recurse /) >>.

=item * <Path::Find> - C<@paths = path_find( $dir, "*.png" )>. For complex queries, use I<matchable>: C<< my $sub = matchable( sub { my( $entry, $directory, $fullname, $depth ) = @_; $depth E<lt>= 3 } >>.

=item * <Path::Extended::Dir> - C<< @paths = Path::Extended::Dir-E<gt>new($dir)-E<gt>find('*.txt') >>.

=item * <Path::Iterator::Rule> - C<< $i = Path::Iterator::Rule-E<gt>new-E<gt>file; @paths = $i-E<gt>clone-E<gt>size("E<gt>10k")-E<gt>all(@dirs); $i-E<gt>size("E<lt>10k")... >>.

=item * <Path::Class::Each> - C<< dir($dir)-E<gt>each(sub { push @paths, "$_" }) >>.

=item * <Path::Class::Iterator> - C<< $i = Path::Class::Iterator-E<gt>new(root =E<gt> $dir, depth =E<gt> 2); until ($i-E<gt>done) { push @paths, $i-E<gt>next-E<gt>stringify } >>.

=item * <Path::Class::Rule> - C<< @paths = Path::Class::Rule-E<gt>new-E<gt>file-E<gt>size("E<gt>10k")-E<gt>all($dir) >>.

=back

=head2 noenter (@filters)

Tells C<find> not to enter directories matching the filters behind it.

=head2 errorenter (&block)

Calls C<&block> for every error that occurs when a directory cannot be entered.

=head2 find_stop ()

Stops C<find> being called in one of its filters, C<errorenter> or C<noenter>.

	my $count = 0;
	find "ex", sub { find_stop if ++$count == 3; 1}  # -> 2

=head2 erase (@paths)

Removes files and empty directories. Returns C<@paths>. If there is an I/O error, it throws an exception.

	eval { erase "/" }; $@  # ~> erase dir /: Device or resource busy
	eval { erase "/dev/null" }; $@  # ~> erase file /dev/null: Permission denied

B<Cm. Also:>

=over

=item * <unlink> + <rmdir>.

=item * <File::Path> - C<remove_tree("dir")>.

=item * <File::Path::Tiny> - C<File::Path::Tiny::rm($path)>. Does not throw exceptions.

=back

=head2 replace (&sub, @files)

Replaces each file with C<$_> if it is modified by C<&sub>. Returns files that have no replacements.

C<@files> can contain arrays of two elements. The first is treated as a path and the second as a layer. The default layer is C<:utf8>.

C<&sub> is called for each file in C<@files>. It transmits:

=over

=item * C<$_> - file contents.

=item * C<$a> — path to the file.

=item * C<$b> — the layer by which the file was read and by which it will be written.

=back

In the example below, the file "replace.ex" is read by the C<:utf8> layer and written by the C<:raw> layer in the C<replace> function:

	local $_ = "replace.ex";
	lay "abc";
	replace { $b = ":utf8"; y/a/¡/ } [$_, ":raw"];
	cat  # => ¡bc

B<Cm. Also:>

=over

=item * <File::Edit>.

=item * <File::Edit::Portable>.

=item * <File::Replace>.

=item * <File::Replace::Inplace>.

=back

=head2 mkpath (;$path)

Like B<mkdir -p>, but considers the last part of the path (after the last slash) to be a filename and does not create it as a directory. Without a parameter, uses C<$_>.

=over

=item * If C<$path> is not specified, use C<$_>.

=item * If C<$path> is an array reference, then the path is used as the first element and rights as the second element.

=item * The default permission is C<0755>.

=item * Returns C<$path>.

=back

	local $_ = ["A", 0755];
	mkpath   # => A
	
	eval { mkpath "/A/" }; $@   # ~> mkpath /A: Permission denied
	
	mkpath "A///./file";
	-d "A"  # -> 1

B<Cm. Also:>

=over

=item * <File::Path> - C<mkpath("dir1/dir2")>.

=item * <File::Path::Tiny> - C<File::Path::Tiny::mk($path)>. Does not throw exceptions.

=back

=head2 mtime (;$path)

Modification time of C<$path> in unixtime with fractional part (from C<Time::HiRes::stat>). Without a parameter, uses C<$_>.

Throws an exception if the file does not exist or does not have permission:

	local $_ = "nofile";
	eval { mtime }; $@  # ~> mtime nofile: No such file or directory
	
	mtime ["/"]   # ~> ^\d+(\.\d+)?$

B<Cm. Also:>

=over

=item * C<-M> — C<-M "file.txt">, C<-M _> in days from the current time.

=item * <stat> - C<(stat "file.txt")[9]> in seconds (unixtime).

=item * <Time::HiRes> - C<(Time::HiRes::stat "file.txt")[9]> in seconds with fractional part.

=back

=head2 sta (;$path)

Returns statistics about the file. Without a parameter, uses C<$_>.

To be used with other file functions, it can receive a reference to an array from which it takes the first element as the file path.

Throws an exception if the file does not exist or does not have permission:

	local $_ = "nofile";
	eval { sta }; $@  # ~> sta nofile: No such file or directory
	
	sta(["/"])->{ino} # ~> ^\d+$ 
	sta(".")->{atime} # ~> ^\d+(\.\d+)?$

B<Cm. Also:>

=over

=item * <Fcntl> – contains constants for mode recognition.

=item * <BSD::stat> - optionally returns atime, ctime and mtime in nanoseconds, user flags and file generation number. Has an OOP interface.

=item * <File::chmod> – C<chmod("o=,g-w","file1","file2")>, C<@newmodes = getchmod("+x","file1","file2")>.

=item * <File::stat> – provides an OOP interface to stat.

=item * <File::Stat::Bits> – similar to <Fcntl>.

=item * <File::stat::Extra> – extends <File::stat> with methods to obtain information about the mode, and also reloads B<-X>, B<< <=> >>, B<cmp> and B<~~> operators and stringified.

=item * <File::Stat::Ls> – returns the mode in the format of the ls utility.

=item * <File::Stat::Moose> – OOP interface for Moose.

=item * <File::Stat::OO> – provides an OOP interface to stat. Can return atime, ctime and mtime at once in C<DateTime>.

=item * <File::Stat::Trigger> – monitors changes in file attributes.

=item * <Linux::stat> – parses /proc/stat and returns additional information. However, it does not work on other OSes.

=item * <Stat::lsMode> – returns the mode in the format of the ls utility.

=item * <VMS::Stat> – returns VMS ACLs.

=back

=head2 path (;$path)

Splits a file path into its components or assembles it from its components.

=over

=item * If it receives a reference to an array, it treats its first element as a path.

=item * If it receives a link to a hash, it collects a path from it. Unfamiliar keys are simply ignored. Also ignores volume on UNIX.

=item * The file system is not accessed.

=back

	path "."       # --> {path => ".", volume => undef, dir => undef, file => ".", name => undef, ext => undef}
	path ["/"]     # --> {path => "/", volume => undef, dir => "/", file => undef, name => undef, ext => undef}
	local $_ = "";
	path           # --> {path => "", volume => undef, dir => undef, file => undef, name => undef, ext => undef}
	path "a/b/c.ext.ly"   # --> {path => "a/b/c.ext.ly", volume => undef, dir => "a/b", file => "c.ext.ly", name => "c", ext => "ext.ly"}
	
	path +{dir  => "/", ext => "ext.ly"}    # => /.ext.ly
	path +{file => "b.c", ext => "ly"}      # => b.ly
	path +{path => "a/b/f.c", dir => "m"}   # => m/f.c
	
	local $_ = +{path => "a/b/f.c", dir => undef, ext => undef};
	path             # => a/b/f.c
	path +{path => "a/b/f.c", volume => "/x", dir => "m/y", file => "f.y", name => "j", ext => "ext"} # => m/y/j.ext
	path +{path => "a/b/f.c", volume => "/x", dir =>  "/y", file => "f.y", name => "j", ext => "ext"} # => /y/j.ext

B<Cm. Also:>

=over

=item * <File::Spec> – C<< ($volume, $directories, $file) = File::Spec-E<gt>splitpath($path) >>.

=item * <File::Basename> – C<($name, $path, $suffix) = fileparse($fullname, @suffixlist)>.

=item * <Path::Class::File> – C<< file('foo', 'bar.txt')-E<gt>is_absolute >>.

=item * <Path::Extended::File> – C<< Path::Extended::File-E<gt>new('path/to/file')-E<gt>basename >>.

=item * <Parse::Path> – C<< Parse::Path-E<gt>new(path =E<gt> 'gophers[0].food.count', style =E<gt> 'DZIL')-E<gt>push("chunk") >>. Works with paths as with arrays (C<push>, C<pop>, C<shift>, C<splice>). It also overloads comparison operators. It has styles: C<DZIL>, C<File::Unix>, C<File::Win32>, C<PerlClass> and C<PerlClassUTF8>.

=back

=head2 include (;$pkg)

Connects C<$pkg> (if it has not already been connected via C<use> or C<require>) and returns it. Without a parameter, uses C<$_>.

lib/A.pm file:

	package A;
	sub new { bless {@_}, shift }
	1;

lib/N.pm file:

	package N;
	sub ex { 123 }
	1;



	use lib "lib";
	include("A")->new               # ~> A=HASH\(0x\w+\)
	[map include, qw/A N/]          # --> [qw/A N/]
	{ local $_="N"; include->ex }   # -> 123

=head2 catonce (;$file)

Reads the file for the first time. Any subsequent attempt to read this file returns C<undef>. Used to insert js and css modules into the resulting file. Without a parameter, uses C<$_>.

=over

=item * C<$file> can contain arrays of two elements. The first is treated as a path and the second as a layer. The default layer is C<:utf8>.

=item * If C<$file> is not specified, use C<$_>.

=back

	local $_ = "catonce.txt";
	lay "result";
	catonce  # -> "result"
	catonce  # -> undef
	
	eval { catonce[] }; $@ # ~> catonce not use ref path!

=head2 wildcard (;$wildcard)

Converts a file mask to a regular expression. Without a parameter, uses C<$_>.

=over

=item * C<**> - C<[^/]*>

=item * C<*> - C<.*>

=item * C<?> - C<.>

=item * C<??> - C<[^/]>

=item * C<{> - C<(>

=item * C<}> - C<)>

=item * C<,> - C<|>

=item * Other characters are escaped using C<quotemeta>.

=back

	wildcard "*.{pm,pl}"  # \> (?^usn:^.*?\.(pm|pl)$)
	wildcard "?_??_**"  # \> (?^usn:^._[^/]_[^/]*?$)

Used in filters of the C<find> function.

B<Cm. Also:>

=over

=item * <File::Wildcard>.

=item * <String::Wildcard::Bash>.

=item * <Text::Glob> - C<glob_to_regex("*.{pm,pl}")>.

=back

=head2 goto_editor ($path, $line)

Opens the file in the editor from .config at the specified line. Defaults to C<vscodium %p:%l>.

.config.pm file:

	package config;
	
	config_module 'Aion::Fs' => {
	    EDITOR => 'echo %p:%l > ed.txt',
	};
	
	1;



	goto_editor "mypath", 10;
	cat "ed.txt"  # => mypath:10\n
	
	eval { goto_editor "`", 1 }; $@  # ~> `:1 --> 512

=head2 from_pkg (;$pkg)

Transfers the packet to the FS path. Without a parameter, uses C<$_>.

	from_pkg "Aion::Fs"  # => Aion/Fs.pm
	[map from_pkg, "Aion::Fs", "A::B::C"]  # --> ["Aion/Fs.pm", "A/B/C.pm"]

=head2 to_pkg (;$path)

Translates the path from the FS to the package. Without a parameter, uses C<$_>.

	to_pkg "Aion/Fs.pm"  # => Aion::Fs
	[map to_pkg, "Aion/Fs.md", "A/B/C.md"]  # --> ["Aion::Fs", "A::B::C"]

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Fs is copyright © 2023 by Yaroslav O. Kosmina. Rusland. All rights reserved.
