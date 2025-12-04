package Aion::Annotation;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.3";

# Дефолтный путь для сканирования
use config LIB => ['lib'];

# Директория в которую складывать файлы конфигурации
use config INI => 'etc/annotation';

# Директория с кешем
use config CACHE => 'var/cache';

use Aion::Fs qw/find erase mkpath path mtime from_pkg to_pkg/;
use POSIX qw/strftime/;
use Time::Local qw/timelocal/;

use Aion;

with qw/Aion::Run/;

# Кодовая база для сканирования
has lib => (is => 'ro', isa => ArrayRef[Str], arg => '-l', default => LIB);

# Директория куда сохранять файлы аннотаций
has ini => (is => 'ro', isa => Str, arg => '-i', default => INI);

# Просто считать аннотации
has force => (is => 'ro', isa => Bool, arg => '-f', default => 0);

# Аннотации: annotation_name.pkg.sub_or_has_name => [[line, annotation_desc]...]
has ann => (is => 'ro', isa => HashRef[HashRef[HashRef[ArrayRef[Tuple[Int, Str]]]]], default => sub {
	my $self = shift;
	my %ann;
	return \%ann if $self->force;

	return \%ann if !-d(my $ini = $self->ini);

	while(<$ini/*.ann>) {
		my $path = $_;
		my $annotation_name = path()->{name};
		open my $f, "<:utf8", $_ or do { warn "$_ not opened: $!"; next };
		while(<$f>) {
			warn "$path corrupt on line $.!" unless /^([\w:]+)#(\w*),(\d+)=(.*)$/;
			push @{$ann{$annotation_name}{$1}{$2}}, [$3, $4];
		}
		close $f;
	}

	\%ann
});

# Путь к файлу с комментариями
has remark_path => (is => 'ro', isa => Str, default => sub { shift->ini . "/remarks.ini" });

# Комментарии: pkg.sub_or_has_name => [[line, remark]...]
has remark => (is => 'ro', isa => HashRef[HashRef[Tuple[Int, ArrayRef[Str]]]], default => sub {
	my ($self) = @_;
	my %remark;
	return \%remark if $self->force;

	my $remark_path = $self->remark_path;
	return \%remark if !-e $remark_path;

	open my $f, "<:utf8", $remark_path or do { warn "$remark_path not opened: $!"; return \%remark };
	while(<$f>) {
		warn "$remark_path corrupt on line $.!" unless /^([\w:]+)#(\w*),(\d+)=(.*)$/;
		$remark{$1}{$2} = [$3, [map { s/\\(.)/$1/gr } split /\\n/, $4]];
	}
	close $f;

	\%remark
});

# Путь к файлу с временем последнего доступа к модулям
has modules_mtime_path => (is => 'ro', isa => Str, default => CACHE . "/modules.mtime.ini");

# Время последнего доступа к модулям: pkg => unixtime
has modules_mtime => (is => 'ro', isa => HashRef[Int], default => sub {
	my ($self) = @_;

	my %mtime;
	return \%mtime if $self->force;

	my $mtime_path = $self->modules_mtime_path;
	return \%mtime if !-e $mtime_path;

	open my $f, "<:utf8", $mtime_path or do { warn "$mtime_path not opened: $!"; return 0 };
	while(<$f>) {
		warn "$mtime_path corrupt on line $.!" unless /^(?<module>[\w:]+)=(?<year>\d{4})-(?<mon>\d{2})-(?<mday>\d{2}) (?<hour>\d{2}):(?<min>\d{2}):(?<sec>\d{2})$/;
		$mtime{$+{module}} = timelocal($+{sec}, $+{min}, $+{hour}, $+{mday}, $+{mon} - 1, $+{year});
	}
	close $f;

	\%mtime
});

# Сканирует модули и сохраняет аннотации
#@run aion:scan „Scan modules and save annotations”
sub scan {
	my ($self) = @_;

	my @libs = @{$self->lib};
	s/\/$// for @libs;

	my $modules_mtime = $self->modules_mtime;
	my $ann = $self->ann;
	my $remark = $self->remark;
	my %exists;

	for my $lib (@libs) {
		my $iter = find $lib, "*.pm", "-f";
		while(<$iter>) {
			my $pkg = to_pkg(substr $_, 1 + length $lib);
			$exists{$pkg} = 1;
			my $mtime = int mtime;
			next if !$self->force && exists $modules_mtime->{$pkg} && $modules_mtime->{$pkg} == $mtime;
			$modules_mtime->{$pkg} = $mtime;

			delete $_->{$pkg} for values %$ann;
			delete $remark->{$pkg};

			open my $f, "<:utf8", $_ or do { warn "$_ not opened: $!"; next };
			my @ann; my @rem;
			my $save_annotation = sub {
				my ($name, $pkg1) = @_;
				$pkg1 //= $pkg;
				push @{$ann->{$_->[0]}{$pkg1}{$name}}, $_->[1] for @ann;
				$remark->{$pkg1}{$name} = [$., [@rem]] if @rem;
				@ann = @rem = ();
			};
			while(<$f>) {
				last if /^(__END__|__DATA__)\s*$/;
				push @ann, [$1, [$., $2]] if /^#\@(\w+)\s+(.*?)\s*$/;
				push @rem, $1 if /^#\s(.*?)\s*$/;
				$save_annotation->() if /^\s*$/;
				$save_annotation->($2, $1) if /^sub\s+(?:([\w:]+)::)?(\w+)/;
				$save_annotation->($+{s}) if /^has \s+ (?: (?<s>\w+) | '(?<s>(\\'|[^'])*)' | "(?<s>(\\"|[^"])*)" )/x;
			}
			$save_annotation->();
			close $f;
		}
	}

	# Удаляем пакеты в аннотациях, которых уже нет в проекте
	for my $annotation_name (keys %$ann) {
		my $pkgs = $ann->{$annotation_name};
		for my $pkg (keys %$pkgs) {
			 delete $pkgs->{$pkg} if !exists $exists{$pkg};
		}
	}
	
	mkpath($self->ini . "/");

	# Сохраням аннотации и удаляем файлы с аннотациями, которых уже нет в проекте
	for my $annotation_name (sort keys %$ann) {
		my $pkgs = $ann->{$annotation_name};
		my $path = $self->annotation_path($annotation_name);
		if(!keys %$pkgs) {
			erase($path) if -e $path;
			next;
		}
		open my $f, ">:utf8", $path or do { warn "$path not writed: $!" };
		for my $pkg (sort keys %$pkgs) {
			my $subs = $pkgs->{$pkg};
			for my $sub (sort keys %$subs) {
				my $annotation = $subs->{$sub};
				print $f "$pkg#$sub,$_->[0]=$_->[1]\n" for @$annotation;
			}
		}
		close $f;
	}
	
	# Удаляем временна файлов, которых уже нет в проекте
	for my $pkg (keys %$modules_mtime) {
		delete $modules_mtime->{$pkg} if !exists $exists{$pkg};
	}
	
	# Сохраняем время последнего изменения файлов
	my $mtime_path = mkpath $self->modules_mtime_path;

	open my $f, ">:utf8", $mtime_path or do { warn "$mtime_path not writed: $!" };
	printf $f "%s=%s\n", $_, strftime('%Y-%m-%d %H:%M:%S', localtime $modules_mtime->{$_}) for sort grep { $modules_mtime->{$_} } keys %$modules_mtime;
	close $f;

	# Сохраняем комментарии
	my $remark_path = $self->remark_path;
	open my $f, ">:utf8", $remark_path or do { warn "$remark_path not writed: $!" };
	for my $pkg (sort keys %$remark) {
		next if !exists $exists{$pkg};
		my $subs = $remark->{$pkg};
		for my $sub (sort keys %$subs) {
			my ($line, $rem) = @{$subs->{$sub}};
			print $f "$pkg#$sub,$line=", join("\\n", @$rem), "\n" if @$rem;
		}
	}
	close $f;
	
	$self
}

# Путь к файлу аннотаций
sub annotation_path {
	my ($self, $annotation_name) = @_;
	return $self->ini . "/$annotation_name.ann";
};

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Annotation - processes annotations in perl modules

=head1 VERSION

0.0.3

=head1 SYNOPSIS

lib/For/Test.pm file:

	package For::Test;
	# The package for testing
	#@deprecated for_test
	
	#@deprecated
	#@todo add1
	# Is property
	#   readonly
	has abc => (is => 'ro');
	
	#@todo add2
	#@param Int $a
	#@param Int[] $r
	sub xyz {}
	
	1;



	use Aion::Annotation;
	
	Aion::Annotation->new->scan;
	
	open my $f, '<', 'var/cache/modules.mtime.ini' or die $!; my @modules_mtime = <$f>; chop for @modules_mtime; close $f;
	open my $f, '<', 'etc/annotation/remarks.ini' or die $!; my @remarks = <$f>; chop for @remarks; close $f;
	open my $f, '<', 'etc/annotation/todo.ann' or die $!; my @todo = <$f>; chop for @todo; close $f;
	open my $f, '<', 'etc/annotation/deprecated.ann' or die $!; my @deprecated = <$f>; chop for @deprecated; close $f;
	open my $f, '<', 'etc/annotation/param.ann' or die $!; my @param = <$f>; chop for @param; close $f;
	
	0+@modules_mtime  # -> 1
	$modules_mtime[0] # ~> ^For::Test=\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$
	\@remarks         # --> ['For::Test#,4=The package for testing', 'For::Test#abc,9=Is property\n  readonly']
	\@todo            # --> ['For::Test#abc,6=add1', 'For::Test#xyz,11=add2']
	\@deprecated      # --> ['For::Test#,3=for_test', 'For::Test#abc,5=']
	\@param           # --> ['For::Test#xyz,12=Int $a', 'For::Test#xyz,13=Int[] $r']

=head1 DESCRIPTION

C<Aion::Annotation> scans the perl modules in the B<lib> directory and prints them to the corresponding files in the B<etc/annotation> directory.

You can change B<lib> through the C<LIB> config, and B<etc/annotation> through the C<INI> config.

=over

=item 1. B<modules.mtime.ini> stores the times of the last module update.

=item 2. B<remarks.ini> stores comments for routines, properties and packages.

=item 3. The B<name.ann> files save annotations by their names.

=back

=head1 SUBROUTINES/METHODS

=head2 scan ()

Scans the codebase specified by the C<LIB> config (list of directories, default C<["lib"]>). And it takes out all the annotations and comments and prints them into the corresponding files in the C<INI> directory (by default "etc/annotation").

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Annotation module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All Rights Reserved.
