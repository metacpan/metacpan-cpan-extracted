package Aion::Fs::Cat;

use common::sense;

use overload fallback => 1,
	'*{}' => sub { shift->{f} },
	'-X' => \&_fileop,
	'<>' => sub { shift->next },
	'&{}' => sub {
		my ($self) = @_;
		sub { scalar $self->next }
	},
	'@{}' => sub { [shift->next] },
	'""' => sub { "cat<${\shift->{path}}>" },
;

sub new {
	my $cls = shift;
	bless {@_}, ref $cls || $cls
}

sub path { shift->{path} }

sub next {
	my $f = shift->{f};
	<$f>
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

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Fs::Cat - файловый дескриптор с автозакрытием

=head1 SYNOPSIS

	use Aion::Fs qw/lay/;
	use Aion::Fs::Cat;
	use Symbol;
	
	my $file = "lay.test.txt";
	
	lay $file, "xyz";
	
	my $f = Symbol::gensym;
	open $f, "<", $file;
	
	$f = Aion::Fs::Cat->new(f => $f, path => $file);
	
	-d $f # -> ""
	-f $f # -> 1
	
	read $f, my $buf, 1;
	$buf # => x
	
	<$f> # => yz
	
	$f->path; # => lay.test.txt
	
	undef $f;

=head1 DESCRIPTION

Содержит файловый дескриптор, который закрывается в деструкторе. А благодаря перегрузке операторов C<*{}>, C<-X> и C<< E<lt>E<gt> >> работает со всеми файловыми операциями C<perl>.

Используется в LL<https://metacpan.org/pod/Aion::Fs#icat-(%3B%24path)>.

=head1 SUBROUTINES

=head2 new (%args)

Конструктор.

=head2 path ()

Путь к файлу.

=head2 next ()

Следующая строка.

=head2 DESTROY ()

Деструктор. Закрывает файловый дескриптор.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Fs::Cat module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
