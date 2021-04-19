package App::MigrateToTest2V0::Rule::ReplaceIsDeeplyToIs;
use strict;
use warnings;
use parent 'App::MigrateToTest2V0::Rule';

sub apply {
    my ($class, $doc) = @_;

    my $tokens = $doc->find(sub {
        my (undef, $elem) = @_;
        return $elem->isa('PPI::Token') && $elem->content eq 'is_deeply';
    });
    return unless $tokens;

    for my $token (@$tokens) {
        $token->set_content('is');
    }
}

1;
