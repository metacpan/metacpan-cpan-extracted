package Carp::SyntaxHighlightSource;

use 5.010001;
use strict;
use warnings;
use utf8;
use SyntaxHighlight::Any qw(highlight_string);
use Term::ANSIColor;
#use Text::ANSI::Util qw(ta_strip);
use Tie::Cache;

our $VERSION = '0.03'; # VERSION

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(source_cluck);

our ($CarpLevel, $MaxArgNums, $MaxEvalLen, $MaxArgLen, $Verbose);

# If a string is too long, trims it with ...
sub str_len_trim {
    my $str = shift;
    my $max = shift || 0;
    if (2 < $max and $max < length($str)) {
        substr($str, $max - 3) = '...';
    }
    return $str;
}

# Transform an argument to a function into a string.
sub format_arg {
    my $arg = shift;
    if (ref($arg)) {
        $arg = defined($overload::VERSION) ? overload::StrVal($arg) : "$arg";
    }elsif (not defined($arg)) {
        $arg = 'undef';
    }
    $arg =~ s/'/\\'/g;
    $arg = str_len_trim($arg, $MaxArgLen);

    # Quote it?
    $arg = "'$arg'" unless $arg =~ /^-?[\d.]+\z/;

    # The following handling of "control chars" is direct from
    # the original code - it is broken on Unicode though.
    # Suggestions?
    utf8::is_utf8($arg)
          or $arg =~ s/([[:cntrl:]]|[[:^ascii:]])/sprintf("\\x{%x}",ord($1))/eg;
    return $arg;
}

# Takes the info from caller() and figures out the name of the sub/require/eval
sub get_subname {
    my $info = shift;
    if (defined($info->{evaltext})) {
        my $eval = $info->{evaltext};
        if ($info->{is_require}) {
            return "require $eval";
        }
        else {
            $eval =~ s/([\\\'])/\\$1/g;
            return "eval '" . str_len_trim($eval, $MaxEvalLen) . "'";
        }
    }

    return ($info->{sub} eq '(eval)') ? 'eval {...}' : $info->{sub};
}

sub caller_info {
    my $i = shift(@_) + 1;
    package DB;
    my %call_info;
    @call_info{
        qw(pack file line sub has_args wantarray evaltext is_require)
    } = caller($i);

    unless (defined $call_info{pack}) {
        return ();
    }

    my $sub_name = Carp::SyntaxHighlightSource::get_subname(\%call_info);
    if ($call_info{has_args}) {
        my @args = map {Carp::SyntaxHighlightSource::format_arg($_)} @DB::args;
        if ($MaxArgNums and @args > $MaxArgNums) { # More than we want to show?
            $#args = $MaxArgNums;
            push @args, '...';
        }
        # Push the args onto the subroutine
        $sub_name .= '(' . join (', ', @args) . ')';
    }
    $call_info{sub_name} = $sub_name;
    return wantarray() ? %call_info : \%call_info;
}

sub long_error_loc {
    my $i;
    my $lvl = $CarpLevel;
    {
        my $pkg = caller(++$i);
        redo unless 0 > --$lvl;
    }
    return $i - 1;
}

sub longmess_heavy {
    return @_ if ref($_[0]); # don't break references as exceptions
    my $i = long_error_loc();
    return ret_backtrace($i, @_);
}

# Returns a full stack backtrace starting from where it is told.
sub ret_backtrace {
    my ($i, $err, %options) = @_;
    my $mess;
    $i++;

    my $tid_msg = '';
    if (defined &Thread::tid) {
        my $tid = Thread->self->tid;
        $tid_msg = " thread $tid" if $tid;
    }

    my %i = caller_info($i);
    my $context = get_context($i{file}, $i{line}, %options);
    print $context;
    $mess = "$err at $i{file} line $i{line}$tid_msg\n";

    while (my %i = caller_info(++$i)) {
        #use Data::Dump; dd \%i;
        my $context = get_context($i{file}, $i{line}, %options);
        print $context;
        $mess .= "\t$i{sub_name} called at $i{file} line $i{line}$tid_msg\n";
    }

    return $mess;
}

sub format_line {
    my ($line_number, $text, %options) = @_;

    $text .= "\n" unless $text =~ /\n$/;
    return "$text" unless $options{number};
    sprintf "%4d: %s", $line_number, $text;
}

sub get_context {
    my ($file, $line, %options) = @_;

    # for best result, we highlight whole file, but we cache a certain amount of
    # highlighted source files.
    state $cache;
    if (!$cache) {
        $cache = {};
        tie %$cache, 'Tie::Cache', 16;
    }

    %options = (
        lines  => 3,
        number => 1,
        color  => 'reverse',
        %options,
    );

    my $lines;
    if ($cache->{$file}) {
        $lines = $cache->{$file};
    } else {
        local $/;
        open my $fh, '<', $file or die "can't open $file: $!\n";
        my $src = highlight_string(~~<$fh>, {lang=>"perl", output=>"ansi"});
        $lines = [split /^/, $src];
        close $fh or die "can't close $file: $!\n";
        $cache->{$file} = $lines;

        # make calculations easier by having line 1 at element 1
        unshift @$lines => '';
   }

    my $min_line = $line - $options{lines};
    $min_line = 1 if $min_line < 1;

    my $max_line = $line + $options{lines};

    my $source = "context for $file line $line:\n\n";

    for my $c_line ($min_line .. $line - 1) {
        next unless defined $lines->[$c_line];
        $source .= format_line($c_line, $lines->[$c_line], %options);
    }

    $source .=
        colored([$options{color}], format_line($line, $lines->[$line], %options));

    for my $c_line ($line + 1 .. $max_line) {
        next unless defined $lines->[$c_line];
        $source .= format_line($c_line, $lines->[$c_line], %options);
    }

    $source .= ('=' x 75) . "\n";
    $source;
}

sub source_cluck ($;@) { warn longmess_heavy(@_) }

1;
# ABSTRACT: Die/warn of errors with stack backtrace and source context

__END__

=pod

=encoding UTF-8

=head1 NAME

Carp::SyntaxHighlightSource - Die/warn of errors with stack backtrace and source context

=head1 VERSION

This document describes version 0.03 of Carp::SyntaxHighlightSource (from Perl distribution Carp-Always-SyntaxHighlightSource), released on 2016-03-16.

=head1 SYNOPSIS

    use Carp::SyntaxHighlightSource 'source_cluck';
    source_cluck 'some error';
    source_cluck 'some error',
        lines => 5, number => 0, color => 'yellow on_blue';

=head1 DESCRIPTION

This module exports one function, C<source_cluck()>, which prints stack traces
with syntax-highlighted source code extracts to make it obvious what has been
called from where.

It does not work for one-liners because there is no file from which to load
source code.

Syntax-highlighting is done using L<SyntaxHighlight::Any>. You need one or more
backends for syntax-highlighting to work, e.g. B,Pygments> or B<GNU
source-highlight>.

=over 4

=item source_cluck

    source_cluck 'some error';
    source_cluck 'some error',
        lines => 5, number => 0, color => 'yellow on_blue';

Like L<Carp>'s C<cluck()>, but it also displays the source code context of all
call frames, with three lines before and after each call being shown, and the
call being highlighted.

It takes as arguments a string (the error message) and a hash of options. The
following options are recognized:

=over 4

=item lines

Number of lines to display before and after the line reported in the stack
trace. Defaults to 3.

=item number

Boolean value to indicate whether line numbers should be printed at the
beginning of the context source code lines. Defaults to yes.

=item color

The color in which to print the source code line reported in the stack trace. It
has to be a string that L<Term::ANSIColor> understands. Defaults to C<black
on_yellow>.

=back

This is just a quick hack - not all of C<Carp>'s or even just C<cluck()>'s
features are present. The code borrows heavily from C<Carp>.

=back

=for Pod::Coverage .*

=head1 CREDITS

Modified from L<Carp::Source>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Carp-Always-SyntaxHighlightSource>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Carp-Always-SyntaxHighlightSource>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Carp-Always-SyntaxHighlightSource>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Carp::Always::SyntaxHighlightSource>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
