package Aion::Pleroma;
# Контейнер для эонов (сервисов)

use common::sense;

# Источник конфигурации - аннотации
use config INI => 'etc/annotation/eon.ann';

# Один из источников конфигурации
use config PLEROMA => {};

use Aion;

# Файл с аннотациями
has ini => (is => 'ro', isa => Maybe[Str], default => INI);

# Конфигурация: ключ => класс#метод_класса
has pleroma => (is => 'ro', isa => HashRef[Str], default => sub {
	my ($self) = @_;
	
	my %pleroma = %{&PLEROMA};
	return \%pleroma unless defined $self->ini;
	
	open my $f, '<:utf8', INI or die "Not open ${\$self->ini}: $!";
	while(<$f>) {
		close($f), die "${\$self->ini} corrupt at line $.: $_" unless /^([\w:]+)#(\w*),\d+=(.*)$/;
		my ($pkg, $sub, $key) = ($1, $2, $3);
		my $action = join "#", $pkg, $sub || 'new';
		
		$key = $key ne ""? $key: $pkg;
		
		close($f), die "The eon $key is $pleroma{$key}, but added other $action" if exists $pleroma{$key};
		
		$pleroma{$key} = $action;
	}
	close $f;
	
	\%pleroma
});

# Совокупность порождённых эонов (сервисов)
has eon => (is => 'ro', isa => HashRef[Object], lazy => 0, default => sub { +{} });

# Получить эон из контейнера
sub get {
	my ($self, $key) = @_;
	
	my $eon = $self->{eon}{$key};
	return $eon if $eon;
	
	my $config = $self->pleroma->{$key};
	if($config) {
		my ($pkg, $method) = $config =~ /#/? ($`, $'): ();
		eval "require $pkg" or die unless $pkg->can('new') || $pkg->can('does');
		$self->{eon}{$key} = $pkg->$method;
	}
	else { undef }
}

# Получить эон из контейнера и исключение, если его там нет
sub resolve {
	my ($self, $key) = @_;
	
	$self->get($key) // die "$key is'nt eon!"
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Pleroma - container of aeons

=head1 SYNOPSIS

	use Aion::Pleroma;
	
	my $pleroma = Aion::Pleroma->new;
	
	$pleroma->get('user') # -> undef
	$pleroma->resolve('user') # @-> user is'nt eon!

=head1 DESCRIPTION

Implements the dependency container pattern.

An eon is created when requesting from a container via the C<get> or C<resolve> method, or via the C<eon> aspect as a lazy C<default>. Laziness can be canceled via the C<lazy> aspect.

The container is in the C<$Aion::pleroma> variable and can be replaced with C<local>.

The configuration for creating eons is obtained from the C<PLEROMA> config and the annotation file (created by the C<Aion::Annotation> package). The annotation file can be replaced via the C<INI> config.

=head1 FEATURES

=head2 ini

Annotation file.

	Aion::Pleroma->new->ini # => etc/annotation/eon.ann

=head2 pleroma

Configuration: key => 'class#class_method'.

File lib/Ex/Eon/AnimalEon.pm:

	package Ex::Eon::AnimalEon;
	#@eon
	
	use common::sense;
	
	use Aion;
	 
	has role => (is => 'ro');
	
	#@eon ex.cat
	sub cat { __PACKAGE__->new(role => 'cat') }
	
	#@eon ex.dog
	sub dog { __PACKAGE__->new(role => 'dog') }
	
	1;

File etc/annotation/eon.ann:

	Ex::Eon::AnimalEon#,2=
	Ex::Eon::AnimalEon#cat,10=ex.cat
	Ex::Eon::AnimalEon#dog,13=ex.dog



	Aion::Pleroma->new->pleroma # --> {"Ex::Eon::AnimalEon" => "Ex::Eon::AnimalEon#new", "ex.dog" => "Ex::Eon::AnimalEon#dog", "ex.cat" => "Ex::Eon::AnimalEon#cat"}

=head2 eon

The totality of generated eons.

	my $pleroma = Aion::Pleroma->new;
	
	$pleroma->eon # --> {}
	my $cat = $pleroma->resolve('ex.cat');
	$pleroma->eon # --> { "ex.cat" => $cat }

=head1 SUBROUTINES

=head2 get ($key)

Receive an eon from the container.

	my $pleroma = Aion::Pleroma->new;
	$pleroma->get('') # -> undef
	$pleroma->get('ex.dog')->role # => dog

=head2 resolve ($key)

Get an eon from the container or an exception if it is not there.

	my $pleroma = Aion::Pleroma->new;
	$pleroma->resolve('e.ibex') # @=> e.ibex is'nt eon!
	$pleroma->resolve('ex.dog')->role # => dog

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Pleroma module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
