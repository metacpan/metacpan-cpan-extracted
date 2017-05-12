package App::perl2js::Converter;

use strict;
use warnings;
use Compiler::Lexer;
use Compiler::Parser;

use Module::Load;

use App::perl2js::Context;
use App::perl2js::Converter::Node::File;
use App::perl2js::Node::File;

# http://perldoc.perl.org/perlfunc.html
my $runtime = {
    'print'  => "function print() { console.log(...arguments) }\n",
    'warn'   => "function warn() { console.log(...arguments) }\n",
    # SCALAR
    # ARRAY
    # HASH
    # CODE
    # REF
    # GLOB
    # LVALUE
    # FORMAT
    # IO
    # VSTRING
    # Regexp
    'ref'    => "function ref(a) { return typeof(a) }\n",
    'pop'    => "function pop(a) { return a.pop() }\n",
    # 'push'   => "function push(a) { }\n",
    # 'map'    => "function map(a) { }\n",
    # 'splice' => "function splice(a) { }\n",
    'bless'  => "function bless(obj, proto) { return Object.create(proto, obj) }\n",
    # 'join'   => "function join(a) { }\n",
    'length' => "function length(a) { return a.length }\n",
};


my @runtime = (
    "'use strict';\n",
    "function print() { console.log.apply(console.log, arguments) }\n",
    "function warn() { console.warn.apply(console.log, arguments) }\n",
    "function ref(a) { return typeof (a) }\n",
    "function pop(a) { return Array.prototype.pop.call(a) }\n",
    "function shift(a) { return Array.prototype.shift.call(a) }\n",
    "function push(a, b) { return Array.prototype.push.call(a, b) }\n",
    "function unshift(a, b) { return Array.prototype.unshift.call(a, b) }\n",
    "function bless(obj, proto) {\n",
    "    var new_obj = {};\n",
    "    Object.keys(obj).forEach((key) => {\n",
    "        new_obj[key] = { value: obj[key] }\n",
    "    })\n",
    "    return Object.create(proto, new_obj)\n",
    "}\n",
    "function map(a, b) { return Array.prototype.map.call(b, a) }\n",
    "function join(a, b) { return Array.prototype.join.call(b, a) }\n",
    "function length(a) { return a.length }\n",
    "function range(a, b) {\n",
    "    var list = [];\n",
    "    for (var i = a; i <= b; i++) { list.push(i) }\n",
    "    return list\n",
    "}\n",
    "function string_multi(s, n) {\n",
    "    var str = '';\n",
    "    for (var i = 0; i < n; i++) { str += s }\n",
    "    return str\n",
    "}\n",
    "function default_or(a, b) { return ((a === undefined) || (a === null)) ? b : a }\n",
);

sub new {
    my ($class) = @_;
    return bless({
        lexer => Compiler::Lexer->new(),
        parser => Compiler::Parser->new(),
    }, $class);
}

sub convert {
    my ($self, $script) = @_;

    my $tokens = $self->{lexer}->tokenize($script);
    my $ast = $self->{parser}->parse($tokens);

    $ast->walk(sub {
        my ($node) = @_;
        delete $node->{parent};
        my $ref = ref($node);
        $ref =~ s/Compiler::Parser/App::perl2js::Converter/;
        load $ref;
        bless $node, $ref;
    });

    my $context = App::perl2js::Context->new;
    my $root = App::perl2js::Converter::Node::File->new(body => $ast->root);
    reconstruct($root);
    $root->to_js_ast($context);
    my $file = $context->root;

    return join(
        '',
        @runtime,
        $file->to_javascript(0),
    );
}

sub reconstruct {
    my ($node) = @_;
    # expression/statement
    ## args
    ## cond
    ## expr
    ## false_expr
    ## from
    ## idx
    ## init
    ## itr
    ## key
    ## left
    ## name
    ## option
    ## progress
    ## prototype
    ## right
    ## to
    ## true_expr
    ## false_stmt

    # block
    ## body
    ## data
    ## stmt
    ## true_stmt
    # for my $key ('body', 'data', 'stmt', 'true_stmt') {
    for my $key ('body', 'stmt', 'true_stmt') {
        if ($node->{$key}) {
            my $statement = delete $node->{$key};
            my $statements = [];
            while ($statement) {
                push @$statements, $statement;
                $statement = delete $statement->{next};
            }
            $node->statements($statements);
            for my $statement (@$statements) {
                reconstruct($statement);
            }
        }
    }
    if ($node->{false_stmt}) {
        my $statement = $node->{false_stmt};
        reconstruct($statement);
    }
}

1;
