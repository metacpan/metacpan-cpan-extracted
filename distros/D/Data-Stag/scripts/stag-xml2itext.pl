#!/usr/local/bin/perl -w

use Data::Stag qw(:all);
use Data::Stag::XMLParser;
use Data::Stag::ITextWriter;
my $p = Data::Stag::XMLParser->new;
my $h = Data::Stag::ITextWriter->new;
$p->handler($h);
foreach my $xmlfile (@ARGV) {
    $p->parse($xmlfile);
}
__END__

=head1 NAME

stag-xml2itext - converts between stag formats

=head1 DESCRIPTION

Converts from xml to itext format.

=head1 SEE ALSO

L<Data::Stag>

=cut

