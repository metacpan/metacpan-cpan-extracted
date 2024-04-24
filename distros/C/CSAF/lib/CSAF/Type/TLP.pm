package CSAF::Type::TLP;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
extends 'CSAF::Type::Base';

my @LABELS = (qw[AMBER GREEN RED WHITE]);

has label => (
    is      => 'rw',
    default => 'WHITE',
    isa     => sub {
        my $test = shift;
        Carp::croak 'Unknown TLP label' unless grep { $test eq $_ } @LABELS;
    },
    coerce => sub { uc $_[0] }
);

has url => (is => 'rw', default => 'https://www.first.org/tlp/');

sub TO_CSAF {

    my $self = shift;

    my $output = {};

    $output->{label} = $self->label;
    $output->{url}   = $self->url if ($self->url);

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::TLP

=head1 SYNOPSIS

    use CSAF::Type::TLP;
    my $type = CSAF::Type::TLP->new( );


=head1 DESCRIPTION

Traffic Light Protocol (TLP) (L<CSAF::Type::TLP>) with the mandatory property Label (C<label>) and
the optional property URL (C<url>) provides details about the TLP classification of the document.


=head2 METHODS

L<CSAF::Type::TLP> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->label

The C<label> provides the TLP label of the document.

    $csaf->document->distribution->tlp->label('AMBER');

Valid values are:

    AMBER
    GREEN
    RED
    WHITE

=item $type->url

The C<url> provides a URL where to find the textual description of the TLP version which is used in this document.

    $csaf->document->distribution->tpl->url('https://www.us-cert.gov/tlp');

    $csaf->document->distribution->tpl->url('https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Kritis/Merkblatt_TLP.pdf');

The default value is the URL to the definition by FIRST:

    https://www.first.org/tlp/

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
