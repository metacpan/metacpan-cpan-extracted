package Acme::constant;
{
  $Acme::constant::VERSION = '0.1.3';
}
use 5.014;
use strictures 1;
use Carp ();

sub generate_constant {
    my ($package, $name, @values) = @_;
    # Prototype is used to make it work like a constant (constants
    # shouldn't take arguments). While anonymous subroutines don't use
    # prototypes, the prototype gets meaning when this subroutine is
    # assigned to type glob.
    my $constant = sub () : lvalue {
        # When constant used as array, it's very simple to understand
        # user wants an array. The !defined wantarray check is intended
        # to detect use of wantarray() in void context.
        if (wantarray || !defined wantarray) {
            @values;
        }
        # When constant has one element, writing to it in scalar
        # context is fine.
        elsif (@values == 1) {
            $values[0];
        }
        # This shows an error, as otherwise, this could cause a strange
        # situation where scalar A shows (A)[0], when A has one
        # element, and 2 when A has two elements. The behavior of Array
        # constructor in ECMAScript is already confusing enough (new
        # Array(3) is [,,,], but new Array(3, 3) is [3, 3]).
        else {
            Carp::croak "Can't call ${package}::$name in scalar context";

            # Return lvalue in order to make older versions of Perl
            # happy, even when it's not going to be used.
            @values;
        }
    };
    # Make a block, to make a scope for strict "refs".
    {
        # Because of symbol table modifications, I have to allow
        # symbolic references.
        no strict qw(refs);
        *{"${package}::$name"} = $constant;
    }
}

sub import {
    my $package = caller;

    # The first argument is this package name
    my $name = shift;

    # Without arguments, simply fail.
    if (@_ == 0) {
        Carp::carp qq[Useless use of "$name" pragma];
    }

    # When called with one argument, this argument would be hash
    # reference.
    elsif (@_ == 1) {
        my %hash = %{shift()};
        # each is safe here, as %hash is lexical variable.
        while (my ($name, $value) = each %hash) {
            generate_constant $package, $name, $value;
        }
    }

    # Otherwise, assume one constant, that possibly could return a list
    # of values.
    else {
        my $name = shift;
        generate_constant $package, $name, @_;
    }
    return;
}

# Return positive value to make Perl happy.
'Acme!';

__END__

=head1 NAME

Acme::constant - Like constant, except actually not.

=head1 SYNOPSIS

    use Acme::constant ACME => 42;
    print "ACME is now ", ACME, ".\n";
    ACME = 84;
    print "But now, ACME is ", ACME, "\n";

    use Acme::constant LIST => 1, 2, 3;
    print "Second element of list is ", (LIST)[1], ".\n";
    (LIST) = (4, 5, 6);
    print "But now, the second element is ", (LIST)[1], "\n";

=head1 DESCRIPTION

This pragma lets you make inconstant constants, just like the constants
the users of Ruby or Opera (before Opera 14, that is) already enjoyed.

Unlike Perl constants, that are replaced at compile time, Acme
constants, in true dynamic programming language style, can be modified
even after declaration.

Just like constants generated with standard C<use constant> pragma, the
constants declared with C<use Acme::Constant> don't have any sigils.
This makes using constants easier, as you don't have to remember what
sigil do constants use.

=head1 NOTES

As the Perl compiler needs to know about which barewords are keywords,
constants have to defined in C<BEGIN> section. Usually, this is not a
problem, as C<use> statement is automatically put in implicit C<BEGIN>
section, but that also means you cannot dynamically create constants.
For example, in the example below, the C<DEBUG> constant is always
created, with value 1, as C<use> is processed when Perl parser sees
it.

    if ($ENV{DEBUG}) {
        use Acme::constant DEBUG => 1; # WRONG!
    }

It's possible to dynamically use this module using L<if> module,
however, this is likely to cause problems when trying to use constant
that doesn't exist.

    use if $ENV{DEBUG}, Acme::constant => DEBUG => 1;

You can also use directly use C<import> method, in order to
conditionally load constant.

    BEGIN {
        require Acme::constant;
        Acme::constant->import(DEBUG => 1) if $ENV{DEBUG};
    }

Howver, usually the good idea to declare constant anyway, as using
undefined constants in strict mode causes Perl errors (and sometimes
could be parsed incorrectly).

    use Acme::constant DEBUG => $ENV{DEBUG};

Constants belong to the package they were defined in. When you declare
constant in some module, the constant is subroutine declared in it.
However, it's possible to export constants with module such as
L<Exporter>, just as you would export standard subroutine.

    package Some::Package;
    use Acme::constant MAGIC => "Hello, world!\n";

    package Some::Other::Package;
    print Some::Package::MAGIC; # MAGIC directly won't work.

=head2 List constants

Just like standard L<constant> module, you can use lists with this
module. However, there are few catches you should be aware of.

To begin with, you cannot use list constants in scalar context. While
L<constant> module lets you do this, I believe allowing something like
this can open can of worms, because constant with one element is just
as valid constant (that wouldn't return 1). Something like this won't
work.

    use Acme::constant NUMBERS => 1..6;
    print 'Found ', scalar NUMBERS, " numbers in NUMBERS.\n"; # WRONG!

Instead, to count number of elements in the constant, you can use the
C<() => trick, that lets you count elements in any sort of list.

    use Acme::constant NUMBERS => 1..6;
    print 'Found ', scalar(() = NUMBERS), " numbers in NUMBERS.\n";

Also, as C<use> statement arguments are always parsed in the list
context, sometimes you could be surprised with argument being executed
in list context, instead of scalar context.

    use Acme::constant TIMESTAMP => localtime; # WRONG!

Usually, when this happens, it's possible to use C<scalar> operator in
order to force interpretation of code in scalar context.

    use Acme::constant TIMESTAMP => scalar localtime;

Constants return lists, not arrays (you don't use C<@> syntax, do
you?), so in order to get single element, you will need to put a
constant in parenthesis.

    use Acme::constant NUMBERS => 1..6;
    print join(" ", (NUMBERS)[2..4]), "\n";

=head2 Assignments

The assignments are done using standard C<=> operator.

    use Acme::constant SOMETHING => 1;
    SOMETHING = 2;
    print "Something is ", SOMETHING, ".\n";

    use Acme::constant ARRAY => 1, 2, 3;
    my $four = 7;
    ($four, ARRAY) = (4, 5, 6);
    print "Something is ", join(", ", ARRAY), ", and four is $four.\n";

There are also catches about assignments. Perl normally runs the part
after C<=> operator in scalar context, unless leftside argument is
a list or array. As inconstant constant is neither a list or array,
the argument on right side is ran in scalar context. For example,
following code will only save 2, as comma operator is ran in scalar
context.

    use Acme::constant SOMETHING => 0;
    SOMETHING = (1, 2); # WRONG!
    print "Something is ", join(", ", SOMETHING), ".\n";

In order to force list interpretation, you need to put constant in
the parenthesis.

    use Acme::constant SOMETHING => 0;
    (SOMETHING) = (1, 2);
    print "Something is ", join(", ", SOMETHING), ".\n";

Similarly, you cannot modify list constant in scalar context, as Perl
expects you put a list, not a single value.

    use Acme::constant SOMETHING => (1, 2);
    SOMETHING = 3; # WRONG!
    print "Something is ", SOMETHING, ".\n";

To fix that, you need to put constant in parenthesis. This is only
needed when constant has different number of elements than one, so
after such assignment, you can use normal assignment, without
parenthesis.

    use Acme::constant SOMETHING => (1, 2);
    (SOMETHING) = 3;
    print "Something is ", SOMETHING, ".\n";
    SOMETHING = 4;
    print "Something is now ", SOMETHING, ".\n";

Also, the localization of Acme constants is broken, and while it will
change the value, it won't change value back after leaving the block.
This is related to that you cannot localize lexicals and references in
Perl 5.

    use Acme::constant PI => 4 * atan2 1, 1;
    {
        local PI = 3;
        print "PI = ", PI, "\n";
    }
    print "PI = ", PI, "\n";

=head1 CAVEATS

Other than caveats mentioned here, general caveats about constants
also exist. Unlike standard L<constants> module, constants with names
like C<STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG> can be used
outside C<main::> package, because of different method of generating
constants.

The constants can be problematic to use in context that automatically
stringifies the barewords. For example, the following code is wrong.

    use Acme::constant KEY => "acme";
    my %hash;
    $hash{KEY} = 42; # Works like $hash{"KEY"} = 42;

Instead, you should use following code.

    use Acme::constant KEY => "acme";
    my %hash;
    $hash{(KEY)} = 42;

=head1 DIAGNOSTICS

=over 4

=item Can't call %s in scalar context

(F) You tried to call constant containing constant containing different
numbers than one in scalar context. As it's hard to determine what you
mean, you have to disambiguate your call. If you want to get count of
elements, you may want to assign it to C<()>, like C<() = CONSTANT>. If
you want to get last element, use C<(CONSTANT)[-1]>.

=item Can't modify non-lvalue subroutine call

(F) You tried to assign single value to constant containing an array.
This won't work, as Perl expects a list to be assigned. If you really
want to assign an single element, use C<(CONSTANT) = $value> syntax.

This error is provided by Perl, and as such, it could be confusing,
as constant actually is lvalue, just assigned in wrong context.

=item Useless localization of subroutine entry

(W syntax) You tried to localize constant with C<local> operator. This
is legal, but currently has no effect. This may change in some future
version of Perl, but in the meantime such code is discouraged.

=item Useless use of "Acme::constant" pragma

(W) You did C<use Acme::constant;> without any arguments. This isn't
very useful. If this is what you mean, write C<use Acme::constant ();>
instead.

=back

=head1 SEE ALSO

L<constant> - Builtin constant module.

L<Readonly> - Constant scalars, arrays, and hashes.

=head1 BUGS

Please L<use GitHub|https://github.com/GlitchMr/Acme-constant/issues>
to report bugs.

=head1 SOURCE

The source code for Acme::constant is available can be found
L<https://github.com/GlitchMr/Acme-constant/>.

=head1 COPYRIGHT

Copyright 2013 by Konrad Borowski <glitchmr@myopera.com>.
