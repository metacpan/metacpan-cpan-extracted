package Astro::ADS::Role::ResultMapper;
$Astro::ADS::Role::ResultMapper::VERSION = '1.92';
use Moo::Role;
use strictures 2;

use Astro::ADS::Paper;
use Astro::ADS::QTree;
use Astro::ADS::Result;

sub parse_response {
    my ($self, $json) = @_;

    unless ($json && exists $json->{responseHeader}) {
        warn 'No response to parse';
        return;
    }
    # re-map wanted hash keys
    my $result_params;
    @{$result_params}{ qw<q rows fl> } = @{$json->{responseHeader}{params}}{ qw<q rows fl> };
    $result_params->{status} = @{$json->{responseHeader}}{ status };
    @{$result_params}{ qw<numFound start> } = @{$json->{response}}{ qw<numFound start> };
    $result_params->{numFoundExact} = $json->{response}{numFoundExact} ? 1 : 0;

    my @papers;
    for my $paper ( @{$json->{response}->{docs}} ) {
        push @papers, Astro::ADS::Paper->new( $paper );
    }
    $result_params->{docs} = \@papers if @papers;

    return Astro::ADS::Result->new( $result_params );
}

sub parse_qtree_response {
    my ($self, $response) = @_;

    my $json = $response->json;
    unless ($json && exists $json->{responseHeader}) {
        warn 'No response to parse';
        return;
    }
    # re-map wanted hash keys
    my $result_params;
    @{$result_params}{ qw<qtime status> } = @{$json->{responseHeader}}{ qw<QTime status> };
    $result_params->{qtree} = $json->{qtree};

    $result_params->{asset} = $response->content->asset;

    return Astro::ADS::QTree->new( $result_params );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Astro::ADS::Role::ResultMapper - Maps the JSON structure returned from an ADS search query
to an Astro::ADS::Result object

=head1 VERSION

version 1.92

=head1 SYNOPSIS 

    use Moo;
    extends 'Astro::ADS';
    with 'Astro::ADS::Role::ResultMapper';

    ...
    return $self->parse_response( $json );

=head1 DESCRIPTION

=head2 parse_response

Takes the Mojo Response JSON and maps it to the Result object parameters,
returning a Result object with Papers in the B<docs> attribute.

=head2 parse_qtree_response

Takes the Mojo Response and maps it to the QTree object parameters,
allocating the JSON fields to attributes and the C<content> to the C<asset>
attribute to allow use of the Mojo::Asset::move_to function.

This interface is subject to change up to v2.0 to discover the best way
to use the returned value.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Boyd Duffee.

This is free software, licensed under:

  The MIT (X11) License

=cut
