package Class::Accessor::Ref;

use strict;
use vars qw($VERSION $_DEBUG);
$VERSION = '0.05';
use base 'Class::Accessor';

$_DEBUG = 0;

=pod

=head1 NAME

Class::Accessor::Ref - Access members by reference

=head1 SYNOPSIS

  package Foo;
  use Class::Accessor::Ref;
  use base qw(Class::Accessor::Ref);
  use Some::API;

  my @members = qw(fruit color);
  Foo->mk_accessors(@members);     # as with Class::Accessor
  Foo->mk_refaccessors(@members);

  my $obj = Foo->new({fruit => 'grape', color => 'green'});
  Some::API::redden($obj->_ref_color);        # OR
  Some::API::redden($obj->get_ref('color'));
  print $obj->color;               # prints 'red'

  # safe against typos in memeber name
  ${ $obj->get_ref('color') } =~ s/^(.)/\U$1/;

  # same as above, but shorter setup
  package Foo;
  use Class::Accessor::Ref qw(fruit color);

=head1 DESCRIPTION

This is an extension of Class::Accessor that allows taking a reference
of members of an object. This is typically useful when your class
implementation uses a third-party module that expects an in/out parameter
in its interface.

Without Class::Accessor::Ref, you might try to do something like

  my $reference = \$obj->member;   # WRONG!
  Some::API::call($reference);

But that takes a reference to a B<copy> of $obj->member, and is thus
not useful if you want to use the reference to later change the member's
value.

It is quite possible to do something like

  my $reference = \$obj->{member}; # right, but risky

But then you will get no errors if you accidentally mistype the member's
name.

Class::Accessor::Ref is used very similarly to Class::Accessor --
just subclass it instead of Class::Accessor in your module, and call
mk_accessors on the fields you want to generate accessors for. Then, call
mk_refaccessors on the subset of the fields you want reference-taking
accessors generated for. The accessors will be automatically named
_ref_FIELD. You can continue to use the normal (non-reference) accessors
as before whenever appropriate.


=cut

use vars qw(%CLASSES);

my $ref_accessor = sub {
	my($self, $field) = @_;
	return \$self->{$field};
};

sub mk_refaccessors {
	my($class, @fields) = @_;
	no strict 'refs';
	for my $field (@fields) {
		if ($_DEBUG) { warn "$class->mk_refaccessors($field)\n" }
		die "$field is not a valid field" unless $class->can($field);
		# Canfield's some sort of a game, isn't it?
		*{"${class}::_ref_$field"} = sub { $ref_accessor->($_[0], $field) };
		$CLASSES{$class}->{$field} = 1;
	}
}


=pod

=head2 Methods

=over 4

=item B<mk_refaccessor>

    Class->mk_refaccessors(@fields);

This creates accessor methods for each named field given in @fields.
Foreach field in @fields it will generate one accessor called
"_ref_field()".  Normal accessors for the fields *must* have already
been created with Class::Accessor::mk_accessors(). For example:

    # Generates _ref_foo(), _ref_bar() but not _ref_baz():
          Class->mk_accessors(qw(foo bar baz));
          Class->mk_refaccessors(qw(foo bar));

It is up to the user of this reference to know what to do with it.

=item B<get_ref>

    $obj->get_ref(@field_names)

This returns references to members of $obj, specified by name in
@field_names. In scalar context, returns a reference to the first field.
This method is useful if you want to fetch several references from the object
at once, or if you don't like the _ref_ prefix.

    # Get referece to $obj->{foo}
          $fooref = $obj->get_ref('foo');
    #
    # Get several references at once
          ($fooref, $barref) = $obj->get_ref(qw/foo bar/);
    #
    # Stringify the reference, not the number "1":
          print "\$obj->{foo} is at " . $obj->get_ref('foo');

=cut

# XXX: This could benefit from memoization, but I don't know if
# I want to add that without asking the users -- if they call this
# on many many objects, it'll just be a waste of space. But adding
# a real LRU cache seems like a bit of an overkill :/

sub get_ref {
	my($self, @fields) = @_;
	my $class = ref $self;
	die "Can't take reference to members of unknown class $class. ".
		"Did you call $class->mk_refaccessors?"
		unless $CLASSES{$class};
	my @refs;
	foreach my $field (@fields) {
		die "Can't take reference to member $field of class $class. ".
			"Did you specify this field when calling $class->mk_refaccessors?"
			unless $CLASSES{$class}->{$field};
		push @refs, \$self->{$field};
	}
	return wantarray ? @refs : $refs[0];
}

=item B<import>

    use Class::Accessor::Ref qw(foo bar baz);

For the sake of convenience, you can specify what fields to generate
accessors for on the C<use> line. It also makes your calling package
a subclass of Class::Accessor::Ref, so you don't need to C<use base>.
If you want to generate refaccessors for only a subset of your regular
accessors, don't use this option, but rather make separate calls to
mk_accessors and mk_refaccessors. [Supporting this on the C<use> line
was considered, but I decided it was too cumbersome and would break code
that's just switching from Class::Accessor.]

    package Foo;
    use Class::Accessor::Ref qw(foo bar baz);

Is equivalent to

    package Foo;
    use Class::Accessor::Ref;
    use base 'Class::Accessor::Ref';
    Foo->mk_accessors(qw/foo bar baz/);
    Foo->mk_refaccessors(qw/foo bar baz/);

=back

=cut

sub import {
	my($class, @fields) = @_;
    return if !@fields;
	my $call_pkg = (caller)[0];
	if ($_DEBUG) { warn "$class: use C::A::R qw(".(join " ", @fields).")\n" }
    {
        # fake C<< packge Foo; use base 'Class::Accessor::Ref' >>
        no strict 'refs';
        push @{"$call_pkg\::ISA"}, $class;
    }
	if (@fields) {
		$call_pkg->mk_accessors(@fields);
		$call_pkg->mk_refaccessors(@fields);
	}
}

=head1 CAVEATS

Class::Accessor::Ref generates methods called _ref_SOMETHING in the
caller's namespace. Having an existing member whose name begins with
_ref_ would render the normal accessor to that member inaccessible,
so don't do that.

One point of Class::Accessor is to allow you to avoid changing members
directly. Since whoever gets hold of the return value of a _ref_ accessor
can circumvent any validations you may have imposed on the member (for
example, by overriding the normal setter method), this can be considered
somewhat unsafe. The main use of Class::Accessor::Ref is inside class
implementations, where you have control over who you trust with giving
a reference to your private data and who you don't.

=head1 COPYRIGHT (The "MIT" License)

Copyright 2003-2007 Gaal Yahas.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=head1 AUTHOR

Gaal Yahas <gaal@forum2.org>


=head1 SEE ALSO

L<Class::Accessor>

=cut


1;
