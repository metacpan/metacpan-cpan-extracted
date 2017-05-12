package Acme::MetaSyntactic::bible;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::bible - Bible books

=head1 DESCRIPTION

List of bible books (King James version).

=head1 CONTRIBUTOR

Abigail

=head1 CHANGES

=over 4

=item *

2012-10-08 - v1.000

Published in Acme-MetaSyntactic-Themes version 1.022.

=item *

2005-10-24

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
genesis exodus leviticus numbers deuteronomy joshua judges ruth i_samuel
ii_samuel i_kings ii_kings i_chronicles ii_chronicles ezra nehemiah esther
job psalms proverbs ecclesiastes song_of_solomon isaiah jeremiah
lamentations ezekiel daniel hosea joel amos obadiah jonah micah nahum
habakkuk zephaniah haggai zechariah malachi

matthew mark luke john acts_of_the_apostles romans i_corinthians
ii_corinthians galatians ephesians philippians colossians i_thessalonians
ii_thessalonians i_timothy ii_timothy titus philemon hebrews james
i_peter ii_peter i_john ii_john iii_john jude revelation
