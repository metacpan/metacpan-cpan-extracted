package App::MigrateToTest2V0::Rule::ReplaceIsaOkHASHOrArrayToRefOk;
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
        next unless $second_arg->isa('PPI::Token::Quote');

        if ($second_arg->content =~ /HASH|ARRAY/) {
            $stmt->first_token->set_content('ref_ok');
        }
    }
}

1;
