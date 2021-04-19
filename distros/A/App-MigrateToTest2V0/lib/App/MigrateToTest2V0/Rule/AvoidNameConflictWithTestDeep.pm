package App::MigrateToTest2V0::Rule::AvoidNameConflictWithTestDeep;
use strict;
use warnings;
use parent 'App::MigrateToTest2V0::Rule';
use PPIx::Utils qw(is_function_call);
use List::Util qw(any);
use Test::Deep ();
use constant TEST_DEEP_EXPORTS => [@Test::Deep::EXPORT];

sub apply {
    my ($class, $doc) = @_;

    my $stmts = $doc->find(sub {
        my (undef, $elem) = @_;
        return $elem->isa('PPI::Statement::Include') && $elem->module eq 'Test::Deep';
    });
    return unless $stmts;

    my $tokens = $doc->find(sub {
        my (undef, $elem) = @_;
        return $elem->isa('PPI::Token::Word') && any { $elem->content eq $_ } @{ TEST_DEEP_EXPORTS() };
    });
    $tokens ||= [];

    for my $token (@$tokens) {
        next unless is_function_call($token);
        $token->set_content('Test::Deep::' . $token->content);
    }

    # replace use
    for my $stmt (@$stmts) {
        my $module_name_token = $stmt->schild(1);

        # remove arguments
        my $elem = $module_name_token->next_sibling;
        while ($elem->content ne ';') {
            my $next = $elem->next_sibling;
            $elem->remove;
            $elem = $next;
        }

        # add ()
        $module_name_token->insert_after(PPI::Token::Structure->new(')'));
        $module_name_token->insert_after(PPI::Token::Structure->new('('));
        $module_name_token->insert_after(PPI::Token::Whitespace->new(' '));
    }
}

1;
