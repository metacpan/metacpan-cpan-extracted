package Acme::Kensiro;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = 'kensiro';

our $VERSION = '0.16';

use 5.008001;

sub kensiro {
    my $src = shift;

    my $dst = reverse(unpack("b32",  pack("L", $src)));
    $dst =~ s/^0*(.+)/$1/;
    $dst =~ s/0/た/g;
    $dst =~ s/1/あ/g;

    return $dst;
}

1;
__END__

=for stopwords kensiro sinsu

=encoding utf-8

=head1 NAME

Acme::Kensiro - kensiro-sinsu

=head1 SYNOPSIS

    use Acme::Kensiro;
    kensiro(16); # => あたたたた

=head1 DESCRIPTION

kensiro-sinsu.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 SEE ALSO

L<http://www.asahi-net.or.jp/~rc4t-ishr/kensiro.html>

=head1 AUTHOR

Tokuhiro Matsuno  C<< <tokuhirom __@__ gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Tokuhiro Matsuno C<< <tokuhiro __at__ mobilefactory.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

