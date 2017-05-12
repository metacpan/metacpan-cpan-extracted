use strict;
use warnings;

package Data::Remember;
{
  $Data::Remember::VERSION = '0.140490';
}
# ABSTRACT: remember complex information without giving yourself a headache

use Carp;
use Scalar::Util qw/ reftype /;
use Class::Load ();
use Data::Remember::Class;


sub import {
    my $class   = shift;
    my $brain   = shift || 'Memory';

    my $caller = caller;

    my $gray_matter = Data::Remember::Class->new($brain, @_);
    $class->_import_brain( $gray_matter => $caller );
}

sub _import_brain {
    my $class   = shift;
    my $brain   = shift;
    my $package = shift;

    no strict 'refs';

    *{"$package\::remember"}          = remember($brain);
    *{"$package\::remember_these"}    = remember_these($brain);
    *{"$package\::recall"}            = recall($brain);
    *{"$package\::recall_each"}       = recall_each($brain);
    *{"$package\::recall_and_update"} = recall_and_update($brain);
    *{"$package\::forget"}            = forget($brain);
    *{"$package\::forget_when"}       = forget_when($brain);
    *{"$package\::brain"}             = brain($brain);
}


sub remember {
    my $brain = shift;

    sub ($$) {
        my $que  = shift;
        my $fact = shift;

        $brain->remember($que, $fact);
        return;
    };
}


sub remember_these {
    my $brain = shift;

    sub ($$) {
        my $que  = shift;
        my $fact = shift;

        $brain->remember_these($que, $fact);
        return;
    };
}


sub recall {
    my $brain = shift;

    sub ($) {
        my $que = shift;

        return scalar $brain->recall($que);
    };
}


sub recall_each {
    my $brain = shift;

    sub ($) {
        my $que = shift;

        return scalar $brain->recall_each($que);
    };
}


sub recall_and_update {
    my $brain = shift;

    sub (&$) {
        my $code = shift;
        my $que  = shift;

        return scalar $brain->recall_and_update($code, $que);
    };
}


sub forget {
    my $brain = shift;

    sub ($) {
        my $que = shift;

        $brain->forget($que);
        return;
    };
}


sub forget_when {
    my $brain = shift;

    sub (&$) {
        my $code = shift;
        my $que = shift;

        $brain->forget_when($code, $que);
        return;
    };
}


sub brain {
    my $brain = shift;

    sub () { return $brain->brain };
}


1;

__END__

=pod

=head1 NAME

Data::Remember - remember complex information without giving yourself a headache

=head1 VERSION

version 0.140490

=head1 SYNOPSIS

  use Data::Remember 'Memory';

  remember foo => 1;
  remember [ bar => 7 ], [ 'spaz', 'w00t', 'doof', 'flibble' ];
  remember [ 'xyz', 'abc', 'mno' ] => { some => 'thing' };

  remember_these cook => 'goose';
  remember_these cook => 'duck';
  remember_these cook => 'turkey';

  my $foo     = recall 'foo';        # retrieve a simple key
  my $wibbler = recall [ bar => 7 ]; # retrieve a complex key
  my $alpha   = recall 'xyz';        # retrieve a subkey

  my $cook    = recall [ 'cook' ];   # retrieves [ qw/ goose duck turkey / ]

  forget 'foo';

  my $foo_again = recall 'foo'; # $foo_again is undef

  forget_when { /^duck$/ } [ 'cook' ]; 

  my $cook_again = recall 'cook'; # $cook_again is [ qw/ goose turkey / ]

=head1 DESCRIPTION

This is the original interface, but the preferred implementation is now L<Data::Remember::Class>. This is now just a functional wrapper around that interface.

See L<Data::Remember::Class> for more documentaiton.

=head1 SUBROUTINES

By using this module you will automatically import (I know, how rude) four subroutines into the calling package: L</remember>, L</remember_these>, L</recall>, L</recall_and_update>, L</forget>, L<forget_when>, and L</brain>.

=head2 import $brain, @options;

Called automagically when you C<use> this package. Do B<NOT> try

  use Data::Remember ();

This will keep import from being called, which will keep you from using any of the nice features of this package. Since it uses deep magic in the import process, attempting to call C<Data::Remember::remember()> and such won't work correctly. 

If you can't import these methods, sorry. Send me a bug report and a patch and I'll consider it.

The C<$brain> argument lets you select a brain plugin to use. The brain plugins available with this distribution currently include:

=over

=item *

L<Data::Remember::Memory>

=item *

L<Data::Remember::DBM>

=item *

L<Data::Remember::YAML>

=item *

L<Data::Remember::Hybrid>

=item *

L<Data::Remember::POE>

=back

You can specify C<$brain> as a short name if it exists under "C<Data::Remember::>". (For example, "C<DBM>" will load "C<Data::Remember::DBM>".) if C<$brain> contains a "C<::>", then it will be treated as a fully qualified name, in case you want to create your own brain. See L</CREATING A BRAIN>.

The C<@options> are whatever options described in the brain's module documentation.

=head2 remember $que, $fact

Remember the given C<$fact> at memory que C<$que>. See L<Data::Remember::Class/QUE> for an in depth discussion of C<$que>. The C<$fact> can be anything your brain can store. This will generally include, at least, scalars, hash references, and array references.

=head2 remember_these $que, $fact

Stores the given C<$fact> at the give C<$que>, but stores it by pushing it onto the back of an array stored at C<$que>. This allows you to remember a list of things at a given C<$que>:

  remember_these stooges => 'Larry';
  remember_these stooges => 'Curly';
  remember_these stooges => 'Moe';

  my $stooges = recall 'stooges'; # returns the array [ qw( Larry Curly Moe ) ]

=head2 recall $que

Recalls a previously stored fact located at the memory location described by C<$que>. See L<Data::Remember::Class/QUE> for an in depth discussion of that argument.

If no fact is found at that que, C<undef> will be returned.

=head2 recall_each $que

Returns an iterator that can be used to iterate over all the facts stored under C<$que>. See L<Data::Remember::Class/QUE> for more information on the que. The way the iterator works will depend on what kind of data C<$que> points to.

=over

=item *

L<Hash.> For hashes, the iterator will work similar to the built-in C<each> operator. It will return each key/value pair found in the hash in no particular order.

=item *

L<Array.> For arrays, the iterator will return each index and value as a pair, in order.

=item *

L<Scalar.> For anything else, it will return a single pair. The first element in the pair will be C<undef> and the second will be the scalar value.

=back

When the iterator is finished it returns an empty list.

The iterator captures the keys and array length at the time it was created. If changes are made to the data stored, it will return the same keys or array indexes that were stored at the moment of the call, but the values returned will be whatever is current stored. If the value at the que is removed entirely, the iterator closes over the original reference and will proceed anyway.

=head2 recall_and_update { ... } $que

This helper allows you to simultaneously recall and update an entry. For example, if you want to increment the entry while recalling it:

  my $count = recall_and_update { $_++ } 'count';

any modification to C<$_> will be stored back into the given que. The result of the code run is returned by the function. For example, if you wanted to replace every "G" with "Q" in the brain, but wanted to use the original unmodified string, you could:

  my $with_g = recall_and_update { my $copy = $_; s/G/Q/g; $copy } 'some_que';

=head2 forget $que

Tells the brain to forget a previously remembered fact stored at C<$que>. See L<Data::Remember::Class/QUE> for an in depth discussion of the argument. If no fact is stored at the given C<$que>, this subroutine does nothing.

=head2 forget_when { ... } $que

Tells the brain to forget a previously remembered fact stored at C<$que>. The behavior of C<forget_when> changes depending on the nature of the fact stored at C<$que>.

If C<$que> is a hash, the code reference given as the first argument will be called for each key/value pair and passed the key in C<$_[0]> and the value in C<$_[1]>. When the code reference returns true, that pair will be forgotten.

If C<$que> is an array, the code reference given as the first argument will be called for each index/value pair and passed the index in C<$_[0]> and the value in C<$_[1]>, the value will be passed in C<$_> as well. If the code reference returns a true value, that value will be forgotten.

For any other type of fact stored in the brain, the code reference will be called with C<$_[0]> set to C<undef> and C<$_[1]> and C<$_> set to the value of the fact. The whole que will be forgotten if the code reference returns true.

=head2 brain

Returns the inner object used to store data. This can be used in case the brain plugin provides additional methods or features that need manual access. For example, if you want to use L<DBM::Deep>s locking features, you could:

  brain->dbm->begin_work;

  my $balance = recall 'balance';
  remember balance => $balance + 150;

  brain->dbm->commit;

=head1 CREATING A BRAIN

If you would like to create a custom brain plugin, you need to create a package that implements four methods: C<new>, C<remember>, C<recall>, and C<forget>.

The C<new> method will take the list of options passed to L</import> for your brain in addition to the class name. It should return a blessed reference that will be used for all further method calls.

The C<remember> method will be passed a normalized reference to a que array and the fact the user has asked to store. You should read through L<Data::Remember::Class/QUE> and handle the first argument as described there. Then, store the second argument at the memory location described.

The C<recall> method will be passed a normalized reference to a que array, which should be treated as described in L<Data::Remember::Class/QUE>. Your implementation should return the fact stored at that location or C<undef>. It's important that your implementation avoid the pit-falls caused by auto-vivifying keys. The C<recall> method should never modify the memory of your brain.

The C<forget> method will be passed a normalized reference to a que array, which should be treated as described in L<Data::Remember::Class/QUE>. Your implementation should then delete any fact stored there. Other than deleting this key, the C<forget> method should not modify any other aspect of the memory of your brain.

To build a brain, I highly recommend extending L<Data::Remember::Memory>, which performs (or should perform) all the work of safely storing and fetching records from a Perl data structure according to the interface described here. It stores everything under C<< $self->{brain} >>. At the very least, you should read through that code before building your brain.

The L<Data::Remember::DBM> or other included brains may also be a good place to look. They extend L<Data::Remember::Memory> so that I didn't have to repeat myself.

=head1 DIAGNOSTICS

This class emits the following warnings:

=over

=item The brain BRAIN may not have loaded correctly: ERROR

This message indicates that an error occurred while loading the package named C<BRAIN>. C<ERROR> contains the nested error message. This is only a warning because it's possible that this failure is normal (e.g., if the package is not defined in it's own Perl module).

=item Undefined que element used in call to SUB.

This message indicates that you attempted to pass an undefined value as a component of the que to the named subroutine. Such calls are ignored by L<Data::Remember>. (Hence the warning.) 

=back

Whenever possible, this library attempts not to throw exceptions. The major exception that rule (HAH!) is during initialization. Any problems detected there are generally very important, so exceptions are thrown liberally.

Here are the exceptions that are emitted by this class:

=over

=item This does not look like a valid brain: BRAIN

The brain plugin name given does not look like a valid Perl class name. L<Data::Remember> won't even check to see if it is a brain plugin unless it could be a package name.

=item Your brain cannot remember facts: BRAIN

You attempted to use a brain class that does not provide a C<remember()> method.

=item Your brain cannot recall facts: BRAIN

You attempted to use a brain class that does not provide a C<recall()> method.

=item Your brain cannot forget facts: BRAIN

You attempted to use a brain class that does not provide a C<forget()> method.

=back

=head1 SEE ALSO

L<Data::Remember::Memory>, L<Data::Remember::DBM>, L<Data::Remember::YAML>, L<Data::Remember::Hybrid>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
