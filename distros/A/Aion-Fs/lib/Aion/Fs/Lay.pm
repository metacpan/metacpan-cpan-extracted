package Aion::Fs::Lay;

use common::sense;

use overload fallback => 1,
	'*{}' => sub { shift->{f} },
	'-X' => \&_fileop,
	'""' => sub { "lay<${\shift->{path}}>" },
;

sub new {
	my $cls = shift;
	bless {@_}, ref $cls || $cls
}

sub path { shift->{path} }

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

Aion::Fs::Lay - файловый дескриптор с автозакрытием

=head1 SYNOPSIS

	use Aion::Fs::Lay;
	use Symbol;
	
	my $file = "lay.test.txt";
	
	my $f = Symbol::gensym;
	open $f, ">", $file or die $!;
	
	$f = Aion::Fs::Lay->new(f => $f, path => $file);
	
	printf $f "%s!\n", "hi";
	
	-s $f; # -> 0
	my $std = select $f; $| = 1; select $std;
	-s $f; # -> 4
	
	$f->path; # => lay.test.txt
	
	undef $f;

=head1 DESCRIPTION

Содержит файловый дескриптор, который закрывается в деструкторе. А благодаря перегрузке оператора C<*{}> работает со всеми файловыми операциями B<perl>.

Используется в LL<https://metacpan.org/pod/Aion::Fs#ilay-(%3B%24path)>.

=head1 SUBROUTINES

=head2 new (%params)

Конструктор.

=head2 path ()

Путь к файлу.

=head2 DESTROY ()

Деструктор. Закрывает файловый дескриптор.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Fs::Lay module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
