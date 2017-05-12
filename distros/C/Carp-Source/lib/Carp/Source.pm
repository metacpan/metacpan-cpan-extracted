use 5.008;
use strict;
use warnings;

package Carp::Source;
BEGIN {
  $Carp::Source::VERSION = '1.101420';
}
# ABSTRACT: Warn of errors with stack backtrace and source context
use utf8;
use Term::ANSIColor;
use Exporter qw(import);
our %EXPORT_TAGS = (util => [qw(source_cluck)],);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };
our ($MaxArgNums, $MaxEvalLen, $MaxArgLen, $Verbose);

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
    } elsif (not defined($arg)) {
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

      # x{"."%x} is a kludge so we don't have a template start_tag in the code
      or $arg =~ s/([[:cntrl:]]|[[:^ascii:]])/sprintf("\\x{"."%x}",ord($1))/eg;
    return $arg;
}

# Takes the info from caller() and figures out the name of
# the sub/require/eval
sub get_subname {
    my $info = shift;
    if (defined($info->{evaltext})) {
        my $eval = $info->{evaltext};
        if ($info->{is_require}) {
            return "require $eval";
        } else {
            $eval =~ s/([\\\'])/\\$1/g;
            return "eval '" . str_len_trim($eval, $MaxEvalLen) . "'";
        }
    }
    return ($info->{sub} eq '(eval)') ? 'eval {...}' : $info->{sub};
}

sub caller_info {
    my $i = shift(@_) + 1;

    # FIXME Dist::Zilla's [PkgVersion] adds a BEGIN { $DB::VERSION = ... }
    # here; should skip package DB
    ## no critic (ProhibitNestedSubs)
    package DB;
BEGIN {
  $DB::VERSION = '1.101420';
}
    my %call_info;
    @call_info{qw(pack file line sub has_args wantarray evaltext is_require)} =
      caller($i);
    unless (defined $call_info{pack}) {
        return ();
    }
    my $sub_name = Carp::Source::get_subname(\%call_info);
    if ($call_info{has_args}) {
        my @args = map { Carp::Source::format_arg($_) } @DB::args;
        if ($MaxArgNums and @args > $MaxArgNums) {  # More than we want to show?
            $#args = $MaxArgNums;
            push @args, '...';
        }

        # Push the args onto the subroutine
        $sub_name .= '(' . join(', ', @args) . ')';
    }
    $call_info{sub_name} = $sub_name;
    return wantarray() ? %call_info : \%call_info;
}

sub longmess_heavy {
    return @_ if ref($_[0]);    # don't break references as exceptions
    return ret_backtrace(0, @_);
}

# Returns a full stack backtrace starting from where it is
# told.
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
    $mess = "$err at $i{file} line $i{line}$tid_msg\n";
    while (my %i = caller_info(++$i)) {
        my $context = get_context($i{file}, $i{line}, %options);
        print $context;
        $mess .= "\t$i{sub_name} called at $i{file} line $i{line}$tid_msg\n";
    }
    return $mess;
}

sub format_line {
    my ($line_number, $text, %options) = @_;
    return "$text\n" unless $options{number};
    sprintf "%4d: %s\n", $line_number, $text;
}

sub get_context {
    my ($file, $line, %options) = @_;
    %options = (
        lines  => 3,
        number => 1,
        color  => 'black on_yellow',
        %options,
    );
    open my $fh, '<', $file or die "can't open $file: $!\n";
    chomp(my @lines = <$fh>);
    close $fh or die "can't close $file: $!\n";

    # make calculations easier by having line 1 at element 1
    unshift @lines => '';
    my $min_line = $line - $options{lines};
    $min_line = 0 if $min_line < 0;
    my $max_line = $line + $options{lines};
    my $source   = "context for $file line $line:\n\n";
    for my $c_line ($min_line .. $line - 1) {
        next unless defined $lines[$c_line];
        $source .= format_line($c_line, $lines[$c_line], %options);
    }
    $source .=
      format_line($line, colored([ $options{color} ], $lines[$line]), %options);
    for my $c_line ($line + 1 .. $max_line) {
        next unless defined $lines[$c_line];
        $source .= format_line($c_line, $lines[$c_line], %options);
    }
    $source .= ('=' x 75) . "\n";
    $source;
}
sub source_cluck ($;@) { warn longmess_heavy(@_) }
1;


__END__
=pod

=head1 NAME

Carp::Source - Warn of errors with stack backtrace and source context

=head1 VERSION

version 1.101420

=head1 SYNOPSIS

    use Carp::Source 'source_cluck';
    source_cluck 'some error';
    source_cluck 'some error',
        lines => 5, number => 0, color => 'yellow on_blue';

=head1 DESCRIPTION

This module exports one function, C<source_cluck()>, which prints stack traces
with source code extracts to make it obvious what has been called from where.

It does not work for one-liners because there is no file from which to load
source code.

=head1 FUNCTIONS

=head2 source_cluck

    source_cluck 'some error';
    source_cluck 'some error',
        lines => 5, number => 0, color => 'yellow on_blue';

Like L<Carp>'s C<cluck()>, but it also displays the source code context of all
call frames, with three lines before and after each call being shown, and the
call being highlighted.

It takes as arguments a string (the error message) and a hash of options. The
following options are recognized:

=over 4

=item C<lines>

Number of lines to display before and after the line reported in the stack
trace. Defaults to 3.

=item C<number>

Boolean value to indicate whether line numbers should be printed at the
beginning of the context source code lines. Defaults to yes.

=item C<color>

The color in which to print the source code line reported in the stack trace.
It has to be a string that L<Term::ANSIColor> understands. Defaults to C<black
on_yellow>.

=back

This is just a quick hack - not all of C<Carp>'s or even just C<cluck()>'s
features are present. The code borrows heavily from C<Carp>.

=head2 caller_info

FIXME

=head2 format_arg

FIXME

=head2 format_line

FIXME

=head2 get_context

FIXME

=head2 get_subname

FIXME

=head2 longmess_heavy

FIXME

=head2 ret_backtrace

FIXME

=head2 source_cluck

FIXME

=head2 str_len_trim

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Carp-Source>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Carp-Source/>.

The development version lives at
L<http://github.com/hanekomu/Carp-Source/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

