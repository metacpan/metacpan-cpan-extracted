package App::ElasticSearch::Utilities::QueryString::BareWords;
# ABSTRACT: Mostly fixing case and tracking dangling words

use strict;
use warnings;

our $VERSION = '7.8'; # VERSION

use CLI::Helpers qw(:output);
use namespace::autoclean;

use Moo;
with 'App::ElasticSearch::Utilities::QueryString::Plugin';

sub _build_priority { 1; }

my %BareWords = (
    and => { query_string => 'AND', invert => 0, dangles => 1 },
    or  => { query_string => 'OR',  invert => 0, dangles => 1 },
    not => { query_string => 'NOT', invert => 1, dangles => 1 },
);


sub handle_token {
    my ($self,$token) = @_;

    debug(sprintf "%s - evaluating token '%s'", $self->name, $token);
    return exists $BareWords{lc $token} ? [$BareWords{lc $token}] : undef;
}

# Return True;
1;

__END__

=pod

=head1 NAME

App::ElasticSearch::Utilities::QueryString::BareWords - Mostly fixing case and tracking dangling words

=head1 VERSION

version 7.8

=head1 SYNOPSIS

=head2 App::ElasticSearch::Utilities::QueryString::Barewords

The following barewords are transformed:

    or => OR
    and => AND
    not => NOT

=for Pod::Coverage handle_token

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
