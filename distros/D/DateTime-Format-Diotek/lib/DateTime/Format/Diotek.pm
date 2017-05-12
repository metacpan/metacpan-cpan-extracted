package DateTime::Format::Diotek;
{
  $DateTime::Format::Diotek::VERSION = '0.0.1';
}
# ABSTRACT: parse only YYYYMMDDhhmmss format
use strict;
use warnings;
use DateTime::Format::Builder
(
    parsers => {
        parse_datetime => [
            {
                params => [qw(year month day hour minute second)],
                regex  => qr/^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/,
            }
        ]
    }
);


1;

__END__
=pod

=encoding utf-8

=head1 NAME

DateTime::Format::Diotek - parse only YYYYMMDDhhmmss format

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    use DateTime::Format::Diotek;
    my $dt = DateTime::Format::Diotek->parse_datetime('20120203065530'); # YYYYMMDDhhmmss
    print $dt->ymd; # 2012-02-03
    print $dt->hms; # 06:55:30

=head1 AUTHOR

Hyungsuk Hong <aanoaa@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

