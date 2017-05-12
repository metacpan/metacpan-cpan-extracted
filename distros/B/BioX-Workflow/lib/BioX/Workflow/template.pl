#!/usr/bin/env perl


use Text::Template;

my $template = Text::Template->new(TYPE => 'FILE',  SOURCE => $ARGV[0]);
$text = $template->fill_in();  # Replaces `{$recipient}' with `King'
print $text;
