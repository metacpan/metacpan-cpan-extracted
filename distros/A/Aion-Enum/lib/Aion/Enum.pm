package Aion::Enum;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.3";

use constant;
use Aion -role;

# Импорт
sub import {
	my $pkg = caller;
	*{"${pkg}::issa"} = \&issa if $pkg->can('issa') != \&issa;
	*{"${pkg}::case"} = \&case if $pkg->can('case') != \&case;
	eval "package $pkg; use Aion -role; with 'Aion::Enum'; 1" or die
}

sub unimport {
	my $pkg = caller;
	undef &{"${pkg}::issa"};
	undef &{"${pkg}::case"};
	eval "package $pkg; no Aion; 1" or die
}

#@category Свойства
has name  => (is => 'ro');
has value => (is => 'ro');
has stash => (is => 'ro');
has alias => (is => 'ro', default => sub {
    my ($self) = @_;
    $self->_alias->{$self->{name}};
});

#@category Управленцы

# Создать перечисление
sub case(@) {
	my ($name, $value, $stash) = @_;
	
	die "The case name must by 1+ simbol!" unless length $name;
	
	my $pkg = caller;
	my $meta = $Aion::META{$pkg};
	my $issa = $meta->{issa};
	my $enum = $meta->{enum} //= [];
	
	$issa->{name}->validate($name, "$name name") if $issa->{name};
	$issa->{value}->validate($value, "$name value") if $issa->{value};
	$issa->{stash}->validate($stash, "$name stash") if $issa->{stash};
	$issa->{alias}->validate($pkg->_alias->{$name}, "$name alias") if $issa->{alias};
	
	my $case = bless {
        name => $name,
        defined($value)? (value => $value): (),
        defined($stash)? (stash => $stash): (),
    }, $pkg;

    push @$enum, $case;

    constant->import("${pkg}::$name", $case);

    return;
}

# Задаёт типы для value и stash
sub issa(@) {
	my $pkg = caller;
	my ($nameisa, $valueisa, $stashisa, $aliasisa) = map { ref $_ eq '' ? eval "package $pkg; $_" || die : $_ } @_;
	$Aion::META{$pkg}{issa} = {
		name => $nameisa,
		value => $valueisa,
		stash => $stashisa,
		alias => $aliasisa,
	};
	return;
}

#@category Перечисления

# Перечисления
sub cases {
	my ($cls) = @_;
	@{$Aion::META{ref $cls || $cls}{enum}}
}

# Имена
sub names {
	my ($cls) = @_;
	map $_->{name}, $cls->cases
}

# Значения
sub values {
	my ($cls) = @_;
	map $_->{value}, $cls->cases
}

# Дополнения
sub stashes {
	my ($cls) = @_;
	map $_->{stash}, $cls->cases
}

# Псевдонимы
sub aliases {
	my ($cls) = @_;
	map $_->alias, $cls->cases
}

my %ALIAS;
sub _alias {
	my ($cls) = @_;
	$cls = ref $cls || $cls;
	my $alias_ref = $ALIAS{$cls};
	
	return $alias_ref if $alias_ref;
	
	my $alias_ref = $ALIAS{$cls} = {};

    my $path = $INC{($cls =~ s!::!/!gr) . ".pm"};
    die "$cls not loaded!" unless $path;
    open my $f, "<:utf8", $path or die "$path: $!";
    my $alias;
    my $id = '[a-zA-Z_]\w*';
    while(<$f>) {
        $alias = $1 if /^# (\S.*?)\s*$/;

        do {
            $alias_ref->{$+{id}} = $alias;
            undef $alias;
        } if /^case \s+ (
                (?<id>$id)
            | '(?<id>$id)'
            | "(?<id>$id)"
            | q[wq]? (?:
                \{ (?<id>$id) \}
                | \[ (?<id>$id) \]
                | \( (?<id>$id) \)
                | < (?<id>$id) >
                | ([~!\@#$%^&*-+=\\\/|]) (?<id>$id) \2
            )
        )/x;
    }
    close $f;
    
    $alias_ref
}

#@category Конструкторы

# Получить case по имени c исключением
sub fromName {
	my ($cls, $name) = @_;
	my $case = $cls->tryFromName($name);
    die "Did not case with name `$name`!" unless defined $case;
	$case
}

# Получить case по имени
sub tryFromName {
	my ($cls, $name) = @_;
	my ($case) = grep { $_->{name} ~~ $name } $cls->cases;
	$case
}

# Получить case по значению c исключением
sub fromValue {
	my ($cls, $value) = @_;
	my $case = $cls->tryFromValue($value);
    die "Did not case with value `$value`!" unless defined $case;
	$case
}

# Получить case по значению
sub tryFromValue {
	my ($cls, $value) = @_;
	my ($case) = grep { $_->{value} ~~ $value } $cls->cases;
	$case
}

# Получить case по значению c исключением
sub fromStash {
	my ($cls, $stash) = @_;
	my $case = $cls->tryFromStash($stash);
    die "Did not case with stash `$stash`!" unless defined $case;
	$case
}

# Получить case по значению
sub tryFromStash {
	my ($cls, $stash) = @_;
	my ($case) = grep { $_->{stash} ~~ $stash } $cls->cases;
	$case
}

# Получить case по псевдониму c исключением
sub fromAlias {
	my ($cls, $alias) = @_;
	my $case = $cls->tryFromAlias($alias);
    die "Did not case with alias `$alias`!" unless defined $case;
	$case
}

# Получить case по псевдониму
sub tryFromAlias {
	my ($cls, $alias) = @_;
	my ($case) = grep { $_->{alias} ~~ $alias } $cls->cases;
	$case
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion :: Enum - Listing in the style of OOP, when each renewal is an object

=head1 VERSION

0.0.3

=head1 SYNOPSIS

File lib/StatusEnum.pm:

	package StatusEnum;
	
	use Aion::Enum;
	
	# Active status
	case active => 1, 'Active';
	
	# Passive status
	case passive => 2, 'Passive';
	
	1;



	use StatusEnum;
	
	&StatusEnum::active->does('Aion::Enum') # => 1
	
	StatusEnum->active->name   # => active
	StatusEnum->passive->value # => 2
	StatusEnum->active->alias  # => Active status
	StatusEnum->passive->stash # => Passive
	
	[ StatusEnum->cases   ] # --> [StatusEnum->active, StatusEnum->passive]
	[ StatusEnum->names   ] # --> [qw/active passive/]
	[ StatusEnum->values  ] # --> [qw/1 2/]
	[ StatusEnum->aliases ] # --> ['Active status', 'Passive status']
	[ StatusEnum->stashes ] # --> [qw/Active Passive/]

=head1 DESCRIPTION

C<Aion :: Enum> allows you to create transfers-objects. These transfers may contain additional methods and properties. You can add roles to them (using C<with>) or use them as a role.

An important feature is the preservation of the procedure for listing.

C<Aion::Enum> is similar to php8 enums, but has the additional properties C<alias> and C<stash>.

=head1 SUBROUTINES

=head2 case ($name, [$value, [$stash]])

Creates a listing: his constant.

	package OrderEnum {
	    use Aion::Enum;
	
	    case 'first';
	    case second => 2;
	    case other  => 3, {data => 123};
	}
	
	&OrderEnum::first->name  # => first
	&OrderEnum::first->value # -> undef
	&OrderEnum::first->stash # -> undef
	
	&OrderEnum::second->name  # => second
	&OrderEnum::second->value # -> 2
	&OrderEnum::second->stash # -> undef
	
	&OrderEnum::other->name  # => other
	&OrderEnum::other->value # -> 3
	&OrderEnum::other->stash # --> {data => 123}

=head2 issa ($nameisa, [$valueisa], [$stashisa], [$aliasisa])

Indicates the type (ISA) of meanings and additions.

Its name is a reference to the goddess Isse from the story “Under the Moles of Mars” Burrose.

	eval {
	package StringEnum;
	    use Aion::Enum;
	
	    issa Str => Int => Undef => Undef;
	
	    case active => "Active";
	};
	$@ # ~> active value must have the type Int. The it is 'Active'
	
	eval {
	package StringEnum;
	    use Aion::Enum;
	
	    issa Str => Str => Int;
	
	    case active => "Active", "Passive";
	};
	$@ # ~> active stash must have the type Int. The it is 'Passive'

File lib/StringEnum.pm:

	package StringEnum;
	use Aion::Enum;
	
	issa Str => Undef => Undef => StrMatch[qr/^[A-Z]/];
	
	# pushkin
	case active => ;
	
	1;



	require StringEnum # @-> active alias must have the type StrMatch[qr/^[A-Z]/]. The it is 'pushkin'!

=head1 CLASS METHODS

=head2 cases ($cls)

List of transfers.

	[ OrderEnum->cases ] # --> [OrderEnum->first, OrderEnum->second, OrderEnum->other]

=head2 names ($cls)

Names of transfers.

	[ OrderEnum->names ] # --> [qw/first second other/]

=head2 values ($cls)

The values of the transfers.

	[ OrderEnum->values ] # --> [undef, 2, 3]

=head2 stashes ($cls)

Additions of transfers.

	[ OrderEnum->stashes ] # --> [undef, undef, {data => 123}]

=head2 aliases ($cls)

Pseudonyms of transfers.

LIB/authorenum.pm file:

	package AuthorEnum;
	
	use Aion::Enum;
	
	# Pushkin Aleksandr Sergeevich
	case pushkin =>;
	
	# Yacheykin Uriy
	case yacheykin =>;
	
	case nouname =>;
	
	1;



	require AuthorEnum;
	[ AuthorEnum->aliases ] # --> ['Pushkin Aleksandr Sergeevich', 'Yacheykin Uriy', undef]

=head2 fromName ($cls, $name)

Get Case by name with exceptions.

	OrderEnum->fromName('first') # -> OrderEnum->first
	eval { OrderEnum->fromName('not_exists') }; $@ # ~> Did not case with name `not_exists`!

=head2 tryFromName ($cls, $name)

Get Case by name.

	OrderEnum->tryFromName('first')      # -> OrderEnum->first
	OrderEnum->tryFromName('not_exists') # -> undef

=head2 fromValue ($cls, $value)

Get Case by value with exceptions.

	OrderEnum->fromValue(undef) # -> OrderEnum->first
	eval { OrderEnum->fromValue('not-exists') }; $@ # ~> Did not case with value `not-exists`!

=head2 tryFromValue ($cls, $value)

Get Case by value.

	OrderEnum->tryFromValue(undef)        # -> OrderEnum->first
	OrderEnum->tryFromValue('not-exists') # -> undef

=head2 fromStash ($cls, $stash)

Get CASE on addition with exceptions.

	OrderEnum->fromStash(undef) # -> OrderEnum->first
	eval { OrderEnum->fromStash('not-exists') }; $@ # ~> Did not case with stash `not-exists`!

=head2 tryFromStash ($cls, $value)

Get Case for addition.

	OrderEnum->tryFromStash({data => 123}) # -> OrderEnum->other
	OrderEnum->tryFromStash('not-exists')  # -> undef

=head2 fromAlias ($cls, $alias)

Get Case by pseudonym with exceptions.

	AuthorEnum->fromAlias('Yacheykin Uriy') # -> AuthorEnum->yacheykin
	eval { AuthorEnum->fromAlias('not-exists') }; $@ # ~> Did not case with alias `not-exists`!

=head2 tryFromAlias ($cls, $alias)

Get case by alias.

	AuthorEnum->tryFromAlias('Yacheykin Uriy') # -> AuthorEnum->yacheykin
	AuthorEnum->tryFromAlias('not-exists')     # -> undef

=head1 FEATURES

=head2 name

Property only for reading.

	package NameEnum {
	    use Aion::Enum;
	
	    case piter =>;
	}
	
	NameEnum->piter->name # => piter

=head2 value

Property only for reading.

	package ValueEnum {
	    use Aion::Enum;
	
	    case piter => 'Pan';
	}
	
	ValueEnum->piter->value # => Pan

=head2 stash

Property only for reading.

	package StashEnum {
	    use Aion::Enum;
	
	    case piter => 'Pan', 123;
	}
	
	StashEnum->piter->stash # => 123

=head2 alias

Property only for reading.

Aliases work only if the package is in the module, as they read the comment before the case due to reflection.

LIB/aliasenum.pm file:

	package AliasEnum;
	
	use Aion::Enum;
	
	# Piter Pan
	case piter => ;
	
	1;



	require AliasEnum;
	AliasEnum->piter->alias # => Piter Pan

=head1 SEE ALSO

=over

=item 1. L<enum>.

=item 2. L<Class::Enum>.

=back

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

⚖ I<* gplv3 *>

=head1 COPYRIGHT

The Aion :: Enum Module is Copyright © 2025 Yaroslav O. Kosmina. Rusland. All Rights Reserved.
