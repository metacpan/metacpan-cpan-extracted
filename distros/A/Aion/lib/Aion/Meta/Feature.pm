package Aion::Meta::Feature;

use common::sense;

use Aion::Meta::Util qw//;
use Aion::Meta::FeatureConstruct;
use List::Util qw/pairmap/;

Aion::Meta::Util::create_getters(qw/pkg name opt has construct order/);
Aion::Meta::Util::create_accessors(qw/
	required excessive isa 
	lazy builder default trigger release cleaner
	make_reader make_writer make_predicate make_clearer
/);

#  Конструктор
sub new {
	my ($cls, $pkg, $name, @has) = @_;

	my $meta = $Aion::META{$pkg};

	bless {
		pkg => $pkg,
		name => $name,
		opt => {@has},
		has => \@has,
		construct => Aion::Meta::FeatureConstruct->new($pkg, $name),
		order => scalar keys %{$meta->{feature}},
		stash => {},
	}, ref $cls || $cls;
}

# Строковое представление фичи
sub stringify {
	my ($self) = @_;
	my $has = join ', ', pairmap { "$a => ${\
		Aion::Meta::Util::val_to_str($b)
	}" } @{$self->{has}};
	return "has $self->{name} => ($has) of $self->{pkg}";
}

# Создаёт свойство
sub mk_property {
	my ($self) = @_;

	my $meta = $Aion::META{$self->pkg};

	my $ASPECT = $meta->{aspect};
	my $has = $self->{has};
	for(my $i=0; $i<@$has; $i+=2) {
		my ($aspect, $value) = @$has[$i, $i+1];
		my $aspect_sub = $ASPECT->{$aspect};
		die "has: not exists aspect `$aspect`!" if !$aspect_sub;
		$aspect_sub->($value, $self, $aspect);
	}
	
	my $accessor = $self->construct->accessor;
	eval $accessor;
	die if $@;

	if($self->{make_reader}) {
		my $reader = $self->construct->reader;
		eval $reader;
		die if $@;
	}
	
	if($self->{make_writer}) {
		my $writer = $self->construct->writer;
		eval $writer;
		die if $@;
	}
	
	if($self->{make_predicate}) {
		my $predicate = $self->construct->predicate;
		eval $predicate;
		die if $@;
	}
	
	if($self->{make_clearer}) {
		my $clearer = $self->construct->clearer;
		eval $clearer;
		die if $@;
	}
}

# Представление себя в коде
sub meta {
	my ($self) = @_;
	$self->{meta} //= do {
		my ($cls, $name) = @$self{qw/pkg name/};
		"\$Aion::META{'$cls'}{feature}{$name}"
	};
}

# Доступ к сташу со свойствами 
sub stash {
	my ($self, $key, $val) = @_;

	my $stash = $self->{stash}{scalar caller} //= {};
	
	@_ > 2? do { $stash->{$key} = $val; $self }: $stash->{$key};
}

# Сравнивает старую фичу с перезагружаемой
sub compare {
	my ($self, $other) = @_;
	
	die "Types mismatch: $other->{isa} <=> $self->{isa}" if $self->{isa} && $self->{isa} ne $other->{isa};
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Meta::Feature - feature metadescriptor

=head1 SYNOPSIS

	use Aion::Meta::Feature;
	
	our $feature = Aion::Meta::Feature->new("My::Package", "my_feature" => (is => 'rw'));
	
	$feature->stringify  # => has my_feature => (is => 'rw') of My::Package

=head1 DESCRIPTION

Describes a feature that is added to the class by the C<has> function.

=head1 METHODS

=head2 pkg

Пакет, к которому относится фича.

	$::feature->pkg # -> "My::Package"

=head2 name

Feature name.

	$::feature->name # -> "my_feature"

=head2 opt

Feature options hash.

	$::feature->opt # --> {is => 'rw'}

=head2 has

An array of feature options in the form of key-value pairs.

	$::feature->has # --> ['is', 'rw']

=head2 construct

Feature constructor object.

	ref $::feature->construct # \> Aion::Meta::FeatureConstruct

=head2 order()

The serial number of the feature in the class.

	$::feature->order # -> 0

=head2 required (;$bool)

Flag for requiring a feature in the constructor (C<new>).

	$::feature->required(1);
	$::feature->required # -> 1

=head2 excessive (;$bool)

Feature redundancy flag in the constructor (C<new>). If it is there, an exception should be thrown.

	$::feature->excessive(1);
	$::feature->excessive # -> 1

=head2 isa (;Object[Aion::Type])

Type constraint on feature value.

	use Aion::Type;
	
	my $Int = Aion::Type->new(name => 'Int');
	
	$::feature->isa($Int);
	$::feature->isa # -> $Int

=head2 lazy (;$bool)

Lazy initialization flag.

	$::feature->lazy(1);
	$::feature->lazy # -> 1

=head2 builder (;$sub)

Feature value builder or C<undef>.

	my $builder = sub {};
	$::feature->builder($builder);
	$::feature->builder # -> $builder

=head2 default (;$value)

Default value for the feature.

	$::feature->default(42);
	$::feature->default # -> 42

=head2 trigger (;$sub)

Event handler for feature value change or C<undef>.

	my $trigger = sub {};
	$::feature->trigger($trigger);
	$::feature->trigger # -> $trigger

=head2 release (;$sub)

Event handler for reading a value from a feature or C<undef>.

	my $release = sub {};
	$::feature->release($release);
	$::feature->release # -> $release

=head2 cleaner (;$sub)

Event handler for removing a feature from an object or C<undef>.

	my $cleaner = sub {};
	$::feature->cleaner($cleaner);
	$::feature->cleaner # -> $cleaner

=head2 make_reader (;$bool)

Flag for creating a reader method.

	$::feature->make_reader(1);
	$::feature->make_reader # -> 1

=head2 make_writer (;$bool)

Flag for creating a writer method.

	$::feature->make_writer(1);
	$::feature->make_writer # -> 1

=head2 make_predicate (;$bool)

Flag for creating a predicate method.

	$::feature->make_predicate(1);
	$::feature->make_predicate # -> 1

=head2 make_clearer (;$bool)

Flag for creating a cleanup method.

	$::feature->make_clearer(1);
	$::feature->make_clearer # -> 1

=head2 new ($pkg, $name, @has)

Feature designer.

	my $feature = Aion::Meta::Feature->new('My::Class', 'attr', is => 'ro', default => 1);
	$feature->pkg # -> "My::Class"
	$feature->name # -> "attr"
	$feature->opt # --> {is => 'ro', default => 1}

=head2 stringify()

String representation of a feature.

	$::feature->stringify # -> "has my_feature => (is => 'rw') of My::Package"

=head2 mk_property()

Creates a property accessor, getter, setter, predicate, and purifier.

	package My::Package { use Aion }
	
	$::feature->mk_property;
	
	!!My::Package->can('my_feature') # -> 1

=head2 meta()

Returns code as text to access the feature's meta information.

	$::feature->meta # \> $Aion::META{'My::Package'}{feature}{my_feature}

=head2 stash ($key; $val)

Access the property store for the calling package.

	$::feature->stash('my_key', 'my_value');
	$::feature->stash('my_key') # -> 'my_value'

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Meta::Feature module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
