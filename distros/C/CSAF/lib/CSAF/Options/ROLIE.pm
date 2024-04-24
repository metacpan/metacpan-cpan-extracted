package CSAF::Options::ROLIE;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
with 'CSAF::Util::Options';

use constant TRUE  => !!1;
use constant FALSE => !!0;

has csaf_directory => (is => 'rw');
has base_url       => (is => 'rw', trigger => 1, default => 'https://psirt.domain.tld/advisories/csaf');
has feed_filename  => (is => 'rw', default => 'csaf-feed-tlp-white.json');
has feed_id        => (is => 'rw', trigger => 1, default => 'csaf-feed-tlp-white');
has feed_link      => (is => 'rw', default => sub { [] });
has feed_title     => (is => 'rw', default => 'CSAF feed (TLP:WHITE)');
has tlp_label      => (is => 'rw', trigger => 1, default => 'WHITE', coerce => sub { uc $_[0] });

sub _trigger_base_url {
    my $self = shift;
    $self->feed_link([{rel => 'self', href => $self->feed_url}]);
}

sub _trigger_tlp_label {

    my $self = shift;

    $self->feed_id('csaf-feed-tlp-' . lc($self->tlp_label));
    $self->feed_title('CSAF feed (TLP:' . $self->tlp_label . ')');

}

sub _trigger_feed_id {

    my $self = shift;

    $self->feed_filename($self->feed_id . '.json');
    $self->feed_link([{rel => 'self', href => $self->feed_url}]);

}

sub feed_url {
    my $self = shift;
    return join('/', $self->base_url, $self->feed_filename);
}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Options::ROLIE - CSAF::ROLIE::Feed configurator

=head1 SYNOPSIS

    use CSAF::Options::ROLIE;
    my $options = CSAF::Options::ROLIE->new( );

    $options->options->configure(
        feed_id    => 'acme-csaf-feed-tlp-white',
        feed_title => 'ACME Security Advisory CSAF feed (TLP:WHITE)'
        base_url   => 'https://security.acme.tld/advisories/csaf'
    );


=head1 DESCRIPTION

L<CSAF::Options::ROLIE> is a configurator of L<CSAF::ROLIE::Feed>.


=head2 METHODS

L<CSAF::Options::ROLIE> inherits all methods from L<CSAF::Util::Options>.


=head2 ATTRIBUTES

=over

=item csaf_directory

CSAF documents base directory.

=item base_url

The base URL for ROLIE feed (default C<https://psirt.domain.tld/advisories/csaf>).

=item feed_filename

ROLIE feed filename (default C<csaf-feed-tlp-white.json>).

=item feed_id

ROLIE feed ID (default C<csaf-feed-tlp-white> or C<csaf-feed-tlp- + tlp_label>).

=item feed_link

ROLIE feed link (default C<[ rel => 'self', href => feed_url ]>)

=item feed_title

ROLIE feed title (default C<CSAF feed (TLP:WHITE)> or C<CSAF feed (TLP: + tlp_white + )>).

=item feed_url

ROLIE feed URL (default C<base_url + feed_filename>)

=item tlp_label

TLP (Traffic Light Protocol) label (default C<WHITE>).

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

This software is copyright (c) 2023-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
