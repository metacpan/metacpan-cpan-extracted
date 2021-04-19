package App::MigrateToTest2V0::Rule::ReplaceUseTestMoreToUseTest2V0;
use strict;
use warnings;
use parent 'App::MigrateToTest2V0::Rule';

sub apply {
    my ($class, $doc) = @_;

    my $use = $doc->find_first(sub {
        my (undef, $elem) = @_;
        return $elem->isa('PPI::Statement::Include') && $elem->module eq 'Test::More';
    });
    return unless $use;

    my $module_name_token = $use->schild(1);
    $module_name_token->set_content('Test2::V0');

    return unless $use->arguments;

    my $arg_kind = ($use->arguments)[0];
    # add statement
    if ($arg_kind eq 'tests') {
        # plan tests => ...;
        my $test_num = ($use->arguments)[2];
        my $plan_stmt = PPI::Statement->new;
        $plan_stmt->add_element(PPI::Token::Whitespace->new("\n"));
        $plan_stmt->add_element(PPI::Token::Word->new('plan'));
        $plan_stmt->add_element(PPI::Token::Whitespace->new(' '));
        $plan_stmt->add_element(PPI::Token::Word->new('tests'));
        $plan_stmt->add_element(PPI::Token::Whitespace->new(' '));
        $plan_stmt->add_element(PPI::Token::Operator->new('=>'));
        $plan_stmt->add_element(PPI::Token::Whitespace->new(' '));
        $plan_stmt->add_element(PPI::Token::Number->new($test_num));
        $plan_stmt->add_element(PPI::Token::Structure->new(';'));
        $use->insert_after($plan_stmt);
    } elsif ($arg_kind eq 'skip_all') {
        # skip_all ...;
        my $skip_reason = ($use->arguments)[2];
        my $skip_all_stmt = PPI::Statement->new;
        $skip_all_stmt->add_element(PPI::Token::Whitespace->new("\n"));
        $skip_all_stmt->add_element(PPI::Token::Word->new('skip_all'));
        $skip_all_stmt->add_element(PPI::Token::Whitespace->new(' '));
        $skip_all_stmt->add_element($skip_reason);
        $skip_all_stmt->add_element(PPI::Token::Structure->new(';'));
        $use->insert_after($skip_all_stmt);
    }

    # remove arguments
    my $elem = $module_name_token->next_sibling;
    while ($elem->content ne ';') {
        my $next = $elem->next_sibling;
        $elem->remove;
        $elem = $next;
    }
}

1;
