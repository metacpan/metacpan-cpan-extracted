
###                                                                 ###
# Class::ArrayObjects - Utility class for array based objects         #
# Robin Berjon <robin@knowscape.com>                                  #
# ------------------------------------------------------------------- #
# 01/12/2003 - v1.02 support non-existing "with"                      #
# 07/07/2003 - v1.01 patch by Slaven Rezic so that "extend" will look #
#              into @ISA in case the class isn't specified.           #
# 06/07/2002 - v1.00 clean up                                         #
# 21/04/2001 - v0.04 many many documentation updates + release        #
# 02/04/2001 - v0.03 feature upgrade in view of release               #
# 28/01/2001 - v0.02 a few enhancements and uses                      #
# 12/12/2000 - v0.01 initial hack                                     #
###                                                                 ###


package Class::ArrayObjects;

use strict;
no  strict 'refs';
use vars qw($VERSION %packages);

$VERSION = '1.03';


#---------------------------------------------------------------------#
# import()
# this is where all the work gets done, at load
#---------------------------------------------------------------------#
sub import {
    my $class = shift;
    @_ or return;

    my $pkg = caller;
    my $method = shift;
    my $options = shift;

    ### grab the start index and the fields
    my ($idx, @fld, @real_fld);

    # for basic definition
    if ($method eq 'define') {
        $options->{fields} ||= [];
        $idx = 0;
        @fld = @{$options->{fields}};
        @real_fld = @fld;
    }

    # for extension
    elsif ($method eq 'extend') {
        $options->{with} ||= [];
        {
            no strict 'refs';
            if (not defined $options->{class} and @{ $pkg . '::ISA' } == 1) {
                $options->{class} = ${ $pkg . '::ISA' }[0];
            }
        }
        die "[$pkg]: can't extend undefined class $options->{class} with package $pkg"
            unless defined $packages{$options->{class}};

        # get what is needed to store the real idx
        @real_fld = (@{$packages{$options->{class}}}, @{$options->{with}});

        # support import of parent fields
        if ($options->{import}) {
            $idx = 0;
            @fld = @real_fld;
        }
        else {
            $idx = $#{$packages{$options->{class}}} + 1;
            @fld = @{$options->{with}};
        }
    }

    # there was an error
    else {
        die "[$pkg]: first arg must be 'define' or 'extend'";
    }

    # now lets create the subs
    for my $enum (@fld) {
        my $qname = "${pkg}::$enum";
        my $value = $idx;
        *$qname = sub () { $value };
        $idx++;

        # another way of doing it:
        # eval "sub ${pkg}::$enum () { $idx }";
        # die "[$pkg]: $@" if $@;
        # $idx++
    }
    $packages{$pkg} = \@real_fld; # store the fields for extension
    return 1;
}
#---------------------------------------------------------------------#



1;
=pod

=head1 NAME

Class::ArrayObjects - utility class for array based objects

=head1 SYNOPSIS

  package Some::Class;
  use Class::ArrayObjects define => {
                                      fields  => [qw(_foo_ _bar_ BAZ)],
                                    };

  or

  package Other::Class;
  use base 'Some::Class';
  use Class::ArrayObjects extend => {
                                      class   => 'Some::Class',
                                      with    => [qw(_zorg_ _fnord_ BEZ)],
                                      import  => 1,
                                    };

=head1 DESCRIPTION

This module is little more than a cute way of defining constant subs
in your own package. Constant subs are very useful when dealing with
array based objects because they allow one to access array slots by
name instead of by index.

=head2 Why use arrays for objects instead of hashes ?

There are two apparently compelling reasons to use arrays for objects
instead of hashes.

First: speed. In my benchmarks on a few boxes around here I've seen
arrays be faster by 30%. I must admit that my benchmarks weren't
perfect as I wasn't all that interested in speed per se, only in
knowing whether I was to take a serious performance hit or not (I was
nevertheless pleasantly surprised to note the opposite, it can't
hurt).

Second: memory. Memory was much more important to me as I was
targeting a mod_perl environment where every bit of memory tends to
count. Depending on how they are used, arrays use from 30% up to 65%
less space than hashes. As a rule of thumb the more keys you have, the
more you may save.

It must be said though that despite the fact that I happened to be
looking for ways to save space, it's not a reason to jump into array
based objects and start converting every single hash you have to an
array. Yes, I did see some of my processes lose I<~3Mo> of unshared
memory so there are definitely cases when it's useful. Such cases are
usually when you have lots of objects and/or structures that are
fairly similar in nature (ie have the same keys) but contain different
values. I don't know how Perl works internally but it would seem only
logical that it has to store the keys with every hash, whereas using
arrays there are no keys (which is why this package exists: to provide
you with something that looks like keys into arrays).

In addition to that, this package can be seen as twisting slightly the
view on how to do OO in Perl, encouraging some limited encapsulation
of fields and extension subclassing rather than override subclassing
(the latter really being a matter of taste).

=head2 Why not pseudo-hashes ?

Pseudo-hashes never appealed to me, they always seemed to have been
hacked on top of Perl. They never left experimental status, which
probably says a lot already. A number of things that work with hashes
and arrays don't work with them (and development seems to have
stopped). And overall, they usually end up not saving you any space
anyway. Pseudo-hashes must die.

=head2 Why Class::ArrayObjects ?

But why then use this class instead of the C<enum> or C<constant>
modules ? Because it adds extra sugar (yum).

Its main advantage over C<constant> (imho of course) is that you don't
have to define the value of each field. Less typing, more readability.

C<enum> also provides that plus but it enforces naming rules in a
way which I find limiting (it probably has very good reasons to do so,
but I think that they don't apply in the context of array based
objects). This module only complains if you try to use a field name
that isn't a valid Perl sub name. (Note: right now it doesn't even
complain because I was convinced when I wrote it that Perl would. But
it turns out that you are perfectly allowed to define a sub with a
forbidden name. Whether this is a bug or a feature, I don't know).

And last but not least, it defines a way to allow for inheritance
while using array based objects. A major drawback of array based
objects is that unlike with hashes, if your base class adds a field,
you have to move all your fields' indices up by one. You shouldn't
have to know such things, or even to care about it.

Here, instead of using the C<define> option (which creates fields in
a class), simply use the C<extend> option. Tell it which class to
extend (it needs to be already loaded, and must use
Class::ArrayObjects to define its fields too) and which fields to add.
Class::ArrayObjects takes care of counting from the right index in
your subclass. It can't do multiple inheritance, and unless someone
hacks it in somehow I doubt it ever will.

You may use the C<import> option to require that your parents' fields
be defined in your own package too, so that you can access them. It is
off by default so that you can use fields with the same names as those
of your superclasse(s) (which is a plus over hash based objects) and
also to avoid defining subs all over your package without you knowing
about them.

It may be worth noting that the added functionality doesn't get in the
way, and using this to define constants is just as fast as using
C<constant> or C<enum>.

=head1 USING Class::ArrayObjects

There are two ways to use Class::ArrayObjects, either to simply define
fields to use in your own objects, or to extend fields defined in a
superclass of your. In a wild burst of creative naming I thus spawned
into existence two options named respectively C<define> and C<extend>.

The way the two are used is the same:

use Class::ArrayObjects I<option-name> => I<hashref of options>

=head2 The define option

  package Some::Class;
  use Class::ArrayObjects define => {
                                      fields  => [qw(_foo_ _bar_ BAZ)],
                                    };

C<define> has only one option: C<fields>. It is an arrayref of strings
which are the names of the fields you wish to use. They can be anything,
so long as they are valid Perl sub names.

=head2 The extend option

  package Other::Class;
  use base 'Some::Class';
  use Class::ArrayObjects extend => {
                                      class   => 'Some::Class',
                                      with    => [qw(_zorg_ _fnord_ BEZ)],
                                      import  => 1,
                                    };

C<extend> has three options:

=over 4

=item * class

This defines the class to extend (it must also use Class::ArrayObjects
and have been loaded previously). If that class is not specified, it will
look at @ISA. If @ISA contains only one item it will use that one.

=item * with

This is exactly equivalent to C<fields> except that it reads better to
have extend class Foo with x,y,z.

=item * import

Defaulting to false, setting it to any true value will make your
superclasses' fields also defined in your package. This can be needed
at times, though I wouldn't encourage its use.

=back

=head2 After that ?

After you've defined fields, all you have to do is use them as indices
to your arrays.

  package Some::Class;
  use Class::ArrayObjects define => {
                                      fields  => [qw(_foo_ _bar_ BAZ)],
                                    };

  my @arry = qw(zorg stuff blurp);
  print $arry[_bar_]; # stuff

Any operation you can do on arrays with numeric indices works exactly
the same way. The only difference is that you are using names, which
are much easier to remember. There is no performance penalty for this,
Perl is smart enough to inline the return values of constant subs so
that when in the above example you say _bar_ it really sees 1.

=head2 A note to mod_perl users

The contexts in which I use this module are mostly mod_perl related.
In fact, one of the reasons I created it was to allow for the space
efficient representation of many objects. It may be further
optimizable, but so far it has already seemed to work well.

You can preload this module without defining any fields as follows:

  use Class::ArrayObjects qw();

In that case, C<import()> will not be called and nothing will happen
other then the preloading of the code. As a precaution, even if it
were called it would return immediately.

I do recommend that you preload all modules that are based on
Class::ArrayObjects so that the data it stores internally about which
fields belong to which classes (in order to allow for extension)
remains shared by all the processes.

=head1 BUGS AND CAVEATS

I don't know of any outstanding bugs presently but it is not
impossible that some may have filtered out. I have been using this
module in production for some time now, and it appears to be behaving
with stability.

Of course, you mustn't define a field in your package with the same
name as another sub.

As a rule of thumb, I find that this kind of class works better for
extension subclasses than for override subclasses, but YMMV.

=head1 TODO

 - add an interface to allow people to mess with the internals on
 demand
 - add serialisation helpers to allow one to persist an object based
 on Class::ArrayObjects and later retrieve it regardless of whether
 the order of the fields have changed or not.

=head1 ACKNOWLEDGMENTS

Greg Bacon's for his article I<Perl Heresies: Building Objects Out of
Arrays> which I read ages ago and inspired this module, one of the
first I put on CPAN.

Slaven Rezic for the @ISA patch.

=head1 AUTHOR

Robin Berjon, robin@knowscape.com

=head1 COPYRIGHT

Copyright (c) 2000-2002 Robin Berjon. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

nothing that I can think of...

=cut

