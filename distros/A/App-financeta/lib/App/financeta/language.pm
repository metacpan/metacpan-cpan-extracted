package App::financeta::language::grammar;
use strict;
use warnings;
use 5.10.0;

our $VERSION = '0.13';
$VERSION = eval $VERSION;
use Pegex::Base;
extends 'Pegex::Grammar';
use App::financeta::utils qw(log_filter);
use Log::Any '$log', filter => \&App::financeta::utils::log_filter;

use constant text => <<GRAMMAR;
%grammar financeta
%version 0.11

program: statement* end-of-program
statement: comment | instruction | declaration

end-of-program: - EOS
comment: /- HASH ANY* EOL/ | blank-line
blank-line: /- EOL/

_: / BLANK* EOL?/
__: / BLANK+ EOL?/
line-ending: /- SEMI - EOL?/

declaration: - /((i:'allow'|'no'))/ - /((i:'long'|'short'))/ - /(i:'trades')/ - line-ending
instruction: order - /(i:'when'|'if')/ - conditions - line-ending
conditions: single-condition | nested-condition

nested-condition: start-nested single-condition end-nested
single-condition: any-condition-expr+ % logic-op
any-condition-expr: single-condition-expr | nested-condition-expr
nested-condition-expr: start-nested single-condition-expr end-nested
single-condition-expr: comparison | complement
comparison: comparison-state | comparison-basic
comparison-state: - variable - state-op-pre - state - state-op-post? -
comparison-basic: - value-expression - compare-op - value-expression -

complement: - not-op - value-expression
value-expression: complement | value
state: /((i:'positive' | 'negative' | 'zero'))/ | value
value: variable | number
state-op-pre: - /((i: 'becomes' | 'crosses' ))/ -
state-op-post: - /(i: 'from') - ((i: 'above' | 'below'))/ -
compare-op: /((i:'is' | 'equals'))/ |
    /([ BANG EQUAL LANGLE RANGLE] EQUAL | (: LANGLE | RANGLE ))/
not-op: /((i:'not') | BANG)/
logic-op: /((i:'and' | 'or'))/ | /([ AMP PIPE ]{2})/

# instruction-task
order: buy-sell quantity? - /(i:'at')/ - price -
buy-sell: - /((i:'buy' | 'sell'))/ -
quantity: number
price: - variable | number -
variable: - DOLLAR identifier -

# basic tokens
start-nested: /- LPAREN -/
end-nested: /- RPAREN -/
identifier: /(! keyword)( ALPHA [ WORDS ]*)/
keyword: /(i:
        'buy' | 'sell' | 'at' | 'equals' | 'true' | 'false' | 'if' |
        'when' | 'and' | 'or' | 'not' | 'above' | 'is' |
        'becomes' | 'crosses' | 'below' | 'from' | 'to' |
        'positive' | 'negative' | 'zero' | 'over' | 'into' |
        'allow' | 'trades' | 'short' | 'long' | 'no'
        )/
number: real-number | integer | boolean
real-number: /('-'? DIGIT* '.' DIGIT+)/
integer: /('-'? DIGIT+)/
boolean: /((i:'true'|'false'))/

GRAMMAR

sub get_regexes {
    return {
        green => [qw(
            buy sell negative positive zero below above long short
        )],
        blue => [qw(
            at equals if when and or not is becomes crosses from to
            over into trades
        )],
        red => [qw(allow no true false)],
        black => '(\$\w+)',
    };
}

1;

package App::financeta::language::receiver;
use strict;
use warnings;
use 5.10.0;

our $VERSION = '0.13';
$VERSION = eval $VERSION;
use App::financeta::utils qw(log_filter);
use Log::Any '$log', filter => \&App::financeta::utils::log_filter;
use Perl::Tidy;
use Pegex::Base;
extends 'Pegex::Tree';

has debug => 0;

has preset_vars => [];

has preset_vars_hash => undef;

has const_vars => {
    positive => sprintf("%0.06f", 1e-6),
    negative => sprintf("%0.06f", -1e-6),
    zero => 0,
    lookback => 1,
};

has local_vars => {};

has index_var_count => 0;

has PnL => { long => 1, short => 0 };

sub got_comment {} # strip the comments out

sub got_boolean {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
        $got = shift @$got;
    }
    return ($got eq 'true') ? 1 : 0;
}

sub got_variable {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
        $got = shift @$got;
    }
    $got = lc $got; # case-insensitive
    unless (defined $self->preset_vars_hash) {
        my $arr = $self->preset_vars;
        my %pvars = map { $_ => 1 } @$arr;
        $self->preset_vars_hash(\%pvars);
    }
    if (exists $self->preset_vars_hash->{$got} or
        exists $self->local_vars->{$got}) {
        # do nothing
    } else {
        $self->parser->throw_error( "Variable $got does not exist");
        return;
#        $self->local_vars->{$got} = 1;
    }
    return '$' . $got;
}

sub got_quantity {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
        $got = shift @$got;
    }
    return { quantity => $got };
}

sub got_price {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
        $got = shift @$got;
    }
    return { price => $got };
}

sub got_value {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
        XXX {value => $got};
    }
    return $got;
}

sub got_buy_sell {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
        $got = shift @$got;
    }
    return { trigger => lc $got };
}

sub got_compare_op {
    my ($self, $got) = @_;
    $got = '==' if ($got =~ /is|equals/i);
    return { compare => $got};
}

sub got_not_op {
    my ($self, $got) = @_;
    $got = lc $got;
    $got = '!' if $got eq 'not';
    return { complement => $got };
}

sub got_logic_op {
    my ($self, $got) = @_;
    $got = lc $got;
    $got = '&' if $got eq 'and';
    $got = '|' if $got eq 'or';
    return { logic => $got };
}

sub got_state_op_pre {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
        $got = shift @$got;
    }
    return 'ACT::' . lc $got;
}

sub got_state_op_post {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
        $got = shift @$got;
    }
    return 'DIRXN::' . lc $got;
}

sub got_state {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
        XXX {state => $got};
    }
    return $got if $got =~ /^\$/;
    $got = 0 if $got eq 'zero';
    # if it is a number
    return "STATE::$got" if $got =~ /^[\d\.\+\-]+$/;
    return 'STATE::' . lc $got;
}

sub got_comparison_state {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
    } else {
        XXX {comparison_state => $got};
    }
    my ($var, $act, $state, $dirxn) = @$got;
    my $fn;
    if ($act eq 'ACT::becomes') {
        if ($state =~ /^\$/) {
            # state is a variable
            $fn = 'merge';
        } else {
            $state =~ s/^STATE:://;
            # use the const_var values
            $state = $self->const_vars->{$state} if $state =~ /\w/;
            $fn = 'become';
        }
    } elsif ($act eq 'ACT::crosses') {
        $dirxn = 'DIRXN::below' unless defined $dirxn;
        $fn = "x$1" if $dirxn =~ /DIRXN::(.*)/;
        if ($state =~ /STATE::(.*)/) {
            $state = $1;
            # use the const_var values
            $state = $self->const_vars->{$state} if ($state =~ /\w/ and
                                defined $self->const_vars->{$state});
        }
    } else {
        XXX {comparison_state => $got};
    }
    unless (defined $fn) {
        XXX {comparison_state => $got};
    }
    return { $fn => [ $var, $state ] };
}

sub got_complement {
    my ($self, $got) = @_;
    XXX { complement => $got };
}

sub got_value_expression {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
    } elsif (ref $got eq 'HASH') {
        XXX { value_expr => $got };
    } else {
        # single values like variables and numbers
        return $got;
    }
    XXX { value_expr => $got };
}

sub _got_comparison_basic_3 {
    my ($self, $lhs, $op, $rhs) = @_;
    if (ref $lhs ne 'HASH' and ref $rhs ne 'HASH' and ref $op eq 'HASH') {
        return { compare => [ $lhs, $rhs, $op->{compare} ] };
    } else {
        XXX { comparison_basic => [$lhs, $op, $rhs] };
    }
}

sub got_comparison_basic {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
    } else {
        XXX {comparison_basic => $got};
    }
    return $self->_got_comparison_basic_3(@$got) if scalar(@$got) eq 3;
    XXX {comparison_basic => $got};
}

sub got_order {
    my ($self, $got) = @_;
    $self->flatten($got) if ref $got eq 'ARRAY';
    my $res = {};
    # merge the order trigger details into one hash
    foreach (@$got) {
        if (ref $_ eq 'HASH') {
            $res = { %$res, %{$_} };
        } else {
            XXX {order => $got};
        }
    }
    return { order => $res };
}

sub got_conditions {
    my ($self, $got) = @_;
    # conditions have to be in the order that the user asked them
    return { conditions => $got };
}

sub got_instruction {
    my ($self, $got) = @_;
    my $res = {};
    # merge the order trigger details into one hash
    foreach (@$got) {
        if (ref $_ eq 'HASH') {
            $res = { %$res, %{$_} };
        } else {
            XXX { instruction => $got };
        }
    }
    return $res;
}

sub got_declaration {
    my ($self, $got) = @_;
    if (ref $got eq 'ARRAY') {
        $self->flatten($got);
    }
    return unless scalar @$got >= 2;
    my $short = 0;
    my $long = 0;
    my $val = 1 if $got->[0] eq 'allow';
    $val = 0 if $got->[0] eq 'no';
    my $type = $got->[1];
    $self->PnL->{$type} = $val if defined $val;
    return; # don't return anything
}

sub _generate_pdl_begin {
    my $self = shift;
    my $lookback = $self->const_vars->{lookback};
    my $pvars = $self->preset_vars;
    my @decls = ();
    foreach (@$pvars) {
        push @decls, 'my $' . $_ . ' = shift;';
    }
    my @exprs = (
        'use PDL;',
        'use PDL::NiceSlice;',
        'sub {', # an anonymous sub
        @decls,
        'my $buys = zeroes($close->dims);',
        'my $sells = zeroes($close->dims);',
        'my $lookback = ' . $lookback . ';',
    );
    return join("\n", @exprs);
}

sub _generate_pdl_end {
    my $self = shift;
    my $lookback = $self->const_vars->{lookback};
    my $long = $self->PnL->{long};
    my $short = $self->PnL->{short};
    $long = 1 unless defined $long;
    $short = 0 unless defined $short;
    my @exprs = (
        "return { buys => \$buys, sells => \$sells, long => $long, short => $short };",
        '}', # end of subroutine
    );
    return join("\n", @exprs);
}

sub _generate_pdl_custom {
    my ($self, $ins) = @_;
    #YYY { instruction => $ins };
    if (ref $ins ne 'HASH') {
        XXX $ins;
    }
    my $order = $ins->{order};
    my $conds = $ins->{conditions};
    if ((defined $order and ref $order ne 'HASH') or
        (defined $conds and ref $conds ne 'ARRAY')) {
        XXX $ins;
    }
    # conds is a stack of hashes
    my @indexes = ();
    my @expressions = ();
    while (@$conds) {
        my $c = shift @$conds;
        next unless ref $c eq 'HASH';
        if (defined $c->{become}) {
            my ($state1, $state2) = @{$c->{become}};
            my $expr;
            my $index = $self->index_var_count;
            my $idxvar = '$idx_' . $index;
            push @indexes, "my $idxvar = xvals($state1" .
                            '->dims) - $lookback; ';
            push @indexes, "$idxvar = $idxvar" .
                        "->setbadif($idxvar < 0)->setbadtoval(0);";
            $self->index_var_count($index + 1);
            # state is not a var but a number for become
            # masks use bitwise & instead of logical &&
            if ($state2 >= 0) {
                $expr = "($state1 >= $state2) & ($state1" .
                "->index($idxvar) < $state2)";
            } else {
                $expr = "($state1 <= $state2) & ($state1" .
                "->index($idxvar) > $state2)";
            }
            push @expressions, $expr;
        }
        if (defined $c->{xbelow} or defined $c->{xabove}) {
            my $dirxn = 'xabove' if defined $c->{xabove};
            $dirxn = 'xbelow' if defined $c->{xbelow};
            my ($state1, $state2) = @{$c->{$dirxn}};
            my $index = $self->index_var_count;
            #TODO: whatif the state1 and state2 have different dims ?
            my $idxvar = '$idx_' . $index;
            push @indexes, "my $idxvar = xvals($state1" .
                            '->dims) - $lookback; ';
            push @indexes, "$idxvar = $idxvar" .
                        "->setbadif($idxvar < 0)->setbadtoval(0);";
            $self->index_var_count($index + 1);
            # state2 can be var or number
            my $expr;
            my $s1 = '<' if $dirxn eq 'xbelow';
            $s1 = '>' if $dirxn eq 'xabove';
            my $s2 = '>' if $dirxn eq 'xbelow';
            $s2 = '<' if $dirxn eq 'xabove';
            # masks use bitwise & instead of logical &&
            if ($state2 =~ /^\$/) {
                $expr = "($state1" . "->index($idxvar) $s1 $state2" .
                        "->index($idxvar)) & ($state1 $s2 $state2)";
            } else {
                $expr = "($state1" . "->index($idxvar) $s1 $state2) "
                        . "& ($state1 $s2 $state2)";
            }
            push @expressions, $expr;
        }
        if (defined $c->{logic}) {
            push @expressions, $c->{logic};
        }
        if (defined $c->{compare}) {
            my ($lhs, $rhs, $op) = @{$c->{compare}};
            my $expr = "($lhs $op $rhs)";
            push @expressions, $expr;
        }
    }
    #YYY { expressions => \@expressions, indexes => \@indexes };
    if (defined $order->{trigger} and defined $order->{price}) {
        my $trig = $order->{trigger};
        my $px = $order->{price};
        my $qty = $order->{quantity} || 100;
        # px can be a variable or number
        my $tvar = '$' . $trig . 's';
        my $index = $self->index_var_count;
        my $idxvar = '$idx_' . $index;
        push @indexes, "my $idxvar = which(" .
                join(' ', @expressions) . ');';
        if ($px =~ /^\$/) {
            push @indexes, $tvar . "->index($idxvar) .= $px" .
                          "->index($idxvar);";
        } else {
            push @indexes, $tvar . "->index($idxvar) .= $px;";
        }
        $self->index_var_count($index + 1);
    } else {
        XXX $order;
    }
    return join("\n", @indexes);
}

sub final {
    my ($self, $got) = @_;
    $self->flatten($got) if ref $got eq 'ARRAY';
    my @code = ();
    foreach (@$got) {
        push @code, $self->_generate_pdl_custom($_);
    }
    return unless scalar @code;
    my $final_code = join("\n", $self->_generate_pdl_begin(), @code,
                            $self->_generate_pdl_end());
    my $tidy_code;
    Perl::Tidy::perltidy(source => \$final_code, destination => \$tidy_code);
    $log->debug("Tidy Code:\n$tidy_code");
    return $tidy_code;
}

1;

package App::financeta::language;
use strict;
use warnings;
use 5.10.0;

use Pegex::Parser;
use App::financeta::mo;
use App::financeta::utils qw(log_filter);
use Log::Any '$log', filter => \&App::financeta::utils::log_filter;

$| = 1;
has debug => 0;

has preset_vars => [];

has grammar => (default => sub {
    return App::financeta::language::grammar->new;
});

sub get_grammar_regexes {
    my $self = shift;
    return $self->grammar->get_regexes;
}

has receiver => (builder => '_build_receiver');

sub _build_receiver {
    my $self = shift;
    return App::financeta::language::receiver->new(
        debug => $self->debug,
        preset_vars => $self->preset_vars,
    );
}

has parser => (builder => '_build_parser');

sub _build_parser {
    my $self = shift;
    return Pegex::Parser->new(
        grammar => $self->grammar,
        receiver => $self->receiver,
        debug => $self->debug,
        throw_on_error => 0,
    );
}

sub compile {
    my ($self, $text, $presets) = @_;
    return unless (defined $text and length $text);
    # update the debug flag to keep it dynamic
    $self->receiver->debug($self->debug);
    $self->receiver->index_var_count(0); # reset for each compilation
    # update the preset vars if necessary
    $self->receiver->preset_vars($presets || $self->preset_vars);
    $self->receiver->preset_vars_hash(undef);
    return $self->parser->parse($text);
}

sub generate_coderef {
    my ($self, $code) = @_;
    return unless $code;
    my $coderef = eval $code;
    $log->error("Unable to compile into a code-ref: $@") if $@;
    return $coderef;
}

1;

__END__
### COPYRIGHT: 2013-2023. Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 3rd Sept 2014
### LICENSE: Refer LICENSE file
