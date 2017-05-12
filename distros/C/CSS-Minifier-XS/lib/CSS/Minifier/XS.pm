package CSS::Minifier::XS;

use strict;
use warnings;

require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);
our @EXPORT_OK = qw(minify);

our $VERSION = '0.09';

bootstrap CSS::Minifier::XS $VERSION;

1;

=head1 NAME

CSS::Minifier::XS - XS based CSS minifier

=head1 SYNOPSIS

  use CSS::Minifier::XS qw(minify);
  $minified = minify($css);

=head1 DESCRIPTION

C<CSS::Minifier::XS> is a CSS "minifier"; its designed to remove un-necessary
whitespace and comments from CSS files, while also B<not> breaking the CSS.

C<CSS::Minifier::XS> is similar in function to C<CSS::Minifier>, but is
substantially faster as its written in XS and not just pure Perl.

=head1 METHODS

=over

=item minify($css)

Minifies the given C<$css>, returning the minified CSS back to the caller.

=back

=head1 HOW IT WORKS

C<CSS::Minifier::XS> minifies the CSS by removing un-necessary whitespace from
CSS documents.  Comment blocks are also removed, I<except> when (a) they
contain the word "copyright" in them, or (b) they're needed to implement the
"Mac/IE Comment Hack".

Internally, the minification is done by taking multiple passes through the CSS
document:

=head2 Pass 1: Tokenize

First, we go through and parse the CSS document into a series of tokens
internally.  The tokenizing process B<does not> check to make sure that you've
got syntactically valid CSS, it just breaks up the text into a stream of tokens
suitable for processing by the subsequent stages.

=head2 Pass 2: Collapse

We then march through the token list and collapse certain tokens down to their
smallest possible representation.  I<If> they're still included in the final
results we only want to include them at their shortest.

=over

=item Whitespace

Runs of multiple whitespace characters are reduced down to a single whitespace
character.  If the whitespace contains any "end of line" (EOL) characters, then
the end result is the I<first> EOL character encountered.  Otherwise, the
result is the first whitespace character in the run.

=item Comments

Comments implementing the "Mac/IE Comment Hack" are collapsed down to the
smallest possible comment that would still implement the hack ("/*\*/" to start
the hack, and "/**/" to end it).

=item Zero Units

Zero Units (e.g. "0px") are reduced down to just "0", as the CSS specification
indicates that the unit is not required when its a zero value.

=back

=head2 Pass 3: Pruning

We then go back through the token list and prune and remove un-necessary
tokens.

=over

=item Whitespace

Wherever possible, whitespace is removed; before+after comment blocks, and
before+after various symbols/sigils.

=item Comments

Comments that either (a) are needed to implement the "Mac/IE Comment Hack", or
that (b) contain the word "copyright" in them are preserved.  B<All> other
comments are removed.

=item Symbols/Sigils

Semi-colons that are immediately followed by a closing brace (e.g. ";}") are
removed; semi-colons are needed to separate multiple declarations, but aren't
required at the end of a group.

=item Everything else

We keep everything else; identifiers, quoted literal strings, symbols/sigils,
etc.

=back

=head2 Pass 4: Re-assembly

Lastly, we go back through the token list and re-assemble it all back into a
single CSS string, which is then returned back to the caller.

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 REPORTING BUGS

Please report bugs via RT
(L<http://rt.cpan.org/Dist/Display.html?Queue=CSS::Minifier::XS>),
and be sure to include the CSS that you're having troubles minifying.

=head1 COPYRIGHT

Copyright (C) 2007-, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
license as Perl itself.

=head1 SEE ALSO

C<CSS::Minifier>.

=cut
