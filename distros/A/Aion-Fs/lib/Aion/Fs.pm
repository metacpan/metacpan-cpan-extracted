package Aion::Fs;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.6";

use Exporter qw/import/;
use Scalar::Util qw//;
use Time::HiRes qw//;

our @EXPORT = our @EXPORT_OK = grep {
	ref \$Aion::Fs::{$_} eq "GLOB" && *{$Aion::Fs::{$_}}{CODE} && !/^(?:_|(NaN|import)\z)/
} keys %Aion::Fs::;


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
	my ($pkg) = @_;
	$pkg = $_ if @_ == 0;
	return $pkg if $pkg->can("new");
	my $path = from_pkg $pkg;
	return $pkg if exists $INC{$path};
	require $path;
	$pkg
}

# как mkdir -p
use constant FILE_EXISTS => 17;
use constant DIR_DEFAULT_PERMISSION => 0755;
sub mkpath (;$) {
	my ($path) = @_;
	$path = $_ if @_ == 0;
	my $permission;
	($path, $permission) = @$path if ref $path;
	$permission = DIR_DEFAULT_PERMISSION unless Scalar::Util::looks_like_number $permission;
	while($path =~ m!/!g) {
		mkdir $`, $permission
			or ($! != FILE_EXISTS? die "mkpath $`: $!": ())
				if $` ne '';
	}
	undef $!;
	$path
}

# Считывает файл
sub cat(;$) {
    my ($file) = @_;
	$file = $_ if @_ == 0;
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
	my ($file) = @_;
	$file = $_ if @_ == 0;
	die "catonce not use ref path!" if ref $file;
	return undef if exists $FILE_INC{$file};
	$FILE_INC{$file} = 1;
	cat $file
}

# Вернуть время модификации файла
sub mtime(;$) {
	my ($file) = @_;
	$file = $_ if @_ == 0;
	($file) = @$file if ref $file;
	(Time::HiRes::stat $file)[9] // die "mtime $file: $!"
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
sub find($;@) {
	my $file = shift;
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

	my @ret;
	local $_;

    FILE: while(@$file) {
		$_ = shift @$file;

		for my $filter (@filters) {
			goto DIR unless $filter->();
		}

		push @ret, $_;

		DIR: if(-d) {
			for my $noenter (@noenters) {
				next FILE if $noenter->();
			}

			opendir my $dir, $_ or do { $errorenter->(); next FILE };
			my @file;
			while(my $f = readdir $dir) {
				push @file, "$_/$f" if $f !~ /^\.{1,2}\z/;
			}
			push @$file, sort @file;
			closedir $dir;
		}
	}
	@ret
}

# Не входить в подкаталоги
sub noenter(@) {
	bless [@_], "Aion::Fs::noenter"
}

# Вызывается для всех ошибок ввода-вывода
sub errorenter(&) {
	bless shift, "Aion::Fs::errorenter"
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
		if($file ne $_) { lay [$$aref, $$bref], $_ } else { push @noreplace, $$aref }
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

Aion::Fs - utilities for filesystem: read, write, find, replace files, etc

=head1 VERSION

0.0.6

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
	            errorenter { die "find $_: $!" };
	
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

This module provide light entering to filesystem.

Modules C<File::Path>, C<File::Slurper> and
C<File::Find> are quite weighted with various features that are rarely used, but take time to get acquainted and, thereby, increases the entry threshold.

In C<Aion::Fs> used the programming principle KISS - Keep It Simple, Stupid.

Supermodule C<IO::All> provide OOP, and C<Aion::Fs> provide FP.

=over

=item * OOP - object oriented programming.

=item * FP - functional programming.

=back

=head1 SUBROUTINES/METHODS

=head2 cat ($file)

Read file. If file not specified, then use C<$_>.

	cat "/etc/passwd"  # ~> root

C<cat> read with layer C<:utf8>. But you can set the level like this:

	lay "unicode.txt", "↯";
	length cat "unicode.txt"            # -> 1
	length cat["unicode.txt", ":raw"]   # -> 3

C<cat> raise exception by error on io operation:

	eval { cat "A" }; $@  # ~> cat A: No such file or directory

B<See also:>

=over

=item * <File::Slurp> — C<read_file('file.txt')>.

=item * <File::Slurper> — C<read_text('file.txt')>, C<read_binary('file.txt')>.

=item * <IO::All> — C<< io('file.txt') E<gt> $contents >>.

=back

=head2 lay ($file, $content)

Write C<$content> in C<$file>.

=over

=item * If one parameter specified, then use C<$_> as C<$file>.

=item * C<lay> using layer C<:utf8>. For set layer using two elements array for C<$file>:

=back

	lay "unicode.txt", "↯"  # => unicode.txt
	lay ["unicode.txt", ":raw"], "↯"  # => unicode.txt
	
	eval { lay "/", "↯" }; $@ # ~> lay /: Is a directory

B<See also:>

=over

=item * <File::Slurp> — C<write_file('file.txt', $contents)>.

=item * <File::Slurper> — C<write_text('file.txt', $contents)>, C<write_binary('file.txt', $contents)>.

=item * <IO::All> — C<< io('file.txt') E<lt> $contents >>.

=back

=head2 find ($path, @filters)

Finded files and returns array paths from start path or paths if C<$path> is array ref.

Filters may be:

=over

=item * Subroutine - the each path fits to C<$_> and test with subroutine.

=item * Regexp - test the each path on the regexp.

=item * String as "-Xxx", where C<Xxx> - one or more symbols. Test on the perl file testers. Example "-fr" test the path on C<-f> and C<-r> file testers.

=item * Any string interpret function C<wildcard> to regexp and the each path test on it.

=back

The paths that have not passed testing by C<@filters> are not returned.

If filter -X is unused, then throw exception:

	eval { find "example", "-h" }; $@   # ~> Undefined subroutine &Aion::Fs::h called

If C<find> is impossible to enter the subdirectory, then call errorenter with set variable C<$_> and C<$!>.

	mkpath ["example/", 0];
	
	[find "example"]    # --> ["example"]
	[find "example", noenter "-d"]    # --> ["example"]
	
	eval { find "example", errorenter { die "find $_: $!" } }; $@   # ~> find example: Permission denied

B<See also:>

=over

=item * <File::Find> — C<find(sub { push @paths, $File::Find::name }, $dir)>.

=back

=head2 noenter (@filters)

No enter to catalogs. Using in C<find>. C<@filters> same as in C<find>.

=head2 errorenter (&block)

Call C<&block> for each error on open catalog.

=head2 erase (@paths)

Remove files and empty catalogs. Returns the C<@paths>.

	eval { erase "/" }; $@  # ~> erase dir /: Device or resource busy
	eval { erase "/dev/null" }; $@  # ~> erase file /dev/null: Permission denied

B<See also:>

=over

=item * <unlink>.

=item * <File::Path> — C<remove_tree("dir")>.

=back

=head2 mkpath ($path)

As B<mkdir -p>, but consider last path-part (after last slash) as filename, and not create this catalog.

=over

=item * If C<$path> not specified, then use C<PATH>.

=item * If C<$path> is array ref, then use path as first and permission as second element.

=item * Default permission is C<0755>.

=item * Returns C<$path>.

=back

	local $_ = ["A", 0755];
	mkpath   # => A
	
	eval { mkpath "/A/" }; $@   # ~> mkpath /A: Permission denied
	
	mkpath "A///./file";
	-d "A"  # -> 1

B<See also:>

=over

=item * <File::Path> — C<mkpath("dir1/dir2")>.

=back

=head2 mtime ($file)

Time modification the C<$file> in unixtime in subsecond resolution (from Time::HiRes::stat).

Raise exeception if file not exists, or not permissions:

	local $_ = "nofile";
	eval { mtime }; $@  # ~> mtime nofile: No such file or directory
	
	mtime ["/"]   # ~> ^\d+(\.\d+)?$

B<See also:>

=over

=item * <-M> — C<-M "file.txt">, C<-M _> in days.

=item * <stat> — C<(stat "file.txt")[9]> in seconds.

=item * <Time::HiRes> — C<(Time::HiRes::stat "file.txt")[9]> in seconds with fractional part.

=back

=head2 replace (&sub, @files)

Replacing each the file if C<&sub> replace C<$_>. Returns files in which there were no replacements.

C<@files> can contain arrays of two elements. The first one is treated as a path, and the second one is treated as a layer. Default layer is C<:utf8>.

	local $_ = "replace.ex";
	lay "abc";
	replace { $b = ":utf8"; y/a/¡/ } [$_, ":raw"];
	cat  # => ¡bc

B<See also:>

=over

=item * <File::Edit>.

=item * <File::Edit::Portable>.

=back

=head2 include ($pkg)

Require C<$pkg> and returns it.

File lib/A.pm:

	package A;
	sub new { bless {@_}, shift }
	1;

File lib/N.pm:

	package N;
	sub ex { 123 }
	1;



	use lib "lib";
	include("A")->new               # ~> A=HASH\(0x\w+\)
	[map include, qw/A N/]          # --> [qw/A N/]
	{ local $_="N"; include->ex }   # -> 123

=head2 catonce ($file)

Read the file in first call with this file. Any call with this file return C<undef>. Using for insert js and css modules in the resulting file.

	local $_ = "catonce.txt";
	lay "result";
	catonce  # -> "result"
	catonce  # -> undef
	
	eval { catonce[] }; $@ # ~> catonce not use ref path!

=head2 wildcard ($wildcard)

Translate the wildcard to regexp.

=over

=item * C<**> - C<[^/]*>

=item * C<*> - C<.*>

=item * C<?> - C<.>

=item * C<??> - C<[^/]>

=item * C<{> - C<(>

=item * C<}> - C<)>

=item * C<,> - C<|>

=item * Any symbols translate by C<quotemeta>.

=back

	wildcard "*.{pm,pl}"  # \> (?^usn:^.*?\.(pm|pl)$)
	wildcard "?_??_**"  # \> (?^usn:^._[^/]_[^/]*?$)

Using in filters the function C<find>.

B<See also:>

=over

=item * <File::Wildcard>.

=item * <String::Wildcard::Bash>.

=back

=head2 goto_editor ($path, $line)

Open the file in editor from config on the line.

File .config.pm:

	package config;
	
	config_module 'Aion::Fs' => {
	    EDITOR => 'echo %p:%l > ed.txt',
	};
	
	1;



	goto_editor "mypath", 10;
	cat "ed.txt"  # => mypath:10\n
	
	eval { goto_editor "`", 1 }; $@  # ~> `:1 --> 512

Default the editor is C<vscodium>.

=head2 from_pkg (;$pkg)

From package to file path.

	from_pkg "Aion::Fs"  # => Aion/Fs.pm
	[map from_pkg, "Aion::Fs", "A::B::C"]  # --> ["Aion/Fs.pm", "A/B/C.pm"]

=head2 to_pkg (;$path)

From file path to package.

	to_pkg "Aion/Fs.pm"  # => Aion::Fs
	[map to_pkg, "Aion/Fs.md", "A/B/C.md"]  # --> ["Aion::Fs", "A::B::C"]

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Fs is copyright © 2023 by Yaroslav O. Kosmina. Rusland. All rights reserved.
