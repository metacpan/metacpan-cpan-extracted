package Attribute::Handlers::Prospective;
$VERSION = '0.01';
use Filter::Simple;
use Text::Balanced ':ALL';
use Carp;

our $id          = qr/(?>[a-z_]\w*(?:::[a-z_]\w*)*)/i;
our $parens      = qr/[(](?:(?>[^()]+)|(??{$parens}))*[)]/;
our $attr        = qr/$id(?:$parens)?/;
our $decl        = qr/my|our|local/;
our $sigil       = qr/[\$\@%*]/;
our $comments	 = qr/(?-sm:\s*#.*\n)*\s*/;

our $attr_list5  = qr/:$comments($attr$comments(?::?$comments$attr$comments)*)/;
our $sub_decl5   = qr/\bsub\s+($id)\s*(?:$attr_list5)?\s*($parens)?/;
our $sub_anon5   = qr/\bsub\s*(?:$attr_list5)?\s*($parens)?/;
our $var_decl5   = qr/\b($decl)\s*($id?)\s*($sigil)($id)\s*$attr_list5\s*(\S)/;
our $var_noattr5 = qr/\b($decl\s*$id?\s*$sigil$id\s*(?=\S)(?!:))/;

our $attr_list6  = qr/\bis\s+($attr(?:\s*(?:(?:\bis\b)?\s*$attr|#[^\n]\n))*)/;
our $sub_decl6   = qr/\bsub\s+($id)\s*(?:$attr_list6)?\s*($parens)?(?=\s*[{])/;
our $sub_anon6   = qr/\bsub\s*(?:$attr_list6)?\s*($parens)?/;
our $var_decl6   = qr/\b($decl)\s*($id?)\s*($sigil)($id)\s*$attr_list6\s*(\S)/;
our $var_noattr6 = qr/\b($decl\s+$id?\s*$sigil$id\s*(?=\S)(?!is\b))/;

our ($attr_list, $sub_decl, $sub_anon, $var_decl, $var_noattrs);

our %ATTRS = ( ATTR => {} );

our @PHASES = qw(BEGIN CHECK INIT RUN END);

sub get_attr {
	my $attr = shift;
	my $package = shift || caller;
	return $ATTRS{$package} unless $attr;
	return $ATTRS{$package}{$attr};
}

sub def_handler {
	my ($location, $type, $phase, $attr, $ATTR) = @_;
	use Data::Dumper 'Dumper';
	return $ATTR->{rawdata} ? "*{'$attr (RAWDATA)'} = \\&$attr;" : ""
		if !$phase && !$type;
	return "*{'$attr ($type)'} = \\&$attr;"
		if !$phase && $ATTR->{types}{$type};
	return "*{'$attr ($type $phase)'} = \\&$attr;"
		if $ATTR->{types}{$type} && $ATTR->{phases}{$phase};
	return "";
}

sub def_attr {
	my ($sub, $data, $pkg) = @_;
	my $ATTR = $ATTRS{$pkg}{$sub} = {};
	$ATTR->{phases}{$_} = $data =~ s/\s*,?\s*($_)\s*,?\s*// for @PHASES;
	$ATTR->{phases}{INIT} = 1 unless grep $ATTR->{phases}{$_}, @PHASES;
	$ATTR->{handler} = $sub =~ /::/ ? $sub : $pkg."::".$sub;
	$data .= ',ANY' unless $data =~/\b(SCALAR|ARRAY|HASH|GLOB|CODE|VAR)\b/;
	$ATTR->{types}{SCALAR} = 1 if $data =~ /\b(undef|ANY|VAR|SCALAR)\b/;
	$ATTR->{types}{ARRAY}  = 1 if $data =~ /\b(undef|ANY|VAR|ARRAY)\b/;
	$ATTR->{types}{HASH}   = 1 if $data =~ /\b(undef|ANY|VAR|HASH)\b/;
	$ATTR->{types}{GLOB}   = 1 if $data =~ /\b(undef|ANY|GLOB)\b/;
	$ATTR->{types}{CODE}   = 1 if $data =~ /\b(undef|ANY|CODE)\b/;
	$ATTR->{rawdata}       = 1 if $data =~ /\b(RAWDATA)\b/;
	return $ATTR;
}

sub def_call {
	my ($impl, $owner, $reftype, $attr, $args) = @_;
	foreach my $phase ( qw(BEGIN CHECK INIT RUN END) ) {
	    $impl->{$phase} .= 
		"eval{$owner->\${\\'$attr ($reftype $phase)'}($args,'$phase');1} || " .
		"eval{$owner->\${\\'AUTOATTR ($reftype $phase)'}($args,'$phase');1};";
	}
}

sub def_call_prepost {
	my ($impl, $owner, $reftype, $args, $arglist) = @_;
	foreach my $handler ( qw(PREATTR POSTATTR) ) {
	    foreach my $phase ( qw(BEGIN CHECK INIT RUN END) ) {
		$impl->{$phase} .= 
			"eval{$owner->\${\\'$handler ($reftype $phase)'}($args, '$handler',$arglist,'$phase');1}; ";
	    }
	}
}

my %sigil_to_type = (
	'$' => 'SCALAR',
	'@' => 'ARRAY',
	'%' => 'HASH',
	'&' => 'CODE',
	'*' => 'GLOB',
);

sub impl_attrs {
	my ($attrs,$name,$pkg,$sigil,$decl,$type) = @_;
	my %impl;
	my $prepostargs = "";
	my $noprepost = 0;
	my $glob = ($decl eq 'my')            ? "'LEXICAL($sigil$name)'"
	         : ($decl eq 'sub' && !$name) ? "'ANON'"
	         :                              "\\*$name";
	my $referent = $name ? "\\$sigil$name" : '$_';
	my $location = $name && $name =~ /^(.*::)+/ ? $1
		     : 				   '__PACKAGE__';
	my $owner = $type ? $type : $location;
	my $reftype = $sigil_to_type{$sigil};
	while (1) {
		$attrs =~ m/\G:?$comments\s*($id)($parens)?$comments/gc or last;
		my ($attr, $data) = ($1, $2||"");
		$data =~ s/^[(]|[)]$//g;
		$data ||= 'undef';
		if ($attr eq 'ATTR') {
			my $ATTR = def_attr($name, $data, $pkg);
			$noprepost=1;
			$impl{BEGIN} .= def_handler($location, undef, undef, $name, $ATTR);
			foreach my $type ( qw(SCALAR ARRAY HASH CODE GLOB) ) {
			  $impl{BEGIN} .= def_handler($location, $type, undef, $name, $ATTR);
			  foreach my $phase ( qw(BEGIN CHECK INIT RUN END) ) {
			    $impl{BEGIN} .= def_handler($location, $type, $phase, $name, $ATTR);
			}}
			next;
		}
		$data &&= "$owner->can('$attr (RAWDATA)') ? q($data) : eval q([$data])";
		my $args = "$glob,$referent,'$attr',$data";
		$impl{BEGIN} .= "die 'No such $reftype attribute: '.${owner}.'::$attr' unless $owner->can('$attr ($reftype)') || $owner->can('AUTOATTR ($reftype)');";
		def_call(\%impl, $owner, $reftype, $attr, $args);
		$prepostargs .= "[$owner,$args],";
	}
	def_call_prepost(\%impl, $owner, $reftype, "$glob, $referent", "[$prepostargs]")
		unless $noprepost;
	return join " ",
	            map { ($_ eq 'RUN' ? "" : $_) . "{ $impl{$_} }" }
	                grep { defined $impl{$_} }
				qw(BEGIN CHECK INIT RUN END);
}

sub _usage_AH_ {
        croak "Usage: use $_[0] autotie => {AttrName => TieClassName,...}";
}

FILTER {
	my $caller = shift;
	my $classname = shift;
	my $autotied = "";
	while (@_) {
		my $cmd = shift;
		next if $cmd =~ /^Perl\s*6$/;
		if ($cmd =~ /^autotie((?:ref)?)$/) {
		    my $tiedata = $1 ? '$ref, @$data' : '@$data';
		    my $mapping = shift;
		    _usage_AHI_ $class unless ref($mapping) eq 'HASH';
		    while (my($attr, $tieclass) = each %$mapping) {
			$tieclass =~ s/^($id)(.*)/$1/is;
			my $args = $2||'()';
			_usage_AH_ $class unless $attr =~ $id
					 && $tieclass =~ $id;
			$attr =~ s/__CALLER__/$caller/e;
			$attr = $caller."::".$attr unless $attr =~ /::/;
			$autotied .= qq(
			    eval { require $tieclass and $tieclass->import($args) };
			    sub $attr : ATTR(VAR,RUN) {
				my (\$ref, \$data) = \@_[2,4];
				my \$type = ref(\$ref);
				if (\$type eq 'SCALAR') {
				    tie \$\$ref,'$tieclass',$tiedata
				}
			        elsif (\$type eq 'ARRAY') {
				    tie \@\$ref,'$tieclass',$tiedata
			        }
				elsif (\$type eq 'HASH') {
				    tie \%\$ref,'$tieclass',$tiedata
				}
			        else {
				    print STDERR "Can't autotie a \$type\n" and exit
				}
			    }
                       );
		    }
		}
		else {
		    print STDERR "Can't understand $cmd\n" and exit;
		}
	}
	$_ = $autotied . $_;
	pos() ||= 0;
	my $newcode;
	my $extracted;
	while (pos() < length()) {
		my @found;
		if (($extracted) = extract_quotelike($_,q//) and $extracted or
		    ($extracted) = extract_variable($_,q//) and $extracted ) {
			$newcode .= $extracted;
		}
		elsif (m/\G$sub_decl/gc) {
			my ($name, $attrs, $params) = ($1,$2||"",$3||"");
			my ($block) = extract_codeblock;
			$DB::single = 1;
			$newcode .= "sub $name $params $block ;"
			          . impl_attrs($attrs,$name,$caller,'&','sub');
		}
		elsif (m/\G$sub_anon/gc) {
			my ($attrs, $params) = ($1||"",$2||"");
			my ($block) = extract_codeblock;
			$newcode .= "do { local \$_ = sub $params $block; "
			          . impl_attrs($attrs,undef,$caller,'&','sub')
				  . ' ; $_ }';
		}
		elsif (m/\G$var_noattrs/gc) {
			$newcode .= $1;
		}
		elsif (m/\G$var_decl/gc) {
			my ($decl, $type, $sigil, $name, $attrs, $nextchar)
			 = ($1,    $2||"",$3,     $4,    $5||"", $6);
			$newcode .= "$decl $type $sigil$name; "
			          . impl_attrs($attrs,$name,$caller,$sigil,$decl,$type)
				  . "; "
				  . ($nextchar eq '=' ? "$sigil$name " : "")
				  . $nextchar;
		}
		elsif (m/\G($id|$parens|.)/gcs) {
		        $newcode .= $1;
		}
		else {
			die "Internal error";
		}
	}
	$_ = $newcode;
	# print STDERR if $_;
}
qr/^__(END|DATA)__$/m;

no warnings;
my $filterer = *import{CODE};
my $mod_filterer = sub { unshift @_, scalar caller; goto &$filterer };
*import = sub {
	if (grep /Perl\s*6/, @_) {
		$attr_list   = $attr_list6;
		$sub_decl    = $sub_decl6;
		$sub_anon    = $sub_anon6;
		$var_decl    = $var_decl6;
		$var_noattrs = $var_noattr6;
	}
	else {
		$attr_list   = $attr_list5;
		$sub_decl    = $sub_decl5;
		$sub_anon    = $sub_anon5;
		$var_decl    = $var_decl5;
		$var_noattrs = $var_noattr5;
	}
	*{caller()."::import"} = $mod_filterer;
	goto &$mod_filterer
};

1;

__END__

=head1 NAME

Attribute::Handlers::Prospective - Richer semantics for attribute handlers

=head1 VERSION

This document describes version 0.01 of Attribute::Handlers::Prospective,
released October 25, 2001.

=head1 SYNOPSIS

	package MyClass;
	require v5.6.1;
	use Attribute::Handlers::Prospective;

	sub Good : ATTR(SCALAR) {
		my ($package, $symbol, $referent, $attr, $data, $phase) = @_;

		# Invoked for any scalar variable with a :Good attribute,
		# provided the variable was declared in MyClass (or
		# a derived class) or typed to MyClass.

		# Do whatever to $referent here (executed in INIT phase).
		...
	}

	sub Bad : ATTR(SCALAR) {
		# Invoked for any scalar variable with a :Bad attribute,
		# provided the variable was declared in MyClass (or
		# a derived class) or typed to MyClass.
		...
	}

	sub Good : ATTR(ARRAY) {
		# Invoked for any array variable with a :Good attribute,
		# provided the variable was declared in MyClass (or
		# a derived class) or typed to MyClass.
		...
	}

	sub Ugly : ATTR(CODE) {
		# Invoked for any subroutine declared in MyClass (or a 
		# derived class) with an :Ugly attribute.
		...
	}

	sub Omni : ATTR {
		# Invoked for any scalar, array, hash, or subroutine
		# with an :Omni attribute, provided the variable or
		# subroutine was declared in MyClass (or a derived class)
		# or the variable was typed to MyClass.
		# Use ref($_[2]) to determine what kind of referent it was.
		...
	}

	sub AUTOATTR : ATTR {
		# A handler named AUTOATTR is automagically invoked for
		# any scalar, array, hash, or subroutine with an attribute
		# for which no explicit handler is defined
		# This is analogous to sub AUTOLOAD for method calls.
		# Use $_[3] to determine the actual name of the attribute
		...
	}

	sub PREATTR : ATTR {
		my ($package, $symbol, $referent, $attr, $arglists, $phase) = @_;

		# Any handler named PREATTR is automagically invoked before
		# any other attribute handlers on the referent.
		# $_[4] contains an array of arrays, each of which is the
		# complete argument list that will be sent to each attribute
		# ascribed to the referent
		...

	sub POSTATTR : ATTR {
		my ($package, $symbol, $referent, $attr, $arglists, $phase) = @_;

		# Any handler named POSTATTR is automagically invoked after
		# any other attribute handlers on the referent.
		# $_[4] contains an array of arrays, each of which is the
		# complete argument list that was sent to each attribute
		# ascribed to the referent
		...
	}



=head1 DESCRIPTION

This module, when inherited by a package, allows that package's class to
define attribute handler subroutines for specific attributes. Variables
and subroutines subsequently defined in that package, or in packages
derived from that package may be given attributes with the same names as
the attribute handler subroutines, which will then be called in one of
the compilation phases (i.e. in a C<BEGIN>, C<CHECK>, C<INIT>, run-time,
or C<END> block).

To create a handler, define it as a subroutine with the same name as
the desired attribute, and declare the subroutine itself with the  
attribute C<:ATTR>. For example:

	package LoudDecl;
	use Attribute::Handlers::Prospective;

	sub Loud :ATTR {
		my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
		print STDERR
			ref($referent), " ",
			*{$symbol}{NAME}, " ",
			"($referent) ", "was just declared ",
			"and ascribed the ${attr} attribute ",
			"with data ($data)\n",
			"in phase $phase\n";
	}

This creates an handler for the attribute C<:Loud> in the class LoudDecl.
Thereafter, any subroutine declared with a C<:Loud> attribute in the class
LoudDecl:

	package LoudDecl;

	sub foo: Loud {...}

causes the above handler to be invoked, and passed:

=over

=item [0]

the name of the package into which it was declared;

=item [1]

a reference to the symbol table entry (typeglob) containing the subroutine;

=item [2]

a reference to the subroutine;

=item [3]

the name of the attribute;

=item [4]

any data associated with that attribute;

=item [5]

the name of the phase in which the handler is being invoked.

=back

Likewise, declaring any variables with the C<:Loud> attribute within the
package:

        package LoudDecl;

        my $foo :Loud;
        my @foo :Loud;
        my %foo :Loud;

will cause the handler to be called with a similar argument list (except,
of course, that C<$_[2]> will be a reference to the variable).

The package name argument will typically be the name of the class into
which the subroutine was declared, but it may also be the name of a derived
class (since handlers are inherited).

If a lexical variable is given an attribute, there is no symbol table to 
which it belongs, so the symbol table argument (C<$_[1]>) is set to the
string C<'LEXICAL(I<name>)'>, where I<name> is the name of the lexical
(including its sigil). Likewise, ascribing an attribute to
an anonymous subroutine results in a symbol table argument of C<'ANON'>.

The data argument passes in the value (if any) associated with the 
attribute. For example, if C<&foo> had been declared:

        sub foo :Loud("turn it up to 11, man!") {...}

then the string C<"turn it up to 11, man!"> would be passed as the
last argument.

Attribute::Handlers::Prospective usually treats the value(s) passed as the
the data argument (C<$_[4]>) as standard Perl 
(but see L<"Non-interpretive attribute handlers">).
The attribute's arguments are evaluated in an array context and
passed as an anonymous array.

For example, all of these:

        sub foo :Loud(till=>ears=>are=>bleeding) {...}
        sub foo :Loud(['till','ears','are','bleeding']) {...}
        sub foo :Loud(qw/till ears are bleeding/) {...}

causes it to pass C<['till','ears','are','bleeding']> as the handler's
data argument. If the data can't be parsed as valid Perl, then a
compilation error will occur.

If no value is associated with the attribute, C<undef> is passed.


=head2 Typed lexicals

Regardless of the package in which it is declared, if a lexical variable is
ascribed an attribute, the handler that is invoked is the one belonging to
the package to which it is typed. For example, the following declarations:

        package OtherClass;

        my LoudDecl $loudobj : Loud;
        my LoudDecl @loudobjs : Loud;
        my LoudDecl %loudobjex : Loud;

causes the LoudDecl::Loud handler to be invoked (even if OtherClass also
defines a handler for C<:Loud> attributes).


=head2 Type-specific attribute handlers

If an attribute handler is declared and the C<:ATTR> specifier is given
the name of a built-in type (C<SCALAR>, C<ARRAY>, C<HASH>, C<CODE>, or
C<GLOB>), the handler is only applied to declarations of that type. For
example, the following definition:

        package LoudDecl;

        sub RealLoud :ATTR(SCALAR) { print "Yeeeeow!" }

creates an attribute handler that applies only to scalars:


        package Painful;
        use base LoudDecl;

        my $metal : RealLoud;           # invokes &LoudDecl::RealLoud
        my @metal : RealLoud;           # error: unknown attribute
        my %metal : RealLoud;           # error: unknown attribute
        sub metal : RealLoud {...}      # error: unknown attribute


You can also explicitly indicate that a single handler is meant to be
used for all types of referents like so:

        package LoudDecl;
        use Attribute::Handlers::Prospective;

        sub SeriousLoud :ATTR(ANY) { warn "Hearing loss imminent" }

(I.e. C<ATTR(ANY)> is a synonym for C<:ATTR>).


=head2 Non-interpretive attribute handlers

Occasionally it is preferable that the data argument of an attribute
be treated as a string, rather than as valid Perl.

This can be specified by giving the C<ATTR> attribute of 
an attribute handler the keyword C<RAWDATA>. For example:

        sub Raw          : ATTR(RAWDATA) {...}
        sub Nekkid       : ATTR(SCALAR,RAWDATA) {...}
        sub Au::Naturale : ATTR(RAWDATA,ANY) {...}

Then the handler makes absolutely no attempt to interpret the data it
receives and simply passes it as an uninterpolated C<q(...)> string:

        my $power : Raw(1..100);        # handlers receives "1..100"

=head2 Phase-specific attribute handlers

By default, attribute handlers are called just before execution
(in an C<INIT> block). This seems to be optimal in most cases because
most things that can be defined are defined by that point but nothing has
been executed.

However, it is possible to set up attribute handlers that are called at
other points in the program's compilation or execution, by explicitly
stating the phase (or phases) in which you wish the attribute handler to
be called. For example:

        sub Early    :ATTR(SCALAR,BEGIN) {...}
        sub Earlyish :ATTR(SCALAR,CHECK) {...}
        sub Normal   :ATTR(SCALAR,INIT) {...}
        sub Active   :ATTR(SCALAR,RUN) {...}
        sub Final    :ATTR(SCALAR,END) {...}
        sub Bookends :ATTR(SCALAR,BEGIN,END) {...}

As the last example indicates, a handler may be set up to be (re)called in
two or more phases. The phase name is passed as the handler's final argument.

Note that attribute handlers that are scheduled for the C<BEGIN> phase
are handled as soon as the attribute is detected (i.e. before any
subsequently defined C<BEGIN> blocks are executed).

Attribute handlers that are scheduled for the C<RUN> phase are executed
every time the code itself executes.


=head2 Default attribute handlers

Perl makes it possible to create default handlers for subroutine calls,
by defining a subroutine named C<AUTOLOAD>. Likewise
Attribute::Handlers::Prospective makes it possible to set up default
handlers for attributes, by defining an attribute handler named
C<AUTOATTR>.

For example:

	package Real;

	sub RealAttr : ATTR {
		print "You ascribed a RealAttr attribute to $_[2]\n";
	}

	sub AUTOATTR : ATTR {
		warn "You tried to ascribe a :$_[3] attribute to $_[2]\n",
		     "but there's no such attribute defined in class $_[0]\n",
		     "(Did you mean :RealAttr?)\n";
	}

Now, ascribing any other attribute except C<:RealAttr> to a referent associated
with the Real package provokes a warning.

If the C<AUTOATTR> hadn't been defined, ascribing any other attribute would
have produced a fatal error.

Note that the arguments an C<AUTOATTR> receives are indentical to those
that would have been received by the real attribute handler it's replacing.


=head2 Pre- and post-attribute handlers

There are two other attribute handlers whose names mark them as special:
C<PREATTR> and C<POSTATTR>. Any handler with one of these names is treated as
a prefix/postfix handler, and is called automatically on any referent that
is ascribed one or more attributes.

These handlers receive the same six arguments as any other handler, the only
difference being that their C<$data> argument (C<$_[4]>) is an array of arrays.
Each of those inner arrays is the complete argument list that each attribute in
turn will receive.

For example, to report each attribute scribed to any scalar, we could write:

	use Data::Dumper 'Dumper';

	sub UNIVERSAL::PREATTR : ATTR(SCALAR) {
		my $name = *{$_[1]}{NAME};
		$name = "PACKAGE(\$$name)" unless $name =~ /^LEXICAL/;
		print "$name was ascribed:\n";
		foreach $arglist ( @{$_[4]} ) {
			print "$arglist->[3](", Dumper($arglist), ")\n"
		}
	}

Note that changes to the argument lists within the pre- and postfix handlers
I<do not> propagate to the actual attribute handler calls (though they
may do so in future releases).


=head2 Attributes as C<tie> interfaces

Attributes make an excellent and intuitive interface through which to tie
variables. For example:

        use Attribute::Handlers::Prospective;
        use Tie::Cycle;

        sub UNIVERSAL::Cycle : ATTR(SCALAR, RUN) {
                my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
                $data = [ $data ] unless ref $data eq 'ARRAY';
                tie $$referent, 'Tie::Cycle', $data;
        }

        # and thereafter...

        package main;

        my $next : Cycle('A'..'Z');     # $next is now a tied variable

        while (<>) {
                print $next;
        }

In fact, this pattern is so widely applicable that Attribute::Handlers::Prospective
provides a way to automate it: specifying C<'autotie'> in the
C<use Attribute::Handlers::Prospective> statement. So, the previous example,
could also be written:

        use Attribute::Handlers::Prospective autotie => { Cycle => 'Tie::Cycle' };

        # and thereafter...

        package main;

        my $next : Cycle('A'..'Z');     # $next is now a tied variable

        while (<>) {
                print $next;

The argument after C<'autotie'> is a reference to a hash in which each key is
the name of an attribute to be created, and each value is the class to which
variables ascribed that attribute should be tied.

Note that there is no longer any need to import the Tie::Cycle module --
Attribute::Handlers::Prospective takes care of that automagically. You can even pass
arguments to the module's C<import> subroutine, by appending them to the
class name. For example:

        use Attribute::Handlers::Prospective
                autotie => { Dir => 'Tie::Dir qw(DIR_UNLINK)' };

If the attribute name is unqualified, the attribute is installed in the
current package. Otherwise it is installed in the qualifier's package:

        package Here;

        use Attribute::Handlers::Prospective autotie => {
                Other::Good => Tie::SecureHash, # tie attr installed in Other::
                        Bad => Tie::Taxes,      # tie attr installed in Here::
            UNIVERSAL::Ugly => Software::Patent # tie attr installed everywhere
        };

Autoties are most commonly used in the module to which they actually tie, 
and need to export their attributes to any module that calls them. To
facilitiate this, Attribute::Handlers::Prospective recognizes a special "pseudo-class" --
C<__CALLER__>, which may be specified as the qualifier of an attribute:

        package Tie::Me::Kangaroo:Down::Sport;

        use Attribute::Handlers::Prospective autotie => { __CALLER__::Roo => __PACKAGE__ };

This causes Attribute::Handlers::Prospective to define the C<Roo> attribute in the package
that imports the Tie::Me::Kangaroo:Down::Sport module.

=head3 Passing the tied object to C<tie>

Occasionally it is important to pass a reference to the object being tied
to the TIESCALAR, TIEHASH, etc. that ties it. 

The C<autotie> mechanism supports this too. The following code:

        use Attribute::Handlers::Prospective autotieref => { Selfish => Tie::Selfish };
        my $var : Selfish(@args);

has the same effect as:

        tie my $var, 'Tie::Selfish', @args;

But when C<"autotieref"> is used instead of C<"autotie">:

        use Attribute::Handlers::Prospective autotieref => { Selfish => Tie::Selfish };
        my $var : Selfish(@args);

the effect is to pass the C<tie> call an extra reference to the variable
being tied:

        tie my $var, 'Tie::Selfish', \$var, @args;



=head2 Universal attributes

Installing handlers into UNIVERSAL, makes them...err..universal.
For example:

        package Descriptions;
        use Attribute::Handlers::Prospective;

        my %name;
        sub name { return $name{$_[2]}||*{$_[1]}{NAME} }

        sub UNIVERSAL::Name :ATTR {
                $name{$_[2]} = $_[4];
        }

        sub UNIVERSAL::Purpose :ATTR {
                print STDERR "Purpose of ", &name, " is $_[4]\n";
        }

        sub UNIVERSAL::Unit :ATTR {
                print STDERR &name, " measured in $_[4]\n";
        }

Let's you write:

        use Descriptions;

        my $capacity : Name(capacity)
                     : Purpose(to store max storage capacity for files)
                     : Unit(Gb);


        package Other;

        sub foo : Purpose(to foo all data before barring it) { }

        # etc.


=head1 DIAGNOSTICS

=over

=item C<No such %s attribute: %s>

And attribute was applied to a referent for which there is no 
corresponding attribute handler. Typically this means that the
attribute handler that was declared does not handle the type
of referent you used.

=item C<Can't autotie a %s>

You can only declare autoties for types C<"SCALAR">, C<"ARRAY">, 
C<"HASH">, and C<GLOB>. They're the only things that Perl can tie.

=item C<Internal error>

Something is rotten in the state of the program. 
Send a bug report.

=back

=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 BUGS

There are undoubtedly serious bugs lurking somewhere in code this funky :-)
Bug reports and other feedback are most welcome.

=head1 COPYRIGHT

         Copyright (c) 2001, Damian Conway. All Rights Reserved.
       This module is free software. It may be used, redistributed
           and/or modified under the same terms as Perl itself.
