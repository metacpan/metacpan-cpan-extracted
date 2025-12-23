use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Fs - утилиты для файловой системы: чтение, запись, поиск, замена файлов и т.д.
# 
# # VERSION
# 
# 0.2.2
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Fs;

lay mkpath "hello/world.txt", "hi!";
lay mkpath "hello/moon.txt", "noreplace";
lay mkpath "hello/big/world.txt", "hellow!";
lay mkpath "hello/small/world.txt", "noenter";

::like scalar do {mtime "hello";}, qr{^\d+(\.\d+)?$}, 'mtime "hello";  # ~> ^\d+(\.\d+)?$'; undef $::_g0; undef $::_e0;

local ($::_g0 = do {[map cat, grep -f, find ["hello/big", "hello/small"]];}, $::_e0 = do {[qw/ hellow! noenter /]}); ::is_deeply $::_g0, $::_e0, '[map cat, grep -f, find ["hello/big", "hello/small"]];  # --> [qw/ hellow! noenter /]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my @noreplaced = replace { s/h/$a $b H/ }
    find "hello", "-f", "*.txt", qr/\.txt$/, sub { /\.txt$/ },
        noenter "*small*",
            errorenter { warn "find $_: $!" };

local ($::_g0 = do {\@noreplaced;}, $::_e0 = do {["hello/moon.txt"]}); ::is_deeply $::_g0, $::_e0, '\@noreplaced; # --> ["hello/moon.txt"]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {cat "hello/world.txt";}, $::_e0 = "hello/world.txt :utf8 Hi!"); ::ok $::_g0 eq $::_e0, 'cat "hello/world.txt";       # => hello/world.txt :utf8 Hi!' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {cat "hello/moon.txt";}, $::_e0 = "noreplace"); ::ok $::_g0 eq $::_e0, 'cat "hello/moon.txt";        # => noreplace' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {cat "hello/big/world.txt";}, $::_e0 = "hello/big/world.txt :utf8 Hellow!"); ::ok $::_g0 eq $::_e0, 'cat "hello/big/world.txt";   # => hello/big/world.txt :utf8 Hellow!' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {cat "hello/small/world.txt";}, $::_e0 = "noenter"); ::ok $::_g0 eq $::_e0, 'cat "hello/small/world.txt"; # => noenter' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {[find "hello", "*.txt"];}, $::_e0 = do {[qw!  hello/moon.txt  hello/world.txt  hello/big/world.txt  hello/small/world.txt  !]}); ::is_deeply $::_g0, $::_e0, '[find "hello", "*.txt"]; # --> [qw!  hello/moon.txt  hello/world.txt  hello/big/world.txt  hello/small/world.txt  !]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my @dirs;

my $iter = find "hello", "-d";

while(<$iter>) {
    push @dirs, $_;
}

local ($::_g0 = do {\@dirs;}, $::_e0 = do {[qw!  hello  hello/big hello/small  !]}); ::is_deeply $::_g0, $::_e0, '\@dirs; # --> [qw!  hello  hello/big hello/small  !]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

erase reverse find "hello";

local ($::_g0 = do {-e "hello";}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-e "hello";  # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Этот модуль облегчает использование файловой системы.
# 
# Модули `File::Path`, `File::Slurper` и
# `File::Find` обременены различными возможностями, которые используются редко, но требуют времени на ознакомление и тем самым повышают порог входа.
# 
# В `Aion::Fs` же использован принцип программирования KISS - чем проще, тем лучше!
# 
# Супермодуль `IO::All` не является конкурентом `Aion::Fs`, т.к. использует ООП подход, а `Aion::Fs` – ФП.
# 
# * ООП – объектно-ориентированное программирование.
# * ФП – функциональное программирование.
# 
# # SUBROUTINES/METHODS
# 
# ## cat ($file)
# 
# Считывает файл. Если параметр не указан, использует `$_`.
# 
::done_testing; }; subtest 'cat ($file)' => sub { 
::like scalar do {cat "/etc/passwd"}, qr{root}, 'cat "/etc/passwd"  # ~> root'; undef $::_g0; undef $::_e0;

# 
# `cat` читает со слоем `:utf8`. Но можно указать другой слой следующим образом:
# 

lay "unicode.txt", "↯";
local ($::_g0 = do {length cat "unicode.txt"}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'length cat "unicode.txt"            # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {length cat["unicode.txt", ":raw"]}, $::_e0 = do {3}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'length cat["unicode.txt", ":raw"]   # -> 3' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# `cat` вызывает исключение в случае ошибки операции ввода-вывода:
# 

::like scalar do {eval { cat "A" }; $@}, qr{cat A: No such file or directory}, 'eval { cat "A" }; $@  # ~> cat A: No such file or directory'; undef $::_g0; undef $::_e0;

# 
# ### See also
# 
# * [autodie](https://metacpan.org/pod/autodie) – `open $f, "r.txt"; $s = join "", <$f>; close $f`.
# * [File::Slurp](https://metacpan.org/pod/File::Slurp) – `read_file('file.txt')`.
# * [File::Slurper](https://metacpan.org/pod/File::Slurper) – `read_text('file.txt')`, `read_binary('file.txt')`.
# * [File::Util](https://metacpan.org/pod/File::Util) – `File::Util->new->load_file(file => 'file.txt')`.
# * [IO::All](https://metacpan.org/pod/IO::All) – `io('file.txt') > $contents`.
# * [IO::Util](https://metacpan.org/pod/IO::Util) – `$contents = ${ slurp 'file.txt' }`.
# * [Mojo::File](https://metacpan.org/pod/Mojo::File) – `path($file)->slurp`.
# 
# ## lay ($file?, $content)
# 
# Записывает `$content` в `$file`.
# 
# * Если указан один параметр, использует `$_` вместо `$file`.
# * `lay`, использует слой `:utf8`. Для указания иного слоя используется массив из двух элементов в параметре `$file`:
# 
::done_testing; }; subtest 'lay ($file?, $content)' => sub { 
local ($::_g0 = do {lay "unicode.txt", "↯"}, $::_e0 = "unicode.txt"); ::ok $::_g0 eq $::_e0, 'lay "unicode.txt", "↯"  # => unicode.txt' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {lay ["unicode.txt", ":raw"], "↯"}, $::_e0 = "unicode.txt"); ::ok $::_g0 eq $::_e0, 'lay ["unicode.txt", ":raw"], "↯"  # => unicode.txt' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

::like scalar do {eval { lay "/", "↯" }; $@}, qr{lay /: Is a directory}, 'eval { lay "/", "↯" }; $@ # ~> lay /: Is a directory'; undef $::_g0; undef $::_e0;

# 
# ### See also
# 
# * [autodie](https://metacpan.org/pod/autodie) – `open $f, ">r.txt"; print $f $contents; close $f`.
# * [File::Slurp](https://metacpan.org/pod/File::Slurp) – `write_file('file.txt', $contents)`.
# * [File::Slurper](https://metacpan.org/pod/File::Slurper) – `write_text('file.txt', $contents)`, `write_binary('file.txt', $contents)`.
# * [IO::All](https://metacpan.org/pod/IO::All) – `io('file.txt') < $contents`.
# * [IO::Util](https://metacpan.org/pod/IO::Util) – `slurp \$contents, 'file.txt'`.
# * [File::Util](https://metacpan.org/pod/File::Util) – `File::Util->new->write_file(file => 'file.txt', content => $contents, bitmask => 0644)`.
# * [Mojo::File](https://metacpan.org/pod/Mojo::File) – `path($file)->spew($chars, 'UTF-8')`.
# 
# ## find (;$path, @filters)
# 
# Рекурсивно обходит и возвращает пути из указанного пути или путей, если `$path` является ссылкой на массив. Без параметров использует `$_` как `$path`.
# 
# Фильтры могут быть:
# 
# * Подпрограммой – путь к текущему файлу передаётся в `$_`, а подпрограмма должна вернуть истину или ложь, как они понимаются perl-ом.
# * Regexp – тестирует каждый путь регулярным выражением.
# * Строка в виде "-Xxx", где `Xxx` – один или несколько символов. Аналогична операторам perl-а для тестирования файлов. Пример: `-fr` проверяет путь файловыми тестировщиками [-f и -r](https://perldoc.perl.org/functions/-X).
# * Остальные строки превращаются функцией `wildcard` (см. ниже) в регулярное выражение для проверки каждого пути.
# 
# Пути, не прошедшие проверку `@filters`, не возвращаются.
# 
# Если фильтр -X не является файловой функцией perl, то выбрасывается исключение:
# 
::done_testing; }; subtest 'find (;$path, @filters)' => sub { 
::like scalar do {eval { find "example", "-h" }; $@}, qr{Undefined subroutine &Aion::Fs::h called}, 'eval { find "example", "-h" }; $@   # ~> Undefined subroutine &Aion::Fs::h called'; undef $::_g0; undef $::_e0;

# 
# В этом примере `find` не может войти в подкаталог и передаёт ошибку в функцию `errorenter` (см. ниже) с установленными переменными `$_` и `$!` (путём к каталогу и сообщением ОС об ошибке). 
# 
# **Внимание!** Если `errorenter` не указана, то все ошибки **игнорируются**!
# 

mkpath ["example/", 0];

local ($::_g0 = do {[find "example"]}, $::_e0 = do {["example"]}); ::is_deeply $::_g0, $::_e0, '[find "example"]                  # --> ["example"]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[find "example", noenter "-d"]}, $::_e0 = do {["example"]}); ::is_deeply $::_g0, $::_e0, '[find "example", noenter "-d"]    # --> ["example"]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

::like scalar do {eval { find "example", errorenter { die "find $_: $!" } }; $@}, qr{find example: Permission denied}, 'eval { find "example", errorenter { die "find $_: $!" } }; $@   # ~> find example: Permission denied'; undef $::_g0; undef $::_e0;

mkpath for qw!ex/1/11 ex/1/12 ex/2/21 ex/2/22!;

my $count = 0;
find "ex", sub { find_stop if ++$count == 3; 1};
local ($::_g0 = do {$count}, $::_e0 = do {3}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$count # -> 3' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ### See also
# 
# * [AudioFile::Find](https://metacpan.org/pod/AudioFile::Find) – ищет аудиофайлы в указанной директории. Позволяет фильтровать их по атрибутам: названию, артисту, жанру, альбому и трэку.
# * [Directory::Iterator](https://metacpan.org/pod/Directory::Iterator) – `$it = Directory::Iterator->new($dir, %opts); push @paths, $_ while <$it>`.
# * [IO::All](https://metacpan.org/pod/IO::All) – `@paths = map { "$_" } grep { -f $_ && $_->size > 10*1024 } io(".")->all(0)`.
# * [IO::All::Rule](https://metacpan.org/pod/IO::All::Rule) – `$next = IO::All::Rule->new->file->size(">10k")->iter($dir1, $dir2); push @paths, "$f" while $f = $next->()`.
# * [File::Find](https://metacpan.org/pod/File::Find) – `find( sub { push @paths, $File::Find::name if /\.png/ }, $dir )`.
# * [File::Find::utf8](https://metacpan.org/pod/File::Find::utf8) – как [File::Find](https://metacpan.org/pod/File::Find), только пути файлов в _utf8_.
# * [File::Find::Age](https://metacpan.org/pod/File::Find::Age) – сортирует файлы по времени модификации (наследует [File::Find::Rule](https://metacpan.org/pod/File::Find::Rule)): `File::Find::Age->in($dir1, $dir2)`.
# * [File::Find::Declare](https://metacpan.org/pod/File::Find::Declare) – `@paths = File::Find::Declare->new({ size => '>10K', perms => 'wr-wr-wr-', modified => '<2010-01-30', recurse => 1, dirs => [$dir1] })->find`.
# * [File::Find::Iterator](https://metacpan.org/pod/File::Find::Iterator) – имеет ООП интерфейс с итератором и функции `imap` и `igrep`.
# * [File::Find::Match](https://metacpan.org/pod/File::Find::Match) – вызывает обработчик на каждый подошедший фильтр. Похож на `switch`.
# * [File::Find::Node](https://metacpan.org/pod/File::Find::Node) – обходит иерархию файлов параллельно несколькими процессами: `tie @paths, IPC::Shareable, { key => "GLUE STRING", create => 1 }; File::Find::Node->new(".")->process(sub { my $f = shift; $f->fork(5); tied(@paths)->lock; push @paths, $f->path; tied(@paths)->unlock })->find; tied(@paths)->remove`.
# * [File::Find::Fast](https://metacpan.org/pod/File::Find::Fast) – `@paths = @{ find($dir) }`.
# * [File::Find::Object](https://metacpan.org/pod/File::Find::Object) – имеет ООП интерфейс с итератором.
# * [File::Find::Parallel](https://metacpan.org/pod/File::Find::Parallel) – умеет сравнивать два каталога и возвращать их объединение, пересечение и количественное пересечение.
# * [File::Find::Random](https://metacpan.org/pod/File::Find::Random) – выбирает файл или директорию наугад из иерархии файлов.
# * [File::Find::Rex](https://metacpan.org/pod/File::Find::Rex) – `@paths = File::Find::Rex->new(recursive => 1, ignore_hidden => 1)->query($dir, qr/^b/i)`.
# * [File::Find::Rule](https://metacpan.org/pod/File::Find::Rule) – `@files = File::Find::Rule->any( File::Find::Rule->file->name('*.mp3', '*.ogg')->size('>2M'), File::Find::Rule->empty )->in($dir1, $dir2);`. Имеет итератор, процедурный интерфейс и расширения [::ImageSize](File::Find::Rule::ImageSize) и [::MMagic](File::Find::Rule::MMagic): `@images = find(file => magic => 'image/*', '!image_x' => '>20', in => '.')`.
# * [File::Find::Wanted](https://metacpan.org/pod/File::Find::Wanted) – `@paths = find_wanted( sub { -f && /\.png/ }, $dir )`.
# * [File::Hotfolder](https://metacpan.org/pod/File::Hotfolder) – `watch( $dir, callback => sub { push @paths, shift } )->loop`. Работает на `AnyEvent`. Настраиваемый. Есть распараллеливание на несколько процессов.
# * [File::Mirror](https://metacpan.org/pod/File::Mirror) – формирует так же параллельный путь для копирования файлов: `recursive { my ($src, $dst) = @_; push @paths, $src } '/path/A', '/path/B'`.
# * [File::Set](https://metacpan.org/pod/File::Set) – `$fs = File::Set->new; $fs->add($dir); @paths = map { $_->[0] } $fs->get_path_list`.
# * [File::Wildcard](https://metacpan.org/pod/File::Wildcard) – `$fw = File::Wildcard->new(exclude => qr/.svn/, case_insensitive => 1, sort => 1, path => "src///*.cpp", match => qr(^src/(.*?)\.cpp$), derive => ['src/$1.o','src/$1.hpp']); push @paths, $f while $f = $fw->next`.
# * [File::Wildcard::Find](https://metacpan.org/pod/File::Wildcard::Find) – `findbegin($dir); push @paths, $f while $f = findnext()` или  `findbegin($dir); @paths = findall()`.
# * [File::Util](https://metacpan.org/pod/File::Util) – `File::Util->new->list_dir($dir, qw/ --pattern=\.txt$ --files-only --recurse /)`.
# * [Mojo::File](https://metacpan.org/pod/Mojo::File) – `say for path($path)->list_tree({hidden => 1, dir => 1})->each`.
# * [Path::Find](https://metacpan.org/pod/Path::Find) – `@paths = path_find( $dir, "*.png" )`. Для сложных запросов использует _matchable_: `my $sub = matchable( sub { my( $entry, $directory, $fullname, $depth ) = @_; $depth <= 3 }`.
# * [Path::Extended::Dir](https://metacpan.org/pod/Path::Extended::Dir) – `@paths = Path::Extended::Dir->new($dir)->find('*.txt')`.
# * [Path::Iterator::Rule](https://metacpan.org/pod/Path::Iterator::Rule) – `$i = Path::Iterator::Rule->new->file; @paths = $i->clone->size(">10k")->all(@dirs); $i->size("<10k")...`.
# * [Path::Class::Each](https://metacpan.org/pod/Path::Class::Each) – `dir($dir)->each(sub { push @paths, "$_" })`.
# * [Path::Class::Iterator](https://metacpan.org/pod/Path::Class::Iterator) – `$i = Path::Class::Iterator->new(root => $dir, depth => 2); until ($i->done) { push @paths, $i->next->stringify }`.
# * [Path::Class::Rule](https://metacpan.org/pod/Path::Class::Rule) – `@paths = Path::Class::Rule->new->file->size(">10k")->all($dir)`.
# 
# ## noenter (@filters)
# 
# Говорит `find` не входить в каталоги соответствующие фильтрам за ним.
# 
# ## errorenter (&block)
# 
# Вызывает `&block` для каждой ошибки возникающей при невозможности войти в какой-либо каталог.
# 
# ## find_stop ()
# 
# Останавливает `find` будучи вызван в одном из его фильтров, `errorenter` или `noenter`.
# 
::done_testing; }; subtest 'find_stop ()' => sub { 
my $count = 0;
find "ex", sub { find_stop if ++$count == 3; 1};
local ($::_g0 = do {$count}, $::_e0 = do {3}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$count # -> 3' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## erase (@paths)
# 
# Удаляет файлы и пустые каталоги. Возвращает `@paths`. При ошибке ввода-вывода выбрасывает исключение.
# 
::done_testing; }; subtest 'erase (@paths)' => sub { 
::like scalar do {eval { erase "/" }; $@}, qr{erase dir /: Device or resource busy}, 'eval { erase "/" }; $@  # ~> erase dir /: Device or resource busy'; undef $::_g0; undef $::_e0;
::like scalar do {eval { erase "/dev/null" }; $@}, qr{erase file /dev/null: Permission denied}, 'eval { erase "/dev/null" }; $@  # ~> erase file /dev/null: Permission denied'; undef $::_g0; undef $::_e0;

# 
# ### See also
# 
# * `unlink` + `rmdir`.
# * [File::Path](https://metacpan.org/pod/File::Path) – `remove_tree("dir")`.
# * [File::Path::Tiny](https://metacpan.org/pod/File::Path::Tiny) – `File::Path::Tiny::rm($path)`. Не выбрасывает исключений.
# * [Mojo::File](https://metacpan.org/pod/Mojo::File) – `path($file)->remove`.
# 
# ## replace (&sub, @files)
# 
# Заменяет каждый файл на `$_`, если его изменяет `&sub`. Возвращает файлы, в которых не было замен.
# 
# `@files` может содержать массивы из двух элементов. Первый рассматривается как путь, а второй – как слой. Слой по умолчанию – `:utf8`.
# 
# `&sub` вызывается для каждого файла из `@files`. В неё передаются:
# 
# * `$_` – содержимое файла.
# * `$a` – путь к файлу.
# * `$b` – слой которым был считан файл и которым он будет записан.
# 
# В примере ниже файл "replace.ex" считывается слоем `:utf8`, а записывается слоем `:raw` в функции `replace`:
# 
::done_testing; }; subtest 'replace (&sub, @files)' => sub { 
local $_ = "replace.ex";
lay "abc";
replace { $b = ":utf8"; y/a/¡/ } [$_, ":raw"];
local ($::_g0 = do {cat}, $::_e0 = "¡bc"); ::ok $::_g0 eq $::_e0, 'cat  # => ¡bc' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ### See also
# 
# * [File::Edit](https://metacpan.org/pod/File::Edit) – `File::Edit->new($file)->replace('x', 'y')->save`.
# * [File::Edit::Portable](https://metacpan.org/pod/File::Edit::Portable) – `File::Edit::Portable->new->splice(file => $file, line => 10, contens => ["line1", "line2"])`.
# * [File::Replace](https://metacpan.org/pod/File::Replace) – `($infh,$outfh,$repl) = replace3($file); while (<$infh>) { print $outfh "X: $_" } $repl->finish`.
# * [File::Replace::Inplace](https://metacpan.org/pod/File::Replace::Inplace).
# 
# ## mkpath (;$path)
# 
# Как **mkdir -p**, но считает последнюю часть пути (после последней косой черты) именем файла и не создаёт её каталогом. Без параметра использует `$_`.
# 
# * Если `$path` не указан, использует `$_`.
# * Если `$path` является ссылкой на массив, тогда используется путь в качестве первого элемента и права в качестве второго элемента.
# * Права по умолчанию – `0755`.
# * Возвращает `$path`.
# 
::done_testing; }; subtest 'mkpath (;$path)' => sub { 
local $_ = ["A", 0755];
local ($::_g0 = do {mkpath}, $::_e0 = "A"); ::ok $::_g0 eq $::_e0, 'mkpath   # => A' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

::like scalar do {eval { mkpath "/A/" }; $@}, qr{mkpath /A: Permission denied}, 'eval { mkpath "/A/" }; $@   # ~> mkpath /A: Permission denied'; undef $::_g0; undef $::_e0;

mkpath "A///./file";
local ($::_g0 = do {-d "A"}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-d "A"  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ### See also
# 
# * [File::Path](https://metacpan.org/pod/File::Path) – `mkpath("dir1/dir2")`.
# * [File::Path::Tiny](https://metacpan.org/pod/File::Path::Tiny) – `File::Path::Tiny::mk($path)`. Не выбрасывает исключений.
# 
# ## mtime (;$path)
# 
# Время модификации `$path` в unixtime с дробной частью (из `Time::HiRes::stat`). Без параметра использует `$_`.
# 
# Выбрасывает исключение, если файл не существует или нет прав:
# 
::done_testing; }; subtest 'mtime (;$path)' => sub { 
local $_ = "nofile";
::like scalar do {eval { mtime }; $@}, qr{mtime nofile: No such file or directory}, 'eval { mtime }; $@  # ~> mtime nofile: No such file or directory'; undef $::_g0; undef $::_e0;

::like scalar do {mtime ["/"]}, qr{^\d+(\.\d+)?$}, 'mtime ["/"]   # ~> ^\d+(\.\d+)?$'; undef $::_g0; undef $::_e0;

# 
# ### See also
# 
# * `-M` – `-M "file.txt"`, `-M _` в днях от текущего времени.
# * [stat](https://metacpan.org/pod/stat) – `(stat "file.txt")[9]` в секундах (unixtime).
# * [Time::HiRes](https://metacpan.org/pod/Time::HiRes) – `(Time::HiRes::stat "file.txt")[9]` в секундах с дробной частью.
# * [Mojo::File](https://metacpan.org/pod/Mojo::File) – `path($file)->stat->mtime`.
# 
# ## sta (;$path)
# 
# Возвращает статистику о файле. Без параметра использует `$_`.
# 
# Чтобы можно было использовать с другими файловыми функциями, может получать ссылку на массив из которого берёт первый элемент в качестве файлового пути.
# 
# Выбрасывает исключение, если файл не существует или нет прав:
# 
::done_testing; }; subtest 'sta (;$path)' => sub { 
local $_ = "nofile";
::like scalar do {eval { sta }; $@}, qr{sta nofile: No such file or directory}, 'eval { sta }; $@  # ~> sta nofile: No such file or directory'; undef $::_g0; undef $::_e0;

::like scalar do {sta(["/"])->{ino}}, qr{^\d+$}, 'sta(["/"])->{ino} # ~> ^\d+$'; undef $::_g0; undef $::_e0;
::like scalar do {sta(".")->{atime}}, qr{^\d+(\.\d+)?$}, 'sta(".")->{atime} # ~> ^\d+(\.\d+)?$'; undef $::_g0; undef $::_e0;

# 
# ### See also
# 
# * [Fcntl](https://metacpan.org/pod/Fcntl) – содержит константы для распознавания режима.
# * [BSD::stat](https://metacpan.org/pod/BSD::stat) – дополнительно возвращает atime, ctime и mtime в наносекундах, флаги пользователя и номер генерации файла. Имеет ООП-интерфейс.
# * [File::chmod](https://metacpan.org/pod/File::chmod) – `chmod("o=,g-w","file1","file2")`, `@newmodes = getchmod("+x","file1","file2")`.
# * [File::stat](https://metacpan.org/pod/File::stat) – предоставляет ООП-интерфейс к stat.
# * [File::Stat::Bits](https://metacpan.org/pod/File::Stat::Bits) – аналогичен [Fcntl](https://metacpan.org/pod/Fcntl).
# * [File::stat::Extra](https://metacpan.org/pod/File::stat::Extra) – расширяет [File::stat](https://metacpan.org/pod/File::stat) методами для получения информации о режиме, а так же перезагружает **-X**, **<=>**, **cmp** и **~~** операторы и стрингифицируется.
# * [File::Stat::Ls](https://metacpan.org/pod/File::Stat::Ls) – возвращает режим в формате утилиты ls.
# * [File::Stat::Moose](https://metacpan.org/pod/File::Stat::Moose) – ООП интерфейс на Moose.
# * [File::Stat::OO](https://metacpan.org/pod/File::Stat::OO) – предоставляет ООП-интерфейс к stat. Может возвращать atime, ctime и mtime сразу в `DateTime`.
# * [File::Stat::Trigger](https://metacpan.org/pod/File::Stat::Trigger) – следилка за изменением атрибутов файла.
# * [Linux::stat](https://metacpan.org/pod/Linux::stat) – парсит /proc/stat и возвращает доп-информацию. Однако в других ОС не работает.
# * [Stat::lsMode](https://metacpan.org/pod/Stat::lsMode) – возвращает режим в формате утилиты ls.
# * [VMS::Stat](https://metacpan.org/pod/VMS::Stat) – возвращает списки VMS ACL.
# 
# ## path (;$path)
# 
# Разбивает файловый путь на составляющие или собирает его из составляющих.
# 
# * Если получает ссылку на массив, то воспринимает его первый элемент как путь.
# * Если получает ссылку на хэш, то собирает из него путь. Незнакомые ключи просто игнорирует. Набор ключей для каждой ФС – разный.
# * ФС берётся из системной переменной `$^O`.
# * К файловой системе не обращается.
# 
::done_testing; }; subtest 'path (;$path)' => sub { 
{
    local $^O = "freebsd";

local ($::_g0 = do {path "."}, $::_e0 = do {{path => ".", file => ".", name => "."}}); ::is_deeply $::_g0, $::_e0, '    path "."        # --> {path => ".", file => ".", name => "."}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path ".bashrc"}, $::_e0 = do {{path => ".bashrc", file => ".bashrc", name => ".bashrc"}}); ::is_deeply $::_g0, $::_e0, '    path ".bashrc"  # --> {path => ".bashrc", file => ".bashrc", name => ".bashrc"}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path ".bash.rc"}, $::_e0 = do {{path => ".bash.rc", file => ".bash.rc", name => ".bash", ext => "rc"}}); ::is_deeply $::_g0, $::_e0, '    path ".bash.rc"  # --> {path => ".bash.rc", file => ".bash.rc", name => ".bash", ext => "rc"}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path ["/"]}, $::_e0 = do {{path => "/", dir => "/"}}); ::is_deeply $::_g0, $::_e0, '    path ["/"]      # --> {path => "/", dir => "/"}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
    local $_ = "";
local ($::_g0 = do {path}, $::_e0 = do {{path => ""}}); ::is_deeply $::_g0, $::_e0, '    path            # --> {path => ""}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path "a/b/c.ext.ly"}, $::_e0 = do {{path => "a/b/c.ext.ly", dir => "a/b", file => "c.ext.ly", name => "c", ext => "ext.ly"}}); ::is_deeply $::_g0, $::_e0, '    path "a/b/c.ext.ly"   # --> {path => "a/b/c.ext.ly", dir => "a/b", file => "c.ext.ly", name => "c", ext => "ext.ly"}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path +{dir  => "/", ext => "ext.ly"}}, $::_e0 = "/.ext.ly"); ::ok $::_g0 eq $::_e0, '    path +{dir  => "/", ext => "ext.ly"}    # => /.ext.ly' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path +{file => "b.c", ext => "ly"}}, $::_e0 = "b.ly"); ::ok $::_g0 eq $::_e0, '    path +{file => "b.c", ext => "ly"}      # => b.ly' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path +{path => "a/b/f.c", dir => "m"}}, $::_e0 = "m/f.c"); ::ok $::_g0 eq $::_e0, '    path +{path => "a/b/f.c", dir => "m"}   # => m/f.c' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

    local $_ = +{path => "a/b/f.c", dir => undef, ext => undef};
local ($::_g0 = do {path}, $::_e0 = "f"); ::ok $::_g0 eq $::_e0, '    path # => f' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path +{path => "a/b/f.c", volume => "/x", dir => "m/y/", file => "f.y", name => "j", ext => "ext"}}, $::_e0 = "m/y//j.ext"); ::ok $::_g0 eq $::_e0, '    path +{path => "a/b/f.c", volume => "/x", dir => "m/y/", file => "f.y", name => "j", ext => "ext"} # => m/y//j.ext' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path +{path => "a/b/f.c", volume => "/x", dir => "/y", file => "f.y", name => "j", ext => "ext"}}, $::_e0 = "/y/j.ext"); ::ok $::_g0 eq $::_e0, '    path +{path => "a/b/f.c", volume => "/x", dir => "/y", file => "f.y", name => "j", ext => "ext"} # => /y/j.ext' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
}

{
    local $^O = "MSWin32"; # also os2, symbian and dos

local ($::_g0 = do {path "."}, $::_e0 = do {{path => ".", file => ".", name => "."}}); ::is_deeply $::_g0, $::_e0, '    path "."        # --> {path => ".", file => ".", name => "."}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path ".bashrc"}, $::_e0 = do {{path => ".bashrc", file => ".bashrc", name => ".bashrc"}}); ::is_deeply $::_g0, $::_e0, '    path ".bashrc"  # --> {path => ".bashrc", file => ".bashrc", name => ".bashrc"}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path "/"}, $::_e0 = do {{path => "\\", dir => "\\", folder => "\\"}}); ::is_deeply $::_g0, $::_e0, '    path "/"        # --> {path => "\\", dir => "\\", folder => "\\"}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path "\\"}, $::_e0 = do {{path => "\\", dir => "\\", folder => "\\"}}); ::is_deeply $::_g0, $::_e0, '    path "\\"       # --> {path => "\\", dir => "\\", folder => "\\"}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path ""}, $::_e0 = do {{path => ""}}); ::is_deeply $::_g0, $::_e0, '    path ""         # --> {path => ""}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path "a\\b\\c.ext.ly"}, $::_e0 = do {{path => "a\\b\\c.ext.ly", dir => "a\\b\\", folder => "a\\b", file => "c.ext.ly", name => "c", ext => "ext.ly"}}); ::is_deeply $::_g0, $::_e0, '    path "a\\b\\c.ext.ly"   # --> {path => "a\\b\\c.ext.ly", dir => "a\\b\\", folder => "a\\b", file => "c.ext.ly", name => "c", ext => "ext.ly"}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path +{dir  => "/", ext => "ext.ly"}}, $::_e0 = "\\.ext.ly"); ::ok $::_g0 eq $::_e0, '    path +{dir  => "/", ext => "ext.ly"}    # => \\.ext.ly' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path +{dir  => "\\", ext => "ext.ly"}}, $::_e0 = "\\.ext.ly"); ::ok $::_g0 eq $::_e0, '    path +{dir  => "\\", ext => "ext.ly"}   # => \\.ext.ly' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path +{file => "b.c", ext => "ly"}}, $::_e0 = "b.ly"); ::ok $::_g0 eq $::_e0, '    path +{file => "b.c", ext => "ly"}      # => b.ly' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path +{path => "a/b/f.c", dir => "m/r/"}}, $::_e0 = "m\\r\\f.c"); ::ok $::_g0 eq $::_e0, '    path +{path => "a/b/f.c", dir => "m/r/"}   # => m\\r\\f.c' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path +{path => "a/b/f.c", dir => undef, ext => undef}}, $::_e0 = "f"); ::ok $::_g0 eq $::_e0, '    path +{path => "a/b/f.c", dir => undef, ext => undef} # => f' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path +{path => "a/b/f.c", volume => "x", dir => "m/y/", file => "f.y", name => "j", ext => "ext"}}, $::_e0 = 'x:m\y\j.ext'); ::ok $::_g0 eq $::_e0, '    path +{path => "a/b/f.c", volume => "x", dir => "m/y/", file => "f.y", name => "j", ext => "ext"} # \> x:m\y\j.ext' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path +{path => "x:/a/b/f.c", volume => undef, dir =>  "/y/", file => "f.y", name => "j", ext => "ext"}}, $::_e0 = '\y\j.ext'); ::ok $::_g0 eq $::_e0, '    path +{path => "x:/a/b/f.c", volume => undef, dir =>  "/y/", file => "f.y", name => "j", ext => "ext"} # \> \y\j.ext' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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

local ($::_g0 = do {path "Work1:Documents/Letters/Letter1.txt"}, $::_e0 = do {$path}); ::is_deeply $::_g0, $::_e0, '    path "Work1:Documents/Letters/Letter1.txt" # --> $path' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path {volume => "Work", file => "Letter1.pm", ext => "txt"}}, $::_e0 = "Work:Letter1.txt"); ::ok $::_g0 eq $::_e0, '    path {volume => "Work", file => "Letter1.pm", ext => "txt"} # => Work:Letter1.txt' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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

local ($::_g0 = do {path "/cygdrive/c/Documents/Letters/Letter1.txt"}, $::_e0 = do {$path}); ::is_deeply $::_g0, $::_e0, '    path "/cygdrive/c/Documents/Letters/Letter1.txt" # --> $path' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path {volume => "c", file => "Letter1.pm", ext => "txt"}}, $::_e0 = "/cygdrive/c/Letter1.txt"); ::ok $::_g0 eq $::_e0, '    path {volume => "c", file => "Letter1.pm", ext => "txt"} # => /cygdrive/c/Letter1.txt' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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

local ($::_g0 = do {path 'c:\Documents\Letters\Letter1.txt'}, $::_e0 = do {$path}); ::is_deeply $::_g0, $::_e0, '    path \'c:\Documents\Letters\Letter1.txt\' # --> $path' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path {volume => "c", file => "Letter1.pm", ext => "txt"}}, $::_e0 = 'c:Letter1.txt'); ::ok $::_g0 eq $::_e0, '    path {volume => "c", file => "Letter1.pm", ext => "txt"} # \> c:Letter1.txt' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path {dir => 'r\t\\',  file => "Letter1",    ext => "txt"}}, $::_e0 = 'r\t\Letter1.txt'); ::ok $::_g0 eq $::_e0, '    path {dir => \'r\t\\\',  file => "Letter1",    ext => "txt"} # \> r\t\Letter1.txt' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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

local ($::_g0 = do {path "DISK:[DIRECTORY.SUBDIRECTORY]FILENAME.EXTENSION";}, $::_e0 = do {$path}); ::is_deeply $::_g0, $::_e0, '    path "DISK:[DIRECTORY.SUBDIRECTORY]FILENAME.EXTENSION"; # --> $path' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

local ($::_g0 = do {path 'NODE["account password"]::DISK$USER:[DIRECTORY.SUBDIRECTORY]FILENAME.EXTENSION;7'}, $::_e0 = do {$path}); ::is_deeply $::_g0, $::_e0, '    path \'NODE["account password"]::DISK$USER:[DIRECTORY.SUBDIRECTORY]FILENAME.EXTENSION;7\' # --> $path' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path {volume => "DISK:", file => "FILENAME.pm", ext => "EXTENSION"}}, $::_e0 = "DISK:FILENAME.EXTENSION"); ::ok $::_g0 eq $::_e0, '    path {volume => "DISK:", file => "FILENAME.pm", ext => "EXTENSION"} # => DISK:FILENAME.EXTENSION' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path {user => "USER", folder => "DIRECTORY.SUBDIRECTORY", file => "FILENAME.pm", ext => "EXTENSION"}}, $::_e0 = '$USER:[DIRECTORY.SUBDIRECTORY]FILENAME.EXTENSION'); ::ok $::_g0 eq $::_e0, '    path {user => "USER", folder => "DIRECTORY.SUBDIRECTORY", file => "FILENAME.pm", ext => "EXTENSION"} # \> $USER:[DIRECTORY.SUBDIRECTORY]FILENAME.EXTENSION' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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

local ($::_g0 = do {path $path->{path}}, $::_e0 = do {$path}); ::is_deeply $::_g0, $::_e0, '    path $path->{path} # --> $path' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path {volume => "%sysname#module1>", file => "File.pm", ext => "txt"}}, $::_e0 = "%sysname#module1>File.txt"); ::ok $::_g0 eq $::_e0, '    path {volume => "%sysname#module1>", file => "File.pm", ext => "txt"} # => %sysname#module1>File.txt' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path {module => "module1", file => "File.pm"}}, $::_e0 = "%#module1>File.pm"); ::ok $::_g0 eq $::_e0, '    path {module => "module1", file => "File.pm"} # => %#module1>File.pm' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path {sysname => "sysname", file => "File.pm"}}, $::_e0 = "%sysname#>File.pm"); ::ok $::_g0 eq $::_e0, '    path {sysname => "sysname", file => "File.pm"} # => %sysname#>File.pm' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path {dir => "dir>subdir>", file => "File.pm", ext => "txt"}}, $::_e0 = "dir>subdir>File.txt"); ::ok $::_g0 eq $::_e0, '    path {dir => "dir>subdir>", file => "File.pm", ext => "txt"} # => dir>subdir>File.txt' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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

local ($::_g0 = do {path $path->{path}}, $::_e0 = do {$path}); ::is_deeply $::_g0, $::_e0, '    path $path->{path} # --> $path' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

    $path = {
        path => '.$.Directory.Directory.',
        dir => '.$.Directory.Directory.',
        folder => '.$.Directory.Directory',
    };

local ($::_g0 = do {path '.$.Directory.Directory.'}, $::_e0 = do {$path}); ::is_deeply $::_g0, $::_e0, '    path \'.$.Directory.Directory.\' # --> $path' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path {volume => "ADFS::HardDisk.", file => "File"}}, $::_e0 = "ADFS::HardDisk.$.File"); ::ok $::_g0 eq $::_e0, '    path {volume => "ADFS::HardDisk.", file => "File"} # => ADFS::HardDisk.$.File' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path {folder => "x"}}, $::_e0 = "x."); ::ok $::_g0 eq $::_e0, '    path {folder => "x"}  # => x.' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path {dir    => "x."}}, $::_e0 = "x."); ::ok $::_g0 eq $::_e0, '    path {dir    => "x."} # => x.' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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

local ($::_g0 = do {path $path->{path}}, $::_e0 = do {$path}); ::is_deeply $::_g0, $::_e0, '    path $path->{path} # --> $path' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path $path}, $::_e0 = "$path->{path}"); ::ok $::_g0 eq $::_e0, '    path $path         # => $path->{path}' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path 'report'}, $::_e0 = do {{path => 'report', file => 'report', name => 'report'}}); ::is_deeply $::_g0, $::_e0, '    path \'report\' # --> {path => \'report\', file => \'report\', name => \'report\'}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path {volume => "x", file => "f"}}, $::_e0 = "x:f"); ::ok $::_g0 eq $::_e0, '    path {volume => "x", file => "f"} # => x:f' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {path {folder => "x"}}, $::_e0 = "x:"); ::ok $::_g0 eq $::_e0, '    path {folder => "x"} # => x:' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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

local ($::_g0 = do {path $path->{path}}, $::_e0 = do {$path}); ::is_deeply $::_g0, $::_e0, '    path $path->{path} # --> $path' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path {volume => "x", file => "f"}}, $::_e0 = do {' f  x'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '    path {volume => "x", file => "f"} # -> \' f  x\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
}


# 
# ### See also
# 
# * https://en.wikipedia.org/wiki/Path_(computing)
# 
# Модули для определения ОС, а значит и определения, какие в ОС файловые пути:
# 
# * `$^O` – суперглобальная переменная с названием текущей ОС.
# * [Devel::CheckOS](https://metacpan.org/pod/Devel::CheckOS), [Perl::OSType](https://metacpan.org/pod/Perl::OSType) – определяют ОС.
# * [Devel::AssertOS](https://metacpan.org/pod/Devel::AssertOS) – запрещает использовать модуль вне указанных ОС.
# * [System::Info](https://metacpan.org/pod/System::Info) – информация об ОС, её версии, дистрибутиве, CPU и хосте.
# 
# Выделяют части файловых путей:
# 
# * [File::Spec](https://metacpan.org/pod/File::Spec) – `($volume, $directories, $file) = File::Spec->splitpath($path)`. Поддерживает только unix, win32, os/2, vms, cygwin и amigaos.
# * [File::Spec::Functions](https://metacpan.org/pod/File::Spec::Functions) – `($volume, $directories, $file) = splitpath($path)`.
# * [File::Spec::Mac](https://metacpan.org/pod/File::Spec::Mac) – входит в [File::Spec](https://metacpan.org/pod/File::Spec), но не определяется им, поэтому приходится использовать отдельно. Для mac os по 9-ю версию.
# * [File::Basename](https://metacpan.org/pod/File::Basename) – `($name, $path, $suffix) = fileparse($fullname, @suffixlist)`.
# * [Path::Class::File](https://metacpan.org/pod/Path::Class::File) – `file('foo', 'bar.txt')->is_absolute`.
# * [Path::Extended::File](https://metacpan.org/pod/Path::Extended::File) – `Path::Extended::File->new($file)->basename`.
# * [Mojo::File](https://metacpan.org/pod/Mojo::File) – `path($file)->extname`.
# * [Path::Util](https://metacpan.org/pod/Path::Util) – `$filename = basename($dir)`.
# * [Parse::Path](https://metacpan.org/pod/Parse::Path) – `Parse::Path->new(path => 'gophers[0].food.count', style => 'DZIL')->push("chunk")`. Работает с путями как с массивами (`push`, `pop`, `shift`, `splice`). Так же перегружает операторы сравнения. У него есть стили: `DZIL`, `File::Unix`, `File::Win32`, `PerlClass` и `PerlClassUTF8`.
# 
# ## transpath ($path?, $from, $to)
# 
# Переводит путь из формата одной ОС в другую.
# 
# Если `$path` не указан, то используется `$_`.
# 
# Перечень поддерживаемых ОС смотрите в примерах подпрограммы `path` чуть выше или так: `keys %Aion::Fs::FS`.
# 
# Названия ОС – регистронезависимы.
# 
::done_testing; }; subtest 'transpath ($path?, $from, $to)' => sub { 
local $_ = ">x>y>z.doc.zip";
local ($::_g0 = do {transpath "vos", "unix"}, $::_e0 = '/x/y/z.doc.zip'); ::ok $::_g0 eq $::_e0, 'transpath "vos", "unix"       # \> /x/y/z.doc.zip' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {transpath "vos", "VMS"}, $::_e0 = '[.x.y]z.doc.zip'); ::ok $::_g0 eq $::_e0, 'transpath "vos", "VMS"        # \> [.x.y]z.doc.zip' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {transpath $_, "vos", "RiscOS"}, $::_e0 = '.x.y.z/doc/zip'); ::ok $::_g0 eq $::_e0, 'transpath $_, "vos", "RiscOS" # \> .x.y.z/doc/zip' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# 
# ## splitdir (;$dir)
# 
# Разбивает директорию на составляющие. Директорию следует вначале получить из `path->{dir}`.
# 
::done_testing; }; subtest 'splitdir (;$dir)' => sub { 
local $^O = "unix";
local ($::_g0 = do {[ splitdir "/x/" ]}, $::_e0 = do {["", "x", ""]}); ::is_deeply $::_g0, $::_e0, '[ splitdir "/x/" ]    # --> ["", "x", ""]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## joindir (;$dirparts)
# 
# Объединяет директорию из составляющих. Затем полученную директорию следует включить в `path +{dir => $dir}`.
# 
::done_testing; }; subtest 'joindir (;$dirparts)' => sub { 
local $^O = "unix";
local ($::_g0 = do {joindir qw/x y z/}, $::_e0 = "x/y/z"); ::ok $::_g0 eq $::_e0, 'joindir qw/x y z/    # => x/y/z' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path +{ dir => joindir qw/x y z/ }}, $::_e0 = "x/y/z/"); ::ok $::_g0 eq $::_e0, 'path +{ dir => joindir qw/x y z/ } # => x/y/z/' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## splitext (;$ext)
# 
# Разбивает расширение на составляющие. Расширение следует вначале получить из `path->{ext}`.
# 
::done_testing; }; subtest 'splitext (;$ext)' => sub { 
local $^O = "unix";
local ($::_g0 = do {[ splitext ".x." ]}, $::_e0 = do {["", "x", ""]}); ::is_deeply $::_g0, $::_e0, '[ splitext ".x." ]    # --> ["", "x", ""]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## joinext (;$extparts)
# 
# Объединяет расширение из составляющих. Затем полученное расширение следует включить в `path +{ext => $ext}`.
# 
::done_testing; }; subtest 'joinext (;$extparts)' => sub { 
local $^O = "unix";
local ($::_g0 = do {joinext qw/x y z/}, $::_e0 = "x.y.z"); ::ok $::_g0 eq $::_e0, 'joinext qw/x y z/    # => x.y.z' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {path +{ ext => joinext qw/x y z/ }}, $::_e0 = ".x.y.z"); ::ok $::_g0 eq $::_e0, 'path +{ ext => joinext qw/x y z/ } # => .x.y.z' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## include (;$pkg)
# 
# Подключает `$pkg` (если он ещё не был подключён через `use` или `require`) и возвращает его. Без параметра использует `$_`.
# 
# Файл lib/A.pm:
#@> lib/A.pm
#>> package A;
#>> sub new { bless {@_}, shift }
#>> 1;
#@< EOF
# 
# Файл lib/N.pm:
#@> lib/N.pm
#>> package N;
#>> sub ex { 123 }
#>> 1;
#@< EOF
# 
::done_testing; }; subtest 'include (;$pkg)' => sub { 
use lib "lib";
::like scalar do {include("A")->new}, qr{A=HASH\(0x\w+\)}, 'include("A")->new               # ~> A=HASH\(0x\w+\)'; undef $::_g0; undef $::_e0;
local ($::_g0 = do {[map include, qw/A N/]}, $::_e0 = do {[qw/A N/]}); ::is_deeply $::_g0, $::_e0, '[map include, qw/A N/]          # --> [qw/A N/]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{ local $_="N"; include->ex }}, $::_e0 = do {123}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{ local $_="N"; include->ex }   # -> 123' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## catonce (;$file)
# 
# Считывает файл в первый раз. Любая последующая попытка считать этот файл возвращает `undef`. Используется для вставки модулей js и css в результирующий файл. Без параметра использует `$_`.
# 
# * `$file` может содержать массивы из двух элементов. Первый рассматривается как путь, а второй – как слой. Слой по умолчанию – `:utf8`.
# * Если `$file` не указан – использует `$_`.
# 
::done_testing; }; subtest 'catonce (;$file)' => sub { 
local $_ = "catonce.txt";
lay "result";
local ($::_g0 = do {catonce}, $::_e0 = do {"result"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'catonce  # -> "result"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {catonce}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'catonce  # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

::like scalar do {eval { catonce[] }; $@}, qr{catonce not use ref path\!}, 'eval { catonce[] }; $@ # ~> catonce not use ref path!'; undef $::_g0; undef $::_e0;

# 
# ## wildcard (;$wildcard)
# 
# Переводит файловую маску в регулярное выражение. Без параметра использует `$_`.
# 
# * `**` - `[^/]*`
# * `*` - `.*`
# * `?` - `.`
# * `??` - `[^/]`
# * `{` - `(`
# * `}` - `)`
# * `,` - `|`
# * Остальные символы экранируются с помощью `quotemeta`.
# 
::done_testing; }; subtest 'wildcard (;$wildcard)' => sub { 
local ($::_g0 = do {wildcard "*.{pm,pl}"}, $::_e0 = '(?^usn:^.*?\.(pm|pl)$)'); ::ok $::_g0 eq $::_e0, 'wildcard "*.{pm,pl}"  # \> (?^usn:^.*?\.(pm|pl)$)' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {wildcard "?_??_**"}, $::_e0 = '(?^usn:^._[^/]_[^/]*?$)'); ::ok $::_g0 eq $::_e0, 'wildcard "?_??_**"  # \> (?^usn:^._[^/]_[^/]*?$)' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Используется в фильтрах функции `find`.
# 
# ### See also
# 
# * [File::Wildcard](https://metacpan.org/pod/File::Wildcard).
# * [String::Wildcard::Bash](https://metacpan.org/pod/String::Wildcard::Bash).
# * [Text::Glob](https://metacpan.org/pod/Text::Glob) – `glob_to_regex("*.{pm,pl}")`.
# 
# ## goto_editor ($path, $line)
# 
# Открывает файл в редакторе из .config на указанной строке. По умолчанию использует `vscodium %p:%l`.
# 
# Файл .config.pm:
#@> .config.pm
#>> package config;
#>> 
#>> config_module 'Aion::Fs' => {
#>>     EDITOR => 'echo %p:%l > ed.txt',
#>> };
#>> 
#>> 1;
#@< EOF
# 
::done_testing; }; subtest 'goto_editor ($path, $line)' => sub { 
goto_editor "mypath", 10;
local ($::_g0 = do {cat "ed.txt"}, $::_e0 = "mypath:10\n"); ::ok $::_g0 eq $::_e0, 'cat "ed.txt"  # => mypath:10\n' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

::like scalar do {eval { goto_editor "`", 1 }; $@}, qr{`:1 --> 512}, 'eval { goto_editor "`", 1 }; $@  # ~> `:1 --> 512'; undef $::_g0; undef $::_e0;

# 
# ## from_pkg (;$pkg)
# 
# Переводит пакет в путь ФС. Без параметра использует `$_`.
# 
::done_testing; }; subtest 'from_pkg (;$pkg)' => sub { 
local ($::_g0 = do {from_pkg "Aion::Fs"}, $::_e0 = "Aion/Fs.pm"); ::ok $::_g0 eq $::_e0, 'from_pkg "Aion::Fs"  # => Aion/Fs.pm' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[map from_pkg, "Aion::Fs", "A::B::C"]}, $::_e0 = do {["Aion/Fs.pm", "A/B/C.pm"]}); ::is_deeply $::_g0, $::_e0, '[map from_pkg, "Aion::Fs", "A::B::C"]  # --> ["Aion/Fs.pm", "A/B/C.pm"]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## to_pkg (;$path)
# 
# Переводит путь из ФС в пакет. Без параметра использует `$_`.
# 
::done_testing; }; subtest 'to_pkg (;$path)' => sub { 
local ($::_g0 = do {to_pkg "Aion/Fs.pm"}, $::_e0 = "Aion::Fs"); ::ok $::_g0 eq $::_e0, 'to_pkg "Aion/Fs.pm"  # => Aion::Fs' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[map to_pkg, "Aion/Fs.md", "A/B/C.md"]}, $::_e0 = do {["Aion::Fs", "A::B::C"]}); ::is_deeply $::_g0, $::_e0, '[map to_pkg, "Aion/Fs.md", "A/B/C.md"]  # --> ["Aion::Fs", "A::B::C"]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## from_inc (;$pkg)
# 
# Переводит пакет в путь ФС в `@INC`. Файл с пакетом должен существовать в одном из путей `@INC`. Без параметра использует `$_`.
# 
::done_testing; }; subtest 'from_inc (;$pkg)' => sub { 
local ($::_g0 = do {from_inc "Aion::Fs"}, $::_e0 = do {$INC{'Aion/Fs.pm'}}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'from_inc "Aion::Fs" # -> $INC{\'Aion/Fs.pm\'}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[map from_inc, "A::B::C", "Aion::Fs"]}, $::_e0 = do {[$INC{'Aion/Fs.pm'}]}); ::is_deeply $::_g0, $::_e0, '[map from_inc, "A::B::C", "Aion::Fs"]  # --> [$INC{\'Aion/Fs.pm\'}]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {from_inc "A::B::C"}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'from_inc "A::B::C" # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## to_inc (;$path)
# 
# Переводит путь из ФС в `@INC` в пакет. Без параметра использует `$_`.
# 
::done_testing; }; subtest 'to_inc (;$path)' => sub { 
local ($::_g0 = do {to_inc $INC{'Aion/Fs.pm'}}, $::_e0 = "Aion::Fs"); ::ok $::_g0 eq $::_e0, 'to_inc $INC{\'Aion/Fs.pm\'} # => Aion::Fs' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[map to_inc,"A/B/C.pm", $INC{'Aion/Fs.pm'}]}, $::_e0 = do {["Aion::Fs"]}); ::is_deeply $::_g0, $::_e0, '[map to_inc,"A/B/C.pm", $INC{\'Aion/Fs.pm\'}]  # --> ["Aion::Fs"]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {to_inc 'Aion/Fs.pm'}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'to_inc \'Aion/Fs.pm\' # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ilay (;$path)
# 
# Создаёт файловый дескриптор. Он умеет закрываться, как только на него исчезнет последняя ссылка.
# 
# Так же имеет метод `path`, к-й возвращает путь к файлу.
# 
::done_testing; }; subtest 'ilay (;$path)' => sub { 
my $test_file = "test_ilay_complete.txt";

my $f = ilay $test_file;
print $f "Line 1\n";
print $f "Line 2\n";

my $std = select $f; $| = 1; select $std;
local ($::_g0 = do {-s $f}, $::_e0 = do {14}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-s $f # -> 14' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$f->path}, $::_e0 = "test_ilay_complete.txt"); ::ok $::_g0 eq $::_e0, '$f->path # => test_ilay_complete.txt' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {fileno($f) > 0}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'fileno($f) > 0 # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

undef $f;

local ($::_g0 = do {cat $test_file}, $::_e0 = "Line 1\nLine 2\n"); ::ok $::_g0 eq $::_e0, 'cat $test_file # => Line 1\nLine 2\n' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local $_ = [$test_file, ':raw'];
my $f = ilay;

my $str = "string";
my $num = 42;
my $end = "END";

*FD = *$f{IO};
format FD =
@<<<<<<<< @||||| @>>>>>
$str,     $num,  $end
.

write FD;

$str = 'int';

write FD;

undef *FD;
undef $f;

my $table = << 'TABLE';
string      42      END
int         42      END
TABLE

local ($::_g0 = do {cat $test_file}, $::_e0 = do {$table}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'cat $test_file # -> $table' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ### See also
# 
# * [IO::Handle](https://perldoc.perl.org/IO::Handle).
# 
# ## icat (;$file)
# 
# Создаёт файловый дескриптор с возможностью автозакрытия, как только пропадёт последняя на него ссылка.
# 
# Так же имеет метод `path` возвращающий переданный в него путь.
# 
::done_testing; }; subtest 'icat (;$file)' => sub { 
local $_ = "test_icat_complete.txt";
lay "Line 1\nLine 2\nLine 3\nBinary\x00\x01\x02";

my $f = icat;

my $bytes = read $f, my $buf, 6;
local ($::_g0 = do {$bytes}, $::_e0 = do {6}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$bytes # -> 6' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$buf}, $::_e0 = "Line 1"); ::ok $::_g0 eq $::_e0, '$buf # => Line 1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {scalar <$f>}, $::_e0 = do {"\n"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar <$f> # -> "\n"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[<$f>]}, $::_e0 = do {["Line 2\n", "Line 3\n", "Binary\x00\x01\x02"]}); ::is_deeply $::_g0, $::_e0, '[<$f>] # --> ["Line 2\n", "Line 3\n", "Binary\x00\x01\x02"]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ### See also
# 
# * [IO::Handle](https://perldoc.perl.org/IO::Handle).
# 
# ## isUNIX ()
# 
# Мы находимся в ОС семейства UNIX.
# 
::done_testing; }; subtest 'isUNIX ()' => sub { 
local ($::_g0 = do {isUNIX =~ /^(1|)$/}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'isUNIX =~ /^(1|)$/ # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # AUTHOR
# 
# Yaroslav O. Kosmina <dart@cpan.org>
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Fs is copyright © 2023 by Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
