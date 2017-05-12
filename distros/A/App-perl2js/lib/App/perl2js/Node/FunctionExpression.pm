package App::perl2js::Node::FunctionExpression;

use strict;
use warnings;
use parent qw(App::perl2js::Node::BlockStmt);

sub to_javascript {
    my ($self, $depth) = @_;
    return (
        "function() {\n",
        (scalar(@{$self->statements}) ?
         ($self->indent($depth + 1),
          "if (this !== undefined) { Array.prototype.unshift.call(arguments, this) }\n",
          $self->sentences_to_javascript($depth + 1),
         ) : ()
        ),
        $self->indent($depth),
        "}",
    );
}

1;
