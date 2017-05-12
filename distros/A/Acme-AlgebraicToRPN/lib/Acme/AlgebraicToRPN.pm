package Acme::AlgebraicToRPN;

use warnings;
use strict;

our $VERSION = '0.02';

=head1 NAME

Acme::AlgebraicToRPN - convert algebraic notation to sane RPN

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

  $rpn = Acme::AlgebraicToRPN->new;
  @RPN = $rpn->eval($equation);

=head1 DESCRIPTION

Given a string with algebraic notation, convert to RPN, which is
what any crappy dime store calculator needs to do anyway.

Doesn't really process anything, that's up to you. You will get an
array back with all of the variables and operations in RPN format.
So that 3+4 will come back as

    3
    4
    add

Possible future extensions will be to allow you to actually process
this via hooks that allow specifications of how to handle foreign
functions. But for my purposes, the array is good enough, as I am
passing this on to a C program to do some serious number crunching.

Additionally, you can specify (via the constructor) the names of
your own functions. See below.

=head1 ACKNOWLEDGEMENT

The Hewlett Packard Company and the HP 35, my first real calculator,
and Steffen Mueller for the Math::Symbolic code.

=head1 AUTHOR

X Cramps, C<< <cramps.the at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-algebraictorpn at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-AlgebraicToRPN>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::AlgebraicToRPN

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-AlgebraicToRPN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-AlgebraicToRPN>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-AlgebraicToRPN>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-AlgebraicToRPN>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 X Cramps, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package Acme::AlgebraicToRPN;

use strict;
use warnings;
use Regexp::Common;
use Perl6::Attributes;
use Math::Symbolic;
use Math::SymbolicX::ParserExtensionFactory;

=head2 B<new>

  $al = Acme::AlgebraicToRPN->new(%opts);

%opts (optional) can be:

  userFunc - user functions, as array reference

If you had a user function box and fft, you'd need to
specify them like this:

  $al = Acme::AlgebraicToRPN->new(userFunc =>
    [qw(box fft)]);

=cut

sub new {
    my ($class, %opts) = @_;
    my $self = \%opts;
    bless $self, $class;
    $.stack = [];
    $.parser = Math::Symbolic::Parser->new;
    $.Class = $class;
    if (defined $.userFunc) {
        my @uf = @{$.userFunc};
        my %uf;
        map { $uf{$_} = 1 } @uf;
        $.userFunc = \%uf;
        my %x;
        map {
            my $proc = $_;
            $x{$_} = sub {
                my $argumentstring = shift;
                return Math::Symbolic::Constant->new(
                    qq($proc($argumentstring))
                );
            };
        } @uf;
        Math::SymbolicX::ParserExtensionFactory->add_private_functions(
            $.parser,
            %x
        );
    }
    return $self;
}

=head2 B<rpn>

  @stack = $al->rpn($expr);

Processes $expr (an algebraic format expression) and return the
stack necessary to process it. The stack consists entirely of
variables, constants and operations. For operations, be
prepared to handle (and others, see B<Math::Symbolic> documentation):

  negate
  add
  subtract
  multiply
  divide
  exponentiate
  sin
  cos
  tan
  cot
  asin
  acos
  atan
  atan2
  acot
  sinh
  cosh
  asinh
  acosh

Plus any that you may add in constructor [1].

undef is returned if the parens don't balance. That's all the
checking we do.

  [1] If you supply a custom function, you can supply arguments
      to it. When you see your function name on the returned stack,
      the next thing on the stack is the I<number> of arguments,
      and then the arguments themselves. For example, let's say
      you registered your function 'foo' (in constructor)
      and you gave B<rpn> this equation: 4*foo(a,3)

      You'd get back this:
      4 a 3 2 foo multiply

=cut

sub rpn {
    my ($self, $algebraic) = @_;
    $algebraic =~ s/\s+//g;
    # ensure parens match
    my $open  = $algebraic =~ tr/(/(/;
    my $close = $algebraic =~ tr/)/)/;
    return unless $open == $close;
    #my $tree = Math::Symbolic->parse_from_string($algebraic);
    my $tree;
    my $rpn;

    eval q(
        $tree = $.parser->parse($algebraic);
        $rpn  = $tree->to_string('prefix');
    );

    if ($@) {
        print STDERR "$.Class - equation didn't parse; did you forget ",
            "to add a userFunc?\n";
        return undef;
    }

    $rpn =~ s/\s//g;
    ./_Eval($rpn);
    my @result = ./_Cleanup();
    # reset, ready for next equation
    $.stack = [];
    return @result;
}

=head2 B<rpn_as_string>

  $stack = $al->rpn($expr);

Same as B<rpn>, but returns as a comma-separated list. Split on
commas, and you have your stack to be processed.

=cut

sub rpn_as_string {
    my ($self, $algebraic) = @_;
    my @result = ./rpn($algebraic);
    return join(",", @result);
}

sub _Cleanup {
    my ($self) = @_;
    my @Stack;
    map {
        $_ =~ s/^,//;
        if ($_ ne '') {
            my (@c) = split(',', $_);
            if (@c) {
                s/\s//g foreach @c;
                push(@Stack, @c);
            }
            else {
                push(@Stack, $_);
            }
        }
    } @{$.stack};
    return @Stack;
}

sub _Eval {
    my ($self, $expr) = @_;
    return unless defined $expr;
    #print "Evaling $expr\n";
    if ($expr =~ /(.+?),(.+)/) {
        my $L = $1;
        my $R = $2;
        if ($L =~ /^\w+$/ && $R =~ /$RE{balanced}{-parens=>'()'}/) {
            #print "HERE $L\n";
            push(@{$.stack}, $L);
        }
    }

    if ($expr =~ /(\w+)($RE{balanced}{-parens=>'()'})(.*)/) {
        my $op = $1;
        my $p  = $2;
        my $r  = $3;
        my $core = substr($p, 1, length($p)-2);
        if (defined $.userFunc && defined $.userFunc{$op}) {
            # count # of commas in arg list
            my $na = $core =~ tr/,/,/;
            # bump by one
            $na++;
            # add # of aguments on
            $core = qq($core,$na);
        }
        ./_Eval($core);
        push(@{$.stack}, $core) 
            unless $core =~ /$RE{balanced}{-parens=>'()'}/;
        push(@{$.stack}, $op);
        ./_Eval($r) 
            if defined $r && $r =~ /$RE{balanced}{-parens=>'()'}/;
        push(@{$.stack}, $r) 
            if defined $r && !($r =~ /$RE{balanced}{-parens=>'()'}/);
    }
}

=head2 B<check>

  $ok = $al->check(\@stack, @expected);

Checks result of RPN conversion. @stack is what the B<rpn> function
returned, and @expected is what you expected the result to be. This
is kind of a diagnostic routine for testing.

Returns 1 if both @stack and @expected were the same, 0 if not.

=cut

sub check {
    my ($self, $ref, @result) = @_;
    my @shouldbe = @$ref;
    return 0 unless @shouldbe == @result;
    my $same = 1;
    map {
        my $sb = shift(@shouldbe);
        $same = 0 unless $sb eq $_;
    } @result;
    return $same;
}

1; # End of Acme::AlgebraicToRPN
