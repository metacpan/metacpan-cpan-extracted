package App::ElasticSearch::Utilities::QueryString::Underscored;
# ABSTRACT: Extend some _<type>_ queries

use strict;
use warnings;

our $VERSION = '7.8'; # VERSION

use CLI::Helpers qw(:output);
use namespace::autoclean;

use Moo;
with 'App::ElasticSearch::Utilities::QueryString::Plugin';

sub _build_priority { 20; }

my %Underscored = (
    _prefix_ => sub {
        my ($v) = @_;
        my ($field,$text) = split /[:=]/, $v, 2;

        return unless defined $text and length $text;
        return { condition => { prefix => { $field => $text } } }
    },
);


sub handle_token {
    my ($self,$token) = @_;

    debug(sprintf "%s - evaluating token '%s'", $self->name, $token);
    my ($k,$v) = split /:/, $token, 2;

    return unless exists $Underscored{lc $k} and defined $v;

    return $Underscored{lc $k}->($v);
}

# Return True;
1;

__END__

=pod

=head1 NAME

App::ElasticSearch::Utilities::QueryString::Underscored - Extend some _<type>_ queries

=head1 VERSION

version 7.8

=head1 SYNOPSIS

=head2 App::ElasticSearch::Utilities::QueryString::Underscored

This plugin translates some special underscore surrounded tokens into
the Elasticsearch Query DSL.

Implemented:

=head3 _prefix_

Example query string:

    _prefix_:useragent:'Go '

Translates into:

    { prefix => { useragent => 'Go ' } }

=for Pod::Coverage handle_token

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
