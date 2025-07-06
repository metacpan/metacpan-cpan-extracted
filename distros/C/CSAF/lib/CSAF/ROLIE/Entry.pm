package CSAF::ROLIE::Entry;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
use CSAF::Util qw(parse_datetime);

has id        => (is => 'rw', required => 1);
has title     => (is => 'rw', required => 1);
has published => (is => 'rw', coerce   => \&parse_datetime);
has updated   => (is => 'rw', required => 1, coerce => \&parse_datetime);
has format    => (is => 'rw', required => 1);
has link      => (is => 'rw', required => 1);
has content   => (is => 'rw', required => 1);
has summary   => (is => 'rw');

sub TO_JSON {

    my $self = shift;

    my $json = {
        id        => $self->id,
        title     => $self->title,
        published => $self->published->datetime,
        updated   => $self->updated->datetime,
        format    => $self->format,
        link      => $self->link,
        content   => $self->content
    };

    $json->{summary} = $self->summary if ($self->summary);

    return $json;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::ROLIE::Feed::Entry - ROLIE feed entry

=head1 SYNOPSIS

    use CSAF::ROLIE::Feed::Entry;
    my $entry = CSAF::ROLIE::Feed::Entry->new( );


=head1 DESCRIPTION

ROLIE feed entry for L<CSAF::ROLIE::Feed>.

=head2 METHODS

=over

=item $entry->id

=item $entry->title

=item $entry->published

=item $entry->updated

=item $entry->link

=item $entry->content

=item $entry->summary

=item $entry->TO_JSON

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CSAF/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CSAF>

    git clone https://github.com/giterlizzi/perl-CSAF.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
