#!perl
package Config::Perl;
use warnings;
use strict;

our $VERSION = '0.06';

=head1 Name

Config::Perl - Perl extension for parsing configuration files written in a
subset of Perl and (limited) undumping of data structures (via PPI, not eval)

=head1 Synopsis

=for comment
Remember to test this by copy/pasting to/from 91_author_pod.t

=for comment
TODO Later: metacpan strips the extra space from the front of the code sample,
so the extra space we added in ' END_CONFIG_FILE' breaks the script...
search.cpan.org keeps the space there. What's the best solution?

 use Config::Perl;
 my $parser = Config::Perl->new;
 my $data = $parser->parse_or_die( \<<' END_CONFIG_FILE' );
   # This is the example configuration file
   $foo = "bar";
   %text = ( test => ["Hello", "World!"] );
   @vals = qw/ x y a /;
 END_CONFIG_FILE
 print $data->{'$foo'}, "\n";   # prints "bar\n"
 
 # Resulting $data: {
 #   '$foo'  => "bar",
 #   '%text' => { test => ["Hello", "World!"] },
 #   '@vals' => ["x", "y", "a"],
 # };

=head1 Description

The goal of this module is to support the parsing of a small subset of Perl,
primarily in order to parse configuration files written in that subset of Perl.
As a side effect, this module can "undump" some data structures written by
L<Data::Dumper|Data::Dumper>, but
please make sure to read L<Data::Undump::PPI> for details!

The code is parsed via L<PPI|PPI>, eliminating the need for Perl's C<eval>.
This should provide a higher level of safety* compared to C<eval>
(even when making use of a module like L<Safe|Safe>).

* B<Disclaimer:> A "higher level of safety" does not mean "perfect safety".
This software is distributed B<without any warranty>; without even the implied
warranty of B<merchantability> or B<fitness for a particular purpose>.
See also the license for this software.

This module attempts to provide 100% compatibility with Perl over the subset of Perl it supports.
When a Perl feature is not supported by this module, it should complain 
that the feature is not supported, instead of silently giving a wrong result.
If the output of a parse is different from how Perl would evaluate the same string,
then that is a bug in this module that should be fixed by correcting the output
or adding an error message that the particular feature is unsupported.
However, the result of using this module to parse something that is not valid Perl is undefined;
it may cause an error, or may fail in some other silent way.

This document describes version 0.06 of the module.
Although this module has a fair number of tests, it still lacks some
features (see list below) and there may be bugs lurking.
Contributions are welcome!

=head2 Interface

This module has a simple OO interface. A new parser is created
with C<< Config::Perl->new >>
and documents are parsed with either the method C<parse_or_die> or C<parse_or_undef>.

 my $parser = Config::Perl->new;
 my $out1 = $parser->parse_or_undef(\' $foo = "bar"; ');
 warn "parse failed: ".$parser->errstr unless defined $out1;
 my $out2 = $parser->parse_or_die('filename.pl');

The arguments and return values of these two methods are (almost) the same:
They each take exactly one argument, which is either a filename,
or a reference to a string containing the code to be parsed
(this is the same as L<PPI::Document|PPI::Document>'s C<new> method).

The methods differ in that, as the names imply, C<parse_or_die>
will C<die> on errors, while C<parse_or_undef> will return C<undef>;
the error message is then accessible via the C<errstr> method.

For a successful parse, the return value of each function is a hashref
representing the "symbol table" of the parsed document.
This "symbol table" hash is similar to, but not the same as, Perl's symbol table.
The hash includes a key for every variable declared or assigned to in the document,
the key is the name of the variable including its sigil.
If the document ends with a plain value or list that is not part of an assignment,
that value is saved in the "symbol table" hash with the key "C<_>" (a single underscore).

For example, the string C<"$foo=123; $bar=456;"> will return the data structure
C<< { '$foo'=>123, '$bar'=>456 } >>, and the string C<"('foo','bar')"> will return the data
structure C<< { _=>["foo","bar"] } >>.

Note that documents are currently always parsed in list context.
For example, this means that a document like "C<@foo = ("a","b","c"); @foo>"
will return the array's elements (C<"a","b","c">) instead of the item count (C<3>).
This also means that the special hash element "C<_>" will currently always be an arrayref.

C<< Config::Perl->new(debug=>1) >> turns on debugging.

=head2 What is currently supported

=over

=item *

plain scalars, arrays, hashes, lists

=item *

arrayrefs and hashrefs constructed via C<[]> and C<{}> resp.

=item *

declarations - only C<our>, also C<my> on the outermost level (document)
where it is currently treated exactly like C<our>;
not supported are lexical C<my> inside blocks, C<local> or C<state>

=item *

assignments (except the return value of assignments is not yet implemented)

=item *

simple array and hash subscripts (e.g. C<$x[1]>, C<$x[$y]>, C<$x{z}>, C<$x{"$y"}>)

=item *

very simple variable interpolations in strings (currently only C<"hello$world"> or C<"foo${bar}quz">)
and some escape sequences (e.g. C<"\x00">)

=item *

C<do> blocks (contents limited to the supported features listed here)

=item *

dereferencing via the arrow operator (also implicit arrow operator between subscripts)

=back

=head2 What is not supported (yet)

I hope to achieve a balance where this module is useful, without becoming too much of a re-implementation of Perl.
I've labeled these items with "wishlist", "maybe", and "no", depending on whether I currently feel that
I'd like to support this feature in a later version, I'd consider supporting this feature if the need arises,
or I currently don't think the feature should be implemented.

=over

=item *

lexical variables (C<my>) (wishlist)

=item *

taking references via C<\> and dereferencing via C<@{...}>, C<%{...}>, etc. (wishlist)

=item *

return values of assignments (e.g. C<$foo = do { $bar = "quz" }>) (maybe)

=item *

operators other than assignment (maybe; supporting a subset, like concatenation, is wishlist)

=item *

conditionals, like for example a very simple C<if ($^O eq 'linux') { ... }> (maybe)

=item *

any functions, including C<bless>
(mostly this is "no"; supporting a very small subset of functions, e.g. C<push>, is "maybe")

=item *

anything that can't be resolved via a static parse (including C<sub>s, many regexps, etc.) (no)

=item *

Note this list is not complete.

=back

=head1 Author, Copyright, and License

Copyright (c) 2015 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command "C<perldoc perlartistic>" or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use Carp;
use warnings::register;
use PPI ();
use PPI::Dumper ();

our $DEBUG = 0; # global debug setting

my %KNOWN_ARGS_NEW = map {$_=>1} qw/ debug /;
sub new {
	my ($class,%args) = @_;
	$KNOWN_ARGS_NEW{$_} or croak "unknown argument $_" for keys %args;
	my $self = {
		debug => $args{debug} || $DEBUG,
		errstr => undef,
		ctx => undef, # Note: valid values for ctx currently "list", "scalar", "scalar-void"
		out => undef,
		ptr => undef,
	};
	return bless $self, $class;
}
sub errstr { return shift->{errstr} }

#TODO: make error messages look better and be more useful
sub _dump { return PPI::Dumper->new(shift,whitespace=>0,comments=>0,locations=>1)->string }
sub _errmsg { chomp(my $e=_dump(shift)); $e=~s/^/\t/mg; return "<<< $e >>>" }
sub _errormsg {
	my ($self,$msg) = @_;
	return "$msg ".($self->{ptr}?_errmsg($self->{ptr}):"UNDEF");
}
sub _debug {
	my ($self,$msg) = @_;
	return unless $self->{debug};
	my $line = $self->{ptr} ? $self->{ptr}->line_number : '?';
	my $col = $self->{ptr} ? $self->{ptr}->column_number : '?';
	return print STDERR "[L$line C$col] $msg\n";
}

sub parse_or_undef {  ## no critic (RequireArgUnpacking)
	my $self = shift;
	my $out = eval { $self->parse_or_die(@_) };
	my $errmsg = $@||"Unknown error";
	$self->{errstr} = defined $out ? undef : $errmsg;
	return $out;
}

sub parse_or_die {
	my ($self,$input) = @_;
	# PPI::Documents are not "complete" if they don't have a final semicolon, so tack one on there if it's missing
	$input = \"$$input;" if ref $input eq 'SCALAR' && $$input!~/;\s*$/;
	$self->{doc} = my $doc = PPI::Document->new($input);
	my $errmsg = PPI::Document->errstr||"Unknown error";
	$doc or croak "Parse failed: $errmsg";
	$doc->complete or croak "Document incomplete (missing final semicolon?)";
	$self->{ctx} = 'list'; # we're documented to currently always parse in list context
	$self->{out} = {};
	$self->{ptr} = $doc;
	my $rv = $self->_handle_block(outer=>1);
	croak $rv unless ref $rv;
	my @rv = $rv->();
	$self->{out}{_} = \@rv if @rv;
	return $self->{out};
}

# Handles Documents, Blocks, and do-Blocks
# Returns the last return value from the block
# On Error returns a string, pointer not advanced
# On Success advances pointer over the block
sub _handle_block {  ## no critic (ProhibitExcessComplexity)
	my ($self,%param) = @_; # params: outer
	my $block = $self->{ptr};
	if ($param{outer})
		{ return $self->_errormsg("expected Document") unless $block->isa('PPI::Document') }
	else {
		if ($block->isa('PPI::Token::Word') && $block->literal eq 'do')
			{ $block = $block->snext_sibling }
		return $self->_errormsg("expected Block") unless $block->isa('PPI::Structure::Block');
	}
	$self->_debug("beginning to parse a block with ".$block->schildren." schildren");
	my $block_rv = sub {};
	STATEMENT: for my $stmt ($block->schildren) {
		# last statement in block gets its context, otherwise void context
		local $self->{ctx} = $stmt->snext_sibling ? 'scalar-void' : $self->{ctx};
		# ignore labels
		if ($stmt->isa('PPI::Statement::Compound') && $stmt->schildren==1
			&& $stmt->schild(0)->isa('PPI::Token::Label') ) {
			next STATEMENT;
		}
		local $self->{ptr} = $stmt;
		if (ref( my $rv1 = $self->_handle_assignment( $param{outer}?(outer=>1):() ) )) {
			$self->_debug("parsed an assignment in a block");
			if ($self->{ptr} && (!$self->{ptr}->isa('PPI::Token::Structure') || !$self->{ptr}->content eq ';' || $self->{ptr}->snext_sibling))
				{ return $self->_errormsg("expected Semicolon after assignment") }
			$block_rv = $rv1 unless $self->{ctx} eq 'scalar-void';
		}
		elsif ($stmt->class eq 'PPI::Statement') {
			local $self->{ptr} = $stmt->schild(0);
			my $rv2 = $self->_handle_value();
			$rv2 = $self->_errormsg("expected Semicolon after value")
				if ref($rv2) && $self->{ptr} && (!$self->{ptr}->isa('PPI::Token::Structure') || !$self->{ptr}->content eq ';' || $self->{ptr}->snext_sibling);
			if (ref $rv2) {
				$self->_debug("parsed a plain value in a block");
				if ($self->{ctx} eq 'scalar-void')
					{ warnings::warnif("value in void context") if $rv2->() }
				else
					{ $block_rv = $rv2 }
			}
			else
				{ return $self->_errormsg("couldn't parse ".($param{outer}?"Document":"Block")." Statement: ".join(", and ",$rv1,$rv2)) }
		}
		else
			{ return $self->_errormsg("unsupported element (not an assignment because: $rv1)") }
	}
	$self->{ptr} = $block->snext_sibling;
	return $block_rv
}

# Handles Variable Declarations and Assignment Statements
# Returns TODO Later: implement return value of assignments
# On Error returns a string, pointer not advanced
# On Success advances pointer over the assignment
sub _handle_assignment {  ## no critic (ProhibitExcessComplexity)
	my ($self,%param) = @_; # params: outer
	my $as = $self->{ptr};
	# The handling of ptr is a little tricky here: when we're done,
	# we need to advance the pointer so that it points to just after the assignment,
	# but we also need to be able to roll it back in case of error.
	my $last_ptr;
	{ # block for local ptr
	local $self->{ptr}=$self->{ptr};
	if ($as && $as->class eq 'PPI::Statement::Variable') { # declaration
		# note that Perl does not allow array or hash elements in declarations (no subscripts here)
		return $self->_errormsg("unsupported declaration type \"".$as->type."\"")
			unless $as->type eq 'our' || $as->type eq 'my';
		return $self->_errormsg("Lexical variables (\"my\") not supported") # I'd like to support "my" soon
			unless $as->type eq 'our' || ($as->type eq 'my' && $param{outer});
		$self->_debug("parsing a variable declaration");
		$self->{ptr} = $as->schild(1);
	}
	else {
		return $self->_errormsg("expected Assignment")
			if !$as || $as->class ne 'PPI::Statement'
			|| $as->schildren<3; # with subscripts, there's no upper limit on schildren
		$self->_debug("parsing an assignment (schildren: ".$as->schildren.")");
		$self->{ptr} = $as->schild(0);
	}
	
	my ($lhs_scalar,@lhs);
	if ($self->{ptr}->isa('PPI::Token::Symbol')) {
		my $sym = $self->_handle_symbol();
		return $sym unless ref $sym;
		$lhs_scalar = $sym->{atype} eq '$';
		$self->_debug("assign single LHS \"$$sym{name}\"/$$sym{atype}");
		@lhs = ($sym);
	}
	elsif ($self->{ptr}->isa('PPI::Structure::List')) {
		local $self->{ctx} = 'list';
		my $l = $self->_handle_list(is_lhs=>1);
		return $l unless ref $l;
		@lhs = @$l;
	}
	else
		{ return $self->_errormsg("expected Assign LHS") }
	
	return $self->_errormsg("expected Assign Op")
		unless $self->{ptr}->isa('PPI::Token::Operator') && $self->{ptr}->content eq '=';
	$self->{ptr} = $self->{ptr}->snext_sibling;
	
	my @rhs = do {
		local $self->{ctx} = $lhs_scalar ? 'scalar' : 'list';
		my $rv = $self->_handle_value();
		return $rv unless ref $rv;
		$rv->() };
	$self->_debug("assignment: LHS ".scalar(@lhs)." values, RHS ".scalar(@rhs)." values");
	$last_ptr = $self->{ptr};
	
	for my $l (@lhs) {
		if (!defined($l))  ## no critic (ProhibitCascadingIfElse)
			{ shift @rhs }
		elsif ($l->{atype} eq '$')
			{ ${ $l->{ref} } = shift @rhs }
		elsif ($l->{atype} eq '@') {
			if (!defined ${$l->{ref}})
				{ ${ $l->{ref} } = [@rhs] }
			else
				{ @{ ${ $l->{ref} } } = @rhs }
			last; # slurp
		}
		elsif ($l->{atype} eq '%') {
			if (!defined ${$l->{ref}})
				{ ${ $l->{ref} } = {@rhs} }
			else
				{ %{ ${ $l->{ref} } } = @rhs }
			last; # slurp
		}
		else { confess "Possible internal error: can't assign to "._errmsg($l) }  # uncoverable statement
	}
	} # end block for local ptr
	$self->{ptr} = $last_ptr;
	return sub { return }
}

# If is_lhs false:
#   Handles () lists as well as the *contents* of {} and [] constructors
#   Returns an arrayref of values; in scalar ctx the last value from the list wrapped in an arrayref
# If is_lhs true:
#   Handles assignment LHS symbol () lists
#   Returns an arrayref of _handle_symbol() return values (hashrefs) (and undefs)
# On Error returns a string, pointer not advanced
# On Success advances pointer over the list
sub _handle_list {  ## no critic (ProhibitExcessComplexity)
	my ($self,%param) = @_; # params: is_lhs
	my $outerlist = $self->{ptr};
	return $self->_errormsg("expected List or Constructor")
		unless $outerlist->isa('PPI::Structure::List') || $outerlist->isa('PPI::Structure::Constructor');
	# prevent caller from accidentally expecting a list (we return an arrayref)
	confess "Internal error: _handle_list called in list context" if wantarray;
	croak "can only handle a plain list on LHS"
		if $param{is_lhs} && !$outerlist->isa('PPI::Structure::List');
	$self->_debug("parsing a list ".($param{is_lhs}?"(LHS)":"(Not LHS)"));
	if (!$outerlist->schildren) { # empty list
		$self->{ptr} = $outerlist->snext_sibling;
		return [];
	}
	# the first & only child of the outer list structure is a statement / expression
	my $act_list = $outerlist->schild(0);
	croak "Unsupported list\n"._errmsg($outerlist)
		unless $outerlist->schildren==1 && ($act_list->isa('PPI::Statement::Expression') || $act_list->class eq 'PPI::Statement');
	my @thelist;
	my $last_value; # for scalar context and !is_lhs
	{ # block for local ptr
	my $expect = 'item';
	local $self->{ptr} = $act_list->schild(0);
	while ($self->{ptr}) {
		if ($expect eq 'item') {
			my $peek_next = $self->{ptr}->snext_sibling;
			my $fat_comma_next = $peek_next && $peek_next->isa('PPI::Token::Operator') && $peek_next->content eq '=>';
			if ($param{is_lhs}) {
				if ($self->{ptr}->isa('PPI::Token::Symbol')) {
					my $sym = $self->_handle_symbol();
					return $sym unless ref $sym;
					$self->_debug("LHS List symbol: \"$$sym{name}\"/$$sym{atype}");
					push @thelist, $sym;
				}
				elsif (!$fat_comma_next && $self->{ptr}->isa('PPI::Token::Word') && $self->{ptr}->literal eq 'undef') {
					$self->_debug("LHS List undef");
					push @thelist, undef;
					$self->{ptr} = $self->{ptr}->snext_sibling;
				}
				else
					{ return "Don't support this on LHS: "._errmsg($self->{ptr}) }
			}
			else {
				# handle fat comma autoquoting words
				if ($fat_comma_next && $self->{ptr}->isa('PPI::Token::Word') && $self->{ptr}->literal=~/^\w+$/ ) {
					my $word = $self->{ptr}->literal;
					$self->_debug("list fat comma autoquoted \"$word\"");
					push @thelist, $word;
					$last_value = $word;
					$self->{ptr} = $self->{ptr}->snext_sibling;
				}
				else {
					my $val = $self->_handle_value();
					return $val unless ref $val;
					push @thelist, $val->();
					$last_value = $val->() if $self->{ctx}=~/^scalar\b/;
				}
			}
			$expect = 'separator';
		}
		elsif ($expect eq 'separator') {
			return $self->_errormsg("expected List Separator")
				unless $self->{ptr}->isa('PPI::Token::Operator')
				&& ($self->{ptr}->content eq ',' || $self->{ptr}->content eq '=>');
			$self->{ptr} = $self->{ptr}->snext_sibling;
			$expect = 'item';
		}
		else { confess "really shouldn't happen, bad state $expect" }  # uncoverable statement
	}
	} # end block for local ptr
	$self->{ptr} = $outerlist->snext_sibling;
	# don't use $thelist[-1] here because that flattens all lists - consider: my $x = (3,());
	# in scalar ctx the comma op always throws away its LHS, so $x should be undef
	return [$last_value] if !$param{is_lhs} && $self->{ctx}=~/^scalar\b/;
	return \@thelist;
}

# Handles Symbols, subscripts and (implicit) arrow operator derefs
# Returns a hashref representing the symbol:
#   name = the name of the symbol (TODO Later: Currently only used for debugging messages, remove?)
#   atype = the raw_type of the symbol
#   ref = reference to our storage location
# On Error returns a string, pointer not advanced
# On Success advances pointer over the symbol and possible subscript
sub _handle_symbol {  ## no critic (ProhibitExcessComplexity)
	my ($self) = @_;
	my $sym = $self->{ptr};
	return $self->_errormsg("expected Symbol")
		unless $sym && $sym->isa('PPI::Token::Symbol');
	my %rsym = ( name => $sym->symbol, atype => $sym->raw_type );
	$self->_debug("parsing a symbol \"".$sym->symbol.'"');
	my $temp_ptr = $sym->snext_sibling;
	if ($temp_ptr && $temp_ptr->isa('PPI::Structure::Subscript')) {
		my $ss = $self->_handle_subscript($temp_ptr);
		return $ss unless ref $ss;
		# fetch the variable reference with subscript
		if ($sym->raw_type eq '$' && $sym->symbol_type eq '@' && $$ss{braces} eq '[]') {
			$rsym{ref} = \( $self->{out}{$sym->symbol}[$$ss{sub}] );
		}
		elsif ($sym->raw_type eq '$' && $sym->symbol_type eq '%' && $$ss{braces} eq '{}') {
			$rsym{ref} = \( $self->{out}{$sym->symbol}{$$ss{sub}} );
		}
		else { return $self->_errormsg("can't handle this subscript on this variable: "._errmsg($sym)._errmsg($temp_ptr)) }
		$self->_debug("handled symbol with subscript");
		$temp_ptr = $temp_ptr->snext_sibling;
	}
	else {
		$self->_debug("handled symbol without subscript");
		$rsym{ref} = \( $self->{out}{$sym->symbol} );
		$temp_ptr = $sym->snext_sibling;
	}
	while (1) {
		if ($temp_ptr && $temp_ptr->isa('PPI::Token::Operator') && $temp_ptr->content eq '->') {
			$self->_debug("skipping arrow operator between derefs");
			$temp_ptr = $temp_ptr->snext_sibling;
			next; # ignore arrows
		}
		elsif ($temp_ptr && $temp_ptr->isa('PPI::Structure::Subscript')) {
			my $ss = $self->_handle_subscript($temp_ptr);
			return $ss unless ref $ss;
			if ($$ss{braces} eq '[]')  {
				$self->_debug("deref [$$ss{sub}]");
				return $self->_errormsg("Not an array reference") unless ref(${$rsym{ref}}) eq 'ARRAY';
				$rsym{ref} = \( ${ $rsym{ref} }->[$$ss{sub}] );
			}
			elsif ($$ss{braces} eq '{}') {
				$self->_debug("deref {$$ss{sub}}");
				return $self->_errormsg("Not a hash reference") unless ref(${$rsym{ref}}) eq 'HASH';
				$rsym{ref} = \( ${ $rsym{ref} }->{$$ss{sub}} );
			}
			else { croak "unknown braces ".$$ss{braces} }
			$self->_debug("dereferencing a subscript");
			$temp_ptr = $temp_ptr->snext_sibling;
		}
		else { last }
	}
	$self->{ptr} = $temp_ptr;
	return \%rsym;
}

# Handles a subscript, for use in _handle_symbol
# Input: $self, subscript element
# On Success Returns a hashref with the following elements:
#   sub = the subscript's value
#   braces = the brace type, either [] or {}
# On Error returns a string
# Does NOT advance the pointer
sub _handle_subscript {
	my ($self,$subscr) = @_;
	croak "not a subscript" unless $subscr->isa('PPI::Structure::Subscript');
	# fetch subscript
	my @sub_ch = $subscr->schildren;
	return $self->_errormsg("expected subscript to contain a single expression")
		unless @sub_ch==1 && $sub_ch[0]->isa('PPI::Statement::Expression');
	my @subs = $sub_ch[0]->schildren;
	return $self->_errormsg("expected subscript to contain a single value")
		unless @subs==1;
	my $sub;
	# autoquoting in hash braces
	if ($subscr->braces eq '{}' && $subs[0]->isa('PPI::Token::Word'))
		{ $sub = $subs[0]->literal }
	else {
		local $self->{ctx} = 'scalar';
		local $self->{ptr} = $subs[0];
		my $v = $self->_handle_value();
		return $v unless ref $v;
		$sub = $v->();
	}
	$self->_debug("evaluated subscript to \"$sub\", braces ".$subscr->braces);
	return { sub=>$sub, braces=>$subscr->braces };
}

# Handles lots of different values (including lists)
# Returns a coderef which, when called, returns the value(s)
# On Error returns a string, pointer not advanced
# On Success advances pointer over the value
sub _handle_value {  ## no critic (ProhibitExcessComplexity)
	my ($self) = @_;
	my $val = $self->{ptr};
	return $self->_errormsg("expected Value") unless $val;
	if ($val->isa('PPI::Token::Number')) {  ## no critic (ProhibitCascadingIfElse)
		my $num = 0+$val->literal;
		$self->_debug("consuming number $num as value");
		$self->{ptr} = $val->snext_sibling;
		return sub { return $num }
	}
	elsif ($val->isa('PPI::Token::Word') && $val->literal eq 'undef') {
		$self->_debug("consuming undef as value");
		$self->{ptr} = $val->snext_sibling;
		return sub { return undef }  ## no critic (ProhibitExplicitReturnUndef)
	}
	elsif ($val->isa('PPI::Token::Word') && $val->literal=~/^-\w+$/) {
		my $word = $val->literal;
		$self->_debug("consuming dashed bareword \"$word\" as value");
		$self->{ptr} = $val->snext_sibling;
		return sub { return $word }
	}
	elsif ($val->isa('PPI::Token::Quote')) {
		# handle the known PPI::Token::Quote subclasses
		my $str;
		if ( $val->isa('PPI::Token::Quote::Single') || $val->isa('PPI::Token::Quote::Literal') )
			{ $str = $val->literal }
		elsif ( $val->isa('PPI::Token::Quote::Double') || $val->isa('PPI::Token::Quote::Interpolate') ) {
			# do very limited string interpolation
			$str = $val->string;
			# Perl (at least v5.20) doesn't allow trailing $, it does allow trailing @
			return "final \$ should be \\\$ or \$name" if $str=~/\$$/;
			# Variables
			$str=~s{(?<!\\)((?:\\\\)*)(\$\w+)}{$1.$self->_fetch_interp_var($2)}eg;
			$str=~s{(?<!\\)((?:\\\\)*)(\$)\{(\w+)\}}{$1.$self->_fetch_interp_var($2.$3)}eg;
			return "don't support string interpolation of '$1' in '$str' at "._errmsg($val)
				if $str=~/(?<!\\)(?:\\\\)*([\$\@].+)/;
			# Backslash escape sequences
			$str=~s{\\([0-7]{1,3}|x[0-9A-Fa-f]{2}|.)}{_unbackslash($1)}eg;
		}
		else
			{ confess "unknown PPI::Token::Quote subclass ".$val->class }  # uncoverable statement
		$self->_debug("consuming quoted string \"$str\" as value");
		$self->{ptr} = $val->snext_sibling;
		return sub { return $str };
	}
	elsif ($val->isa('PPI::Token::Symbol')) {
		my $sym = $self->_handle_symbol();
		return $sym unless ref $sym;
		$self->_debug("consuming and accessing symbol \"$$sym{name}\"/$$sym{atype} as value (ctx: ".$self->{ctx}.")");
		if ($sym->{atype} eq '$') {
			return sub { return ${ $sym->{ref} } }
		}
		elsif ($sym->{atype} eq '@') {
			return $self->{ctx}=~/^scalar\b/
				? sub { return scalar( @{ ${ $sym->{ref} } } ) }
				: sub { wantarray or confess "expected to be called in list context";
					return @{ ${ $sym->{ref} } } }
		}
		elsif ($sym->{atype} eq '%') {
			return $self->{ctx}=~/^scalar\b/
				? sub { return scalar( %{ ${ $sym->{ref} } } ) }
				: sub { wantarray or confess "expected to be called in list context";
					return %{ ${ $sym->{ref} } } }
		}
		else { confess "bad symbol $sym" }
	}
	elsif ($val->isa('PPI::Structure::Constructor')) {
		local $self->{ctx} = 'list';
		my $l = $self->_handle_list();
		return $l unless ref $l;
		$self->_debug("consuming arrayref/hashref constructor as value");
		if ($val->braces eq '[]')
			{ return sub { return [ @$l ] } }
		elsif ($val->braces eq '{}')
			{ return sub { return { @$l } } }
		croak "Unsupported constructor\n"._errmsg($val);  # uncoverable statement
	}
	elsif ($val->isa('PPI::Token::Word') && $val->literal eq 'do'
		&& $val->snext_sibling && $val->snext_sibling->isa('PPI::Structure::Block')) {
		$self->_debug("attempting to consume block as value");
		return $self->_handle_block();
	}
	elsif ($val->isa('PPI::Structure::List')) {
		my $l = $self->_handle_list();
		return $l unless ref $l;
		$self->_debug("consuming list as value");
		return $self->{ctx}=~/^scalar\b/
			? sub { return $l->[-1] } # note in this case we should only be getting one value from _handle_list anyway
			: sub { wantarray or confess "expected to be called in list context";
				return @$l }
	}
	elsif ($val->isa('PPI::Token::QuoteLike::Words')) { # qw//
		my @l = $val->literal; # returns a list of words
		$self->_debug("consuming qw/@l/ as value");
		$self->{ptr} = $val->snext_sibling;
		return $self->{ctx}=~/^scalar\b/
			? sub { return $l[-1] }
			: sub { wantarray or confess "expected to be called in list context";
				return @l }
	}
	return $self->_errormsg("can't handle value");
}

my %_backsl_tbl = ( '\\'=>'\\', '$'=>'$', '"'=>'"', "'"=>"'", 'n'=>"\n", 'r'=>"\r", 't'=>"\t" );
sub _unbackslash {
	my ($what) = @_;
	return chr(oct($what)) if $what=~/^[0-7]{1,3}$/;
	return chr(hex($1)) if $what=~/^x([0-9A-Fa-f]{2})$/;  ## no critic (ProhibitCaptureWithoutTest)
	return $_backsl_tbl{$what} if exists $_backsl_tbl{$what};
	croak "Don't support escape sequence \"\\$what\"";
}

sub _fetch_interp_var {
	my ($self,$var) = @_;
	return $self->{out}{$var}
		if exists $self->{out}{$var} && defined $self->{out}{$var};
	warnings::warnif("Use of uninitialized value $var in interpolation");
	return "";
}


1;
