#
# Copyright (C) 1997 Ken MacLeod
# Class::Visitor is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Visitor.pm,v 1.3 1997/11/03 17:38:10 ken Exp $
#

package Class::Visitor;

require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(visitor_class);
use strict;
use vars qw($VERSION);

$VERSION = '0.02';

use Class::Template;
use Class::Iter;

sub visitor_class {
    my( $pkg, $super, $ref ) = @_;
    my @methods = ();
    my %refs = ();
    my %arrays = ();
    my %hashes = ();
    my $out = '';

    members ($pkg, $ref);

    # XXX this is redundant, but saves hacking Class::Template
    Class::Template::parse_fields( $ref, \$out, \@methods, \%refs, \%arrays, \%hashes );

    eval "\@${pkg}::ISA = qw{$super}";
    if ($super eq 'Class::Visitor::Base') {
	eval "\@${pkg}::Iter::ISA = qw{Class::Iter}";
    } else {
	eval "\@${pkg}::Iter::ISA = qw{${super}::Iter}";
    }

    $out = <<EOF;
{
  package $pkg;
EOF
    build_push_methods_( $ref, \$out, \@methods, \%refs, \%arrays, \%hashes );


    my $str = <<'EOF';
  sub accept {
    my $self = shift; my $visitor = shift;
    $visitor->visit_!visit_method! ($self, @_);
  }
  # [self, parent, array, index]
  sub iter {
    my $iter = [@_];
    bless $iter, '!package!::Iter';
  }

  sub new {
    my ($type) = shift;

    my ($self) = !type!;
    bless ($self, $type);

    return ($self);
  }
}

{
  package !package!::Iter;

  sub accept {
    my $self = shift; my $visitor = shift;
    $visitor->visit_!visit_method! ($self, @_);
  }
EOF
        my $visit_method = $pkg;
        $visit_method =~ s/::/_/g;
        $str =~ s/!package!/$pkg/g;
        $str =~ s/!visit_method!/$visit_method/g;
        my $type = (ref ($ref) eq 'HASH') ? '{@_}' : '[@_]';
        $str =~ s/!type!/$type/g;
        $out .= $str;

        build_iter_methods_( $ref, \$out, \@methods, \%refs, \%arrays, \%hashes );

    $out .= "}\n1;\n";

    # XXX we ``inherit'' `print' from Class::Template
    ( $Class::Template::print ) ? print( $out ) : eval $out;
}

sub build_iter_methods_ {
    my( $ref, $out, $methods, $refs, $arrays, $hashes ) = @_;
    my $type = ref $ref;

    my $method;
    foreach $method (@$methods) {
	$$out .= <<EOF;
  sub $method {
    my \$self = shift;
    return (\$self->[0]->$method (\@_));
  }
EOF
	if (defined $arrays->{$method}) {
	    if ($method eq 'contents') {
		$$out .= <<EOF;
  sub children_accept {
      children_accept_contents (\@_);
  }
  sub as_string {
      contents_as_string (\@_);
  }
EOF
	    }
	    my $str = <<'EOF';
  sub push_!member! {
      my $self = shift;
      return ($self->[0]->push_!member! (@_));
  }
  sub pop_!member! {
      my $self = shift;
      return ($self->[0]->pop_!member! (@_));
  }
  sub !member!_as_string {
      my $self = shift;
      return ($self->[0]->!member!_as_string (@_));
  }
  sub children_accept_!member! {
    my $self = shift; my $visitor = shift;
    my $array = $self->[0]->!member!();
    my $ii;
    for ($ii = 0; $ii <= $#$array; $ii ++) {
	my ($child) = $array->[$ii];
	if (!ref ($child)) {
	    my $iter = bless ([$child, $self, $array, $ii],
			      'Class::Scalar::Iter');
	    $visitor->visit_scalar ($iter, @_);
	} else {
	    my $iter = $child->iter ($self, $array, $ii);
	    $iter->accept ($visitor, @_);
	}
    }
  }
EOF
            $str =~ s/!member!/$method/g;
            $$out .= $str;
        }
    }
}

sub build_push_methods_ {
    my( $ref, $out, $methods, $refs, $arrays, $hashes ) = @_;
    my $type = ref $ref;

    my $method;
    my $cnt = 0;		# count used for array classes
    foreach $method (@$methods) {
	if (defined $arrays->{$method}) {
	    if ($method eq 'contents') {
		$$out .= <<EOF;
  sub push {
      return (push_contents (\@_));
  }
  sub pop {
      return (pop_contents (\@_));
  }
  sub as_string {
      return (contents_as_string (\@_));
  }
  sub children_accept {
      return (children_accept_contents (\@_));
  }
EOF
	    }
            my $str = <<'EOF';
  sub push_!member! {
      my $self = shift;
      push (@{$self->!member_ref!}, @_);
  }
  sub pop_!member! {
      my $self = shift;
      return (pop (@{$self->!member_ref!}));
  }
  sub !member!_as_string {
      my $self = shift;
      my $array = $self->!member_ref!;
      my @string;
      my $ii;
      for ($ii = 0; $ii <= $#$array; $ii ++) {
	  my ($child) = $array->[$ii];
	  if (!ref ($child)) {
	      # XXX should use context for a CDATA mapper
	      push (@string, $child);
	} else {
	    # note, not passing as iterator
	    push (@string, $child->as_string(@_));
	}
    }
    return (join ("", @string));
  }
  sub children_accept_!member! {
    my $self = shift; my $visitor = shift;
    my $array = $self->!member_ref!;
    my $ii;
    for ($ii = 0; $ii <= $#$array; $ii ++) {
	my ($child) = $array->[$ii];
	if (!ref ($child)) {
	    $visitor->visit_scalar ($child, @_);
	} else {
	    $child->accept ($visitor, @_);
	}
    }
  }
EOF
            $str =~ s/!member!/$method/g;
            my $member_ref = ($type eq 'HASH') ? "{'$method'}" : "[$cnt]";
            $str =~ s/!member_ref!/$member_ref/g;
            $$out .= $str;
        }

        $cnt ++;
    }
}

package Class::Visitor::Base;

sub is_iter {
    return 0;
}

sub delegate {
    return $_[0];
}

1;
__END__

=head1 NAME

Class::Visitor - Visitor and Iterator extensions to Class::Template

=head1 SYNOPSIS

  use Class::Visitor;

  visitor_class 'CLASS', 'SUPER', { TEMPLATE };
  visitor_class 'CLASS', 'SUPER', [ TEMPLATE ];

  $obj = CLASS->new ();
  $iter = $obj->iter;
  $iter = $obj->iter ($parent, $array, $index);

  $obj->accept($visitor, ...);
  $obj->children_accept($visitor, ...);
  $obj->children_accept_ARRAYMEMBER ($visitor, ...);
  $obj->push_ARRAYMEMBER($value[, ...]);
  $value = $obj->pop_ARRAYMEMBER;
  $obj->as_string ([$context[, ...]]);
  $obj->ARRAYMEMBER_as_string ([$context[, ...]]);

  $iter inherits the following from Class::Iter:

  $iter->parent;
  $iter->is_iter;
  $iter->root;
  $iter->rootpath;
  $iter->next;
  $iter->at_end;
  $iter->delegate;
  $iter->is_same ($obj);

=head1 DESCRIPTION

C<Class::Visitor> extends the getter/setter functions provided by
C<Class::Template> for I<CLASS> by defining methods for using the
Visitor and Iterator design patterns.  All of the Iterator methods are
inherited from C<Class::Iter> except C<iter>.

I<CLASS> is the name of the new class, I<SUPER> the superclass of
this class (will define C<@ISA>), and I<TEMPLATE> is as defined in
C<Class::Template>.

C<$obj->iter> returns a new iterator for this object.  If C<parent>,
C<array>, and C<index> are not defined, then the new iterator is
treated as the root object.  Except as inherited from C<Class::Iter>
or as defined below, methods for C<$iter> and C<$obj> work the same.

The C<accept> methods cause a callback to C<$visitor> with C<$self> as
the first argument plus the rest of the arguments passed to
C<accept>.  This is implemented like:

    sub accept {
        my $self = shift; my $visitor = shift;
        $visitor->visit_MyClass ($self, @_);
    }

C<children_accept> calls C<accept> on each object in the array field
named C<contents>.  C<children_accept_I<ARRAYMEMBER>> does the same for
I<ARRAYMEMBER>.

Calling C<accept> methods on iterators always calls back using
iterators.  Calling C<accept> on non-iterators calls back using
non-iterators.  The latter is significantly faster.

C<push> and C<pop> act like their respective array functions.

C<as_string> returns the concatenated scalar values of the array field
named C<contents>, possibly modified by C<$context>.
C<I<ARRAYMEMBER>_as_string> does the same for I<ARRAYMEMBER>.

Visitor handles scalars specially for C<children_accept> and
C<as_string>.  In the case of C<children_accept>, Visitor will create
an iterator in the class C<Class::Scalar::Iter> with the scalar as the
delegate.

In the case of C<as_string>, Visitor will use the string unless
C<$context-E<gt>{cdata_mapper}> is defined, in which case it returns
the result of calling the C<cdata_mapper> subroutine with the scalar
and the remaining arguments.  The actual implementation is:

    &{$context->{cdata_mapper}} ($scalar, @_);

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), Class::Template(3), Class::Iter(3).

The package C<SGML::SPGrove> uses C<Class::Visitor> extensively.

=cut
