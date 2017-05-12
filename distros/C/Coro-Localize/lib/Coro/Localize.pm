# ABSTRACT: Localize variables to a coroutine
package Coro::Localize;
{
  $Coro::Localize::VERSION = '0.1.2';
}
use common::sense;
use Devel::Declare;
use Data::Alias ();

sub import {
    my $class = shift;
    $class->import_into( scalar caller );
}

my $stub = sub {};
sub import_into {
    my $class = shift;
    my( $target ) = @_;
    Devel::Declare->setup_for( $target => { corolocal => {const => \&parser} } );
    *{$target.'::corolocal'} = $stub;
}

our $prefix = '';
sub get {substr Devel::Declare::get_linestr, length $prefix}
sub set {       Devel::Declare::set_linestr $prefix . $_[0]}

# croak that ignores Devel::Declare and our own package when determining the
# line to blame.
# Rewritten from a version in Begin::Declare
sub croak {
    my($msg, $src) = @_;

    s/\s+/  /g for $msg, $src;
    
    my $yada='';
    if ($src =~ s/^(.{20}).*/$1/) {
        $yada = '...';
    }

    my $thispackage = __PACKAGE__;

    my($ii, $package, $file, $line);
    do {
        ($package,$file,$line) = (caller ++$ii)[1,2];
    }
    while ($package =~/^Devel::Declare|^$thispackage/);
    
    die "$thispackage: $msg '$src'$yada at $file line $line.\n"
}

sub parser {
    local $prefix = substr get, 0, $_[1];
    my $keyword = strip_keyword();
    my @vars = strip_vars();
    my $var_names = 'qw(' . join( ' ', @vars ). ')';
    my $var_vars  = '(' . join( ',', @vars) . ')';
    my $assign = strip_assign();
    my $code = "";

    $code .=     q[use Data::Alias;];
    $code .=     q{my(%external_values,%internal_values);};

    # Initialize the thread local values to undef
    $code .=     q[@internal_values{qw(].join(" ",@vars).q[)} = ();];
    
    # Do initial binding of old values to external and new to thread local
    foreach (@vars) {
        my $sigil = substr($_,0,1);
        if ( $sigil eq '$' ) {
            $code .= q[alias $external_values{'].$_.q['} = ].$_.q[;];
        }
        else {
            $code .= q[alias $external_values{'].$_.q['} = \\].$_.q[;];
        }
    }

    # Setup the on-enter handler
    $code .=     q[Coro::on_enter {];
    foreach (@vars) {
        my $sigil = substr($_,0,1);
        if ( $sigil eq '$' ) {
            $code .= q[alias ].$_.q[ = ].q[$internal_values{'].$_.q['};];
        }
        else {
            $code .= q[alias ].$_.q[ = ].$sigil.q[{ $internal_values{'].$_.q['} };];
        }
    }
    $code .=     q[};];

    # Setup the on-leave handler
    $code .=     q[Coro::on_leave {];
    foreach (@vars) {
        my $sigil = substr($_,0,1);
        if ( $sigil eq '$' ) {
            $code .= q[alias ].$_.q[ = ].q[$external_values{'].$_.q['};];
        }
        else {
            $code .= q[alias ].$_.q[ = ].$sigil.q[{ $external_values{'].$_.q['} };];
        }
    }
    $code .=     q[};];
    
    if ( $assign ) {
        $code .= $var_vars . " $assign";
    }

    set ";" . $code . get;
}

sub strip_space {
    my $skip = Devel::Declare::toke_skipspace length $prefix;
    set substr get, $skip;
}

sub strip_keyword {
    strip_space;
    get =~ /^(corolocal)(?:\b|$)/ or croak "Could not match corolocal", get;
    $prefix .= $1;
    return $1;
}

sub strip_comma {
    if ( get =~ /^,/) {
        $prefix .= ' ';
        return 1;
    }
    else {
        return 0;
    }
}

sub strip_var {
    strip_space;
    (my $line = get) =~ s/^([\$\%\@])//
        or croak "not a valid sigil", get =~ /(.)/;
    my $sigil = $1;
    set $line;
    strip_space;
    ($line = get) =~ s/^(\w+|^[\S])//
        or croak "not a lexical variable name", $sigil.$line;
    set $line;
    $sigil . $1;
}

sub strip_open_paren {
    if (get =~ /^\(/) {
        $prefix .= ' ';
        return 1;
    }
    else {
        return 0;
    }
}
sub strip_close_paren {
    strip_space;
    if (get =~ /^\)/) {
        $prefix .= ' ';
        return 1;
    }
    else {
        croak "expected a close paren ')' not", get;
    }
}

sub strip_vars {
    strip_space;
    my @vars;
    if ( strip_open_paren ) {
        do {
            push @vars, strip_var;
        } while (strip_comma);
        strip_close_paren;
    }
    else {
        push @vars, strip_var;
        if ( strip_comma ) {
            croak "unexpected comma in variable declaration, maybe you meant to wrap these in parens? ", ",".get;
        }
    }
    return @vars;
}
 
 
sub strip_assign {
    strip_space;
    my $rest = get;
    if ($rest =~ /^;/) {
        $prefix .= ' ';
        strip_space;
        return '';
    }
    elsif ($rest =~ /^=[^=]/) {
        $prefix .= ' ' x length($rest);
        return $rest;
    }
    else {
        return '';
    }
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Coro::Localize - Localize variables to a coroutine

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

    use feature qw( say );
    use Coro;
    use Coro::EV;
    use Coro::Localize;
    # Or with Syntax::Feature:
    # use syntax qw( corolocal );
     
    our $scalar = "main loop";
     
    async {
        corolocal $scalar = "thread 1";
        say "# 1 - $scalar";
        cede;
        say "# 3 - $scalar";
        cede;
        say "# 5 - $scalar";
    };
     
    async {
        corolocal $scalar = "thread 2";
        say "# 2 - $scalar";
        cede;
        say "# 4 - $scalar";
        cede;
        say "# 6 - $scalar";
    };

    say "# starting $scalar";
    EV::loop;
    say "# complete $scalar";

# Will print:

    # starting main loop
    # 1 - thread 1
    # 2 - thread 2
    # 3 - thread 1
    # 4 - thread 2
    # 5 - thread 1
    # 6 - thread 2
    # complete main loop

=head1 DESCRIPTION

This provides a new keyword, "corolocal" that works will localize a variable
to a particular coroutine.  This allows you to have thread-local values for
global variables.  It can localize scalars, arrays and hashes.

=head1 IMPLEMENTATION

It localizes variables by Coro on_enter and on_leave blocks combined with
Data::Alias to fiddle with where the variable points.

    corolocal $/ = \2_048;

Is exactly equivalent to:

    use Data::Alias;
    my(%external_values,%internal_values);
    @internal_values{qw($/)} = ();
    alias $external_values{'$/'} = $/;
    Coro::on_enter {
        alias $/ = $internal_values{'$/'};
    };
    Coro::on_leave {
        alias $/ = $external_values{'$/'};
    };
    $/ = \2_048;

And note that on_enter is executed as soon as your declare it.

As with most recent new syntax, this is implemented with L<Devel::Declare>.

=head1 CAVEATS

Due to limitations in Data::Alias, localizing lexically scoped variables
does not work.  Only globals (package or otherwise) can be localized.  This
doesn't seem like too much of a limitation, however, as you're unlikely to
find utility in localizing a lexical.

Unfortunately, at this time, it can't detect this and will just silently be
useless.  In the future it may emit a warning or worse.

=head1 INSPIRATION

L<Coro::LocalScalar> The same sort of idea, but implemented via tied magic
and/or LVALUE scalars.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Syntax::Feature::Corolocal|Syntax::Feature::Corolocal>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/iarna/Coro-Localize>
and may be cloned from L<git://https://github.com/iarna/Coro-Localize.git>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Coro-Localize>

=back

=head2 Bugs / Feature Requests

Please report any bugs at L<https://github.com/iarna/Coro-Localize/issues>.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/iarna/Coro-Localize>

  git clone https://github.com/iarna/Coro-Localize.git

=head1 AUTHOR

Rebecca Turner <becca@referencethis.com>

=head1 ACKNOWLEDGEMENTS

Inspiration for this module came from seeing L<Coro::LocalScalar>.  The
initial shape of the guts of the module came from L<Begin::Declare>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Rebecca Turner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

