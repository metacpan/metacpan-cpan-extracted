package App::PerlNitpick::Rule::RewriteHeredocAsQuotedString;

use Moose;
use String::PerlQuote qw(double_quote);
use PPI::Document;

sub rewrite {
    my ($self, $doc) = @_;
    my $heredocs = $doc->find('PPI::Token::HereDoc') or return;

    for my $heredoc (@{ $heredocs }) {
        # Only handle the heredoc that does not interpolate variables.
        next unless $heredoc->content =~ /'\z/;

        my $content = join '', $heredoc->heredoc;
        my $tok_content = double_quote($content);
        my $tok = PPI::Token::Quote::Double->new( $tok_content );
        $heredoc->insert_before($tok);
        $heredoc->remove;
    }

    return $doc;
}

no Moose;
1;


__END__

=head1 DESCRIPTION

This rule rewrites heredoc as double-quote strings. For example, this code:

    print <<'EOF';
      Nihao
    EOF

... is rewritten as:

    print "  Nihao\n";

=cut
