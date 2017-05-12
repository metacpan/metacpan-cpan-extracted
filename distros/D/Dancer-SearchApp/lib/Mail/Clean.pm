package Mail::Clean;
use strict;
use Exporter 'import';
use vars qw($VERSION);
$VERSION = '0.06';

use vars qw(@EXPORT_OK);
@EXPORT_OK = qw( clean_subject );

=head1 NAME

Mail::Clean - clean up mail parts

=cut

use vars qw(%subject_prefixes);

# https://en.wikipedia.org/wiki/List_of_email_subject_abbreviations
%subject_prefixes = (
    'Re:' => 1,
    'Aw:' => 1,
    'Antw.:' => 1,
    'Antwort:' => 1,
    'Fwd:' => 1,
    'Sv:' => 1,
    'Vs:' => 1,
);

=head2 C<< clean_subject( $subject ) >>

Removes the forwarding and in-reply-to prefixes
from mail titles, leaving only what whas hopefully
the original mail title.

=cut

sub clean_subject {
    my( $subject ) = @_;
    # This should be cached for perfomance reasons
    my $cleaner = join "|",
                  map { quotemeta($_) }
                  sort { length $b <=> length $a || $a cmp $b }
                  keys %subject_prefixes;
    $subject =~ s/^(?:(?:$cleaner)\s*)+//i;
    $subject
};

1;