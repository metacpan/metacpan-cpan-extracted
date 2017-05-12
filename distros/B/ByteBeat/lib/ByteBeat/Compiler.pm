package ByteBeat::Compiler;
use Mo;
use Pegex::Parser;
use Pegex::Grammar;
use ByteBeat::RPN;

has code => ();

my $grammar = <<'...';
# Operator Precedence, Lowest to Highest
# ,
# ?: (right)
# ||
# &&
# | ^
# &
# == !=
# < > <= >=
# << >>
# + -
# * / %
# ! - (unary) (right)
# ** (right)

# ByteBeat Precedence-Climbing Grammar
bytebeat:         expr  # -list -
expr-list:        expr+             %% /- ','/
expr:             log-or-expr
log-or-expr:      log-and-expr+     % /- ( '||' )/
log-and-expr:     or-expr+          % /- ( '&&' )/
or-expr:          and-expr+         % /- ( '|' | '^' )/
and-expr:         equal-expr+       % /- ( '&' )/
equal-expr:       compare-expr+     % /- ( '==' | '!=' )/
compare-expr:     shift-expr+       % /- ( '<' | '>' | '<=' | '>=' )/
shift-expr:       add-sub-expr+     % /- ( '<<' | '>>' )/
add-sub-expr:     mul-div-mod-expr+ % /- ( '+' | '-' )/
mul-div-mod-expr: power-expr+       % /- ( '*' | '/' | '%' )/
power-expr:       token+            % /- ( '**' )/
token:
  | /- '('/ expr /- ')'/
  | variable
  | integer
variable: /- ( 't' )/
integer: /- ( DASH? DIGIT+ )/
...

sub compile {
    my ($self) = @_;
    local $SIG{__WARN__} = sub { };
    my $parser = Pegex::Parser->new(
        grammar => Pegex::Grammar->new(
            text => $grammar,
        ),
        receiver => ByteBeat::RPN->new(),
        # debug => 1,
    );
    $parser->parse($self->code);
}

1;
