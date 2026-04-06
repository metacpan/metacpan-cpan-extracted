#!/usr/bin/env perl
use strict;
use warnings;
use Chandra::Clipboard;

print "=== Chandra::Clipboard Example ===\n\n";

# Set and get text
Chandra::Clipboard->set_text('Hello from Chandra!');
print "Text: ", Chandra::Clipboard->get_text // '(none)', "\n";

# Check availability
print "Has text:  ", Chandra::Clipboard->has_text  ? 'yes' : 'no', "\n";
print "Has html:  ", Chandra::Clipboard->has_html  ? 'yes' : 'no', "\n";
print "Has image: ", Chandra::Clipboard->has_image ? 'yes' : 'no', "\n";

# HTML
Chandra::Clipboard->set_html('<h1>Hello</h1><p>From Chandra</p>');
print "\nHTML set.\n";

# Clear
Chandra::Clipboard->clear;
print "Clipboard cleared.\n";
print "Has text after clear: ", Chandra::Clipboard->has_text ? 'yes' : 'no', "\n";

# Integration with Chandra::App (commented — requires running app)
# use Chandra::App;
# my $app = Chandra::App->new(title => 'Clipboard Demo');
# $app->bind('copy', sub {
#     my ($text) = @_;
#     $app->clipboard->set_text($text);
# });
# $app->bind('paste', sub {
#     return $app->clipboard->get_text;
# });
