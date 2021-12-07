package App::optex::rpn;

our $VERSION = "1.01";

=encoding utf-8

=head1 NAME

rpn - Reverse Polish Notation calculation

=head1 SYNOPSIS

    optex -Mrpn command ...

=head1 VERSION

Version 1.01

=head1 DESCRIPTION

B<rpn> is a filter module for B<optex> command to detect arguments
which look like Reverse Polish Notation (RPN), and replace them by the
result of calculation.

See L<Math::RPN> for Reverse Polish Noatation detail.

Since RPN part requires two terms at least,

    optex -Mrpn echo RAND

print just "RAND".  Use something like C<RAND,0+> to get random
number.

=head1 EXAMPLE

Prevent macOS to suspend for 5 hours.

    $ optex -Mrpn caffeinate -d -t 3600,5*

=head1 INSTALL

cpanm https://github.com/kaz-utashiro/optex-rpn.git

=head1 SEE ALSO

L<App::optex>, L<https://github.com/kaz-utashiro/optex>

L<App::optex::rpn>, L<https://github.com/kaz-utashiro/optex-rpn>

L<https://qiita.com/kaz-utashiro/items/2df8c7fbd2fcb880cee6>

L<Math::RPN>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2021 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use Carp;
use utf8;
use open IO => 'utf8', ':std';
use Data::Dumper;

our %option = (
    debug   => 0,
    verbose => 0,
    );

my($mod, $argv);
sub initialize { ($mod, $argv) = @_ }

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
my $rpn_re      = qr/(?: $term_re ,* ){2,}/xi;

sub rpn_calc {
    use Math::RPN ();
    my @terms = map { /$term_re/g } @_;
    my @ans = do { local $_; Math::RPN::rpn @terms };
    if (@ans == 1 && defined $ans[0] && $ans[0] !~ /[^\.\d]/) {
	$ans[0];
    } else {
	return undef;
    }
}


sub rpn {
    argv {
	my($cmd, @arg) = @_;
	my $count;
	for (@arg) {
	    /^$rpn_re$/ or next;
	    my $calc = rpn_calc($_) // next;
	    if ($calc ne $_) {
		$count++;
		$_ = $calc;
	    }
	}
	warn "exec: $cmd @arg\n" if $option{verbose};
	($cmd, @arg);
    };
}

sub option {
    while (my($k, $v) = splice @_, 0, 2) {
	if ($k =~ s/^no-?//) {
	    $option{$k} = 0;
	} else {
	    $option{$k} = $v;
	}
    }
}

1;

__DATA__

option default --rpn-all

option --rpn-all -M__PACKAGE__::rpn() $<move>

option --rpn -M__PACKAGE__::rpn() $<shift>

#  LocalWords:  rpn optex macOS
