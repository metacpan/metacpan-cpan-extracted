package ARGV::JSON;
use 5.008005;
use strict;
use warnings;
use JSON;

our $VERSION = '0.01';

our $JSON = JSON->new->utf8;
our @Data;

sub import {
    local $/;

    while (local $_ = <>) {
        $JSON->incr_parse($_);

        while (my $datum = $JSON->incr_parse) {
            push @Data, $datum;
        }
    }

    tie *ARGV, 'ARGV::JSON::Handle';
}

package
    ARGV::JSON::Handle;
use Tie::Handle;
use parent -norequire => 'Tie::StdHandle';

sub READLINE {
    if (wantarray) {
        return splice @ARGV::JSON::Data;
    } else {
        return shift @ARGV::JSON::Data;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

ARGV::JSON - Parses @ARGV for accessing JSON via C<< <> >>

=head1 SYNOPSIS

    use ARGV::JSON;

    while (<>) {
        # $_ is a decoded JSON here!
    }

Or in one-liner:

    perl -MARGV::JSON -anal -E 'say $_->{foo}->{bar}' a.json b.json

=head1 DESCRIPTION

ARGV::JSON parses each input from C<< @ARGV >> and enables to access
the JSON data structures via C<< <> >>.

Each C<< readline >> call to C<< <> >> (or C<< <ARGV> >>) returns a
hashref or arrayref or something that the input serializes in the
JSON format.

=head1 SEE ALSO

L<ARGV::URL>.

=head1 LICENSE

Copyright (C) motemen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=cut

