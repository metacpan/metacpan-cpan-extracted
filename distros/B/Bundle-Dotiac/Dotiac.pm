package Bundle::Dotiac;
use strict;
use warnings;

$VERSION = 0.1;

1;

__END__

=head1 NAME

Bundle::Dotiac - Bundle Dotiac::DTL with all Addons

=head1 SYNOPSIS

 perl -MCPAN -e 'install Bundle::Dotiac'

=head1 CONTENTS

Dotiac::DTL - The main module

Dotiac::DTL::Addon::case_insensitive - Makes variables case insensitive

Dotiac::DTL::Addon::importloop - A loop that modifies the root namespace.

Dotiac::DTL::Addon::html_template - Renders HTML::Template templates with Dotiac

Dotiac::DTL::Addon::json - render data into json files, uses L<JSON>.

Dotiac::DTL::Addon::jsonify - render to json (http://www.djangosnippets.org/snippets/1250/). Also uses L<JSON>.

Dotiac::DTL::Addon::markup - Different markup text (django.contrib.markup), uses L<Text::Markdown> amd L<Text::Textile>.

Dotiac::DTL::Addon::unparsed - Don't parse the content of the unparsed tag.

=head1 DESCRIPTION

Installs Dotiac with all the known addons, this way Dotiac can render any valid template it encounters.

"Everything needed to render Django Templates in Perl"

=head1 AUTHOR

Marc Lucksch E<lt>perl@marc-s.deE<gt>

=cut 
