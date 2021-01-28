package CSS::Struct;

use strict;
use warnings;

our $VERSION = 0.04;

1;

__END__

=pod

=encoding utf8

=head1 NAME

CSS::Struct - Struct oriented CSS manipulation.

=head1 DESCRIPTION

This class is for description of CSS::Struct concept. There is specification of
structure. Concrete implementations are in L<CSS::Struct::Output::Raw> and
L<CSS::Struct::Output::Indent>. Abstract class for other implementations is in
L<CSS::Struct::Output>.

=head1 STRUCTURE

 Perl structure:

 Reference to array.
 [type, data]

 Types:
 a - At-rules.
 c - Comment.
 d - Definition.
 e - End of selector.
 i - Instruction.
 r - Raw section.
 s - Selector.

 Data:
 a - $at_rule, $file
 c - @comment
 d - $key, $value
 e - No argument.
 i - $target, $code
 r - @raw_data
 s - $selector

=head1 EXAMPLE

 use strict;
 use warnings;

 use CSS::Struct::Output::Raw;
 use CSS::Struct::Output::Indent;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 indent\n";
         exit 1;
 }
 my $indent = $ARGV[0];

 my $css;
 my %params = (
         'output_handler' => \*STDOUT,
 );
 if ($indent) {
         $css = CSS::Struct::Output::Indent->new(%params);
 } else {
         $css = CSS::Struct::Output::Raw->new(%params);
 }

 $css->put(['s', 'selector#id']);
 $css->put(['s', 'div div']);
 $css->put(['s', '.class']);
 $css->put(['d', 'weight', '100px']);
 $css->put(['d', 'font-size', '10em']);
 $css->put(['e']);

 # Flush to output.
 $css->flush;
 print "\n";

 # Output without argument:
 # Usage: __SCRIPT__ indent

 # Output with argument 0:
 # selector#id,div div,.class{weight:100px;font-size:10em;}

 # Output with argument 1:
 # selector#id, div div, .class {
 #         weight: 100px;
 #         font-size: 10em;
 # }

=head1 SEE ALSO

=over

=item L<CSS::Struct::Output>

Base class for CSS::Struct::Output::*.

=item L<CSS::Struct::Output::Raw>

Raw printing 'CSS::Struct' structure to CSS code.

=item L<CSS::Struct::Output::Indent>

Indent printing 'CSS::Struct' structure to CSS code.

=back

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2007-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
