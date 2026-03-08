use strict;
use warnings;

package Data::ZPath::Node;

use B ();
use Scalar::Util qw(blessed refaddr reftype isdual);

our $VERSION = '0.001000';

sub _created_as_string {
	my $value = shift;
	defined $value
		and not ref $value
		and not _is_bool( $value )
		and not _created_as_number( $value );
}

sub _created_as_number {
	my $value = shift;
	return !!0 unless defined $value;
	return !!0 if ref $value;
	return !!0 if utf8::is_utf8( $value );
	my $b_obj = B::svref_2object(\$value);
	my $flags = $b_obj->FLAGS;
	return !!1 if $flags & ( B::SVp_IOK() | B::SVp_NOK() ) and not( $flags & B::SVp_POK() );
	return !!0;
}

sub _is_bool {
	my $value = shift;

	my $ref = ref($value) || '';
	if ( $ref eq 'SCALAR' and defined $$value ) {
		return !!1 if $$value eq 0;
		return !!1 if $$value eq 1;
	}

	if ( blessed($value) and $value->isa('Types::Serialiser::Boolean') ) {
		return !!1;
	}

	if ( blessed($value) and $value->isa('JSON::PP::Boolean') ) {
		return !!1;
	}

	return !!0 unless defined $value;
	return !!0 if $ref;
	return !!0 unless isdual( $value );
	return !!1 if  $value and "$value" eq '1' and $value + 0 == 1;
	return !!1 if not $value and "$value" eq q'' and $value + 0 == 0;
	return !!0;
}

sub from_root {
	my ( $class, $obj ) = @_;
	return $class->_wrap($obj);
}

sub _wrap {
	my ( $class, $obj, $parent, $key, $ix ) = @_;

	my $is_xml = blessed($obj) && $obj->isa('XML::LibXML::Node');
	my $id;

	if ( blessed($obj) && $obj->isa('XML::LibXML::Document') ) {
		$obj    = $obj->documentElement;
		$key    = $obj->nodeName;
		$is_xml = 1;
	}

	if ( $is_xml ) {
		$id = 'xml:' . refaddr($obj);
	} elsif ( ref($obj) ) {
		$id = 'ref:' . refaddr($obj);
	} elsif ( $parent ) {
		my $pid = $parent->id;
		$pid = 'root' unless defined $pid;
		my $k = defined $key ? $key : '';
		$id = 'slot:' . $pid . ':' . $k;
	} else {
		# primitive: no stable identity, but used as a value node (not deduped as a tree node)
		$id = undef;
	}

	return bless {
		raw    => $obj,
		parent => $parent,
		key    => $key,
		id     => $id,
		ix     => $ix,
		slot   => undef, # coderef getter/setter for Perl scalar lvalue
	}, $class;
}

sub raw    { $_[0]{raw} }
sub parent { $_[0]{parent} }
sub key    { $_[0]{key} }
sub id     { $_[0]{id} }
sub ix     { $_[0]{ix} }
sub index  { $_[0]{ix} }

sub slot {
	my ( $self ) = @_;
	return $self->{slot};
}

sub with_slot {
	my ( $self, $slot ) = @_;
	$self->{slot} = $slot;
	return $self;
}

sub type {
	my ( $self, $x ) = @_;
	$x = $self->{raw} if @_ == 1;

	if ( blessed($x) && $x->isa('CBOR::Free::Tagged') ) {
		return $self->type($x->[1]);
	}

	if ( blessed($x) && $x->isa('XML::LibXML::Namespace') ) {
		return 'attr';
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Attr') ) {
		return 'attr';
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Text') ) {
		return 'text';
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Element') ) {
		return 'element';
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Document') ) {
		return 'document';
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Comment') ) {
		return 'comment';
	}

	if ( blessed($x) && $x->isa('Math::BigInt') ) {
		return 'number';
	}

	return 'null'    unless defined $x;
	return 'map'     if ref($x) eq 'HASH';
	return 'list'    if ref($x) eq 'ARRAY';
	return 'boolean' if _is_bool($x);
	return 'number'  if _created_as_number($x);
	return 'string'  if _created_as_string($x);
	return ref($x);
}

# Essentially returns raw, but normalizes booleans
sub value {
	my ( $self, $x ) = @_;
	$x = $self->{raw} if @_ == 1;

	if ( ref $x and reftype($x) and reftype($x) eq 'SCALAR' ) {
		return !!$$x if $x eq 0 || $x eq 1;
	}
	if ( blessed($x) and $x->isa('Types::Serialiser::Boolean') ) {
		return !!( $x ? 1 : 0 );
	}
	if ( blessed($x) and $x->isa('JSON::PP::Boolean') ) {
		return !!( $x ? 1 : 0 );
	}

	return $x;
}

sub primitive_value {
	my ( $self, $x ) = @_;
	$x = $self->{raw} if @_ == 1;

	if ( blessed($x) && $x->isa('CBOR::Free::Tagged') ) {
		return $self->type($x->[1]);
	}

	if ( blessed($x) && $x->isa('XML::LibXML::Document') ) {
		my $de = $x->documentElement;
		return defined($de) ? $de->textContent : undef;
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Namespace') ) {
		return $x->declaredURI // $x->nodeValue // '';
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Attr') ) {
		return $x->getValue;
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Element') ) {
		return $x->textContent;
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Text') ) {
		return $x->data;
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Comment') ) {
		return $x->data;
	}

	if ( ref $x and reftype($x) and reftype($x) eq 'SCALAR' ) {
		return !!$$x if $x eq 0 || $x eq 1;
	}

	if ( blessed($x) and $x->isa('Types::Serialiser::Boolean') ) {
		return !!( $x ? 1 : 0 );
	}

	if ( blessed($x) and $x->isa('JSON::PP::Boolean') ) {
		return !!( $x ? 1 : 0 );
	}

	return $x;
}

sub string_value {
	my ( $self, $x ) = @_;
	$x = $self->{raw} if @_ == 1;

	if ( blessed($x) && $x->isa('CBOR::Free::Tagged') ) {
		return $self->type($x->[1]);
	}

	if ( blessed($x) && $x->isa('XML::LibXML::Document') ) {
		my $de = $x->documentElement;
		return defined($de) ? $de->textContent : undef;
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Namespace') ) {
		return $x->declaredURI // $x->nodeValue // '';
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Attr') ) {
		return $x->getValue;
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Element') ) {
		return $x->textContent;
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Text') ) {
		return $x->data;
	}
	if ( blessed($x) && $x->isa('XML::LibXML::Comment') ) {
		return $x->data;
	}

	my $v = $self->primitive_value;
	return undef unless defined $v;
	return "$v";
}

sub number_value {
	my ( $self ) = @_;
	my $v = $self->primitive_value;
	return undef unless defined $v && Scalar::Util::looks_like_number($v);

	if ( $Data::ZPath::UseBigInt and $v =~ /\A-?[0-9]{19,}\z/ ) {
		require Math::BigInt;
		return Math::BigInt->from_dec($v);
	}

	return 0 + $v;
}

sub children {
	my ( $self ) = @_;
	my $x = $self->{raw};

	# XML document: treat documentElement as child
	if ( blessed($x) && $x->isa('XML::LibXML::Document') ) {
		my $de = $x->documentElement;
		return unless $de;
		return Data::ZPath::Node->_wrap($de, $self, 0);
	}

	if ( blessed($x) && $x->isa('XML::LibXML::Element') ) {
		my @kids = $Data::ZPath::XmlIgnoreWS ? $x->nonBlankChildNodes : $x->childNodes;
		my %count;
		return map { Data::ZPath::Node->_wrap($_, $self, $_->nodeName, $count{$_->nodeName}++ || 0) } @kids;
	}

	if ( ref($x) eq 'HASH' ) {
		my @out;
		for my $k (keys %$x) {
			my $child = Data::ZPath::Node->_wrap($x->{$k}, $self, $k);
			$child->with_slot(sub {
				if ( @_ ) { $x->{$k} = $_[0]; }
				return $x->{$k};
			}) unless ref($x->{$k});
			push @out, $child;
		}
		return @out;
	}

	if ( ref($x) eq 'ARRAY' ) {
		my @out;
		for ( my $i = 0; $i < @$x; $i++ ) {
			my $child = Data::ZPath::Node->_wrap($x->[$i], $self, $i, $i);
			$child->with_slot(sub {
				if ( @_ ) { $x->[$i] = $_[0]; }
				return $x->[$i];
			}) unless ref($x->[$i]);
			push @out, $child;
		}
		return @out;
	}

	return ();
}

sub attributes {
	my ( $self ) = @_;
	my $x = $self->{raw};
	return unless blessed($x) && $x->isa('XML::LibXML::Element');
	my @attrs = $x->attributes;
	return map { Data::ZPath::Node->_wrap($_, $self, '@' . $_->nodeName) } @attrs;
}

sub name {
	my ( $self ) = @_;
	my $x = $self->{raw};

	if ( blessed($x) && $x->isa('XML::LibXML::Attr') )    { return '@' . $x->nodeName; }
	if ( blessed($x) && $x->isa('XML::LibXML::Element') ) { return $x->nodeName; }
	if ( blessed($x) && $x->isa('XML::LibXML::Text') )    { return '#text'; }

	return $self->{key};
}

sub dump {
	my ( $self ) = @_;
	return {
		'@type'      => $self->type,
		'@id'        => $self->id,
		'@key'       => $self->key,
		'@index'     => $self->index,
		'@value'     => $self->primitive_value,
		children     => [ map $_->dump, $self->children ],
		attributes   => [ map $_->dump, $self->attributes ],
	};
}

sub find {
	require Data::ZPath;
	my ( $self, $zpath ) = @_;
	$zpath = Data::ZPath->new( $zpath ) unless blessed($zpath);
	return $zpath->evaluate( $self );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Data::ZPath::Node - Node wrapper used by Data::ZPath

=head1 DESCRIPTION

Objects of this class wrap underlying Perl or XML values and
provide traversal and type-coercion helpers used while evaluating
ZPath expressions.

=head1 METHODS

=head2 C<< from_root($value) >>

Create a new node from a root value.

=head2 C<< raw >>

Return the wrapped underlying value.

=head2 C<< parent >>

Return the parent node, or undef if this is a root node.

=head2 C<< key >>

Return the key/name/index token used to reach this node.

=head2 C<< id >>

Return a stable identifier string for deduplication where possible.

=head2 C<< ix >>

Return the numeric sibling index for this node when available.

=head2 C<< index >>

Alias for C<ix>.

=head2 C<< slot >>

Return an optional coderef used as a mutable scalar slot.

=head2 C<< with_slot($coderef) >>

Attach a slot coderef to the node and return the node.

=head2 C<< type >>

Return the ZPath type name of the wrapped value.

=head2 C<< value >>

Return the wrapped value, normalizing boolean-like values.

=head2 C<< primitive_value >>

Return a scalar representation suitable for ZPath primitive
comparisons.

=head2 C<< string_value >>

Return the wrapped value coerced to a string, if defined.

=head2 C<< number_value >>

Return the wrapped value coerced to a number, if numeric.

=head2 C<< children >>

Return wrapped child nodes.

For XML elements this returns child nodes, optionally excluding
whitespace-only text nodes depending on
C<$Data::ZPath::XmlIgnoreWS>. For Perl hashes and arrays this
returns wrapped value children.

=head2 C<< attributes >>

Return wrapped XML attributes for an XML element.

=head2 C<< name >>

Return the node name used by path matching.

=head2 C<< dump >>

Return a plain Perl data structure for debugging.

=head2 C<< find( $zpath ) >>

Accepts either a Data::ZPath object or a ZPath string.

The following two are roughly equivalent:

  $zpath->evaluate( $node )
  $node->find( $zpath )

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
