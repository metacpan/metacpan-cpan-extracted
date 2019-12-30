package App::HomeBank2Ledger::Util;
# ABSTRACT: Miscellaneous utility functions

use warnings;
use strict;

use Exporter qw(import);

our $VERSION = '0.007'; # VERSION

our @EXPORT_OK = qw(commify rtrim);


sub commify {
    my $num   = shift;
    my $comma = shift || ',';

    my $str = reverse $num;
    $str =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1$comma/g;

    return scalar reverse $str;
}


sub rtrim {
    my $str = shift;
    $str =~ s/\h+$//;
    return $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::HomeBank2Ledger::Util - Miscellaneous utility functions

=head1 VERSION

version 0.007

=head1 FUNCTIONS

=head2 commify

    $commified = commify($num);
    $commified = commify($num, $comma_char);

Just another commify subroutine.

=head2 rtrim

    $trimmed_str = rtrim($str);

Right-trim a string.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/homebank2ledger/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Charles McGarvey.

This is free software, licensed under:

  The MIT (X11) License

=cut
