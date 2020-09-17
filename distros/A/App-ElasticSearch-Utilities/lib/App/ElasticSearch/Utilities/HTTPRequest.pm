package App::ElasticSearch::Utilities::HTTPRequest;
# ABSTRACT: Allow for strange content elements for Elasticsearch APIs


use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '7.8'; # VERSION

use JSON::MaybeXS;
use Ref::Util qw(is_ref is_arrayref is_hashref);

use parent 'HTTP::Request';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->header('Accept' => 'application/json');

    return $self;
}

sub content {
    my ($self,$body) = @_;

    if( is_arrayref($body) ) {
        # Bulk does this
        my @body;
        foreach my $entry (@{ $body }) {
            push @body, ref $entry ? encode_json($entry) : $entry;
        }
        $body = join '', map { "$_\n" } @body;
        $self->header('Content-Type' => 'application/x-ndjson');
    }
    elsif( is_hashref($body) ) {
        $self->header('Content-Type' => 'application/json');
        $body = encode_json($body);
    }
    elsif( is_ref($body) ) {
        # We can't handle this
        warn sprintf "Invalid reference type '%s' passed to %s, discarding.", ref($body), __PACKAGE__;
        undef($body);
    }

    $self->{_content} = $body if defined $body;

    return $self->{_content};
}

1;

__END__

=pod

=head1 NAME

App::ElasticSearch::Utilities::HTTPRequest - Allow for strange content elements for Elasticsearch APIs

=head1 VERSION

version 7.8

=head1 SYNOPSIS

This subclasses HTTP::Request and handles the B<content()> method invocation
to allow passing content as expected by the Elasticsearch API.  You should not
use this module in your code.

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
