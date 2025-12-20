package Aion::Types;
# Типы-валидаторы для Aion

use common::sense;

use Aion::Meta::Util qw/subref_is_reachable/;
use Aion::Type;
use List::Util qw/all any first/;
use Exporter qw/import/;
require overload;
use Scalar::Util qw/looks_like_number reftype refaddr blessed/;
use Sub::Util qw//;

our @EXPORT = our @EXPORT_OK = grep {
	*{$Aion::Types::{$_}}{CODE}	&& !/^(_|(NaN|import|all|any|first|looks_like_number|reftype|refaddr|blessed|subref_is_reachable)\z)/n
} keys %Aion::Types::;

# Обрабатываем атрибут :Isa
sub MODIFY_CODE_ATTRIBUTES {
    my ($pkg, $referent, @attributes) = @_;

    grep { /^Isa\((.*)\)\z/s? do { _Isa($pkg, $referent, $1); 0 }: 1 } @attributes
}

sub _Isa {
	my ($pkg, $referent, $data) = @_;
	my $subname = Sub::Util::subname $referent;
	$subname =~ s/^.*:://;

	die "Anonymous subroutine cannot use :Isa!" if $subname eq '__ANON__';
	
	my @signature = eval "package $pkg; map { UNIVERSAL::isa(\$_, 'Aion::Type')? \$_: __PACKAGE__->can(\$_)? __PACKAGE__->can(\$_)->(): Aion::Types::External([\$_]) } ($data)";
	die if $@;

	die "$pkg\::$subname has no return type!" if @signature == 0;

	require Aion::Meta::Subroutine;
	my $subroutine = Aion::Meta::Subroutine->new(
		pkg => $pkg,
		subname => $subname,
		signature => \@signature,
		referent => $referent,
	);
	
	if(!subref_is_reachable($referent)) {
		$Aion::META{$pkg}{require}{$subname} = $subroutine;
	} else {
		my $require = delete $Aion::META{$pkg}{require}{$subname};
		$require->compare($subroutine) if $require;

		my $overload = $Aion::META{$pkg}{subroutine}{$subname};
		$overload->compare($subroutine) if $overload;
		
		$subroutine->wrap_sub;
	}	
}

BEGIN {
my $TRUE = sub {1};
my $INIT_ARGS = sub { @{&ARGS} = map External([$_]), @{&ARGS} };
my $INIT_KW_ARGS = sub { @{&ARGS} = List::Util::pairmap { $a => External([$b]) } @{&ARGS} };

# Создание типа
sub subtype(@) {
	my $subtype = shift;
	my %o = @_;

	my ($as, $init_where, $where, $awhere, $message) = delete @o{qw/as init_where where awhere message/};

	$as = External([$as]) if defined $as;
	
	die "subtype $subtype unused keys left: " . join ", ", keys %o if keys %o;

	die "subtype format is Name or Name[args] or Name`[args]" if $subtype !~ /^([A-Z_]\w*)(?:(\`)?\[(.*)\])?$/i;
	my ($name, $is_maybe_arg, $is_arg) = ($1, $2, $3);

	my $pkg = scalar caller;
	die "subtype $subtype: ${pkg}::$name exists!" if *{"${pkg}::$name"}{CODE};

	if($is_maybe_arg) {
		die "subtype $subtype: needs an awhere" if !$awhere;
	} else {
		die "subtype $subtype: awhere is excess" if $awhere;
	}

	die "subtype $subtype: needs a where" if $is_arg && !($where || $awhere);

	my $init_types = do { given($is_arg) {
		$INIT_ARGS when /^[A-Z]\w*(,\s*[A-Z]\w*)?\.\.\.$/;
		$INIT_KW_ARGS when /^[a-z]\w*\s*=>\s*[A-Z],?\s*\.\.\.$/;
		when(/\b[A-Z]\b/) {
			my @args = split /\s*,\s*/, $is_arg;
			my @typeno = grep { $args[$_] =~ /^[A-Z]/ } 0..@args-1;
			(sub { my ($typeno) = @_; sub {
				my $args = &ARGS;
				$args->[$_] = External([$args->[$_]]) for @$typeno;
			} })->(\@typeno);
		}
	}};
	
	if($init_types) {
		$init_where = $init_where
			? (sub { my ($t, $w) = @_; sub { $t->(); $w->() } })->($init_types, $init_where)
			: $init_types;
	}
	
	if($as && $as->{test} != $TRUE) {
		if(!$where && !$awhere) {
			$where = (sub { my ($as) = @_; sub { $as->test } })->($as);
		} else {
			$where = (sub { my ($as, $where) = @_; sub { $as->test && $where->(@_) } })->($as, $where) if $where;
			$awhere = (sub { my ($as, $awhere) = @_; sub { $as->test && $awhere->(@_) } })->($as, $awhere) if $awhere;
		}
	}

	# Тут coerce - прототип - единый для всех порождаемых типов одного типа с разными аргументами
	my $type = Aion::Type->new(name => $name, coerce => []);

	$type->{message} = $message if $message;
	$type->{init} = $init_where if $init_where;
	$type->{as} = $as if $as;

	if($is_maybe_arg) {
		$type->{test} = $where;
		$type->{a_test} = $awhere;
		$type->make_maybe_arg($pkg)
	} elsif($is_arg || $init_where) {
		$type->{test} = $where;
		$type->make_arg($pkg, $is_arg? '$': '')
	} else {
		$type->{test} = $where // $TRUE;
		$type->make($pkg)
	}
}
}

sub as($) { (as => @_) }
sub init_where(&@) { (init_where => @_) }
sub where(&@) { (where => @_) }
sub awhere(&@) { (awhere => @_) }
sub message(&@) { (message => @_) }

sub SELF() { $Aion::Type::SELF }
sub ARGS() { wantarray? @{$Aion::Type::SELF->{args}}: $Aion::Type::SELF->{args} }
sub A() { $Aion::Type::SELF->{args}[0] }
sub B() { $Aion::Type::SELF->{args}[1] }
sub C() { $Aion::Type::SELF->{args}[2] }
sub D() { $Aion::Type::SELF->{args}[3] }

sub M() :lvalue { $Aion::Type::SELF->{M} }
sub N() :lvalue { $Aion::Type::SELF->{N} }

# Создание транслятора. У типа может быть сколько угодно трансляторов из других типов
# coerce Type, from OtherType, via {...}
sub coerce(@) {
	my ($type, %o) = @_;
	my ($from, $via) = delete @o{qw/from via/};

	die "coerce $type unused keys left: " . join ", ", keys %o if keys %o;
	die "coerce $type not Aion::Type!" unless UNIVERSAL::isa($type, "Aion::Type");
	die "coerce $type: from is'nt Aion::Type!" unless UNIVERSAL::isa($from, "Aion::Type");
	die "coerce $type: via is not subroutine!" unless ref $via eq "CODE";

	push @{$type->{coerce}}, [$from, $via];
	return;
}

sub from($) { (from => $_[0]) }
sub via(&) { (via => $_[0]) }

BEGIN {

subtype "Any";
	subtype "Control", as &Any;
		subtype "Union[A, B...]", as &Control,
			where { my $val = $_; any { $_->include($val) } ARGS };
		subtype "Intersection[A, B...]", as &Control,
			where { my $val = $_; all { $_->include($val) } ARGS };
		subtype "Exclude[A...]", as &Control,
			where { my $val = $_; !any { $_->include($val) } ARGS };
		subtype "Option[A]", as &Control,
			init_where {
				SELF->{is_option} = 1;
				Tuple([Object(["Aion::Type"])])->validate(scalar ARGS, "Arguments Option[A]")
			}
			where { A->test };
		subtype "Wantarray[A, S]", as &Control,
			init_where {
				SELF->{is_wantarray} = 1;
				Tuple([Object(["Aion::Type"]), Object(["Aion::Type"])])->validate(scalar ARGS, "Arguments Wantarray[A, S]")
			}
			where { ... };


	subtype "Item", as &Any;
		sub External($) {
			local $_ = $_[0][0];
			UNIVERSAL::isa($_, 'Aion::Type')? $_:
			defined($_) && ref $_ eq ""? Object([$_]): do {
				CodeLike()->validate($_, "External type");
				Aion::Type->new(
					name => 'External',
					as => &Item,
					args => $_[0],
					test => $_,
					UNIVERSAL::can($_, 'coerce')
						? (coerce => [[&Any, (sub { my ($ex) = @_; sub { $ex->coerce } })->($_)]])
						: (),
				)
			}
		}
		subtype "Bool", as &Item, where { ref $_ eq "" and /^(1|0|)\z/ };
		subtype "BoolLike", as &Item, where {
			return 1 if overload::Method($_, 'bool');
			my $m = overload::Method($_, '0+');
			Bool()->include($m ? $m->($_) : $_) };
		subtype "Enum[e...]", as &Item, where { $_ ~~ ARGS };
		subtype "Maybe[A]", as &Item, where { !defined($_) || A->test };
		subtype "Undef", as &Item, where { !defined $_ };
		subtype "Defined", as &Item, where { defined $_ };
			subtype "Value", as &Defined, where { "" eq ref $_ };
				subtype "Version", as &Value, where { "VSTRING" eq ref \$_ };
				subtype "Str", as &Value, where { "SCALAR" eq ref \$_ };
					subtype "Uni", as &Str,	where { utf8::is_utf8($_) || /[\x80-\xFF]/a };
					subtype "Bin", as &Str, where { !utf8::is_utf8($_) && !/[\x80-\xFF]/a };
					subtype "NonEmptyStr", as &Str,	where { /\S/ };
					subtype "StartsWith[start]", as &Str,
						init_where { M = qr/^${\ quotemeta A}/ },
						where { $_ =~ M };
					subtype "EndsWith[end]", as &Str,
						init_where { N = qr/${\ quotemeta A}$/ },
						where { $_ =~ N };
					subtype "Email", as &Str, where { /@/ };
					subtype "Tel", as &Str, where { /^\+\d{7,}\z/ };
					subtype "Url", as &Str, where { /^https?:\/\// };
					subtype "Path", as &Str, where { /^\// };
					subtype "Html", as &Str, where { /^\s*<(!doctype\s+html|html)\b/i };
					subtype "StrDate", as &Str, where { /^\d{4}-\d{2}-\d{2}\z/ };
					subtype "StrDateTime", as &Str, where { /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/ };
					subtype "StrMatch[regexp]", as &Str, where { $_ =~ A };
					subtype "ClassName", as &Str, where { !!$_->can('new') };
					subtype "RoleName", as &Str, where { !$_->can('new') && !!(@{"$_\::ISA"} || first { *{$_}{CODE} } values %{"$_\::"}) };
					subtype "StrRat", as &Str, where { m!\s*/\s*!? &Num->include($`) && &Num->include($`): &Num->test };
					subtype "Num", as &Str, where { looks_like_number($_) && /[\dfn]\z/i };
						subtype "PositiveNum", as &Num, where { $_ >= 0 };
						subtype "Int", as &Num,	where { /^[-+]?\d+\z/ };
							subtype "PositiveInt", as &Int, where { $_ >= 0 };
							subtype "Nat", as &Int, where { $_ > 0 };


			subtype "Ref", as &Defined, where { "" ne ref $_ };
				subtype "Tied`[class]", as &Ref,
					where { my $ref = reftype($_); !!(
						$ref eq "HASH"? tied %$_:
						$ref eq "ARRAY"? tied @$_:
						$ref eq "SCALAR"? tied $$_:
						0
					) }
					awhere { my $ref = reftype($_);
						$ref eq "HASH"? A eq ref tied %$_:
						$ref eq "ARRAY"? A eq ref tied @$_:
						$ref eq "SCALAR"? A eq ref tied $$_:
						""
					};
				subtype "LValueRef", as &Ref, where { ref $_ eq "LVALUE" };
				subtype "FormatRef", as &Ref, where { ref $_ eq "FORMAT" };
				subtype "CodeRef", as &Ref, where { ref $_ eq "CODE" };
					subtype "NamedCode[subname]", as &CodeRef, where { Sub::Util::subname($_) ~~ A };
					subtype "ProtoCode[prototype]", as &CodeRef, where { Sub::Util::prototype($_) ~~ A };
					subtype "ForwardRef", as &CodeRef, where { !subref_is_reachable($_) };
					subtype "ImplementRef", as &CodeRef, where { subref_is_reachable($_) };
					subtype "Isa[type...]", as &CodeRef,
						init_where {
						    my $pkg = caller(2);
							SELF->{args} = [ map { External([UNIVERSAL::isa($_, 'Aion::Type')? $_: $pkg->can($_)? $pkg->can($_)->(): $_]) } ARGS ]
						}
						where {
							my $subroutine = $Aion::Isa{pack "J", refaddr $_} or return "";
							my $signature = $subroutine->{signature};
							my $args = ARGS;
							return "" if @$signature != @$args;
							my $i = 0;
							for my $type (@$args) {
								return "" unless $signature->[$i++] eq $type;
							}
							1
						};
				subtype "RegexpRef", as &Ref, where { ref $_ eq "Regexp" };
				subtype "ValueRef`[A]", as &Ref,
					where { ref($_) ~~ ["SCALAR", "REF"] }
					awhere { ref($_) ~~ ["SCALAR", "REF"] && A->include($$_) };
					subtype "ScalarRef`[A]", as &ValueRef,
						where { ref $_ eq "SCALAR" }
						awhere { ref $_ eq "SCALAR" && A->include($$_) };
					subtype "RefRef`[A]", as &ValueRef,
						where { ref $_ eq "REF" }
						awhere { ref $_ eq "REF" && A->include($$_) };
				subtype "GlobRef", as &Ref, where { ref $_ eq "GLOB" };
					subtype "FileHandle", as &GlobRef,
						where { !!*$_{IO} };
				subtype "ArrayRef`[A]", as &Ref,
					where { ref $_ eq "ARRAY" }
					awhere { my $A = A; ref $_ eq "ARRAY" && all { $A->test } @$_ };
				subtype "HashRef`[A]", as &Ref,
					where { ref $_ eq "HASH" }
					awhere { my $A = A; ref $_ eq "HASH" && all { $A->test } values %$_ };
				subtype "Object`[class]", as &Ref,
					where { blessed($_) ne "" }
					awhere { blessed($_) && $_->isa(A) };
					subtype "Me", as &Object,
						init_where { SELF->{me} = caller(2) }
						where { UNIVERSAL::isa($_, SELF->{me}) };
				subtype "Map[K, V]", as &HashRef,
					where {
						my ($K, $V) = ARGS;
						while(my ($k, $v) = each %$_) {
							return "" unless $K->include($k) && $V->include($v);
						}
						return 1;
					};

				my $tuple_args = ArrayRef([Object(['Aion::Type'])]);
				subtype "Tuple[A...]", as &ArrayRef,
					init_where { $tuple_args->validate(scalar ARGS, "Arguments Tuple[A...]") }
					where {
						my $k = 0;
						for my $A (ARGS) {
							return "" if $A->exclude($_->[$k++]);
						}
						$k == @$_
					};
				subtype "CycleTuple[A...]", as &ArrayRef,
					init_where { $tuple_args->validate(scalar ARGS, "Arguments CycleTuple[A...]") }
					where {
						my $k = 0;
						while($k < @$_) {
							for my $A (ARGS) {
								return "" if $A->exclude($_->[$k++]);
							}
						}
						$k == @$_
					};
				my $dict_args = CycleTuple([&Str, Object(['Aion::Type'])]);
				subtype "Dict[k => A, ...]", as &HashRef,
					init_where { $dict_args->validate(scalar ARGS, "Arguments Dict[k => A, ...]") }
					where {
						my $count = 0; my $k;
						for my $A (ARGS) {
							$k = $A, next unless ref $A;
							if(exists $_->{$k}) {
								return "" if $A->exclude($_->{$k});
								$count++;
							} else {
								return "" if !exists $A->{is_option};
							}
						}
						$count == keys %$_
					};
			subtype "RegexpLike", as &Ref,
				where { reftype($_) eq "REGEXP" || !!overload::Method($_, 'qr') };
			subtype "CodeLike", as &Ref,
				where { reftype($_) eq "CODE" || !!overload::Method($_, '&{}') };
			subtype "ArrayLike`[A]", as &Ref,
				where { reftype($_) eq "ARRAY" || !!overload::Method($_, '@{}') }
				awhere { &ArrayLike->test && do { my $A = A; all { $A->test } @$_ }};
				my $init_limit = sub { if(@{&ARGS} == 1) { SELF->{min} = 0; SELF->{max} = A } else { SELF->{min} = A; SELF->{max} = B } };
				subtype "Lim[from, to?]", as &ArrayLike,
					init_where => $init_limit,
					where { SELF->{min} <= @$_ && @$_ <= SELF->{max} };
			subtype "HashLike`[A]", as &Ref,
				where { reftype($_) eq "HASH" || !!overload::Method($_, "%{}") }
				awhere { &HashLike->test && do { my $A = A; all { $A->test } values %$_ }};
					subtype "HasProp[p...]", as &HashLike,
						where { my $x = $_; all { exists $x->{$_} } ARGS };
					subtype "LimKeys[from, to?]", as &HashLike,
						init_where => $init_limit,
						where { SELF->{min} <= scalar keys %$_ && scalar keys %$_ <= SELF->{max} };
						
		subtype "Like", as (&Str | &Object);
			subtype "HasMethods[m...]", as &Like,
				where { my $x = $_; all { $x->can($_) } ARGS };
			subtype "Overload`[m...]", as &Like,
				where { !!overload::Overloaded($_) }
				awhere { my $x = $_; all { overload::Method($x, $_) } ARGS };
			subtype "InstanceOf[class...]", as &Like, where { my $x = $_; all { $x->isa($_) } ARGS };
			subtype "ConsumerOf[role...]", as &Like, where { my $x = $_; all { $x->DOES($_) } ARGS };
			subtype "StrLike", as &Like, where { !blessed($_) or !!overload::Method($_, '""') };
				subtype "Len[from, to?]", as &StrLike,
					init_where => $init_limit,
					where { SELF->{min} <= length($_) && length($_) <= SELF->{max} };

			subtype "NumLike", as &Like, where { looks_like_number($_) };
				subtype "Float", as &NumLike, where { -3.402823466E+38 <= $_ && $_ <= 3.402823466E+38 };

				my $_from; my $_to;
				subtype "Double", as &NumLike, where {
					$_from //= do { require Math::BigFloat; Math::BigFloat->new('-1.7976931348623157e+308') };
					$_to   //= do { require Math::BigFloat; Math::BigFloat->new( '1.7976931348623157e+308') };
					$_from <= $_ && $_ <= $_to;
				};
				subtype "Range[from, to]", as &NumLike, where { A <= $_ && $_ <= B };

				my $_8bits;
				subtype "Bytes[n]", as &NumLike,
					init_where {
						my $bits = A < 8? 8: ($_8bits //= do {
							require Math::BigInt;
							Math::BigInt->new(8)
						});
						my $N = 1 << ($bits * A - 1);
						N = -$N;
						M = $N-1;
					}
					where { N <= $_ && $_ <= M };
				subtype "PositiveBytes[n]", as &NumLike,
					init_where {
						my $bits = A < 8? 8: ($_8bits //= do {
							require Math::BigInt;
							Math::BigInt->new(8)
						});
						M = (1 << ($bits*A)) - 1;
					}
					where { 0 <= $_ && $_ <= M };

	coerce &Str => from &Undef => via { "" };
	coerce &Int => from &Num => via { int($_+($_ < 0? -.5: .5)) };
	coerce &Bool => from &Any => via { !!$_ };
	
	subtype 'Join[separator]', as &Str, where { 1 };
	coerce &Join, from &ArrayRef, via { join A, @$_ };
	
	subtype 'Split[separator]', as &ArrayRef, where { 1 };
	coerce &Split, from &Str, via { [split A, $_] };
	
	subtype "Rat", as 'Math::BigRat', where { 1 };
	coerce &Rat => from &StrRat => via { Math::BigRat->new($_) };
};

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Types - a library of standard validators and it is used to create new validators

=head1 SYNOPSIS

	use Aion::Types;
	
	BEGIN {
		subtype SpeakOfKitty => as StrMatch[qr/\bkitty\b/i],
			message { "Speak is'nt included kitty!" };
	}
	
	"Kitty!" ~~ SpeakOfKitty # -> 1
	"abc"    ~~ SpeakOfKitty # -> ""
	
	SpeakOfKitty->validate("abc", "This") # @-> Speak is'nt included kitty!
	
	
	BEGIN {
		subtype IntOrArrayRef => as (Int | ArrayRef);
	}
	
	[] ~~ IntOrArrayRef  # -> 1
	35 ~~ IntOrArrayRef  # -> 1
	"" ~~ IntOrArrayRef  # -> ""
	
	
	coerce IntOrArrayRef, from Num, via { int($_ + .5) };
	
	IntOrArrayRef->coerce(5.5) # => 6

=head1 DESCRIPTION

This module exports routines:

=over

=item * C<subtype>, C<as>, C<init_where>, C<where>, C<awhere>, C<message> - for creating validators.

=item * C<SELF>, C<ARGS>, C<A>, C<B>, C<C>, C<D>, C<M>, C<N> - for use in validators of a type and its arguments.

=item * C<coerce>, C<from>, C<via> - to create a value converter from one class to another.

=back

Validator hierarchy:

	Any
		Control
			Union[A, B...]
			Intersection[A, B...]
			Exclude[A...]
			Option[A]
			Wantarray[A, B]
		Item
			External[type]
			Bool
			BoolLike
			Enum[e...]
			Maybe[A]
			Undef
			Defined
				Value
					Version
					Str
						Uni
						Bin
						NonEmptyStr
						StartsWith[start]
						EndsWith[end]
						Email
						Tel
						Url
						Path
						Html
						StrDate
						StrDateTime
						StrMatch[regexp]
						ClassName
						RoleName
						Join[separator]
						Split[separator]
						StrRat
						Num
							PositiveNum
							Int
								PositiveInt
								Nat
				Ref
					Tied`[class]
					LValueRef
					FormatRef
					CodeRef
						NamedCode[subname]
						ProtoCode[prototype]
						ForwardRef
						ImplementRef
						Isa[A...]
					RegexpRef
					ValueRef`[A]
						ScalarRef`[A]
						RefRef`[A]
					GlobRef
						FileHandle
					ArrayRef`[A]
					HashRef`[A]
					Object`[class]
						Me
						Rat
					Map[A => B]
					Tuple[A...]
					CycleTuple[A...]
					Dict[k => A, ...]
					RegexpLike
					CodeLike
					ArrayLike`[A]
						Lim[from, to?]
					HashLike`[A]
						HasProp[p...]
						LimKeys[from, to?]
				Like
					HasMethods[m...]
					Overload`[m...]
					InstanceOf[class...]
					ConsumerOf[role...]
					StrLike
						Len[from, to?]
					NumLike
						Float
						Double
						Range[from, to]
						Bytes[n]
						PositiveBytes[n]

=head1 SUBROUTINES

=head2 subtype ($name, @paraphernalia)

Creates a new type.

	BEGIN {
		subtype One => where { $_ == 1 } message { "Actual 1 only!" };
	}
	
	1 ~~ One	 # -> 1
	0 ~~ One	 # -> ""
	eval { One->validate(0) }; $@ # ~> Actual 1 only!

C<where> and C<message> are syntactic sugar, and C<subtype> can be used without them.

	BEGIN {
		subtype Many => (where => sub { $_ > 1 });
	}
	
	2 ~~ Many  # -> 1
	
	eval { subtype Many => (where1 => sub { $_ > 1 }) }; $@ # ~> subtype Many unused keys left: where1
	
	eval { subtype 'Many' }; $@ # ~> subtype Many: main::Many exists!

=head2 as ($super_type)

Used with C<subtype> to extend the created C<$super_type> type.

=head2 init_where ($code)

Initializes a type with new arguments. Used with C<subtype>.

	BEGIN {
		subtype 'LessThen[n]',
			init_where { Num->validate(A, "Argument LessThen[n]") }
			where { $_ < A };
	}
	
	eval { LessThen["string"] }; $@  # ^=> Argument LessThen[n]
	
	5 ~~ LessThen[5]  # -> ""

=head2 where ($code)

Uses C<$code> as a test. The value for the test is passed to C<$_>.

	BEGIN {
		subtype 'Two',
			where { $_ == 2 };
	}
	
	2 ~~ Two # -> 1
	3 ~~ Two # -> ""

Used with C<subtype>. Required if the type has arguments.

	subtype 'Ex[a]' # @-> subtype Ex[a]: needs a where

=head2 awhere ($code)

Used with C<subtype>.

If the type can be with or without arguments, then it is used to check the set with arguments, and C<where> - without.

	BEGIN {
		subtype 'GreatThen`[num]',
			where { $_ > 0 }
			awhere { $_ > A }
		;
	}
	
	0 ~~ GreatThen # -> ""
	1 ~~ GreatThen # -> 1
	
	3 ~~ GreatThen[3] # -> ""
	4 ~~ GreatThen[3] # -> 1

Required if arguments are optional.

	subtype 'Ex`[a]', where {} # @-> subtype Ex`[a]: needs an awhere
	subtype 'Ex', awhere {} # @-> subtype Ex: awhere is excess
	
	BEGIN {
		subtype 'MyEnum`[item...]',
			as Str,
			awhere { $_ ~~ scalar ARGS }
		;
	}
	
	"ab" ~~ MyEnum[qw/ab cd/] # -> 1

=head2 SELF

Current type. C<SELF> is used in C<init_where>, C<where> and C<awhere>.

=head2 ARGS

Arguments of the current type. In a scalar context, it returns a reference to an array, and in an array context, it returns a list. Used in C<init_where>, C<where> and C<awhere>.

=head2 A, B, C, D

The first, second, third and fifth type arguments.

	BEGIN {
		subtype "Seria[a,b,c,d]", where { A < B && B < $_ && $_ < C && C < D };
	}
	
	2.5 ~~ Seria[1,2,3,4] # -> 1

Used in C<init_where>, C<where> and C<awhere>.

=head2 M, N

C<M> and C<N> are shorthand for C<< SELF-E<gt>{M} >> and C<< SELF-E<gt>{N} >>.

	BEGIN {
		subtype "BeginAndEnd[begin, end]",
			init_where {
				N = qr/^${\ quotemeta A}/;
				M = qr/${\ quotemeta B}$/;
			}
			where { $_ =~ N && $_ =~ M };
	}
	
	"Hi, my dear!" ~~ BeginAndEnd["Hi,", "!"]; # -> 1
	"Hi my dear!" ~~ BeginAndEnd["Hi,", "!"];  # -> ""
	
	"" . BeginAndEnd["Hi,", "!"] # => BeginAndEnd['Hi,', '!']

=head2 message ($code)

Used with C<subtype> to print an error message if the value excludes the type. C<$code> uses: C<SELF> - the current type, C<ARGS>, C<A>, C<B>, C<C>, C<D> - type arguments (if any) and a test value in C<$_>. It can be converted to a string using C<< SELF-E<gt>val_to_str($_) >>.

=head2 coerce ($type, from => $from, via => $via)

Adds a new cast (C<$via>) to C<$type> from C<$from> type.

	BEGIN {subtype Four => where {4 eq $_}}
	
	"4a" ~~ Four # -> ""
	
	Four->coerce("4a") # -> "4a"
	
	coerce Four, from Str, via { 0+$_ };
	
	Four->coerce("4a")	# -> 4
	
	coerce Four, from ArrayRef, via { scalar @$_ };
	
	Four->coerce([1,2,3])           # -> 3
	Four->coerce([1,2,3]) ~~ Four   # -> ""
	Four->coerce([1,2,3,4]) ~~ Four # -> 1

C<coerce> throws exceptions:

	eval {coerce Int, via1 => 1}; $@  # ~> coerce Int unused keys left: via1
	eval {coerce "x"}; $@  # ~> coerce x not Aion::Type!
	eval {coerce Int}; $@  # ~> coerce Int: from is'nt Aion::Type!
	eval {coerce Int, from "x"}; $@  # ~> coerce Int: from is'nt Aion::Type!
	eval {coerce Int, from Num}; $@  # ~> coerce Int: via is not subroutine!
	eval {coerce Int, (from=>Num, via=>"x")}; $@  # ~> coerce Int: via is not subroutine!

Standard casts:

	# Str from Undef — empty string
	Str->coerce(undef) # -> ""
	
	# Int from Num — rounded integer
	Int->coerce(2.5)  # -> 3
	Int->coerce(-2.5) # -> -3
	
	# Bool from Any — 1 or ""
	Bool->coerce([]) # -> 1
	Bool->coerce(0)  # -> ""

=head2 from ($type)

Syntactic sugar for C<coerce>.

=head2 via ($code)

Syntactic sugar for C<coerce>.

=head1 ATTRIBUTES

=head2 :Isa (@signature)

Checks the signature of a subroutine: arguments and results.

	sub minint($$) : Isa(Int => Int => Int) {
		my ($x, $y) = @_;
		$x < $y? $x : $y
	}
	
	minint 6, 5; # -> 5
	eval {minint 5.5, 2}; $@ # ~> Arguments of method `minint` must have the type Tuple\[Int, Int\]\.
	
	sub half($) : Isa(Int => Int) {
		my ($x) = @_;
		$x / 2
	}
	
	half 4; # -> 2
	eval {half 5}; $@ # ~> Return of method `half` must have the type Int. The it is 2.5

=head1 TYPES

=head2 Any

The top level type in the hierarchy. Compares everything.

=head2 Control

The top-level type in hierarchy constructors creates new types from any types.

=head2 Union[A, B...]

Union of several types. Similar to the C<$type1 | $type2>.

	33  ~~ Union[Int, Ref] # -> 1
	[]  ~~ Union[Int, Ref]	# -> 1
	"a" ~~ Union[Int, Ref]	# -> ""

=head2 Intersection[A, B...]

The intersection of several types. Similar to the C<$type1 & $type2> operator.

	15 ~~ Intersection[Int, StrMatch[/5/]] # -> 1

=head2 Exclude[A, B...]

Exclusion of several types. Similar to the C<~$type> operator.

	-5  ~~ Exclude[PositiveInt] # -> 1
	"a" ~~ Exclude[PositiveInt] # -> 1
	5   ~~ Exclude[PositiveInt] # -> ""
	5.5 ~~ Exclude[PositiveInt] # -> 1

If C<Exclude> has many arguments, then it is analogous to C<~ ($type1 | $type2 ...)>.

	-5  ~~ Exclude[PositiveInt, Enum[-2]] # -> 1
	-2  ~~ Exclude[PositiveInt, Enum[-2]] # -> ""
	0   ~~ Exclude[PositiveInt, Enum[-2]] # -> ""

=head2 Option[A]

Additional keys in C<Dict>.

	{a=>55} ~~ Dict[a=>Int, b => Option[Int]]          # -> 1
	{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]]   # -> 1
	{a=>55, b=>31.5} ~~ Dict[a=>Int, b => Option[Int]] # -> ""

=head2 Wantarray[A, S]

If the routine returns different values in array and scalar contexts, then the C<Wantarray> type is used with type C<A> for the array context and type C<S> for the scalar context.

	sub arr : Isa(PositiveInt => Wantarray[ArrayRef[PositiveInt], PositiveInt]) {
		my ($n) = @_;
		wantarray? 1 .. $n: $n
	}
	
	my @a = arr(3);
	my $s = arr(3);
	
	\@a # --> [1,2,3]
	$s  # -> 3

=head2 Item

The top-level type in the hierarchy of scalar types.

=head2 External[type]

Sets C<type> to C<Aion::Type>.

=over

=item * If C<type> is C<Aion::Type>, then returns it unchanged.

=item * If C<type> is a string, then wraps it in C<Object>.

=item * If C<type> can be called, then wraps it in C<< Aion::Type-E<gt>new(test =E<gt> $type, ...) >>. And if it has a C<coerce> method, it will use it for transformations. Thanks to this, it is possible to use external types like C<Type::Tiny> in the C<Aion> ecosystem.

=back

	External['Aion'] # -> Object['Aion']
	External[sub { /^x/ }] ~~ 'xyz' # -> 1
	
	package MyInt {
		use overload "&{}" => sub {
			sub { /^[+-]?[0-9]+$/ }
		};
		
		sub coerce { /\./? int($_): $_ }
	}
	
	my $myint = bless {}, 'MyInt';
	
	External([$myint]) ~~ '+123' # -> 1
	External([$myint])->coerce(10.1) # => 10
	External([$myint])->coerce('abc') # => abc

=head2 Bool

C<1> is true. C<0>, C<""> or C<undef> is false.

	1 ~~ Bool  # -> 1
	0 ~~ Bool  # -> 1
	undef ~~ Bool # -> 1
	"" ~~ Bool # -> 1
	
	2 ~~ Bool  # -> ""
	[] ~~ Bool # -> ""

=head2 Enum[A...]

Enumeration.

	3 ~~ Enum[1,2,3];            # -> 1
	"cat" ~~ Enum["cat", "dog"]; # -> 1
	4 ~~ Enum[1,2,3];            # -> ""

=head2 Maybe[A]

C<undef> or type in C<[]>.

	undef ~~ Maybe[Int] # -> 1
	4 ~~ Maybe[Int]     # -> 1
	"" ~~ Maybe[Int]    # -> ""

=head2 Undef

Only C<undef>.

	undef ~~ Undef # -> 1
	0 ~~ Undef     # -> ""

=head2 Defined

Everything except C<undef>.

	\0 ~~ Defined    # -> 1
	undef ~~ Defined # -> ""

=head2 Value

Defined values without references.

	3 ~~ Value  # -> 1
	\3 ~~ Value    # -> ""
	undef ~~ Value # -> ""

=head2 Len[from, to?]

Specifies a length value from C<from> to C<to>, or from 0 to C<from> if C<to> is missing.

	"1234" ~~ Len[3]   # -> ""
	"123" ~~ Len[3]    # -> 1
	"12" ~~ Len[3]     # -> 1
	"" ~~ Len[1, 2]    # -> ""
	"1" ~~ Len[1, 2]   # -> 1
	"12" ~~ Len[1, 2]  # -> 1
	"123" ~~ Len[1, 2] # -> ""

=head2 Version

Perl version.

	1.1.0 ~~ Version   # -> 1
	v1.1.0 ~~ Version  # -> 1
	v1.1 ~~ Version    # -> 1
	v1 ~~ Version      # -> 1
	1.1 ~~ Version     # -> ""
	"1.1.0" ~~ Version # -> ""

=head2 Str

Strings, including numbers.

	1.1 ~~ Str   # -> 1
	"" ~~ Str    # -> 1
	1.1.0 ~~ Str # -> ""

=head2 Uni

Unicode strings with the utf8 flag or if decoding to utf8 occurs without errors.

	"↭" ~~ Uni # -> 1
	123 ~~ Uni # -> ""
	do {no utf8; "↭" ~~ Uni} # -> 1

=head2 Bin

Binary strings without the utf8 flag and octets with numbers less than 128.

	123 ~~ Bin # -> 1
	"z" ~~ Bin # -> 1
	"↭" ~~ Bin # -> ""
	do {no utf8; "↭" ~~ Bin }   # -> ""

=head2 StartsWith[begin]

The line starts with C<begin>.

	"Hi, world!" ~~ StartsWith["Hi,"]; # -> 1
	"Hi world!" ~~ StartsWith["Hi,"];  # -> ""

=head2 EndsWith[end]

The line ends with C<end>.

	"Hi, world!" ~~ EndsWith["world!"]; # -> 1
	"Hi, world" ~~ EndsWith["world!"];  # -> ""

=head2 NonEmptyStr

A string containing one or more non-blank characters.

	" " ~~ NonEmptyStr              # -> ""
	" S " ~~ NonEmptyStr            # -> 1
	" S " ~~ (NonEmptyStr & Len[2]) # -> ""

=head2 Email

Lines with C<@>.

	'@' ~~ Email     # -> 1
	'a@a.a' ~~ Email # -> 1
	'a.a' ~~ Email   # -> ""

=head2 Tel

The telephone format is a plus sign and seven or more digits.

	"+1234567" ~~ Tel  # -> 1
	"+1234568" ~~ Tel  # -> 1
	"+ 1234567" ~~ Tel # -> ""
	"+1234567 " ~~ Tel # -> ""

=head2 Url

Website URLs are a string prefixed with http:// or https://.

	"http://" ~~ Url # -> 1
	"http:/" ~~ Url  # -> ""

=head2 Path

Paths start with a slash.

	"/" ~~ Path  # -> 1
	"/a/b" ~~ Path  # -> 1
	"a/b" ~~ Path   # -> ""

=head2 Html

HTML starts with C<< E<lt>!doctype html >> or C<< E<lt>html >>.

	"<HTML" ~~ Html            # -> 1
	" <html" ~~ Html           # -> 1
	" <!doctype html>" ~~ Html # -> 1
	" <html1>" ~~ Html         # -> ""

=head2 StrDate

Date in C<yyyy-mm-dd> format.

	"2001-01-12" ~~ StrDate # -> 1
	"01-01-01" ~~ StrDate   # -> ""

=head2 StrDateTime

Date and time in the format C<yyyy-mm-dd HH:MM:SS>.

	"2012-12-01 00:00:00" ~~ StrDateTime  # -> 1
	"2012-12-01 00:00:00 " ~~ StrDateTime # -> ""

=head2 StrMatch[regexp]

Matches a string against a regular expression.

	' abc ' ~~ StrMatch[qr/abc/]  # -> 1
	' abbc ' ~~ StrMatch[qr/abc/] # -> ""

=head2 ClassName

The class name is a package with a C<new> method.

	'Aion::Type' ~~ ClassName  # -> 1
	'Aion::Types' ~~ ClassName # -> ""

=head2 RoleName

The role name is a package without the C<new> method, with C<@ISA>, or with any one method.

	package ExRole1 {
		sub any_method {}
	}
	
	package ExRole2 {
		our @ISA = qw/ExRole1/;
	}
	
	
	'ExRole1' ~~ RoleName    # -> 1
	'ExRole2' ~~ RoleName    # -> 1
	'Aion::Type' ~~ RoleName # -> ""
	'Nouname::Empty::Package' ~~ RoleName # -> ""

=head2 StrRat

String representation of rational numbers.

Since in perl rational numbers are supported using the C<bigrat> pragma, which turns all rational numbers into C<Math::BigRat>, it is used in a ghost to C<Rat>.

	"6/7" ~~ StrRat  # -> 1
	"-6/7" ~~ StrRat # -> 1
	"+6/7" ~~ StrRat # -> 1
	6 ~~ StrRat      # -> 1
	"inf" ~~ StrRat  # -> 1
	"+Inf" ~~ StrRat # -> 1
	"NaN" ~~ StrRat  # -> 1
	"-nan" ~~ StrRat # -> 1
	6.5 ~~ StrRat    # -> 1
	"6.5 " ~~ StrRat # -> ''

=head2 Rat

Rational numbers. Short for C<Object['Math::BigRat']>. Has a ghost.

	use Math::BigRat;
	use Math::BigFloat;
	use Math::BigInt;
	
	"6/7" ~~ Rat # -> ""
	Math::BigRat->new("6/7") ~~ Rat # -> 1

=head2 Num

Numbers.

	-6.5 ~~ Num   # -> 1
	6.5e-7 ~~ Num # -> 1
	"6.5 " ~~ Num # -> ""

=head2 PositiveNum

Positive numbers.

	0 ~~ PositiveNum    # -> 1
	0.1 ~~ PositiveNum  # -> 1
	-0.1 ~~ PositiveNum # -> ""
	-0 ~~ PositiveNum   # -> 1

=head2 Float

A machine floating point number is 4 bytes.

	-4.8 ~~ Float             # -> 1
	-3.402823466E+38 ~~ Float # -> 1
	+3.402823466E+38 ~~ Float # -> 1
	-3.402823467E+38 ~~ Float # -> ""

=head2 Double

A machine floating point number is 8 bytes.

	use Scalar::Util qw//;
	
	                      -4.8 ~~ Double # -> 1
	'-1.7976931348623157e+308' ~~ Double # -> 1
	'+1.7976931348623157e+308' ~~ Double # -> 1
	'-1.7976931348623159e+308' ~~ Double # -> ""

=head2 Range[from, to]

Numbers between C<from> and C<to>.

	1 ~~ Range[1, 3]   # -> 1
	2.5 ~~ Range[1, 3] # -> 1
	3 ~~ Range[1, 3]   # -> 1
	3.1 ~~ Range[1, 3] # -> ""
	0.9 ~~ Range[1, 3] # -> ""

=head2 Int

Whole numbers.

	123 ~~ Int	# -> 1
	-12 ~~ Int	# -> 1
	5.5 ~~ Int	# -> ""

=head2 Bytes[N]

Calculates the maximum and minimum numbers that will fit in C<N> bytes and checks the constraint between them.

	-129 ~~ Bytes[1] # -> ""
	-128 ~~ Bytes[1] # -> 1
	127 ~~ Bytes[1]  # -> 1
	128 ~~ Bytes[1]  # -> ""
	
	# 2 bits power of (8 bits * 8 bytes - 1)
	my $N = 1 << (8*8-1);
	(-$N-1) ~~ Bytes[8] # -> ""
	(-$N) ~~ Bytes[8]   # -> 1
	($N-1) ~~ Bytes[8]  # -> 1
	$N ~~ Bytes[8]      # -> ""
	
	require Math::BigInt;
	
	my $N17 = 1 << (8*Math::BigInt->new(17) - 1);
	
	((-$N17-1) . "") ~~ Bytes[17] # -> ""
	(-$N17 . "") ~~ Bytes[17]     # -> 1
	(($N17-1) . "") ~~ Bytes[17]  # -> 1
	($N17 . "") ~~ Bytes[17]      # -> ""

=head2 PositiveInt

Positive integers.

	+0 ~~ PositiveInt # -> 1
	-0 ~~ PositiveInt # -> 1
	55 ~~ PositiveInt # -> 1
	-1 ~~ PositiveInt # -> ""

=head2 PositiveBytes[N]

Calculates the maximum number that will fit in C<N> bytes (assuming there is no negative bit in the bytes) and checks the limit from 0 to that number.

	-1 ~~ PositiveBytes[1]  # -> ""
	0 ~~ PositiveBytes[1]   # -> 1
	255 ~~ PositiveBytes[1] # -> 1
	256 ~~ PositiveBytes[1] # -> ""
	
	-1 ~~ PositiveBytes[8]   # -> ""
	1.01 ~~ PositiveBytes[8] # -> ""
	0 ~~ PositiveBytes[8]    # -> 1
	
	my $N8 = 2 ** (8*Math::BigInt->new(8)) - 1;
	
	$N8 . "" ~~ PositiveBytes[8]     # -> 1
	($N8+1) . "" ~~ PositiveBytes[8] # -> ""
	
	-1 ~~ PositiveBytes[17] # -> ""
	0 ~~ PositiveBytes[17]  # -> 1

=head2 Nat

Integers 1+.

	0 ~~ Nat	# -> ""
	1 ~~ Nat	# -> 1

=head2 Ref

Link.

	\1 ~~ Ref # -> 1
	[] ~~ Ref # -> 1
	1 ~~ Ref  # -> ""

=head2 Tied`[A]

Link to the associated variable.

	package TiedHash { sub TIEHASH { bless {@_}, shift } }
	package TiedArray { sub TIEARRAY { bless {@_}, shift } }
	package TiedScalar { sub TIESCALAR { bless {@_}, shift } }
	
	tie my %a, "TiedHash";
	tie my @a, "TiedArray";
	tie my $a, "TiedScalar";
	my %b; my @b; my $b;
	
	\%a ~~ Tied # -> 1
	\@a ~~ Tied # -> 1
	\$a ~~ Tied # -> 1
	
	\%b ~~ Tied  # -> ""
	\@b ~~ Tied  # -> ""
	\$b ~~ Tied  # -> ""
	\\$b ~~ Tied # -> ""
	
	ref tied %a     # => TiedHash
	ref tied %{\%a} # => TiedHash
	
	\%a ~~ Tied["TiedHash"]   # -> 1
	\@a ~~ Tied["TiedArray"]  # -> 1
	\$a ~~ Tied["TiedScalar"] # -> 1
	
	\%a ~~ Tied["TiedArray"]   # -> ""
	\@a ~~ Tied["TiedScalar"]  # -> ""
	\$a ~~ Tied["TiedHash"]    # -> ""
	\\$a ~~ Tied["TiedScalar"] # -> ""

=head2 LValueRef

The function allows assignment.

	ref \substr("abc", 1, 2) # => LVALUE
	ref \vec(42, 1, 2) # => LVALUE
	
	\substr("abc", 1, 2) ~~ LValueRef # -> 1
	\vec(42, 1, 2) ~~ LValueRef # -> 1

But it doesn't work with C<:lvalue>.

	sub abc: lvalue { $_ }
	
	abc() = 12;
	$_ # => 12
	ref \abc()  # => SCALAR
	\abc() ~~ LValueRef	# -> ""
	
	
	package As {
		sub x : lvalue {
			shift->{x};
		}
	}
	
	my $x = bless {}, "As";
	$x->x = 10;
	
	$x->x # => 10
	$x	# --> bless {x=>10}, "As"
	
	ref \$x->x			 # => SCALAR
	\$x->x ~~ LValueRef # -> ""

And on the end:

	\1 ~~ LValueRef	# -> ""
	
	my $x = "abc";
	substr($x, 1, 1) = 10;
	
	$x # => a10c
	
	LValueRef->include( \substr($x, 1, 1) )	# => 1

=head2 FormatRef

Format.

	format EXAMPLE_FMT =
	@<<<<<<   @||||||   @>>>>>>
	"left",   "middle", "right"
	.
	
	*EXAMPLE_FMT{FORMAT} ~~ FormatRef   # -> 1
	\1 ~~ FormatRef				# -> ""

=head2 CodeRef

Subroutine.

	sub {} ~~ CodeRef # -> 1
	\1 ~~ CodeRef     # -> ""

=head2 NamedCode[name]

The subroutine with the specified name. C<name> – string or regular character.

	sub code_ex { ... }
	
	\&code_ex ~~ NamedCode['main::code_ex'] # -> 1
	\&code_ex ~~ NamedCode['code_ex']       # -> ""
	\&code_ex ~~ NamedCode[qr/_/]           # -> 1

=head2 ProtoCode[prototype]

A subroutine with the specified prototype.

	sub codex ($;$);
	
	\&codex ~~ ProtoCode['@']     # -> ""
	\&codex ~~ ProtoCode['$;$']   # -> 1
	\&codex ~~ ProtoCode[qr/^\$/] # -> 1

=head2 ForwardRef

Subroutine without body.

	sub code_ref {};
	sub code_forward;
	
	\&code_forward ~~ ForwardRef # -> 1
	\&code_ref ~~ ForwardRef     # -> ""

A subroutine without a body is usually used for pre-declaration, but XS functions also have no body:

	\&UNIVERSAL::isa ~~ ForwardRef # -> 1

Calling an undeclared function using C<\&> creates a reference to the previously declared function:

	main->can('nouname') ~~ ForwardRef # -> ""
	
	\&nouname ~~ ForwardRef # -> 1
	
	main->can('nouname') ~~ ForwardRef # -> 1

=head2 ImplementRef

Subroutine with body.

	sub code_ref {};
	sub code_forward;
	
	\&code_ref ~~ ImplementRef     # -> 1
	\&code_forward ~~ ImplementRef # -> ""

=head2 Isa[A...]

A link to a subroutine with the corresponding signature.

	sub sig_ex :Isa(Aion => Int => Str) {}
	
	\&sig_ex ~~ Isa[Aion => Int => Str] # -> 1
	\&sig_ex ~~ Isa[Object['Aion'] => Int => Str] # -> 1
	\&sig_ex ~~ Isa[Aion => Str => Num] # -> ""
	\&sig_ex ~~ Isa[Int => Num] # -> ""

Subroutines without a body are not wrapped in a signature handler, and the signature is remembered to validate the conformity of a subsequently declared subroutine with a body. Therefore the function has no signature.

	sub unreachable_sig_ex :Isa(Int => Str);
	
	\&unreachable_sig_ex ~~ Isa[Int => Str] # -> ""

=head2 RegexpRef

Regular expression.

	qr// ~~ RegexpRef # -> 1
	\1 ~~ RegexpRef   # -> ""

=head2 ValueRef`[A]

A reference to a scalar or reference.

	\12    ~~ ValueRef                 # -> 1
	\12    ~~ ValueRef                 # -> 1
	\-1.2  ~~ ValueRef[Num]            # -> 1
	\\-1.2 ~~ ValueRef[ValueRef[Num]] # -> 1

=head2 ScalarRef`[A]

Reference to a scalar.

	\12   ~~ ScalarRef      # -> 1
	\\12  ~~ ScalarRef      # -> ""
	\-1.2 ~~ ScalarRef[Num] # -> 1

=head2 RefRef`[A]

Link to link.

	\12    ~~ RefRef                 # -> ""
	\\12   ~~ RefRef                 # -> 1
	\-1.2  ~~ RefRef[Num]            # -> ""
	\\-1.2 ~~ RefRef[ScalarRef[Num]] # -> 1

=head2 GlobRef

Link to global

	\*A::a ~~ GlobRef # -> 1
	*A::a ~~ GlobRef  # -> ""

=head2 FileHandle

File descriptor.

	\*A::a ~~ FileHandle         # -> ""
	\*STDIN ~~ FileHandle        # -> 1
	
	open my $fh, "<", "/dev/null";
	$fh ~~ FileHandle	         # -> 1
	close $fh;
	
	opendir my $dh, ".";
	$dh ~~ FileHandle	         # -> 1
	closedir $dh;
	
	use constant { PF_UNIX => 1, SOCK_STREAM => 1 };
	
	socket my $sock, PF_UNIX, SOCK_STREAM, 0;
	$sock ~~ FileHandle	         # -> 1
	close $sock;

=head2 ArrayRef`[A]

Array references.

	[] ~~ ArrayRef	# -> 1
	{} ~~ ArrayRef	# -> ""
	[] ~~ ArrayRef[Num]	# -> 1
	{} ~~ ArrayRef[Num]	# -> ''
	[1, 1.1] ~~ ArrayRef[Num]	# -> 1
	[1, undef] ~~ ArrayRef[Num]	# -> ""

=head2 Lim[A, B?]

Limits arrays from C<A> to C<B> elements, or from 0 to C<A> if C<B> is missing.

	[] ~~ Lim[5]     # -> 1
	[1..5] ~~ Lim[5] # -> 1
	[1..6] ~~ Lim[5] # -> ""
	
	[1..5] ~~ Lim[1,5] # -> 1
	[1..6] ~~ Lim[1,5] # -> ""
	
	[1] ~~ Lim[1,5] # -> 1
	[] ~~ Lim[1,5]  # -> ""

=head2 HashRef`[H]

Links to hashes.

	{} ~~ HashRef # -> 1
	\1 ~~ HashRef # -> ""
	
	[]  ~~ HashRef[Int]           # -> ""
	{x=>1, y=>2}  ~~ HashRef[Int] # -> 1
	{x=>1, y=>""} ~~ HashRef[Int] # -> ""

=head2 Object`[O]

Blessed links.

	bless(\(my $val=10), "A1") ~~ Object # -> 1
	\(my $val=10) ~~ Object              # -> ""
	
	bless(\(my $val=10), "A1") ~~ Object["A1"] # -> 1
	bless(\(my $val=10), "A1") ~~ Object["B1"] # -> ""

=head2 Me

Blessed references to objects of the current package.

	package A1 {
	 use Aion;
	 bless({}, __PACKAGE__) ~~ Me  # -> 1
	 bless({}, "A2") ~~ Me         # -> ""
	}

=head2 Map[K, V]

Like C<HashRef>, but with a key type.

	{} ~~ Map[Int, Int]               # -> 1
	{5 => 3} ~~ Map[Int, Int]         # -> 1
	+{5.5 => 3} ~~ Map[Int, Int]      # -> ""
	{5 => 3.3} ~~ Map[Int, Int]       # -> ""
	{5 => 3, 6 => 7} ~~ Map[Int, Int] # -> 1

=head2 Tuple[A...]

Tuple.

	["a", 12] ~~ Tuple[Str, Int]    # -> 1
	["a", 12, 1] ~~ Tuple[Str, Int] # -> ""
	["a", 12.1] ~~ Tuple[Str, Int]  # -> ""

=head2 CycleTuple[A...]

Tuple repeated one or more times.

	["a", -5] ~~ CycleTuple[Str, Int] # -> 1
	["a", -5, "x"] ~~ CycleTuple[Str, Int] # -> ""
	["a", -5, "x", -6] ~~ CycleTuple[Str, Int] # -> 1
	["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int] # -> ""

=head2 Dict[k => A, ...]

Dictionary.

	{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str] # -> 1
	
	{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str] # -> ""
	{a => -1.6} ~~ Dict[a => Num, b => Str] # -> ""
	
	{a => -1.6} ~~ Dict[a => Num, b => Option[Str]] # -> 1

=head2 HasProp[p...]

A hash has the following properties. In addition to them, he may have others.

	[0, 1] ~~ HasProp[qw/0 1/] # -> ""
	
	{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/] # -> 1
	{a => 1, b => 2} ~~ HasProp[qw/a b/] # -> 1
	{a => 1, c => 3} ~~ HasProp[qw/a b/] # -> ""
	
	bless({a => 1, b => 3}, "A") ~~ HasProp[qw/a b/] # -> 1

=head2 Like

Object or string.

	"" ~~ Like # -> 1
	1 ~~ Like  # -> 1
	bless({}, "A") ~~ Like # -> 1
	bless([], "A") ~~ Like # -> 1
	bless(\(my $str = ""), "A") ~~ Like # -> 1
	\1 ~~ Like  # -> ""

=head2 HasMethods[m...]

An object or class has listed methods. In addition to them, there may be others.

	package HasMethodsExample {
		sub x1 {}
		sub x2 {}
	}
	
	"HasMethodsExample" ~~ HasMethods[qw/x1 x2/]			# -> 1
	bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/] # -> 1
	bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]	# -> 1
	"HasMethodsExample" ~~ HasMethods[qw/x3/]				# -> ""
	"HasMethodsExample" ~~ HasMethods[qw/x1 x2 x3/]			# -> ""
	"HasMethodsExample" ~~ HasMethods[qw/x1 x3/]			# -> ""

=head2 Overload`[op...]

An object or class with overloaded operators.

	package OverloadExample {
		use overload '""' => sub { "abc" };
	}
	
	"OverloadExample" ~~ Overload            # -> 1
	bless({}, "OverloadExample") ~~ Overload # -> 1
	"A" ~~ Overload                          # -> ""
	bless({}, "A") ~~ Overload               # -> ""

And it has operators specified operators.

	"OverloadExample" ~~ Overload['""'] # -> 1
	"OverloadExample" ~~ Overload['|']  # -> ""

=head2 InstanceOf[A...]

A class or object inherits classes from a list.

	package Animal {}
	package Cat { our @ISA = qw/Animal/ }
	package Tiger { our @ISA = qw/Cat/ }
	
	
	"Tiger" ~~ InstanceOf['Animal', 'Cat'] # -> 1
	"Tiger" ~~ InstanceOf['Tiger']         # -> 1
	"Tiger" ~~ InstanceOf['Cat', 'Dog']    # -> ""

=head2 ConsumerOf[A...]

A class or object has the specified roles.

	package NoneExample {}
	package RoleExample { sub DOES { $_[1] ~~ [qw/Role1 Role2/] } }
	
	'RoleExample' ~~ ConsumerOf[qw/Role1/] # -> 1
	'RoleExample' ~~ ConsumerOf[qw/Role2 Role1/] # -> 1
	bless({}, 'RoleExample') ~~ ConsumerOf[qw/Role3 Role2 Role1/] # -> ""
	
	'NoneExample' ~~ ConsumerOf[qw/Role1/] # -> ""

=head2 BoolLike

Tests for 1, 0, "", undef, or an object with an overloaded C<bool> or C<0+> operator as C<JSON::PP::Boolean>. In the second case, it calls the C<0+> operator and checks the result as C<Bool>.

C<BoolLike> calls the C<0+> operator and checks the result.

	package BoolLikeExample {
		use overload '0+' => sub { ${$_[0]} };
	}
	
	bless(\(my $x = 1 ), 'BoolLikeExample') ~~ BoolLike # -> 1
	bless(\(my $x = 11), 'BoolLikeExample') ~~ BoolLike # -> ""
	
	1 ~~ BoolLike     # -> 1
	0 ~~ BoolLike     # -> 1
	"" ~~ BoolLike    # -> 1
	undef ~~ BoolLike # -> 1
	
	package BoolLike2Example {
		use overload 'bool' => sub { ${$_[0]} };
	}
	
	bless(\(my $x = 1 ), 'BoolLike2Example') ~~ BoolLike # -> 1
	bless(\(my $x = 11), 'BoolLike2Example') ~~ BoolLike # -> 1

=head2 StrLike

A string or object overloaded with the C<""> operator.

	"" ~~ StrLike # -> 1
	
	package StrLikeExample {
		use overload '""' => sub { "abc" };
	}
	
	bless({}, "StrLikeExample") ~~ StrLike # -> 1
	
	{} ~~ StrLike # -> ""

=head2 RegexpLike

A regular expression or object with an overload of the C<qr> operator.

	ref(qr//)  # => Regexp
	Scalar::Util::reftype(qr//) # => REGEXP
	
	my $regex = bless qr//, "A";
	Scalar::Util::reftype($regex) # => REGEXP
	
	$regex ~~ RegexpLike # -> 1
	qr// ~~ RegexpLike   # -> 1
	"" ~~ RegexpLike     # -> ""
	
	package RegexpLikeExample {
	 use overload 'qr' => sub { qr/abc/ };
	}
	
	"RegexpLikeExample" ~~ RegexpLike # -> ""
	bless({}, "RegexpLikeExample") ~~ RegexpLike # -> 1

=head2 CodeLike

A subroutine or object with an overload of the C<&{}> operator.

	sub {} ~~ CodeLike     # -> 1
	\&CodeLike ~~ CodeLike # -> 1
	{} ~~ CodeLike         # -> ""

=head2 ArrayLike`[A]

Arrays or objects with an overloaded operator or C<@{}>.

	{} ~~ ArrayLike      # -> ""
	{} ~~ ArrayLike[Int] # -> ""
	
	[] ~~ ArrayLike # -> 1
	
	package ArrayLikeExample {
		use overload '@{}' => sub {
			shift->{array} //= []
		};
	}
	
	my $x = bless {}, 'ArrayLikeExample';
	$x->[1] = 12;
	$x->{array} # --> [undef, 12]
	
	$x ~~ ArrayLike # -> 1
	
	$x ~~ ArrayLike[Int] # -> ""
	
	$x->[0] = 13;
	$x ~~ ArrayLike[Int] # -> 1

=head2 HashLike`[A]

Hashes or objects with the C<%{}> operator overloaded.

	{} ~~ HashLike  # -> 1
	[] ~~ HashLike  # -> ""
	[] ~~ HashLike[Int] # -> ""
	
	package HashLikeExample {
		use overload '%{}' => sub {
			shift->[0] //= {}
		};
	}
	
	my $x = bless [], 'HashLikeExample';
	$x->{key} = 12.3;
	$x->[0]  # --> {key => 12.3}
	
	$x ~~ HashLike      # -> 1
	$x ~~ HashLike[Int] # -> ""
	$x ~~ HashLike[Num] # -> 1

=head1 Coerces

=head2 Join[R] as Str

String type with conversion of arrays to a string through a delimiter.

	Join([' '])->coerce([qw/a b c/]) # => a b c
	
	package JoinExample { use Aion;
		has s => (isa => Join[', '], coerce => 1);
	}
	
	JoinExample->new(s => [qw/a b c/])->s # => a, b, c
	
	JoinExample->new(s => 'string')->s # => string

=head2 Split[S] as ArrayRef

	Split([' '])->coerce('a b c') # --> [qw/a b c/]
	
	package SplitExample { use Aion;
		has s => (isa => Split[qr/\s*,\s*/], coerce => 1);
	}
	
	SplitExample->new(s => 'a, b, c')->s # --> [qw/a b c/]

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Types module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
