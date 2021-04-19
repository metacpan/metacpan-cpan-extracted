package App::MigrateToTest2V0::Rule::Translate2ndArgumentOfIsaOkWithArrayRef;
use strict;
use warnings;
use parent 'App::MigrateToTest2V0::Rule';
use PPIx::Utils qw(parse_arg_list);

sub apply {
    my ($class, $doc) = @_;

    my $stmts = $doc->find(sub {
        my (undef, $elem) = @_;
        return $elem->isa('PPI::Statement') && $elem->first_token && $elem->first_token->content eq 'isa_ok';
    });
    return unless $stmts;

    for my $stmt (@$stmts) {
        my $second_arg = (parse_arg_list($stmt->first_token))[1]->[0];
        next unless $second_arg;

        my $first_paren = PPI::Token::Structure->new('[');
        my $last_paren = PPI::Token::Structure->new(']');
        $second_arg->insert_before($first_paren);
        $second_arg->insert_after($last_paren);
    }
}

1;
