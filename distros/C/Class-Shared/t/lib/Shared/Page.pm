package Shared::Page;

# A real-world target class: the Template Toolkit, shared by many sites.  It is
# only loaded by a test that has checked that Template is installed, so it is
# not a dependency of this distribution.

use strict;
use warnings;

use parent 'Template';

# Purpose:       fill in a template and return the text.
# Why a method:  Template->process wants a reference to a variable to write its
#                output into.  A reference sent to the backend is a copy, so the
#                backend would fill in its copy and the caller's variable would
#                stay empty.  Done here, in the backend, the text is the return
#                value, which does cross.
# Exit status:   the output; dies with Template's own message if it cannot.
sub render {
	my ($self, $template, $vars) = @_;

	my $output;

	$self->process(\$template, $vars || {}, \$output)
		or die $self->error . "\n";

	return $output;
}

1;
