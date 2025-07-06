package CSAF::Type::ProductIdentificationHelper;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF::Type::Hashes;
use CSAF::Type::GenericURIs;

use URI::PackageURL;

use Moo;
extends 'CSAF::Type::Base';

my $PURL_REGEX = qr{^pkg:[A-Za-z\\.\\-\\+][A-Za-z0-9\\.\\-\\+]*/.+};
my $CPE_REGEX
    = qr{^(cpe:2\.3:[aho\*\-](:(((\?*|\*?)([a-zA-Z0-9\-\._]|(\\[\\\*\?!"#\$%&'\(\)\+,/:;<=>@\[\]\^`\{\|\}~]))+(\?*|\*?))|[\*\-])){5}(:(([a-zA-Z]{2,3}(-([a-zA-Z]{2}|[0-9]{3}))?)|[\*\-]))(:(((\?*|\*?)([a-zA-Z0-9\-\._]|(\\[\\\*\?!"#\$%&'\(\)\+,/:;<=>@\[\]\^`\{\|\}~]))+(\?*|\*?))|[\*\-])){4})|([c][pP][eE]:/[AHOaho]?(:[A-Za-z0-9\._\-~%]*){0,6})$};

has cpe => (is => 'rw', predicate => 1, isa => sub { Carp::croak 'Invalid CPE' if $_[0] !~ /$CPE_REGEX/ },);

has purl => (
    is        => 'rw',
    predicate => 1,
    coerce    => sub { ref($_[0]) eq 'URI::PackageURL' ? $_[0]->to_string : $_[0] },
    isa       => sub { Carp::croak 'Invalid purl' if $_[0] !~ /$PURL_REGEX/ }
);

has hashes => (is => 'rw', trigger => 1, default => sub { CSAF::Type::Hashes->new });

has [qw(sbom_urls serial_numbers skus model_numbers)] => (is => 'rw', predicate => 1, default => sub { [] });

sub _trigger_hashes {

    my ($self) = @_;

    my $hashes = CSAF::Type::Hashes->new;
    $hashes->item(%{$_}) for (@{$self->hashes});

    $self->{hashes} = $hashes;

}

sub x_generic_uris {
    my $self = shift;
    $self->{x_generic_uris} ||= CSAF::Type::GenericURIs->new(@_);
}

sub TO_CSAF {

    my $self = shift;

    my $output = {};

    $output->{cpe}  = $self->cpe  if $self->has_cpe;
    $output->{purl} = $self->purl if $self->has_purl;

    $output->{skus}           = $self->skus           if @{$self->skus};
    $output->{sbom_urls}      = $self->sbom_urls      if @{$self->sbom_urls};
    $output->{serial_numbers} = $self->serial_numbers if @{$self->serial_numbers};
    $output->{model_numbers}  = $self->model_numbers  if @{$self->model_numbers};

    if (@{$self->x_generic_uris->items}) {
        $output->{x_generic_uris} = $self->x_generic_uris;
    }

    if (my $hashes = $self->{hashes}) {
        $output->{hashes} = $hashes->TO_CSAF if ($hashes->size);
    }

    return $output;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Type::ProductIdentificationHelper

=head1 SYNOPSIS

    use CSAF::Type::ProductIdentificationHelper;
    my $type = CSAF::Type::ProductIdentificationHelper->new( );


=head1 DESCRIPTION



=head2 METHODS

L<CSAF::Type::ProductIdentificationHelper> inherits all methods from L<CSAF::Type::Base> and implements the following new ones.

=over

=item $type->cpe

=item $type->hashes

=item $type->model_numbers

=item $type->purl

=item $type->sbom_urls

=item $type->serial_numbers

=item $type->skus

=item $type->x_generic_uris

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
