package Aion::Pleroma;
# Контейнер для эонов (сервисов)

use common::sense;

use Aion::Env AION_PLEROMA_INI => (default => 'etc/annotation/eon.ann');
use Aion::Env AION_PLEROMA_AUTOWARE => (default => 1);
use Aion::Env::Etc EON => (default => {}, key => 'aion.eon');

use Aion;

# Файл с аннотациями
has ini => (is => 'ro', isa => Maybe[Str], default => AION_PLEROMA_INI);

# Конфигурация: ключ => хеш-описание эона (class, method, arguments, calls)
has pleroma => (is => 'ro?!', isa => HashRef, default => sub {
	my ($self) = @_;

	$self->{pleroma} = {};
	$self->autoware('Aion::Pleroma');
	for my $key (keys %{&EON}) { $self->autoware(EON->{$key}, $key) }

	return $self->pleroma unless defined $self->ini and -e $self->ini;

	open my $f, '<:encoding(UTF-8)', $self->ini or die "Not open ${\$self->ini}: $!";
	while(<$f>) {
		do { close $f; die "${\$self->ini} corrupt at line $.: $_" } unless /^([\w:]+)#(\w*),\d+=(.*)$/;
		my ($pkg, $sub, $key) = ($1, $2, $3);

		$key = $key ne ""? $key: ($sub? "$pkg#$sub": $pkg);

		$self->autoware(+{class => $pkg, method => $sub || 'new'}, $key);
	}
	close $f;

	$self->pleroma
});

# Совокупность порождённых эонов-сервисов
has eon => (is => 'ro', isa => HashRef[Object], lazy => 0, default => sub { +{'Aion::Pleroma' => shift} });

# Получить эон из контейнера
sub get {
	my ($self, $key) = @_;
	
	my $eon = $self->{eon}{$key};
	return $eon if $eon;
	
	my $config = _hash_config($self->pleroma->{$key});
	if($config) {
		$self->{eon}{$key} = $self->_build($key, $config);
	}
	elsif(AION_PLEROMA_AUTOWARE and $key =~ /^([\w:]+)(#\w+)?$/ and _find_pm($1)) { $self->autoware($key)->get($key) }
	else { undef }
}

# Получить эон из контейнера или исключение, если его там нет
sub resolve {
	my ($self, $key) = @_;
	
	$self->get($key) // die "$key is'nt eon!";
}

# Добавить в плерому эон. $config — строка 'класс#метод' либо хеш (class, method, arguments, calls)
sub autoware {
	my ($self, $config, $key) = @_;

	$config = _hash_config($config) unless ref $config eq 'HASH';
	my $pkg = $config->{class} // die "autoware: class is undef!";
	my $sub = $config->{method} // 'new';
	my $action = "$pkg#$sub";
	$key //= $sub eq 'new'? $pkg: $action;

	my $pleroma = $self->pleroma;
	my $exists = $pleroma->{$key};
	if(defined $exists) {
		my $str = _string_config($exists);
		die "Added eon $key twice, with $action ne $str" if $str ne $action;
		return $self;
	}

	$pleroma->{$key} = $config;

	# При добавлении нового ключа проверяем, не замкнулся ли цикл ссылок
	$self->_check_cycle($key);

	$self
}

# Пройти по @-ссылкам от $key и выбросить исключение, если цепочка замкнулась на себя
sub _check_cycle {
	my ($self, $start) = @_;

	my %visiting;
	my $walk;
	$walk = sub {
		my ($key, $path) = @_;

		die "Circular eon dependency: " . join(' -> ', @$path, $key)
			if exists $visiting{$key};

		my $pleroma = $self->pleroma;
		my $conf = _hash_config($pleroma->{$key}) or return;

		$visiting{$key} = 1;
		$walk->($_, [@$path, $key]) for _conf_refs($conf);
		delete $visiting{$key};
	};

	$walk->($start, []);
}

# Ключи эонов, на которые ссылается конфигурация (значения, начинающиеся с '@')
sub _conf_refs {
	my ($conf) = @_;
	return () unless $conf;
	my @refs;
	my $collect;
	$collect = sub {
		my ($v) = @_;
		if(defined $v && !ref $v) {
			push @refs, $1 if $v =~ /^@(.+)/;
		}
		elsif(ref $v eq 'ARRAY') { $collect->($_) for @$v }
		elsif(ref $v eq 'HASH')  { $collect->($_) for values %$v }
	};
	$collect->($conf);
	@refs
}

# Построить эон из хеш-описания: class, method, arguments, calls
sub _build {
	my ($self, $key, $conf) = @_;

	my $pkg = $conf->{class} // ($key =~ /^[\w:]+$/a ? $key : undef)
		// die "Eon $key: class is undef! Optional 'class' key or key-as-class.";
	my $method = $conf->{method} // 'new';

	_require($pkg);

	my $args = $conf->{arguments} // {};
	$args = $self->_resolve_args($args);

	my $eon = $self->_construct("$pkg#$method", $args);

	for my $call (@{ $conf->{calls} // [] }) {
		my ($name, @call_args);
		if(ref $call eq 'ARRAY') { ($name, @call_args) = @$call }
		else { $name = $call }
		@call_args = map { $self->_resolve_value($_) } @call_args;
		$eon->$name(@call_args);
	}

	$eon
}

# Вызвать конструктор: именованные (hashref) или упорядоченные (arrayref) аргументы
sub _construct {
	my ($self, $action, $args) = @_;
	my ($pkg, $method) = $action =~ /^([^#]+)#(.+)$/? ($1, $2): ($action, 'new');

	_require($pkg);

	ref($args) eq 'ARRAY'? $pkg->$method(@$args): $pkg->$method(%$args);
}

# Подгрузить пакет, если он ещё не определён в памяти
sub _require {
	my ($pkg) = @_;
	return if $pkg->can('new') || $pkg->can('does');
	$pkg =~ s!::!/!g;
	$pkg =~ s!\z!.pm!;
	require $pkg;
}

# Есть ли файл такого пакета на @INC (для ветки autoware в get)
sub _find_pm {
	my ($pkg) = @_;
	return 1 if $pkg->can('new') || $pkg->can('does');
	my $path = $pkg =~ s!::!/!gr;
	$path .= '.pm';
	for my $dir (@INC) {
		next if ref $dir;
		return 1 if -e "$dir/$path";
	}
	''
}

# Строковое действие -> хеш-конфигурация {class, method}
sub _hash_config {
	my ($action) = @_;
	return $action if ref $action eq 'HASH';
	return undef unless defined $action && $action ne '';
	my ($pkg, $method) = $action =~ /^([^#]+)#(.+)$/? ($1, $2): ($action, 'new');
	+{ class => $pkg, method => $method };
}

# Хеш-конфигурация -> строковое действие 'класс#метод'
sub _string_config {
	my ($conf) = @_;
	return undef unless defined $conf && ref $conf eq 'HASH';
	join '#', @$conf{qw/class method/};
}

# Заменить в аргументах ссылки "@key" на эоны
sub _resolve_args {
	my ($self, $args) = @_;
	if(ref $args eq 'ARRAY') {
		+[ map { $self->_resolve_value($_) } @$args ]
	}
	else {
		+{ map { $_ => $self->_resolve_value($args->{$_}) } keys %$args }
	}
}

# Значение, начинающееся с "@", воспринимается как ссылка на эон
sub _resolve_value {
	my ($self, $val) = @_;
	return $val unless defined $val && !ref $val && $val =~ /^@(.+)/;
	$self->resolve($1);
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

The container can be obtained using C<< Aion-E<gt>pleroma >>.

The configuration for creating eons is obtained from the C<PLEROMA> config and the annotation file (created by the C<Aion::Annotation> package). The annotation file can be replaced via the C<INI> config.

=head1 CONFIG

Module settings that can be set in C<.env>:

=over

=item * AION_PLEROMA_INI – annotation file. Defaults to C<etc/annotation/eon.ann>.

=item * AION_PLEROMA_AUTOWARE – load modules automatically, even if they are not specified in the configuration. Default is C<1>.

=back

=head1 EONS FROM CONFIG

You can add the C<aion.eon> key to C<etc/*.yml> with a description of additional eons. This allows you to assemble eons declaratively: specify constructor arguments (named or ordered), call methods after creation, and pass references to other eons via C<@>.

Let us describe the classes of eons.

File lib/Ex/Eon/Astronomer.pm:

	package Ex::Eon::Astronomer;
	use strict; use warnings;
	
	sub new { my ($class, $name, $telescope) = @_; bless { name => $name, telescope => $telescope, seen => [] }, $class }
	sub name      { $_[0]{name} }
	sub telescope { $_[0]{telescope} }
	sub seen      { $_[0]{seen} }
	sub observe   {
		my ($self, $body) = @_;
		die "body is'nt Planet!" unless $body && $body->isa('Ex::Eon::Planet');
		push @{ $self->{seen} }, $body;
		$body
	}
	
	1;

File lib/Ex/Eon/Planet.pm:

	package Ex::Eon::Planet;
	use common::sense;
	use Aion;
	
	has name       => (is => 'ro');
	has moons      => (is => 'ro', default => 0);
	has discoverer => (is => 'ro');
	
	1;

Now the configuration of the eons. The eon-scientist C<Ex::Eon::Galileo> has arguments specified in order (C<arguments> is an array), after creation the C<observe> method is called with a link to another eon (C<@Ex::Eon::Saturn>). For planets, C<arguments> is a hash, and the C<discoverer> argument refers (C<@>) to the scientist's eon.

File etc/aion/include.yml:

	aion:
	  eon:
	    Ex::Eon::Jupiter:
	      class: 'Ex::Eon::Planet'
	      arguments:
	        name: 'Jupiter'
	        moons: 95
	        discoverer: '@Ex::Eon::Galileo'
	    Ex::Eon::Saturn:
	      class: 'Ex::Eon::Planet'
	      arguments:
	        name: 'Saturn'
	        moons: 146
	    Ex::Eon::Galileo:
	      class: 'Ex::Eon::Astronomer'
	      arguments: [ 'Galileo Galilei', 'refracting telescope' ]
	      calls:
	        - [observe, '@Ex::Eon::Saturn']

In the configuration, the eon C<Ex::Eon::Jupiter> is described before C<Ex::Eon::Galileo> (which it refers to via C<@>). The order of description is not important: eons are generated lazily when requested, so the C<@> link is resolved to a ready-made eon.

Let's read the configuration from C<etc/aion/include.yml> and pass it to the container.

	use Aion::Pleroma;
	use Aion::Env::Etc ();
	
	my $etc = Aion::Env::Etc::parse('etc/aion/include.yml');
	my $pleroma = Aion::Pleroma->new(pleroma => $etc->{aion}{eon});
	
	my $jupiter = $pleroma->resolve('Ex::Eon::Jupiter');
	$jupiter->name    # => Jupiter
	$jupiter->moons   # => 95
	$jupiter->discoverer->name # => Galileo Galilei
	ref($jupiter->discoverer)  # => Ex::Eon::Astronomer
	
	my $galileo = $pleroma->resolve('Ex::Eon::Galileo');
	$galileo->name  # => Galileo Galilei
	$galileo->telescope  # => refracting telescope
	ref($galileo->seen->[0])  # => Ex::Eon::Planet
	$galileo->seen->[0]->name # => Saturn

=head2 Circular dependency

If eons refer to each other, then the container will not be able to spawn them. The cycle is calculated already when adding an eon (C<autoware>) - at the stage of assembling the configuration - and an exception with a chain of references is thrown.

	my $cnt = Aion::Pleroma->new;
	$cnt->autoware({ class => 'Ex::Eon::Galileo', arguments => [ 'Galileo Galilei', 'refracting telescope' ], calls => [[ 'observe', '@Ex::Eon::Jupiter' ]] }, 'Ex::Eon::Galileo');
	$cnt->autoware({ class => 'Ex::Eon::Planet', arguments => { name => 'Jupiter', moons => 95, discoverer => '@Ex::Eon::Galileo' } }, 'Ex::Eon::Jupiter') # @~> Circular eon dependency: .+Ex::Eon::Jupiter

=head2 Eon description keys

Each eon in C<aion.eon> is described by a string or hash.

The line specifies the constructor C<'class#method'> (or just C<'class'>), the default method is C<new>. This is how the simplest eons are created without arguments.

The hash can contain the keys:

=over

=item * C<class> – class (package) of the eon. If not specified and the eon key is similar to the class name (C</^[\w:]+$/>), the key itself is used.

=item * C<method> – method of the constructor class. Defaults to C<new>.

=item * C<arguments> – constructor arguments:

=item * hash – named arguments (C<< new =E<gt> %hash >>);

=item * array – ordered arguments (C<< new =E<gt> @array >>).

=item * C<calls> – list of method calls after eon creation. Each call is a method name (without arguments) or an array C<[method_name, arguments...]>.

=back

An argument (or call element) value starting with C<@> is treated as a reference to another eon: C<@key> is replaced by the child eon from the container.

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



	Aion::Pleroma->new->pleroma # --> { "Ex::Eon::AnimalEon#dog" => { class => "Ex::Eon::AnimalEon", method => "dog" }, "Ex::Eon::AnimalEon" => { class => "Ex::Eon::AnimalEon", method => "new" }, "ex.cat" => { class => "Ex::Eon::AnimalEon", method => "cat" }, "Aion::Pleroma" => { class => "Aion::Pleroma", method => "new" } }

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

=head2 autoware ($config, [$key])

Add an aeon to the pleroma. C<$config> – the string C<'class#method'> (or just C<'class'>) or a hash with the keys C<class>, C<method>, and optionally C<arguments>/C<calls> (see above). If C<$key> is not specified, it is output from the configuration.

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
	
	$pleroma->autoware({class => 'Ex::Eon::AstroEon', method => 'venus'})->get('Ex::Eon::AstroEon#venus')->role # => venus
	
	$pleroma->autoware('Ex::Eon::AstroEon')->get('Ex::Eon::AstroEon')->role # => upiter
	$pleroma->autoware('Ex::Eon::AstroEon#mars', 'Ex::Eon::AstroEon#venus') # @-> Added eon Ex::Eon::AstroEon#venus twice, with Ex::Eon::AstroEon#mars ne Ex::Eon::AstroEon#venus

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Pleroma module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
