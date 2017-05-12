use MooseX::Declare;

role App::Syndicator::HtmlToAscii {
    require HTML::TreeBuilder;
    require HTML::FormatText::WithLinks;

    method html_to_ascii (Str|Undef $html?) {
        return '' unless $html;
        my $tree = HTML::TreeBuilder->new_from_content($html);
        $tree->elementify;

        for ($tree->find('img')) {
            $_->delete;
        }

        my %args = (
            before_link => '<',
            after_link => '> [%n]',
            unique_links => 1,
            anchor_links => 0,
        );

        if (defined $self->{base_uri}) {
            warn "has base";
            $args{base} = $self->{base_uri};
        }

        my $formatter = HTML::FormatText::WithLinks->new(%args);

        my $text = $formatter->format($tree);
        $text =~ s/\s+$//g;
        return $text;
    }
}

1;
