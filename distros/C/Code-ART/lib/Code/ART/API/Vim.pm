package Code::ART::API::Vim;

use 5.016;
use warnings;
use Scalar::Util qw< looks_like_number >;
use List::Util   qw< min max >;

our $VERSION = '0.000001';

# We'll need the core functionality...
use Code::ART ();

# Load the module...
sub import {
    # Export the API...
    no strict 'refs';
    *{caller().'::refactor_to_sub'} = \&refactor_to_sub;
    *{caller().'::classify_var_at'} = \&classify_var_at;
    *{caller().'::find_expr_scope'} = \&find_expr_scope;
    *{caller().'::analyze_code'}    = \&analyze_code;
}

sub refactor_to_sub {
    # Unpack any options...
    my $opt_ref = shift // {};

    # Grab the source code, which will be sent through the input filestream...
    my $source = do{ local $/; readline(*ARGV) };

    # Ask Code::ART to do the actual refactoring...
    my $refactoring = Code::ART::refactor_to_sub($source, $opt_ref);

#    if ($refactoring->{failed}) {
#        $refactoring->{reason} = $refactoring->{failed};
#        $refactoring->{failed} = 1;
#    }

    say _Perl_to_VimScript( $refactoring );
}

sub analyze_code {
    # Load code to be analyzed...
    my $source = do { local $/; readline(*ARGV); };

    # Do the full classification...
    my $classification = Code::ART::classify_all_vars_in($source);
    print _Perl_to_VimScript($classification) and return if $classification->{failed};

    # Generate a pattern to match all variables with various interesting properties...
    my (@cacograms, @undeclared_vars, @unused_vars);
    for my $var (values %{$classification->{vars}}) {
        # Collect cacograms (names that don't help you understand)...
        if ($var->{is_cacogram} && $var->{declared_at}) {
            push @cacograms, _line_and_column_from_ID($source, [$var->{declared_at}])
                             . $var->{sigil} . $var->{raw_name};
        }

        # Collect undeclared variables...
        if ($var->{declared_at} < 0 && !$var->{is_builtin} && $var->{raw_name} !~ /[:']/) {
            push @undeclared_vars, _line_and_column_from_ID($source, [keys %{ $var->{used_at}}])
                                 . $var->{sigil} . $var->{raw_name};
        }
        # Collect unused variables...
        elsif (!keys %{$var->{used_at}}) {
            push @unused_vars, _line_and_column_from_ID($source, [$var->{declared_at}])
                             . $var->{sigil} . $var->{raw_name};
        }
    }

    # Output all the gathered information...
    print _Perl_to_VimScript({
        cacograms       => join('\|', @cacograms),
        undeclared_vars => join('\|', @undeclared_vars),
        unused_vars     => join('\|', @unused_vars),
    });
}

my $VimOWS = '\%(\_s*\%(#.*\_s*\)*\)';
sub classify_var_at {
    # Unpack the specified variable position (i.e. the byte number in the buffer)
    my ($cursor_byte) = @_;

    # Grab the source code, which will be sent through the input filestream...
    my $source = do { local $/; readline(*ARGV); };

    # Ask Code::ART to do the actual classification
    # (making allowance for the fact that Vim byte numbers start at 1,
    #  but Perl string indexes start at zero)...
    my $info = Code::ART::_classify_var_at($source, $cursor_byte - 1);

    # Make sure the resulting information has valid 'sigil' entry...
    $info->{sigil}  //= q{};

    # Convert the various locations found to Vim line/column coordinates...
    $info->{matchloc} = _line_and_column_from_ID($source,
                                                 [$info->{declared_at}, keys %{$info->{used_at}}]);
    $info->{declloc}  = _line_and_column_from_ID($source, [$info->{declared_at}]);

    # Convert scope details to Vim formats...
    my $min_scope
        = $info->{declared_at} >= 0 ? _linenum_from_ID($source, $info->{declared_at})
                                    : 1;
    my $max_scope = _linenum_from_ID($source, $info->{end_of_scope});
    $info->{scopeloc} = '\%>' . ($min_scope-1) . 'l'
                      . '\%<' . ($max_scope+1) . 'l';
    $info->{scope_size} = $max_scope - $min_scope + 1;

    # Work out the correct Vim regex to match the valid sigils
    # of the various declinations of the variable...
    my $sigil_matcher = $info->{sigil} eq '@' ? '\%(\$#\|[@$%]\)'
                      : $info->{sigil} eq '%' ? '[%$@]'
                      : $info->{sigil} eq '$' ? '\$#\@!'
                      :                         '';

    # Build the complete Vim regex for matching any instance of the variable...
    $info->{matchname}
        = $info->{failed}
            ? q{}
            : $sigil_matcher.$VimOWS.'\%('.$info->{raw_name}
             .'\|{'.$VimOWS.$info->{raw_name}.$VimOWS.'}\)'
        ;

    # Build the complete Vim regex for matching just the name of any instance of the variable...
    $info->{matchnameonly}
        = $info->{failed}
            ? q{}
            : $sigil_matcher.$VimOWS.'\%(\zs'.$info->{raw_name}
             .'\ze\|{'.$VimOWS.'\zs'.$info->{raw_name}.'\ze'.$VimOWS.'}\)'
        ;

    # Convert homogram and parogram data to searchable regexes...
    for my $gram_type (qw< homograms parograms >) {
        my $grams = $info->{$gram_type};
        use Data::Dump 'ddx';
        $info->{$gram_type}
            = join('\|', map { my $gram = $grams->{$_};
                               my $from = _linenum_from_ID($source, $gram->{from}) - 1;
                               my $to   = _linenum_from_ID($source, $gram->{to}  ) + 1;
                               '\%>'.$from.'l\%<'.$to.'l\%($#\?\|[%@]\)'.$VimOWS.$_;
                             }
                             keys %{$grams});
    }

    # Convert all that information to a Vim dictionary, and output it...
    say _Perl_to_VimScript($info);
}

sub find_expr_scope {
    my ($from, $to, $match_all) = @_;

    # Grab the source code, which will be sent through the input filestream...
    my $source = do { local $/; readline(*ARGV); };

    my $expr_scope = Code::ART::find_expr_scope($source, $from-1, $to-1, $match_all);
    if ($expr_scope->{failed}) {
        print _Perl_to_VimScript($expr_scope);
        return;
    }

    # Convert individual match locations to a single Vim regex...
    my $matchloc = _line_and_column_from_ID(
                        $source,
                        [map { $_->{from} } @{$expr_scope->{matches}}],
                        [map { '\_.\{'.$_->{length}.'}' } @{$expr_scope->{matches}}],
                   );
    my $firstloc = _line_and_column_from_ID( $source, [ $expr_scope->{matches}[0]{from} ] );

    $expr_scope->{use_version} = $expr_scope->{use_version}->numify;

    print _Perl_to_VimScript({
            matchloc    => $matchloc,
            firstloc    => $firstloc,
            matchcount  => 0+@{$expr_scope->{matches}},
            %{$expr_scope},
          });
}

sub _Perl_to_VimScript {
    my ($value) = @_;
    if (ref($value) eq 'HASH') {
        return '{'
             . join( q{, }, map { qq{'$_' : }._Perl_to_VimScript($value->{$_}) } keys %{$value})
             . '}';
    }
    elsif (ref($value) eq 'ARRAY') {
        return '[' . join( q{, }, map { _Perl_to_VimScript($_) } @{$value} ) . ']';
    }
    elsif (!defined $value) {
        return q{''};
    }
    elsif ($value =~ m{\A \s*+ [+-]?+ \d++ (?: [.]?+ \d*+) ([eE] [+-]?+ \d+)?+ \s*+ \Z}xms) {
        return $value;
    }
    elsif ($value =~ /\n/) {
        $value =~ s{\\}{\\\\}g;
        $value =~ s{\n}{\\n}g;
        $value =~ s{"}{\\"}g;
        return qq{"$value"};
    }
    else {
        $value =~ s{'}{''}g;
        return qq{'$value'};
    }
}

sub _linenum_from_ID {
    my ($source, $id) = @_;

    my $prefix = substr($source, 0, $id);
    $prefix =~ m{(.*)\z};
    return 1 + $prefix =~ tr/\n//;
}

sub _line_and_column_from_ID {
    my ($source, $ids_ref, $etc_ref) = @_;
    my @ids = @{ $ids_ref // [] };
    my @etc = @{ $etc_ref // [] };
    my @positions;    # Accumulates converted position coordinates

    # Convert each ID (a Perl string index) to a Vim line/column coordinate
    @ids = sort {$a <=> $b} @ids;
    for my $id (@ids) {
        # Grab any per-ID suffix to be appended to each location constraint...
        my $etc = shift(@etc) // q{};

        # Skip any undeclared variables...
        next if !$id || $id < 0;

        # The line and column are determined by what preceded the specified position...
        my $prefix = substr($source, 0, $id);
        $prefix =~ m{(.*)\z};
        my $col  = 1 + length($1);
        my $line = 1 + $prefix =~ tr/\n//;

        # Remember the conversion...
        push @positions, '\%'.$line.'l\%'.$col.'c'.$etc;
    }

    # If there were no valid positions, there's no need for a Vim regex...
    return '' if !@positions;

    # Otherwise, build the regex as the disjunction of each possible set of coordinates...
    return '\%(' . join('\|', @positions) . '\)';
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Code::ART::API::Vim - Vim API for Code::ART


=head1 VERSION

This document describes Code::ART version 0.000001


=head1 SYNOPSIS

    perl -MCode::ART::API::Vim -e'refactor_to_sub($OPTIONS)'

    perl -MCode::ART::API::Vim -e'classify_var_at($CURSOR_IDX)'

=head1 DESCRIPTION

This module provides a range of subroutines to help plug the
Code::ART module directly into the Vim editor.

See the F<perlart.vim> plugin for details of how the various components
are used.

See the L<Code::ART> module for documentation of the functions provided
through this API.


=head1 DIAGNOSTICS

Exactly as for the corresponding subroutines in the L<Code::ART> module
(because they are merely passed through from that module).


=head1 CONFIGURATION AND ENVIRONMENT

Code::ART::API::Vim requires no configuration files or environment variables.


=head1 DEPENDENCIES

The L<Code::ART> module.


=head1 INCOMPATIBILITIES

Because this module relies on the PPR module,
it will not run under Perl 5.20
(because regexes are broken in that version of Perl).


=head1 BUGS AND LIMITATIONS

These refactoring and analysis algorithms are not intelligent or
self-aware. They do not understand the code they are processing, and
especially not the purpose or intent of that code. They are merely
applying a set of heuristics (i.e. informed guessing) to try to
determine what you actually wanted the replacement code to do. Sometimes
they will guess wrong. Treat them as handy-but-dumb tools, not as
magical A.I. superfriends. Trust...but verify.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-code-art.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2020, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

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
