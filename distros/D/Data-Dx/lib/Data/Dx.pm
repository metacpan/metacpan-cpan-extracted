package Data::Dx;

=encoding utf8

=cut

use 5.012;
use utf8;
use warnings;

our $VERSION = '0.000011';

use Keyword::Declare;

my %COLOUR = (
    key     => 'bold ansi136',  # Soft orange
    value   => 'cyan',
    punct   => 'bold ansi245',  # Mid-grey
    comment => 'blue',
);

my @OUTPUT;
BEGIN { @OUTPUT = \*STDERR }

sub _dx {
    my ($expr) = @_;
    use List::Util 'max';

    # Flatten the expression to a single line...
    $expr =~ s{\s+}{ }g;

    # Simple arrays and hashes need to be dumped by reference...
    my $ref = $expr =~ /^[\@%][\w:]++$/ ? q{\\} : q{};

    # How much to indent...
    my $indent = ' ' x (length($expr) + 3);

    # Handle unbalanced {...} in the expression...
    my $str_expr = $expr;
       $str_expr =~ s{ ( [\\\{\}] ) }{\\$1}xmsg;

    # Generate the source...
    return qq{Data::Dx::_format_data(__LINE__, __FILE__, q{$str_expr}, q{$indent}, $ref $expr);};
}


sub import {
    my (undef, $opt_ref) = @_;
    my %opt = ( colour => -t *STDERR, %{$opt_ref//{}} );

    # Lexical colour control...
    $^H{'Data::Dx no_colour'} = 1
        if !$opt{colour};

    # Lexical output redirect...
    if ($opt{to}) {
        $^H{'Data::Dx output'} = @OUTPUT;
        push @OUTPUT, $opt{to};
    }

    keyword Dx (Expr $expr) { _dx($expr) }
    keyword Dₓ (Expr $expr) { _dx($expr) }

    utf8->import();
}

sub unimport {
    keyword Dx (Expr $expr) { }
    keyword Dₓ (Expr $expr) { }
}

sub _color {
    state $colorer = eval {
            require Win32::Console::ANSI if $^O eq 'MSWin32';
            require Term::ANSIColor;
            sub { return shift if ((caller 1)[10]//{})->{'Data::Dx no_colour'}
                               || ((caller 2)[10]//{})->{'Data::Dx no_colour'};
                 goto &Term::ANSIColor::colored;
            }
    } // sub { shift };
    $colorer->(@_);
}

sub _format_data {
    # Unpack leadings args...
    my $linenum  = shift;
    my $filename = shift;
    my $expr     = shift;
    my $indent   = shift;

    # Serialize any Contextual::Return::Value objects (which break dump())...
    for my $arg (@_) {
        if ((ref($arg)||q{}) =~ m{\A Contextual::Return}xms) {
            require Contextual::Return;
            Contextual::Return::FREEZE($arg);
        }
    }

    # Then repack data...
    my $data     = @_ > 1 ? [@_] : shift;

    # Lexical configurations...
    my $hint = ((caller 0)[10] // {});

    # Dump the data...
    my $dump;
    if (!defined $data) {
        $dump = _color('undef', $COLOUR{value});
    }
    else {
        use Data::Dump 'dump';
        $dump = dump($data);

        if (!$hint->{'Data::Dx no_colour'}) {
            my $bw_dump = $dump;
            $dump = q{};
            $bw_dump
                =~ s{ $PPR::GRAMMAR
                      (?: (?<key>     (?: (?&PerlString) | (?&PerlBareword) )   (?= \s*+ => ) )
                      |   (?<literal> (?&PerlLiteral) | sub \s*+ { \s*+ ... \s*+ } )
                      |   (?<punct>   \S                                           )
                      |   (?<space>   .                                            )
                      )
                     }{
                        $dump .= exists $+{key}     ? _color( "$+{key}",     $COLOUR{key}   )
                               : exists $+{punct}   ? _color( "$+{punct}",   $COLOUR{punct} )
                               : exists $+{literal} ? _color( "$+{literal}", $COLOUR{value} )
                               :                              "$+{space}";
                        "";
                     }gxmseo;
        }

        $dump =~ s{ (?! \A ) ^ }{$indent}gxms;
    }

    my $output = $OUTPUT[$hint->{'Data::Dx output'} // 0];

    print {$output}
        _color("#line $linenum  $filename\n", $COLOUR{comment}),
        _color($expr,                         $COLOUR{key}),
        _color(' = ',                         $COLOUR{punct}),
              "$dump\n\n";
}




1; # Magic true value required at end of module
__END__

=head1 NAME

Data::Dx - Dump data structures with name and point-of-origin


=head1 VERSION

This document describes Data::Dx version 0.000011


=head1 SYNOPSIS

    use Data::Dx;

    Dx %foo;
    Dx @bar;
    Dx (
        @bar,
        $baz,
    );
    Dx $baz;
    Dx $ref;

    Dₓ @bar[do{1..2;}];
    Dₓ 2*3;
    Dₓ 'a+b';
    Dₓ 100 * sqrt length $baz;
    Dₓ $foo{q[;{{{]};


=head1 DESCRIPTION

This module provides a simple wrapper around the Data::Dump module.

The C<Dx> keyword (and its more-medically-correct alias: C<Dₓ>)
data-dumps its arguments, prefaced by a comment line
that reports the location from which C<Dx> was invoked.

For example, the code in the L<SYNOPSIS> would produce
something like:

    #line 19  demo.pl
    %foo = {
             "foo"    => 1,
             "food"   => 2,
             "fool"   => [1 .. 10],
           }

    #line 20  demo.pl
    @bar = ["b", "a", "r"]


    #line 21  demo.pl
    ( @bar, $baz, ) = ["b", "a", "r", "baz"]


    #line 25  demo.pl
    $baz = "baz"


    #line 26  demo.pl
    $ref = ["b", "a", "r"]


    #line 27  demo.pl
    @bar[do{1..2;}] = ["a", "r"]


    #line 28  demo.pl
    2*3 = 6


    #line 29  demo.pl
    'a+b' = "a+b"


    #line 30  demo.pl
    100 * sqrt length $baz = 173.205080756888


    #line 31  demo.pl
    $foo{q[;{{{]} = undef


If the Term::ANSIColor module is available, the output
will also be colour-coded (unless the C<'colour'> option
is specified as false...see below).


=head1 INTERFACE

=over

=item C<Dx I<expr>>

=item C<Dₓ I<expr>>

These are the only keywords provided by the module.
They are always exported.

C<Dx>/C<Dₓ> can be called with any number of arguments and data-dumps them all.
C<Dx> and C<Dₓ> are keywords, not functions, so they cannot be used as part of
a larger expression, and they do not return a useful value.

Note that, to support the non-ASCII C<Dₓ> variant of the keyword,
loading the module also implicitly sets the C<use utf8> pragma.
If you don't want those semantics, you can explicitly turn them off
like so:

    use Data::Dx;
    no utf8;

If you disable Unicode semantics in this way, any subsequent use of
the C<Dₓ> variant of the keyword will probably raise a warning.


=item C<no Data::Dx;>

If the module is imported with C<no> instead of C<use>,
it still exports the C<Dx> and C<Dₓ> keywords, but as no-ops.

This means that you can leave every C<Dx> and C<Dₓ> in your code
but disable them all (or just all of them in a given scope)
by changing the original C<use Data::Dx> to C<no Data::Dx>

=item C<< use Data::Dx { colour => 0 }; >>

If the module is imported with the C<'colour'> option set false,
output is dumped without colouring, even if Term::ANSIColor is
available.

The option defaults to true if C<STDERR> is directed to a terminal,
and to false otherwise.

If you want coloured output even when C<STDERR> isn't directed to a terminal,
specify it explicitly like this:

    use Data::Dx { colour => 1 };

=back


=head1 DIAGNOSTICS

None, apart from those provided by Data::Dump;


=head1 CONFIGURATION AND ENVIRONMENT

Data::Dx requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires the Data::Dump and Keyword::Declare modules.

If you want syntax colouring on the dumps, also requires the
Term::ANSIColor module (plus Win32::Console::ANSI under Windows)

Only works under Perl 5.12 and later (the release in
which pluggable keywords were added to Perl).

Does not work under Perl 5.20 (due to problems with regex compilation
exposed by the Keyword::Declare module under that release).


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-dx@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010-2017, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


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
