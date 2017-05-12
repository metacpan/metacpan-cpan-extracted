package App::perl2js::Converter::Node::File;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node::BlockStmt';

use App::perl2js::Node::File;

sub to_js_ast {
    my ($self, $context) = @_;
    my $file = App::perl2js::Node::File->new;
    $context->root($file);
    my $statements = $self->statements;
    my $line = 0;
    while ($line < scalar(@$statements)) {
        my $statement = $statements->[$line];
        if ($statement->isa('App::perl2js::Converter::Node::Package')) {
            my $i = $line + 1;
            while (
                defined $statements->[$i] &&
                !$statements->[$i]->isa('App::perl2js::Converter::Node::Package')
            ) {
                $statement->push_statement($statements->[$i]);
                $i++;
            }
            $line = $i - 1;
        }
        $file->push_statement($statement->to_js_ast($context));
        $line++;
    }
    return $file;
}

1;
