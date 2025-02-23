package Astro::ADS::Role::ResultMapper;
# ABSTRACT: Maps the JSON structure returned from an ADS search query
# to a Astro::ADS::Result object
$Astro::ADS::Role::ResultMapper::VERSION = '1.90';
use Moo::Role;
use strictures 2;

use Astro::ADS::Paper;
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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::ADS::Role::ResultMapper - Maps the JSON structure returned from an ADS search query

=head1 VERSION

version 1.90

=head1 DESCRIPTION

Takes the Mojo Response JSON and maps it to the Result object parameters,
returning a Result object with Papers in the B<docs> attribute.

=head1 SYNOPSIS 

    use Moo;
    extends 'Astro::ADS';
    with 'Astro::ADS::Role::ResultMapper';

    ...
    return $self->parse_response( $json );

=head1 AUTHOR

Boyd Duffee <duffee@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Boyd Duffee.

This is free software, licensed under:

  The MIT (X11) License

=cut
