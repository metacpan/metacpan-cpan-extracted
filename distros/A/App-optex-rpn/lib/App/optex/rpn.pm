package App::optex::rpn;

our $VERSION = "1.03";

=encoding utf-8

=head1 NAME

rpn - optex module for Reverse Polish Notation calculation

=head1 SYNOPSIS

    optex -Mrpn command ...

=head1 DESCRIPTION

B<rpn> is a module for the B<optex> command that detects arguments
that look like Reverse Polish Notation (RPN) expressions and replaces
them with their calculated results.

By default, all arguments are processed automatically when the module
is loaded.

=head1 MODULE OPTIONS

Module options can be set via C<-Mrpn::config(...)> or C<--option>
before C<-->.

=over 4

=item B<--auto>, B<--no-auto>

Enable or disable automatic processing of all arguments.  Default is
enabled.  Use C<--no-auto> to disable and process only arguments
specified by C<--rpn>.

=item B<-p> I<name_or_regex>, B<--pattern> I<name_or_regex>

Specify a pattern to match RPN expressions.  The value can be either a
preset name (word characters only, prefix match supported) or a
custom regex pattern.

When C<--pattern> is specified, C<--auto> is ignored.

B<Preset patterns:>

=over 4

=item C<rpn>

Matches C<rpn(...)> and extracts the content inside parentheses.

=item C<equal>

Matches C<...=> at the end and extracts the expression before C<=>.

=back

B<Custom patterns:>

When the value contains non-word characters, it is treated as a
regex pattern.  The pattern must contain a capture group C<(...)> that
captures the RPN expression.  The entire matched portion is replaced
with the calculated result.

Examples:

    # Use preset pattern 'rpn' (or -pr for short)
    optex -Mrpn -pr -- echo '3600*5' '=' rpn(3600,5*)
    # outputs: 3600*5 = 18000

    # Use preset pattern 'equal' (or -pe for short)
    optex -Mrpn -pe -- echo '3600*5' '=' 3600,5*=
    # outputs: 3600*5 = 18000

    # Use custom regex pattern
    optex -Mrpn --pattern 'calc\[(.*)\]' -- echo calc[3600,5*]
    # outputs: 18000

=item B<--quiet>, B<--no-quiet>

Suppress Math::RPN warning messages.  Default is enabled.  Use
C<--no-quiet> to see warnings for invalid expressions.

=item B<--verbose>

Print diagnostic messages.

=back

=head1 COMMAND OPTIONS

These options are available after C<-->.

=over 4

=item B<--rpn> I<expression>

Convert a single RPN expression.

    optex -Mrpn --no-auto -- printf '%s = %d\n' 3600,5* --rpn 3600,5*
    # outputs: 3600,5* = 18000

=back

=head1 EXPRESSIONS

An RPN expression requires at least two terms separated by commas or
colons.  A single term like C<RAND> will not be converted, but
C<RAND,0+> will produce a random number.

=head2 OPERATORS

The following operators are supported (case-insensitive):

=over 4

=item Arithmetic

C<+> (ADD), C<-> (SUB), C<*> (MUL), C</> (DIV), C<%> (MOD),
C<++> (INCR), C<--> (DECR), C<POW>, C<SQRT>

=item Trigonometric

C<SIN>, C<COS>, C<TAN>

=item Logarithmic

C<LOG>, C<EXP>

=item Numeric

C<ABS>, C<INT>

=item Bitwise/Logical

C<&> (AND), C<|> (OR), C<!> (NOT), C<XOR>, C<~>

=item Comparison

C<E<lt>> (LT), C<E<lt>=> (LE), C<=>/C<==> (EQ),
C<E<gt>> (GT), C<E<gt>=> (GE), C<!=> (NE)

=item Conditional

C<IF>

=item Stack

C<DUP>, C<EXCH>, C<POP>

=item Other

C<MIN>, C<MAX>, C<TIME>, C<RAND>, C<LRAND>

=back

See L<Math::RPN> for detailed descriptions of these operators.

=head1 EXAMPLES

Convert 5 hours to seconds (3600 * 5 = 18000):

    $ optex -Mrpn echo 3600,5*
    18000

Prevent macOS from sleeping for 5 hours:

    $ optex -Mrpn caffeinate -d -t 3600,5*

Process multiple expressions:

    $ optex -Mrpn echo 1,2+ 10,3*
    3 30

Generate a random number:

    $ optex -Mrpn echo RAND,0+
    0.316809834520431

=head1 INSTALLATION

=head2 CPANMINUS

    cpanm App::optex::rpn

=head1 SEE ALSO

L<App::optex>, L<https://github.com/kaz-utashiro/optex>

L<App::optex::rpn>, L<https://github.com/kaz-utashiro/optex-rpn>

L<Math::RPN>

L<https://qiita.com/kaz-utashiro/items/2df8c7fbd2fcb880cee6>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2021-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use Carp;
use utf8;
use open IO => 'utf8', ':std';
use Data::Dumper;
use Getopt::EX::Config;
my $config = Getopt::EX::Config->new(
    auto    => 1,
    verbose => 0,
    quiet   => 1,
    pattern => undef,
);

my($mod, $argv);
sub initialize { ($mod, $argv) = @_ }

sub finalize {
    $config->deal_with($argv, 'auto!', 'verbose!', 'quiet!', 'pattern|p=s');
    if (defined $config->{pattern}) {
	rpn_pattern($config->{pattern});
    } elsif ($config->{auto}) {
	rpn();
    }
}

sub argv (&) {
    my $sub = shift;
    @$argv = $sub->(@$argv);
}

my @operator = sort { length $b <=> length $a } split /[,\s]+/, <<'END';
+,ADD  ++,INCR  -,SUB  --,DECR  *,MUL  /,DIV  %,MOD  POW  SQRT
SIN  COS  TAN
LOG  EXP
ABS  INT
&,AND  |,OR  !,NOT  XOR  ~
<,LT  <=,LE  =,==,EQ  >,GT  >=,GE  !=,NE
IF
DUP  EXCH  POP
MIN  MAX
TIME
RAND  LRAND
END

my $operator_re = join '|', map "\Q$_", @operator;
my $term_re     = qr/(?:\d*\.)?\d+|$operator_re/i;
my $rpn_re      = qr/(?: $term_re [,:]* ){2,}/xi;

my %preset_pattern = (
    rpn   => qr/^rpn\((.+)\)$/,
    equal => qr/^(.+)=$/,
);

sub rpn_calc {
    use Math::RPN ();
    my @terms = map { /$term_re/g } @_;
    my @ans = do {
	local $_;
	local $SIG{__WARN__} = $config->{quiet} ? sub {} : undef;
	Math::RPN::rpn @terms;
    };
    if (@ans == 1 && defined $ans[0] && $ans[0] !~ /[^\.\d]/) {
	$ans[0];
    } else {
	return undef;
    }
}


sub rpn {
    my $count = 0;
    for (@$argv) {
	/^$rpn_re$/ or next;
	my $calc = rpn_calc($_) // next;
	if ($calc ne $_) {
	    $count++;
	    $_ = $calc;
	}
    }
    warn "rpn: converted $count expression(s)\n" if $config->{verbose} && $count;
}

sub rpn_pattern {
    my $pattern = shift;
    my $re;
    if ($pattern =~ /^\w+$/) {
	my @matches = grep { /^\Q$pattern/ } keys %preset_pattern;
	@matches == 1 or die @matches == 0
	    ? "rpn: unknown preset pattern '$pattern'\n"
	    : "rpn: ambiguous preset pattern '$pattern' (matches: @matches)\n";
	$re = $preset_pattern{$matches[0]};
    } else {
	$re = qr/$pattern/;
    }
    my $count = 0;
    for (@$argv) {
	/$re/ or next;
	my $expr = $1 // next;
	length $expr or next;
	my $calc = rpn_calc($expr) // next;
	if ($calc ne $expr) {
	    $count++;
	    s/$re/$calc/;
	}
    }
    warn "rpn: converted $count expression(s)\n" if $config->{verbose} && $count;
}

sub convert {
    my %arg = @_;
    my $target = $arg{rpn} // die "rpn: missing expression\n";
    if ($target =~ /^$rpn_re$/) {
	my $calc = rpn_calc($target);
	if (defined $calc && $calc ne $target) {
	    $target = $calc;
	}
    }
    unshift @$argv, $target;
}

1;

__DATA__

option --rpn -M__PACKAGE__::convert(rpn~$<shift>)

#  LocalWords:  rpn optex macOS
