package Acme::RandomEmoji;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(random_emoji);
our $VERSION = '0.01';

our $EMOJI = ## REPLACE ##;

sub random_emoji { ${ $EMOJI }[ int rand @$EMOJI ] }

1;

__END__

=encoding utf-8

=head1 NAME

Acme::RandomEmoji - pick an emoji randomly

=head1 SYNOPSIS

=for html
<a href="https://raw.githubusercontent.com/shoichikaji/Acme-RandomEmoji/master/author/screenshot.png"><img src="https://raw.githubusercontent.com/shoichikaji/Acme-RandomEmoji/master/author/screenshot.png" alt="screenshot"></a>

=head1 DESCRIPTION

Acme::RandomEmoji picks an emoji randomly.

Emoji data is taken from:

=over 4

=item L<http://unicode.org/Public/emoji/latest/emoji-data.txt>

=item L<http://unicode.org/Public/emoji/latest/emoji-sequences.txt>

=item L<http://unicode.org/Public/emoji/latest/emoji-zwj-sequences.txt>

=back

=head1 SEE ALSO

Full Emoji Data L<http://unicode.org/emoji/charts/full-emoji-list.html>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Note that this library uses emoji-data.txt, emoji-sequences.txt and emoji-zwj-sequences.txt,
which have their own license. Please refer to L<http://www.unicode.org/copyright.html>

=cut
