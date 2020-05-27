package Data::AnyXfer::Elastic::Error;

use strict;
use warnings;

use Carp ();

=head1 NAME

Data::AnyXfer::Elastic::Error

=head1 SYNOPSIS

    eval { $index->search( body => {}) };
    
    # handle the output
    my $string = Data::AnyXfer::Elastic::Error->format($@);

    # throw errors
    Data::AnyXfer::Elastic::Error->croak($@);
    Data::AnyXfer::Elastic::Error->carp($@);

=head1 DESCRIPTION

This module is designed to be a helper to handle Elasticsearch errors. Rather
than outputting a large stacktrace these methods output something nicer.

Full error logging are forwared to /var/log/elasticsearch/ anyway.

=cut

sub croak { Carp::croak shift->format(@_) }
sub carp  { Carp::carp shift->format(@_) }

sub format {
    my ( $class, $error ) = @_;

    # not an elasticsearch error - don't know how to handle
    return $error
        unless UNIVERSAL::isa( $error, 'Search::Elasticsearch::Error' );

    # there should always be a type and text
    my $type = $error->{type};
    my $text = $error->{text};
    my $path = $error->{vars}->{request}->{path} || '-';

    my $message = 'Elasticsearch %s error generated (Path: %s ). Error: %s';
    my $string = sprintf $message, lc $type, $path, $text;

    return $string;
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

