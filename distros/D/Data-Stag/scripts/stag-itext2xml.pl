#!/usr/local/bin/perl -w

use Data::Stag qw(:all);
use Data::Stag::ITextParser;
use Data::Stag::XMLWriter;
use Data::Stag::Base;
my $p = Data::Stag::ITextParser->new;
my $h = Data::Stag::Base->new;
#my $h = Data::Stag::XMLWriter->new;
$p->handler($h);
foreach my $f (@ARGV) {
    $p->parse($f);
    print $h->tree->xml;
}

__END__

=head1 NAME

stag-itext2xml - converts between stag formats

=head1 DESCRIPTION

Converts from itext to xml format.

=head1 SEE ALSO

L<Data::Stag>

=cut
