package Aion::Pleroma;
# Контейнер для эонов (сервисов)

use common::sense;

use config {
	INI => 'etc/annotation/eon.ann',
	PLEROMA => {},
	AUTOWARE => 1,
};

use Aion;

# Файл с аннотациями
has ini => (is => 'ro', isa => Maybe[Str], default => INI);

# Конфигурация: ключ => класс#метод_класса
has pleroma => (is => 'ro', isa => HashRef[Str], default => sub {
	my ($self) = @_;
	
	my %pleroma = (%{&PLEROMA}, 'Aion::Pleroma' => 'Aion::Pleroma#new');
	return \%pleroma unless defined $self->ini and -e $self->ini;

	open my $f, '<:utf8', INI or die "Not open ${\$self->ini}: $!";
	while(<$f>) {
		close($f), die "${\$self->ini} corrupt at line $.: $_" unless /^([\w:]+)#(\w*),\d+=(.*)$/;
		my ($pkg, $sub, $key) = ($1, $2, $3);
		my $action = join "#", $pkg, $sub || 'new';

		$key = $key ne ""? $key: ($sub? "$pkg#$sub": $pkg);

		close($f), die "The eon $key is $pleroma{$key}, but added other $action" if exists $pleroma{$key};

		$pleroma{$key} = $action;
	}
	close $f;

	\%pleroma
});

# Совокупность порождённых эонов (сервисов)
has eon => (is => 'ro', isa => HashRef[Object], lazy => 0, default => sub { +{'Aion::Pleroma' => shift} });

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
	elsif(AUTOWARE and $key =~ /^([\w:]+)(#\w+)?$/ and eval "require $1") { $self->autoware($key)->get($key) }
	else { undef }
}

# Получить эон из контейнера или исключение, если его там нет
sub resolve {
	my ($self, $key) = @_;
	
	$self->get($key) // die "$key is'nt eon!"
}

# Добавить в плерому пакет
sub autoware {
	my ($self, $action, $key) = @_;
	my ($pkg, $sub) = $action =~ /#/? ($`, $'): ($action, 'new');
	$action = "$pkg#$sub";
	$key //= $action =~ /#new$/? $pkg: $action;

	if(my $action_exists = $self->pleroma->{$key}) {
		die "Added eon $key twice, with $action ne $action_exists" if $action_exists ne $action;
	}
	else {
		$self->pleroma->{$key} = $action;
	}
	$self
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

=head1 CONFIG

Module settings that can be set in C<.config.pm>:

=over

=item * INI => 'etc/annotation/eon.ann' – annotation file.

=item * PLEROMA => {} – additional set of eons.

=item * AUTOWARE => 1 – load modules automatically, even if they are not specified in the configuration.

=back

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
	
	#@eon
	sub dog { __PACKAGE__->new(role => 'dog') }
	
	1;

File etc/annotation/eon.ann:

	Ex::Eon::AnimalEon#,2=
	Ex::Eon::AnimalEon#cat,10=ex.cat
	Ex::Eon::AnimalEon#dog,13=Ex::Eon::AnimalEon#dog



	Aion::Pleroma->new->pleroma # --> {"Ex::Eon::AnimalEon" => "Ex::Eon::AnimalEon#new", "Ex::Eon::AnimalEon#dog" => "Ex::Eon::AnimalEon#dog", "ex.cat" => "Ex::Eon::AnimalEon#cat", "Aion::Pleroma" => "Aion::Pleroma#new"}

=head2 eon

The totality of generated eons.

	my $pleroma = Aion::Pleroma->new;
	
	$pleroma->eon # --> { "Aion::Pleroma" => $pleroma }
	my $cat = $pleroma->resolve('ex.cat');
	$pleroma->eon # --> { "ex.cat" => $cat, "Aion::Pleroma" => $pleroma }

=head1 SUBROUTINES

=head2 get ($key)

Receive an eon from the container.

	my $pleroma = Aion::Pleroma->new;
	$pleroma->get('') # -> undef
	$pleroma->get('Ex::Eon::AnimalEon#dog')->role # => dog

=head2 resolve ($key)

Get an eon from the container or an exception if it is not there.

	my $pleroma = Aion::Pleroma->new;
	$pleroma->resolve('e.ibex') # @=> e.ibex is'nt eon!
	$pleroma->resolve('Ex::Eon::AnimalEon#dog')->role # => dog

=head2 autoware ($action, [$key])

Add a key to the pleroma.

File lib/Ex/Eon/AstroEon.pm:

	package Ex::Eon::AstroEon;
	use common::sense;
	use Aion;
	
	has role => (is => 'ro', default => 'upiter');
	sub mars { __PACKAGE__->new(role => 'mars') }
	sub venus { __PACKAGE__->new(role => 'venus') }
	
	1;



	my $pleroma = Aion::Pleroma->new;
	$pleroma->autoware('Ex::Eon::AstroEon')->get('Ex::Eon::AstroEon')->role # => upiter
	$pleroma->autoware('Ex::Eon::AstroEon#mars', 'ex.mars')->get('ex.mars')->role # => mars
	$pleroma->autoware('Ex::Eon::AstroEon#venus')->get('Ex::Eon::AstroEon#venus')->role # => venus
	
	$pleroma->autoware('Ex::Eon::AstroEon')->get('Ex::Eon::AstroEon')->role # => upiter
	$pleroma->autoware('Ex::Eon::AstroEon#mars', 'Ex::Eon::AstroEon#venus') # @-> Added eon Ex::Eon::AstroEon#venus twice, with Ex::Eon::AstroEon#mars ne Ex::Eon::AstroEon#venus

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Pleroma module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
