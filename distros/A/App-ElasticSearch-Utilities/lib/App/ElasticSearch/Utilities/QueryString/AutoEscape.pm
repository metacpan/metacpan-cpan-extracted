package App::ElasticSearch::Utilities::QueryString::AutoEscape;
# ABSTRACT: Provides a prefix of '=' to use the term filter

use strict;
use warnings;

our $VERSION = '7.8'; # VERSION

use CLI::Helpers qw(:output);
use Const::Fast;
use namespace::autoclean;

use Moo;
with 'App::ElasticSearch::Utilities::QueryString::Plugin';

sub _build_priority { 5; }


sub handle_token {
    my ($self,$token) = @_;

    debug(sprintf "%s - evaluating token '%s'", $self->name, $token);
    if( $token =~ /^=(.*)$/ ) {
        my ($f,$v) = split /:/, $1, 2;
        return { condition => { term => { $f => $v } }};
    }

    return;
}

# Return True;
1;

__END__

=pod

=head1 NAME

App::ElasticSearch::Utilities::QueryString::AutoEscape - Provides a prefix of '=' to use the term filter

=head1 VERSION

version 7.8

=head1 SYNOPSIS

=head2 App::ElasticSearch::Utilities::QueryString::AutoEscape

Provide an '=' prefix to a query string parameter to promote that parameter to a C<term> filter.

This allows for exact matches of a field without worrying about escaping Lucene special character filters.

E.g.:

    user_agent:"Mozilla/5.0 (iPhone; CPU iPhone OS 12_1_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"

Is evaluated into a weird query that doesn't do what you want.   However:

    =user_agent:"Mozilla/5.0 (iPhone; CPU iPhone OS 12_1_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"

Is translated into:

    { term => { user_agent => "Mozilla/5.0 (iPhone; CPU iPhone OS 12_1_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1" } }

Which provides an exact match to the term in the query.

=for Pod::Coverage handle_token

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
