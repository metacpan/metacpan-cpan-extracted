#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The program fuguseed-qr (QR-PROGRAM, SEC-CHANNELS, SEC-TRUST-3).
# The tests run bin/fuguseed-qr as a child, and they hold each of the
# three streams and the exit code. The last part scans the source of
# the program and of every module that it loads.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use IPC::Open3       qw(open3);
use Module::CoreList ();
use Symbol           qw(gensym);
use FindBin          qw($RealBin);

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

use constant PROGRAM => 'bin/fuguseed-qr';
use constant OUTPUT  => 't/fuguseed/fixtures/qr/vector4.output';

# Test vector 4 of the SeedQR specification, and the word 12 of the
# vector. The BLUE row of that word holds 16 words, and one of them
# is the check word (QR-MNEMONIC-4).
use constant VECTOR =>
    'forum undo fragile fade shy sign arrest garment culture tube off merit';
use constant CHECK_WORD => 'merit';

# The child gets no PERL5LIB and no PERL5OPT of this environment, so
# no module comes from outside this checkout.
delete local @ENV{qw(PERL5LIB PERL5OPT)};

# _slurp($path):
#	The whole file as text.
sub _slurp ($path)
{
	open my $fh, '<', $path or BAIL_OUT("$path: $!");
	local $/ = undef;
	my $text = <$fh>;
	close $fh or BAIL_OUT("close $path: $!");

	return $text;
}

# _run($input, @argument):
#	Run the program with $input on standard input. The result is
#	the standard output, the standard error, and the exit code.
sub _run ( $input, @argument )
{
	local $SIG{PIPE} = 'IGNORE';
	my $fault = gensym;
	my $pid = open3( my $in, my $out, $fault, $^X, '-Ilib', PROGRAM,
		@argument );

	print {$in} $input or BAIL_OUT('the child takes no input');
	close $in;

	local $/ = undef;
	my $output = <$out>;
	my $error  = <$fault>;
	waitpid $pid, 0;
	my $status = $? >> 8;
	close $out;
	close $fault;

	return ( $output // q{}, $error // q{}, $status );
}

# QR-PROGRAM-3 and QR-PROGRAM-4: the words on standard input give the
# SeedQR on standard output.
my ( $output, $error, $status ) = _run( VECTOR . "\n" );
is( $output, _slurp(OUTPUT), 'test vector 4 gives the fixture output' );
is( $error,  q{},            'test vector 4 writes nothing to standard error' );
is( $status, 0,              'test vector 4 exits 0' );

# QR-PROGRAM-2: an argument is a usage error (D-12).
my ( $none, $usage, $code ) = _run( q{}, 'build' );
is( $none, q{}, 'an argument gives no standard output' );
is( $usage, "usage: fuguseed-qr\n", 'an argument gives one usage line' );
is( $code, 2, 'an argument exits 2' );

# QR-PROGRAM-4 and SEC-CHANNELS-2: a failure names the position, and
# standard error carries no word.
my @words = split q{ }, VECTOR;
$words[4] = 'blorp';
my ( $empty, $line, $failure ) = _run( "@words\n" );
my @named = grep { $line =~ /\b\Q$_\E\b/ } @words;
is( $empty, q{}, 'a wrong word gives no standard output' );
is( $line, "fuguseed-qr: word 5 is not in the word list\n",
	'a wrong word gives one line that names the position' );
is( "@named", q{}, 'the failure line holds no word of the input' );
is( $failure, 1, 'a wrong word exits 1' );

my ( $short, $count, $state ) = _run("forum undo\n");
is( $count, "fuguseed-qr: the input holds 2 words, not 12\n",
	'a wrong count gives one line that names the count' );
is( $short, q{}, 'a wrong count gives no standard output' );
is( $state, 1,   'a wrong count exits 1' );

# QR-MNEMONIC-4: a wrong checksum gives the check word alone.
my @typed = split q{ }, VECTOR;
$typed[-1] = 'mercy';
my ( $word, $silent, $result ) = _run( "@typed\n" );
is( $word,   CHECK_WORD . "\n", 'a wrong checksum gives the check word' );
is( $silent, q{},               'the check word run writes nothing to standard error' );
is( $result, 0,                 'the check word run exits 0' );

# The scan. The module list comes from the program itself: a child
# loads App::FuguSeed::QR and prints %INC, so a later module of the
# program joins the scan.
open my $ph, '-|', $^X, '-Ilib', '-MApp::FuguSeed::QR', '-e',
    'print "$_\n" for sort keys %INC'
    or BAIL_OUT("$^X: $!");
my @loaded = <$ph>;
close $ph or BAIL_OUT("close $^X: status $?");
chomp @loaded;

my ( @sources, @outside );
push @sources, PROGRAM;
for my $path (@loaded) {
	( my $module = $path ) =~ s/\.pm\z//;
	$module                =~ s{/}{::}g;
	if ( $module =~ /\AApp::FuguSeed::/ ) {
		push @sources, "lib/$path";
		next;
	}
	push @outside, $module
	    unless Module::CoreList::is_core( $module, undef, 5.034 );
}
is( "@outside", q{}, 'the program loads core modules of perl 5.034 only' );

my %source = map { $_ => 1 } @sources;
my @want   = qw(
    bin/fuguseed-qr
    lib/App/FuguSeed/Codewords.pm
    lib/App/FuguSeed/List.pm
    lib/App/FuguSeed/Matrix.pm
    lib/App/FuguSeed/Mnemonic.pm
    lib/App/FuguSeed/QR.pm
    lib/App/FuguSeed/Text.pm
);
my @absent = grep { !$source{$_} } @want;
is( "@absent", q{}, 'the scan covers the program and its six modules' );

# _code($text):
#	The Perl code of $text, without the comments and the string
#	literals. A single-quoted heredoc goes first: the word list
#	of App::FuguSeed::List holds words such as "open" and "fork",
#	and the module holds the list in such a heredoc. A "#" after
#	a "$" is the last index of an array, and not a comment.
#
#	The strip knows three quote-like operators: q, qq and qw,
#	with braces or with parentheses. It knows a match after =~,
#	!~ or split. An apostrophe in another form, such as s///,
#	pairs with a later apostrophe, and the pair deletes the code
#	between the two. The function dies on a form that it cannot
#	parse, because such a form can hide code from the scan
#	below.
#
#	The first branch of the strip keeps the marker of a heredoc,
#	and each guard below reads the stripped code. A marker in a
#	comment or in a string goes away with the comment or the
#	string, and it stops no scan.
sub _code ($text)
{
	$text =~ s/<<'(\w+)';.*?^\1$//msg;

	$text =~ s{
		  ( << ~? (?: ' \w+ ' | " \w+ " ) )
		| ' [^'\\]* (?: \\. [^'\\]* )* '
		| " [^"\\]* (?: \\. [^"\\]* )* "
		| (?<! [\$\@\%&>] ) \b q [qw]? \s* \{ [^{}]* \}
		| (?<! [\$\@\%&>] ) \b q [qw]? \s* \( [^()]* \)
		| (?: =~ | !~ | \b split ) \K \s* m? / [^/\n]* / \w*
		| (?<! \$ ) \# [^\n]*
	}{ $1 // q{} }gex;

	die "_code: the text holds another heredoc\n"
	    if $text =~ / << ~? ['"A-Za-z_] /x;

	my $form = _unknown($text);
	die "_code: the text holds $form\n" if defined $form;

	return $text;
}

# _unknown($code):
#	The name of the first form of the stripped $code that _code
#	cannot parse, or undef. Each quote character of a known form
#	leaves with that form, so a quote character that stays names
#	a form that the strip missed.
sub _unknown ($code)
{
	return 'a quote character' if $code =~ /['"]/;
	return 'a quote-like operator'
	    if $code =~ m{
		    (?<! [\$\@\%&>-] )
		    \b (?: qq | qr | qx | qw | q | m | s | tr | y )
		    \s* [(\{\[<|!\#'"/]
	    }x;

	# The slash of a division and the slash of the defined-or
	# operator follow a term, between two spaces. Each other
	# slash can open a match.
	( my $rest = $code ) =~ s{ (?<= [\w\)\]\}] ) [ ] //? [ ] }{}gx;
	return 'a slash' if $rest =~ m{/};

	return;
}

# The guard of _code (SEC-TRUST-3). An apostrophe in a form that the
# strip does not know pairs with a later apostrophe, and the pair
# deletes the code between the two. Each refusal names its path, so
# one path cannot stand for another.
like( _code("my \$x = q{don't};\nopen my \$fh, '<', \$path;\n"),
	qr/open/, '_code keeps the code after an apostrophe in q{}' );
like( _code("\$x =~ /can't/;\nopen my \$fh, '<', \$path;\n"),
	qr/open/, '_code keeps the code after an apostrophe in a match' );
like( _code("# the marker <<\"HERE\" of a heredoc\nopen my \$fh;\n"),
	qr/open/, '_code takes a heredoc marker in a comment' );
like( _code("my \$x = \"<<HERE\";\nopen my \$fh;\n"),
	qr/open/, '_code takes a heredoc marker in a string' );

eval { _code('$x =~ s/a/b/;') };
like( $@, qr/\A_code: the text holds a quote-like operator$/,
	'_code refuses a substitution' );
eval { _code("my \$x = <<\"HERE\";\nHERE\n") };
like( $@, qr/\A_code: the text holds another heredoc$/,
	'_code refuses a double-quoted heredoc' );

# $contact:
#	Each builtin of the file system, of process control, of the
#	user information and the group information, of the network,
#	and of System V IPC. The list holds syscall as well, because
#	syscall calls any system call. It holds eof, because eof()
#	and eof(ARGV) open the next file of @ARGV. It holds flock,
#	fcntl and ioctl, because each one reaches past the bytes of
#	a handle. The program must contact nothing but its three
#	standard streams, so SEC-TRUST-3 forbids each one. A sigil
#	before the name makes it a variable, and a fat comma after it
#	makes it a key. Neither one is a call.
my $contact = qr{
	(?<! [\$\@\%] )
	\b(?: open | sysopen | opendir | readdir | closedir | rewinddir
	    | seekdir | telldir | glob | dbmopen | unlink | rename | link
	    | symlink | readlink | mkdir | rmdir | chdir | chroot | chmod
	    | chown | utime | truncate | umask | stat | lstat | eof
	    | flock | fcntl | ioctl
	    | system | exec | fork | qx | readpipe | pipe | wait | waitpid
	    | kill | syscall
	    | socket | socketpair | bind | connect | listen | accept
	    | shutdown | recv | send | getsockname | getpeername
	    | gethostbyname | gethostbyaddr | getservbyname
	    | getpwnam | getpwuid | getpwent | getgrnam | getgrgid
	    | getgrent | getlogin
	    | msgget | msgsnd | msgrcv | semget | semop
	    | shmget | shmread | shmwrite )\b
	(?! \s* => )
}x;

# $file_test:
#	A file test operator, such as -e or -r. Each one reads the
#	file system, and -t reads the state of a filehandle
#	(SEC-TRUST-3).
my $file_test = qr{ (?<! [\w\$] ) - [rwxoRWXOezsfdlpSbctugkTBAMC] \b }x;

# $environment:
#	A read of the environment: %ENV, $ENV{...}, @ENV{...}, and
#	the getenv function of POSIX (SEC-TRUST-3).
my $environment = qr{ \b(?: ENV | getenv )\b }x;

# $read:
#	A read of another handle than standard input: the diamond
#	operator in each of its forms, and readline with another
#	handle. The diamond operator opens each file that @ARGV
#	names, and bin/fuguseed-qr passes @ARGV to run (SEC-TRUST-3).
my $read = qr{
	<> | < (?! STDIN > ) \$? \w+ >
	| \b readline \b (?! \s* \(? \s* \*? STDIN \b )
}x;

# $dynamic:
#	A load of a file, such as require $path or require './x.pl'.
#	The strip above deletes the path of a literal load, so the
#	pattern takes each do and each require that is not a block,
#	a version, or a bareword module (SEC-TRUST-3).
my $dynamic = qr{
	(?<! [\$\@\%>] ) \b(?: do | require )\b
	(?! \s* \{ )
	(?! \s+ v? [0-9] )
	(?! \s+ [A-Za-z_] [\w:]* \s* ; )
}x;

# _hits($code):
#	The name of each contact of the stripped $code with the
#	computer, or an empty list (SEC-TRUST-3). The scan of the
#	sources and the self-test below call this one function, so
#	each pattern above has one place only.
sub _hits ($code)
{
	my @hits = $code =~ /($contact)/g;
	push @hits, 'backtick'  if $code =~ /[`]/;
	push @hits, 'ENV'       if $code =~ $environment;
	push @hits, 'file test' if $code =~ $file_test;
	push @hits, 'read'      if $code =~ $read;
	push @hits, 'load'      if $code =~ $dynamic;

	return @hits;
}

# _refusal($sample):
#	The reason that the scan refuses the code $sample: the hits
#	of _hits, or the message of _code for a form that _code
#	cannot parse. The reason is empty for code that the scan
#	accepts.
sub _refusal ($sample)
{
	my @hits = eval { _hits( _code($sample) ) };
	return $@ if $@;

	return join q{ }, @hits;
}

# The self-test of the patterns (SEC-TRUST-3). The seven sources are
# clean, so each scan assertion below passes with no hit. These two
# tables prove that each pattern fires on the code that it names, and
# that it stays quiet on the code that it does not name. Delete one
# name of $contact, or one arm of $read, and a row here fails.
my @caught = (
	[ q{open my $fh, '<', $path;},          'open' ],
	[ q{sysopen my $fh, $path, 0;},         'sysopen' ],
	[ q{system 'ls';},                      'system' ],
	[ q{exec 'ls';},                        'exec' ],
	[ q{my $pid = fork;},                   'fork' ],
	[ q{my $out = `ls`;},                   'backtick' ],
	[ q{my $out = qx;ls;},                  'qx' ],
	[ q{my $out = readpipe $command;},      'readpipe' ],
	[ q{my @file = glob $pattern;},         'glob' ],
	[ q{socket my $s, 2, 1, 6;},            'socket' ],
	[ q{syscall 20, $buffer;},              'syscall' ],
	[ q{flock $fh, 2;},                     'flock' ],
	[ q{fcntl $fh, 1, 0;},                  'fcntl' ],
	[ q{ioctl $fh, 21505, $buffer;},        'ioctl' ],
	[ q{my $uid = getpwnam 'root';},        'getpwnam' ],
	[ q{my @user = getpwent;},              'getpwent' ],
	[ q{my @group = getgrent;},             'getgrent' ],
	[ q{my $user = getlogin;},              'getlogin' ],
	[ q{my $host = gethostbyaddr $a, 2;},   'gethostbyaddr' ],
	[ q{my $me = getsockname $s;},          'getsockname' ],
	[ q{my $peer = getpeername $s;},        'getpeername' ],
	[ q{my $id = msgget 1, 0;},             'msgget' ],
	[ q{msgsnd $id, $message, 0;},          'msgsnd' ],
	[ q{msgrcv $id, $buffer, 8, 0, 0;},     'msgrcv' ],
	[ q{semop $id, $operation;},            'semop' ],
	[ q{shmread $id, $buffer, 0, 8;},       'shmread' ],
	[ q{shmwrite $id, $buffer, 0, 8;},      'shmwrite' ],
	[ q{my $home = $ENV{HOME};},            'ENV' ],
	[ q{my @value = @ENV{qw(A B)};},        'ENV' ],
	[ q{my @name = keys %ENV;},             'ENV' ],
	[ q{my $home = POSIX::getenv('HOME');}, 'ENV' ],
	[ q{my $there = -e $path;},             'file test' ],
	[ q{my $line = <>;},                    'read' ],
	[ q{my $line = <ARGV>;},                'read' ],
	[ q{my $line = <$fh>;},                 'read' ],
	[ q{my $line = readline ARGV;},         'read' ],
	[ q{last if eof;},                      'eof' ],
	[ q{last if eof(ARGV);},                'eof' ],
	[ q{require './x.pl';},                 'load' ],
	[ q{do './x.pl';},                      'load' ],
	[ q{require $path;},                    'load' ],
);

my @clean = (
	q{my $line = readline STDIN;},
	q{my $line = <STDIN>;},
	q{require Digest::SHA;},
	q{require v5.34;},
	q{use v5.34;},
	q{my $x = do { 1 };},
	q{my $link = 1;},
	q{my $stat = 1;},
	q{my $send = 1;},
	q{my %pair = ( open => 1 );},
	q{my @row = (1); my $last = $#row;},
	q{my $mask = 1 << 3;},
);

for my $case (@caught) {
	my ( $sample, $reason ) = @{$case};
	like( _refusal($sample), qr/\Q$reason\E/,
		"the scan catches $sample" );
}

for my $sample (@clean) {
	is( _refusal($sample), q{}, "the scan takes $sample" );
}

for my $path ( sort @sources ) {
	my $code = _code( _slurp($path) );

	# SEC-TRUST-3: the three standard streams are the one contact
	# of the program with the computer.
	is( join( q{ }, _hits($code) ),
		q{}, "$path contacts nothing but its three streams" );

	# QR-PROGRAM-5: a source loads Digest::SHA, a pragma, and a
	# module of this repository. It loads nothing else.
	my @loads = $code =~ /^\s*(?:use|require)\s+([\w:]+)/mg;
	my @foreign = grep {
		     !/\AApp::FuguSeed::/
		  && !/\A[a-z]/
		  && $_ ne 'Digest::SHA'
	} @loads;
	is( "@foreign", q{}, "$path names no module outside this repository" );
}

done_testing();
