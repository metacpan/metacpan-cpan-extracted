package Binding;

use warnings;
use strict;
use PadWalker qw(peek_my peek_our peek_sub closed_over);
use Devel::Caller qw(caller_cv);
use Data::Dump qw(pp);

use 5.008;

our $VERSION = '0.06';

sub of_caller {
    my ($class, $level) = @_;
    $level = 1 unless defined($level);

    my $self = {
        'caller_cv' => ( caller_cv( $level + 1) || undef ),
        'level'  => $level + 1,
    };
    return bless $self, $class;

}

sub eval {
    my ($self, $code_str) = @_;

    my $vars = peek_my( $self->{level} );

    my $var_declare = "";
    for my $varname (keys %$vars) {
        $var_declare .= "my $varname = " . pp(${$vars->{$varname}}) . ";";
    }
    my $code = "$var_declare; $code_str";
    eval $code;
}

sub var {
    my ($self, $varname) = @_;

    for (my $level = $self->{level}; $level < 100; $level++) {
        my $vars = peek_my($level);
        if (exists $vars->{$varname}) {
            my $varref = $vars->{$varname};
            if (ref($varref) eq 'SCALAR' || ref($varref) eq 'REF') {
                return $$varref;
            }
            elsif (ref($varref) eq 'ARRAY') {
                return @$varref;
            }
            elsif (ref($varref) eq 'HASH') {
                return %$varref;
            }
        }
    }

    die "Unknown var: $varname";
}

sub my_vars {
    my ($self) = @_;
    my $vars = peek_my($self->{level});
    return $vars;
}

sub our_vars {
    my ($self) = @_;
    my $vars = peek_our($self->{level});
    return $vars;
}


1;
__END__

=head1 NAME

Binding - eval with variable binding of caller stacks.

=head1 VERSION

This document describes Binding version 0.01

=head1 SYNOPSIS

    use Binding;

    sub inc_x {
        my $b = Binding->of_caller;
        $b->eval('$x + 1');
    }

    sub fortytwo {
        my $x = 41;
        inc_x;
    }

    sub two {
        my $x = 1;
        inc_x;
    }

    # You probably get the idea now...

=head1 DESCRIPTION

This module can help when you need to eval code with caller's variable
binding. It's similar to Tcl's uplevel function. The name comes from
the Binding class of Ruby language.

It's not doing much yet but let you grab caller variables.

=head1 INTERFACE

=over

=item of_caller([ $level ])

One of the constructors. The C<$level> parameter is optional and
defaults to 1, which means one level up in the stack. The returned
value is a object of C<Binding> class, which can latter be invoked
with C<eval> method.

=item eval( $code_str )

An instance method that evals code in C<$code_str>. Block form of eval
is not accepted. Variables used in $code_str will be referenced to the
one lives the given caller frame.

    # calculate $x + 5
    sub x_add_five {
        # notice the single quotes here.
        Binding->of_caller->eval('$x + 5');
    }

    {
        my $x = 3;
        my $y = add_five;
    }

=item var( $name )

Return the value of the variable named $name in the specified scope.

=item my_vars

Returns all variables declared with "my" in the given binding.

Returns a hashref, which keys are variable names and values are
references to variable values.

See C<peek_my> function in L<PadWalker>.

=item our_vars

Returns all variables declared with "our" that's visible in the given
binding.

Returns a hashref, which keys are variable names and values are
references to variable values.

See C<peek_our> function in L<PadWalker>.

=back

=head1 DEPENDENCIES

L<PadWalker>, L<Data::Dump>, L<Devel::Caller>


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-binding@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

The returned object of C<< Binding->of_caller >> need to be used
immediately, or at least in the same frame of its construction, which means
that this doesn't do what it means yet:

    sub add {
        my $x = 5;
        my $b = Binding->of_caller;

        # Expect the binding '$x' is to the one in caller of add()
        add_x($b);
    }

    sub add_x {
        my $binding = shift;

        # But this $x is referring to the one in add()
        $binding->eval('$x + 1')
    }

    my $x = 3;
    add; # returns 6 instead of 4;

=head1 SEE ALSO

The standard Binding class in Ruby core: L<http://www.ruby-doc.org/core/classes/Binding.html>,
and the extended Binding class L<http://extensions.rubyforge.org/rdoc/classes/Binding.html>.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
