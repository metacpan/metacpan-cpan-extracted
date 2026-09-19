package App::perlvars;

use Moo;
use autodie;

our $VERSION = '0.000008';

use File::Spec    ();
use Path::Tiny    qw( path );
use PPI::Document ();
use Test::Vars import => [qw( test_vars )];

my $SYNTHETIC_PACKAGE = 'PerlvarsSyntheticPackage';
my $WRAPPER_SUB       = '__perlvars_wrapper__';

# Number of lines we prepend when wrapping a package-less file (the synthetic
# "package ...;" line and the "sub ... {" line). Reported line numbers are
# shifted back by this amount. See _validate_package_less.
my $WRAP_OFFSET = 2;

has ignore_file => (
    is        => 'ro',
    predicate => '_has_ignore_file',
);

has lint_scripts => (
    is      => 'ro',
    default => 0,
);

has _ignore_for_package => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_ignore_for_package',
);

sub BUILD {
    my $self = shift;

    # We need to read the file before we start checking anything so we can die
    # if it contains bad lines and not have it look like a failure in a
    # particular file we're tidying.
    $self->_ignore_for_package;

    return;
}

sub validate_file {
    my $self = shift;
    my $file = path(shift);
    unless ( $file->exists ) {
        return ( 1, "$file could not be found" );
    }
    if ( $file->is_dir ) {
        return ( 1, "$file is a dir" );
    }

    my $doc = PPI::Document->new("$file");
    return ( 1, "$file could not be parsed as Perl" ) unless $doc;

    my $package_stmt = $doc->find_first('PPI::Statement::Package');
    if ($package_stmt) {
        my ( $exit_code, @msgs ) = test_vars(
            "$file",
            \&_result_handler,
            %{
                $self->_ignore_for_package->{ $package_stmt->namespace } || {}
            },
        );

        return $exit_code, undef, @msgs;
    }

    # Test::Vars only inspects lexicals in subs in packages, so a package-less
    # file (most .t/.pl scripts) is otherwise skipped. Analyzing it is opt-in:
    # wrapping runs the file's compile-time code and can surface never-seen
    # findings, so the caller must ask via lint_scripts.
    return ( 0, "$file contains no package" ) unless $self->lint_scripts;

    return $self->_validate_package_less( $file, $doc );
}

sub _validate_package_less {
    my $self = shift;
    my $file = shift;    # Path::Tiny
    my $doc  = shift;    # PPI::Document

    # Hand Test::Vars a synthetic "package X; sub Y { ...body... }":
    #   * Wrapping in a sub means require only *compiles* the file, not runs it,
    #     yet its named and anonymous subs become nested subs Test::Vars still
    #     inspects. (The wrapper's own pad -- the file's top-level lexicals -- is
    #     dropped below; see the grep.)
    #   * No #line directive: it would rewrite GvFILE so Test::Vars no longer
    #     matches subs to inspect. We shift line numbers back in
    #     _rewrite_message instead.

    my $code = _code_before_data( $file, $doc );

    my $tmpdir  = Path::Tiny->tempdir;
    my $wrapped = $tmpdir->child( 'lib', "$SYNTHETIC_PACKAGE.pm" );
    $wrapped->parent->mkpath;

    # Copy the body as raw bytes: perl compiles this temp file verbatim, so
    # re-encoding would be wrong and would die on non-UTF-8 source.
    $wrapped->spew(
        "package $SYNTHETIC_PACKAGE;\n",
        "sub $WRAPPER_SUB {\n",
        $code,
        "\n}\n1;\n",
    );

    # Ignore rules are keyed on "main": that is where a script's findings are
    # reported (see _rewrite_message) and the namespace a user keys on.
    #
    # Compiling the file runs its compile-time code (use/BEGIN), which can print
    # or exit/die -- neither is an unused-variable failure, so both degrade to a
    # silent skip:
    #   * STDOUT is redirected during analysis. (Test::Builder dup'd the real
    #     STDOUT earlier, so a compile-time skip_all still prints its TAP plan --
    #     but to STDOUT only, never STDERR, and the file is skipped anyway. We
    #     don't repoint that shared singleton.)
    #   * skip_all etc. call exit(), so Test::Vars' child dies before writing to
    #     its pipe and the parent dies thawing an empty string; the eval traps it.
    my ( $exit_code, @msgs );

    open my $stdout_copy, '>&', \*STDOUT;
    open STDOUT,          '>',  File::Spec->devnull;
    my $analyzed = eval {
        ( $exit_code, @msgs ) = test_vars(
            "$wrapped",
            \&_result_handler,
            %{ $self->_ignore_for_package->{main} || {} },
        );
        1;
    };
    open STDOUT, '>&', $stdout_copy;

    return 0, undef unless $analyzed;

    # A wrapper that won't compile in isolation (a FindBin/"use lib" sibling, or
    # an uninstalled dep) makes Test::Vars inspect nothing and emit an "ignores
    # ... because: $@" note at exit 0. Skip silently rather than report against
    # code we never inspected (and avoid leaking the wrapper path).
    if ( !$exit_code && grep { /^Test::Vars ignores / } @msgs ) {
        return 0, undef;
    }

    # Drop findings on the wrapper sub itself: the file's top-level lexicals are
    # its pad, and one read only from a nested named sub looks "used once" here.
    # This mirrors how Test::Vars ignores file-scope lexicals in a real package;
    # the trade-off is a genuinely unused top-level lexical is not reported.
    @msgs = grep { !/ in &\Q$SYNTHETIC_PACKAGE\E::$WRAPPER_SUB / } @msgs;

    @msgs = map { _rewrite_message( $_, "$file", "$wrapped" ) } @msgs;

    return ( @msgs ? $exit_code : 0 ), undef, @msgs;
}

sub _code_before_data {
    my $file = shift;    # Path::Tiny
    my $doc  = shift;    # PPI::Document

    # Drop everything from __END__/__DATA__ on (it would close our synthetic sub
    # early). Locate the marker via PPI, but slice the *raw* text: PPI drops
    # heredoc bodies when stringified, which would corrupt the code.
    my $cut_line;
    for my $class (qw( PPI::Statement::End PPI::Statement::Data )) {
        my $stmt = $doc->find_first($class) or next;
        my $line = $stmt->line_number;
        $cut_line = $line if !defined $cut_line || $line < $cut_line;
    }

    # Raw bytes, not decoded text (see spew in _validate_package_less); also
    # avoids dying on non-UTF-8 source. Slicing keeps line numbers intact.
    my @lines = $file->lines( { binmode => ':raw' } );
    @lines = @lines[ 0 .. $cut_line - 2 ] if defined $cut_line;

    return join q{}, @lines;
}

sub _rewrite_message {
    my $msg     = shift;
    my $file    = shift;    # original file (string)
    my $wrapped = shift;    # synthetic wrapper file (string)

    # Map the diagnostic back to the real source: shift off the prepended lines
    # (only for our wrapper path, so other files' line numbers are untouched),
    # restore the original path, and hide the synthetic anon tag and package.
    # The line shift runs first, while the wrapper path still anchors it.
    $msg =~ s{(\Q$wrapped\E line )(\d+)}{ $1 . ( $2 - $WRAP_OFFSET ) }ge;
    $msg =~ s{\Q$wrapped\E}{$file}g;
    $msg =~ s{__ANON__\[[^\]]*\]}{__ANON__}g;
    $msg =~ s{\Q$SYNTHETIC_PACKAGE\E::}{main::}g;

    return $msg;
}

sub _build_ignore_for_package {
    my $self = shift;

    return {} unless $self->_has_ignore_file;

    my %vars;
    my %regexes;

    my $file  = path( $self->ignore_file );
    my @lines = $file->lines( { chomp => 1 } );
    for my $line (@lines) {
        next unless $line =~ /\S/;

        my ( $package, $ignore ) = split( /\s*=\s*/, $line );
        unless ( defined $package && defined $ignore ) {
            die 'Invalid line in ' . $self->ignore_file . ": $line\n";
        }

        if ( $ignore =~ m{^qr} ) {
            local $@ = undef;
            ## no critic (BuiltinFunctions::ProhibitStringyEval)
            $ignore = eval $ignore;
            ## use critic
            die $@ if $@;

            push @{ $regexes{$package} }, $ignore;
        }
        else {
            push @{ $vars{$package} }, $ignore;
        }
    }

    my %ignore;
    for my $package ( keys %regexes ) {
        my @re = @{ $regexes{$package} };
        $ignore{$package}{ignore_if} = sub {
            my $check = shift;
            for my $re (@re) {
                return 1 if $check =~ /$re/;
            }
            return 0;
        };
    }

    for my $package ( keys %vars ) {
        $ignore{$package}{ignore_vars}{$_} = 1 for @{ $vars{$package} };
    }

    return \%ignore;
}

sub _result_handler {
    shift;
    my $exit_code = shift;
    my $results   = shift;

    my @errors = map { $_->[1] } grep { $_->[0] eq 'diag' } @{$results};
    return $exit_code, @errors;
}

1;

=pod

=encoding UTF-8

=head1 NAME

App::perlvars - CLI tool to detect unused variables in Perl modules

=head1 VERSION

version 0.000008

=head1 DESCRIPTION

You probably don't want to use this class directly. See L<perlvars> for
documentation on how to use the command line interface.

=head2 ignore_file

The path to a file containing a list of variables to ignore on a per-package
basis. The pattern is C<Module::Name = $variable> or C<Module::Name = qr/some
regex/>. For example:

    Local::Unused = $unused
    Local::Unused = $one
    Local::Unused = $two
    Local::Unused = qr/^\$.*hree$/

=head2 lint_scripts

A boolean, false by default. When false, a file without a C<package>
declaration is not analyzed (C<validate_file> returns a success exit code and a
"contains no package" message). Set it to a true value to also lint
package-less files (most C<.t> and C<.pl> scripts) as described under
L</validate_file>. It is opt-in because wrapping a file executes its
compile-time code and can surface findings on scripts that were never linted
before.

=head2 validate_file

Path to a file which will be validated. Returns an exit code, an error message
and a list of unused variables.

When L</lint_scripts> is true, files without a C<package> declaration are
wrapped in a synthetic package and subroutine so the lexicals inside their
named and anonymous subroutines can still be analyzed; reported line numbers
are mapped back to the original file. File-scope (top-level) lexicals are not
reported, matching how L<Test::Vars> treats file-scope lexicals in a file that
declares a package. Findings in these files are reported against the C<main>
package, so an C<ignore_file> uses C<main> as the package name to suppress a
variable in a package-less file.

Wrapping a file for analysis C<require>s it, which executes its compile-time
code (C<use> statements and C<BEGIN> blocks) even though its runtime statements
do not run. A package-less file that cannot be compiled in isolation -- because
it finds a sibling library at runtime (e.g. L<FindBin>), depends on a module
that is not installed, or contains a C<#line> directive that hides its
subroutines from L<Test::Vars> -- is skipped silently and returns a success
exit code with no notes.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: CLI tool to detect unused variables in Perl modules


