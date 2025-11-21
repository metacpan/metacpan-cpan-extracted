package Aion::Annotation;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.2-prealpha";

# Дефолтный путь для сканирования
use config LIB => ['lib'];

# Директория в которую складывать файлы конфигурации
use config INI => 'etc/annotation';

use Aion::Fs qw/find erase mkpath mtime to_pkg/;
use POSIX qw/strftime/;
use Time::Local qw/timelocal/;

use Aion;

# Кодовая база для сканирования
has lib => (is => 'ro', isa => ArrayRef[Str], default => LIB);

# Директория куда сохранять файлы аннотаций
has ini => (is => 'ro', isa => Str, default => INI);

# Просто считать аннотации
has force => (is => 'ro', isa => Bool, default => 0);

# Аннотации: annotation_name.pkg.sub_or_has_name => annotation_desc
has ann => (is => 'ro', isa => HashRef[HashRef[HashRef[Str]]], default => sub {
	my $self = shift;
	my %ann;
	return \%ann if $self->force;

	return \%ann if !-d(my $ini = $self->ini);

	while(<$ini/*.ann>) {
		my $path = $_;
		my $annotation_name = path()->{name};
		open my $f, "<:utf8", $_ or do { warn "$_ not opened: $!"; next };
		while(<$f>) {
			warn "$path corrupt on line $.!" unless /^([\w:]+)#(\w*)=(.*)$/;
			$ann{$annotation_name}{$1}{$2} = $3;
		}
		close $f;
	}

	\%ann
});

# Путь к файлу с комментариями
has remark_path => (is => 'ro', isa => Str, default => sub { my $self = shift; $self->ini . "/remarks.ini" });

# Комментарии: pkg.sub_or_has_name => remarks
has remark => (is => 'ro', isa => HashRef[HashRef[ArrayRef[Str]]], default => sub {
	my ($self) = @_;
	my %remark;
	return \%remark if $self->force;

	my $remark_path = $self->remark_path;
	return \%remark if !-e $remark_path;

	open my $f, "<:utf8", $remark_path or do { warn "$remark_path not opened: $!"; return \%remark };
	while(<$f>) {
		warn "$remark_path corrupt on line $.!" unless /^([\w:]+)#(\w*)=(.*)$/;
		$remark{$1}{$2} = [map { s/\\(.)/$1/gr } split /\\n/, $3];
	}
	close $f;

	\%remark
});

# Путь к файлу с временем последнего доступа к модулям
has modules_mtime_path => (is => 'ro', isa => Str, default => sub { my $self = shift; $self->ini . "/modules.mtime.ini" });

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
		$mtime{$+{module}} = [0, timelocal($+{sec}, $+{min}, $+{hour}, $+{mday}, $+{mon} - 1, $+{year})];
	}
	close $f;

	\%mtime
});

# Сканирует модули и сохраняет аннотации
sub scan {
	my ($self) = @_;

	my $libs = $self->lib;
	s/\/$// for @$libs;

	my $modules_mtime = $self->modules_mtime;
	my $ann = $self->ann;
	my $remark = $self->remark;
	
	for my $lib (@$libs) {
		my $iter = find $lib, "*.pm", "-f";
		while(<$iter>) {
			my $pkg = to_pkg(substr $_, 1 + length $lib);
			my $mtime = int mtime;
			next if !$self->force && exists $modules_mtime->{$pkg} && $modules_mtime->{$pkg} == $mtime;
			$modules_mtime->{$pkg} = $mtime;

			delete $_->{$pkg} for values %$ann;
			delete $remark->{$pkg};

			open my $f, "<:utf8", $_ or do { warn "$_ not opened: $!"; next };
			my @ann; my @rem;
			my $save_annotation = sub {
				my ($name) = @_;
				$ann->{$_->[0]}{$pkg}{$name} = $_->[1] for @ann;
				$remark->{$pkg}{$name} = [@rem] if @rem;
				@ann = @rem = ();
			};
			while(<$f>) {
				last if /^(__END__|__DATA__)\s*$/;
				push @ann, [$1, $2] if /^#\@(\w+)\s+(.*?)\s*$/;
				push @rem, $1 if /^#\s(.*?)\s*$/;
				$save_annotation->() if /^\s*$/ && (0+@ann || 0+@rem);
				$save_annotation->($1) if /^sub\s+(\w+)/;
				$save_annotation->($+{s}) if /^has \s+ (?: (?<s>\w+) | '(?<s>(\\'|[^'])*)' | "(?<s>(\\"|[^"])*)" )/x;
			}
			$save_annotation->();
			close $f;
		}
	}

	mkpath($self->ini . "/");

	# Сохраням аннотации и удаляем файлы с аннотациями, которых уже нет в проекте
	for my $annotation_name (sort keys %$ann) {
		my $pkgs = $ann->{$annotation_name};
		my $path = $self->ini . "/$annotation_name.ann";
		unlink($path), next if !keys %$pkgs;
		open my $f, ">:utf8", $path or do { warn "$path not writed: $!" };
		for my $pkg (sort keys %$pkgs) {
			my $subs = $pkgs->{$pkg};
			for my $sub (sort keys %$subs) {
				my $annotation = $subs->{$sub};
				print $f "$pkg#$sub=$annotation\n";
			}
		}
		close $f;
	}
	
	# Сохраняем время последнего изменения файлов
	my $mtime_path = $self->modules_mtime_path;

	open my $f, ">:utf8", $mtime_path or do { warn "$mtime_path not writed: $!" };
	printf $f "%s=%s\n", $_, strftime('%Y-%m-%d %H:%M:%S', localtime $modules_mtime->{$_}) for sort grep { $modules_mtime->{$_} } keys %$modules_mtime;
	close $f;

	# Сохраняем комментарии
	my $remark_path = $self->remark_path;
	open my $f, ">:utf8", $remark_path or do { warn "$remark_path not writed: $!" };
	for my $pkg (sort keys %$remark) {
		my $subs = $remark->{$pkg};
		for my $sub (sort keys %$subs) {
			my $rem = $subs->{$sub};
			print $f "$pkg#$sub=", join("\\n", @$rem), "\n" if @$rem;
		}
	}
	close $f;
	
	$self
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Annotation - processes annotations in perl modules

=head1 VERSION

0.0.2-prealpha

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
	sub xyz {}
	
	1;



	use Aion::Annotation;
	
	Aion::Annotation->new->scan;
	
	open my $f, '<', 'etc/annotation/modules.mtime.ini' or die $!; my @modules_mtime = <$f>; chop for @modules_mtime; close $f;
	open my $f, '<', 'etc/annotation/remarks.ini' or die $!; my @remarks = <$f>; chop for @remarks; close $f;
	open my $f, '<', 'etc/annotation/todo.ann' or die $!; my @todo = <$f>; chop for @todo; close $f;
	open my $f, '<', 'etc/annotation/deprecated.ann' or die $!; my @deprecated = <$f>; chop for @deprecated; close $f;
	
	0+@modules_mtime  # -> 1
	$modules_mtime[0] # ~> ^For::Test=\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$
	\@remarks         # --> ['For::Test#=The package for testing', 'For::Test#abc=Is property\n  readonly']
	\@todo            # --> ['For::Test#abc=add1', 'For::Test#xyz=add2']
	\@deprecated      # --> ['For::Test#=for_test', 'For::Test#abc=']

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
