package App::ElasticSearch::Utilities::QueryString::AutoEscape;
# ABSTRACT: Automatically escape characters that have special meaning in
# Lucene

use strict;
use warnings;

our $VERSION = '6.3'; # VERSION

use CLI::Helpers qw(:output);
use Const::Fast;
use namespace::autoclean;

use Moo;
with 'App::ElasticSearch::Utilities::QueryString::Plugin';

const my $special_character_class => qr{[/() ]};

sub _build_priority { 75; }


sub handle_token {
    my ($self,$token) = @_;

    debug(sprintf "%s - evaluating token '%s'", $self->name, $token);
    my $escaped = $token =~ s/($special_character_class)/\\$1/gr;

    # No escaped characters, skip it
    return if $escaped eq $token;

    # Modify the token
    return { query_string => $escaped };
}

# Return True;
1;

__END__

=pod

=head1 NAME

App::ElasticSearch::Utilities::QueryString::AutoEscape - Automatically escape characters that have special meaning in

=head1 VERSION

version 6.3

=head1 SYNOPSIS

=head2 App::ElasticSearch::Utilities::AutoEscape

Escapes characters in the query string that have special meaning in Lucene.

Characters escaped are: ' ', '/', '(', and ')'

=for Pod::Coverage handle_token

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
