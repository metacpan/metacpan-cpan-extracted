package Call::Context;

=encoding utf-8

=head1 NAME

Call::Context - Sanity-check calling context

=head1 SYNOPSIS

    use Call::Context;

    sub gives_a_list {

        #Will die() if the context is not list.
        Call::Context::must_be_list();

        return (1, 2, 3);
    }

    gives_a_list();             # die()s: incorrect context (void)

    my $v = gives_a_list();     # die()s: incorrect context (scalar)

    my @list = gives_a_list();  # lives

    #----------------------------------------------------------------------

    sub scalar_is_bad {

        #Will die() if the context is not list.
        Call::Context::must_not_be_scalar();

        return (1, 2, 3);
    }

    scalar_is_bad();            # lives

    my $v = scalar_is_bad();    # die()s: incorrect context (scalar)

    my @list = scalar_is_bad(); # lives

=head1 DISCUSSION

If your function only expects to return a list, then a call in some other
context is, by definition, an error. The problem is that, depending on how
the function is written, it may actually do something expected in testing, but
then in production act differently.

=head1 FUNCTIONS

=head2 must_be_list()

C<die()>s if the calling function is itself called outside list context.
(See the SYNOPSIS for examples.)

=head2 must_not_be_scalar()

C<die()>s if the calling function is itself called in scalar context.
(See the SYNOPSIS for examples.)

=head1 EXCEPTIONS

This module throws instances of C<Call::Context::X>. C<Call::Context::X> is
overloaded to stringify; however, to keep memory usage low, C<overload> is not
loaded until instantiation.

=head1 REPOSITORY

https://github.com/FGasper/p5-Call-Context

=cut

use strict;
use warnings;

our $VERSION = '0.03';

my $_OVERLOADED_X;

sub must_be_list {
    return _must_be_list(0);
}

sub must_not_be_scalar {
    return if !defined( (caller 1)[5] );
    return _must_be_list(1);
}

sub _must_be_list {
    return if (caller 2)[5];    #wantarray

    $_OVERLOADED_X ||= eval q{
        package Call::Context::X;
        use overload ( q<""> => \\&_spew );
        1;
    };

    die Call::Context::X->_new($_[0]);
}

#----------------------------------------------------------------------

package Call::Context::X;

#Not to be instantiated except from Call::Context!

sub _new {
    my ($class, $accept_void_yn) = @_;

    my ($sub, $ctx) = (caller 3)[3, 5];
    my (undef, $cfilename, $cline, $csub) = caller 4;

    if ($accept_void_yn) {
        return bless \"$sub called in scalar context from $csub (line $cline of $cfilename)", $class;
    }

    $ctx = defined($ctx) ? 'scalar' : 'void';

    return bless \"$sub called in non-list ($ctx) context from $csub (line $cline of $cfilename)", $class;
}

sub _spew { ${ $_[0] } }

1;
