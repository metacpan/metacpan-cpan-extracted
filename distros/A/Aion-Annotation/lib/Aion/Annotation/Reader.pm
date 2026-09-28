package Aion::Annotation::Reader;
# Считыватель аннотаций и комментариев

use common::sense;

use Symbol qw//;
use Time::Local qw/timelocal/;

use overload fallback => 1,
    '*{}' => sub { shift->{f} },
    '-X' => \&_fileop,
    '<>' => sub { shift->next },
    '&{}' => sub {
            my ($self) = @_;
            sub { scalar $self->next }
    },
    '@{}' => sub { [shift->next] },
    '""' => sub { my ($self) = @_; "${\__PACKAGE__}<$self->{type},$self->{path}>" },
;

# Дефолтные пути для сканирования
use Aion::Env AION_ANNOTATION_LIB => (default => 'lib');

# Директория в которую складывать файлы конфигурации
use Aion::Env AION_ANNOTATION_INI => (default => 'etc/annotation');

# Директория с кешем
use Aion::Env AION_ANNOTATION_CACHE => (default => 'var/cache');

use constant {
	READ_REMARKS => '-remarks',
	READ_MTIME => '-mtime',
	MODULES_MTIME_FILE => "modules.mtime.ini",
	REMARKS_FILE => "remarks.ini",
	LINE_REGEX => qr/^([\w:]+)#(\w*),(\d+)=(.*)$/,
	MTIME_REGEX => qr/^(?<module>[\w:]+)=(?<year>\d{4})-(?<mon>\d{2})-(?<mday>\d{2}) (?<hour>\d{2}):(?<min>\d{2}):(?<sec>\d{2})$/,
};

my %DETECT = (ann => \&detect_annotation, mtime => \&detect_mtime, remarks => \&detect_remark);
sub new {
	my ($cls, $ann) = @_;

	my $type = $ann eq READ_REMARKS? 'remarks':
		$ann eq READ_MTIME? 'mtime': 'ann';
	
	my $file = 
		$type eq 'remarks'? join("/", AION_ANNOTATION_INI, REMARKS_FILE):
		$type eq 'mtime'? join("/", AION_ANNOTATION_CACHE, MODULES_MTIME_FILE):
		join("", AION_ANNOTATION_INI, "/", $ann, ".ann");
	
	my $f = Symbol::gensym;
    open $f, "<:encoding(utf8)", $file or die "$file: $!";
	
	bless {f => $f, path => $file, type => $type, detect => $DETECT{$type}}, ref $cls || $cls;
}

sub path { shift->{path} }

# Следующий элемент
sub next {
	my ($self) = @_;
	my $f = $self->{f};
	my $detect = $self->{detect};

	if(wantarray) {
		my @ann;
		while(<$f>) {
			push @ann, $detect->($self, $_);
		}
		return @ann;
	}
	
	my $line = <$f> // return undef;
	$detect->($self, $line);
}

sub DESTROY {
	my ($self) = @_;
	close $self->{f};
}

my %OP;
sub _fileop {
	my ($self, $op) = @_;
	local $_ = $self->{f};
	($OP{$op} //= eval "sub { -$op }" // die)->()
}

# Распознаёт аннотацию
sub detect_annotation {
	my ($self, $line) = @_;
	warn "$self->{path} corrupt on line $.!" unless my ($pkg, $name, $lineno, $ann) = $line =~ LINE_REGEX;
	+{
		pkg => $pkg,
		name => $name,
		line => $lineno,
		annotation => $ann,
	};
}

# Распознаёт комментарий
sub detect_remark {
	my ($self, $line) = @_;
	warn "$self->{path} corrupt on line $.!" unless my ($pkg, $name, $lineno, $remark) = $line =~ LINE_REGEX;
	$remark = join "\n", map { s/\\(.)/$1/gr } split /\\n/, $remark, -1;
	+{
		pkg => $pkg,
		name => $name,
		line => $lineno,
		remark => $remark,
	};
}

# Распознаёт время последнего обновления модуля
sub detect_mtime {
	my ($self, $line) = @_;
	unless($line =~ MTIME_REGEX) {
		warn "$self->{path} corrupt on line $.!";
		return +{pkg => undef, mtime => undef};
	}
	+{
		pkg => $+{module},
		mtime => timelocal($+{sec}, $+{min}, $+{hour}, $+{mday}, $+{mon} - 1, $+{year}),
	};
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Annotation::Reader - reads annotations, comments and module update times

=head1 VERSION

0.1.0

=head1 SYNOPSIS

File etc/annotation/todo.ann:

	For::Test#abc,5=add1
	For::Test#xyz,11=add2

File etc/annotation/remarks.ini:

	For::Test#,4=The package for testing
	For::Test#abc,9=Is property\n  readonly

File var/cache/modules.mtime.ini:

	For::Test=2025-01-02 03:04:05



	use Aion::Annotation::Reader;
	use Time::Local qw/timelocal/;
	
	my $reader = Aion::Annotation::Reader->new('todo');
	
	my @ann; push @ann, $_ while <$reader>;
	
	my $ann = [
		{pkg => 'For::Test', name => 'abc', line => '5',  annotation => 'add1'},
		{pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'},
	];
	
	\@ann # --> $ann
	
	my $reader_remarks = Aion::Annotation::Reader->new(Aion::Annotation::Reader::READ_REMARKS);
	
	my $remarks = [
		{pkg => 'For::Test', name => '',    line => '4', remark => 'The package for testing'},
		{pkg => 'For::Test', name => 'abc', line => '9', remark => "Is property\n  readonly"},
	];
	
	\@{$reader_remarks} # --> $remarks
	
	my $reader_mtime = Aion::Annotation::Reader->new(Aion::Annotation::Reader::READ_MTIME);
	
	# Время хранится как unixtime, поэтому ожидаемое значение не зависит от часового пояса
	my $mtime = [{pkg => 'For::Test', mtime => timelocal(5, 4, 3, 2, 0, 2025)}];
	
	\@{$reader_mtime} # --> $mtime

=head1 DESCRIPTION

C<Aion::Annotation::Reader> reads the files that L<Aion::Annotation> creates and returns their contents line by line as hashes.

Three types of data are available:

=over

=item 1. Annotations from files B<name.ann> (the name is passed to the constructor).

=item 2. Comments from B<remarks.ini>.

=item 3. Module update times from B<modules.mtime.ini>.

=back

The reader is designed as an iterator on top of a file: the constructor opens the file, and the C<next> method returns the next recognized element. The object overloads a number of operations so that the reader can be used as a file or function directly in expressions.

Recognized strings are represented by hashes:

=over

=item 1. Annotation (file B<etc/annotation/*.ann>) – keys C<pkg>, C<name>, C<line>, C<annotation>.

=item 2. Comment (file B<etc/annotation/remarks.ini>) – keys C<pkg>, C<name>, C<line>, C<remark>.

=item 3. Time (file B<var/cache/modules.mtime.ini>) – keys C<pkg>, C<mtime>.

=back

Directories are configured by the environment variables C<AION_ANNOTATION_INI> (default C<etc/annotation>) and C<AION_ANNOTATION_CACHE> (default C<var/cache>).

=head1 OVERLOAD

C<Aion::Annotation::Reader> overloads the operations:

=head2 <>

The reader's challenge.

	my $reader = Aion::Annotation::Reader->new('todo');
	
	my @ann; push @ann, $_ while <$reader>;
	0+@ann  # -> 2

=head2 @{}

List of all elements.

	my $reader = Aion::Annotation::Reader->new('todo');
	
	my $ann = [
		{pkg => 'For::Test', name => 'abc', line => '5',  annotation => 'add1'},
		{pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'},
	];
	
	\@{$reader} # --> $ann

=head2 &{}

Call as functions.

Each call returns the following element or C<undef> at the end:

	my $reader = Aion::Annotation::Reader->new('todo');
	
	&$reader # --> {pkg => 'For::Test', name => 'abc', line => '5', annotation => 'add1'}
	&$reader # --> {pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'}
	&$reader # -> undef

=head2 *{}

File descriptor.

	my $reader = Aion::Annotation::Reader->new('todo');
	my $fh = *$reader;
	readline $fh  # ~> ^For::Test#abc,5=add1$

=head2 -X

File operations.

Operations like C<-e>, C<-s>, C<-f> are performed on the reader file. The result of the operation is cached:

	my $reader = Aion::Annotation::Reader->new('todo');
	-e $reader # -> 1
	-s $reader # -> 43
	-f $reader # -> 1

=head2 ""

String representation.

	my $reader = Aion::Annotation::Reader->new('todo');
	"$reader" # => Aion::Annotation::Reader<ann,etc/annotation/todo.ann>

=head1 CONSTANTS

=head2 READ_REMARKS

Special name with which the comment file is read:

	Aion::Annotation::Reader::READ_REMARKS  # -> "-remarks"

=head2 READ_MTIME

Special name with which the update times file is read:

	Aion::Annotation::Reader::READ_MTIME  # -> "-mtime"

=head2 MODULES_MTIME_FILE

Update times file name:

	Aion::Annotation::Reader::MODULES_MTIME_FILE  # -> "modules.mtime.ini"

=head2 REMARKS_FILE

Comment file name:

	Aion::Annotation::Reader::REMARKS_FILE  # -> "remarks.ini"

=head2 LINE_REGEX

Annotation or comment string regular expression:

	my $line = 'For::Test#abc,5=add1';
	my ($pkg, $name, $lineno, $text) = $line =~ Aion::Annotation::Reader::LINE_REGEX;
	"$pkg|$name|$lineno|$text"  # -> "For::Test|abc|5|add1"

=head2 MTIME_REGEX

Update time string regular expression:

	my $line = 'For::Test=2025-01-02 03:04:05';
	$line =~ Aion::Annotation::Reader::MTIME_REGEX;
	"$+{module}|$+{year}-$+{mon}-$+{mday} $+{hour}:$+{min}:$+{sec}"  # -> "For::Test|2025-01-02 03:04:05"

=head1 SUBROUTINES

=head2 new ($cls, $ann)

Constructor. C<$ann> is passed the name of the annotation (then reads C<etc/annotation/$ann.ann>), or the constants C<READ_REMARKS> or C<READ_MTIME>. The file opens immediately in the constructor:

	my $reader = Aion::Annotation::Reader->new('todo');
	ref $reader       # -> "Aion::Annotation::Reader"
	$reader->{type}   # -> "ann"
	$reader->path     # -> "etc/annotation/todo.ann"

The call is also valid on an instance:

	my $reader = Aion::Annotation::Reader->new('todo');
	$reader->new('todo')->path  # -> "etc/annotation/todo.ann"

If the file does not exist, an exception is thrown:

	eval { Aion::Annotation::Reader->new('no_such_annotation') };
	$@ # ~> ^etc/annotation/no_such_annotation\.ann: 

=head2 path ()

Path to open file:

	my $reader = Aion::Annotation::Reader->new(Aion::Annotation::Reader::READ_REMARKS);
	$reader->path  # -> "etc/annotation/remarks.ini"

=head2 next ()

Returns the next element recognized. In a scalar context - one element or C<undef>, in a list context - all remaining elements:

	my $reader = Aion::Annotation::Reader->new('todo');
	
	scalar $reader->next # --> {pkg => 'For::Test', name => 'abc', line => '5', annotation => 'add1'}
	scalar $reader->next # --> {pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'}
	scalar $reader->next # -> undef

=head2 DESTROY ()

Closes a file when an object is destroyed. Usually called automatically:

	my $f;
	{
		my $reader = Aion::Annotation::Reader->new('todo');
		$f = $reader->{f};
		defined fileno $f # -> 1
	} # $reader->DESTROY closes the file
	
	fileno $f  # -> undef

=head2 detect_annotation ($self, $line)

Recognizes the annotation string. Returns a hash with the keys C<pkg>, C<name>, C<line>, C<annotation>:

	my $test = {
		pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'
	};
	
	my $reader = Aion::Annotation::Reader->new('todo');
	Aion::Annotation::Reader::detect_annotation($reader, "For::Test#xyz,11=add2\n") # --> $test

=head2 detect_remark ($self, $line)

Recognizes a comment line. Escaped sequences C<\n> are turned into newlines, and C<< \E<lt>characterE<gt> >> into the character itself:

	my $test = {
		pkg => 'For::Test', name => 'abc', line => '9', remark => "Is property\n  readonly"
	};
	
	my $reader = Aion::Annotation::Reader->new('todo');
	Aion::Annotation::Reader::detect_remark($reader, "For::Test#abc,9=Is property\\n  readonly\n") # --> $test

=head2 detect_mtime ($self, $line)

Recognizes the update time string. The C<mtime> field is unixtime (in the local time zone):

	use Time::Local qw/timelocal/;
	
	my $test = {
		pkg => 'For::Test', mtime => timelocal(5, 4, 3, 2, 0, 2025)
	};
	
	my $reader = Aion::Annotation::Reader->new('todo');
	Aion::Annotation::Reader::detect_mtime($reader, "For::Test=2025-01-02 03:04:05\n") # --> $test

=head1 CORRUPT LINES

If the string does not match the format, a C<warn> is issued, but the element is still returned - with undefined fields. This allows you not to interrupt reading on a damaged file:

	use Aion::Annotation::Reader;
	
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, @_ };
	
	my $reader = Aion::Annotation::Reader->new('todo');
	
	Aion::Annotation::Reader::detect_annotation($reader, "corrupt line\n") # --> {pkg => undef, name => undef, line => undef, annotation => undef}
	Aion::Annotation::Reader::detect_remark($reader, "corrupt line\n") # --> {pkg => undef, name => undef, line => undef, remark => ''}
	Aion::Annotation::Reader::detect_mtime($reader, "corrupt line\n") # --> {pkg => undef, mtime => undef}
	
	0+@warn  # -> 3
	$warn[0] # ~> ^etc/annotation/todo\.ann corrupt on line 

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Annotation::Reader module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
