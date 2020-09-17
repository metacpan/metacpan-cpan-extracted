package App::ElasticSearch::Utilities::QueryString::IP;
# ABSTRACT: Expand IP CIDR Notation to ES ranges

use strict;
use warnings;

our $VERSION = '7.8'; # VERSION

use Net::CIDR::Lite;
use namespace::autoclean;

use Moo;
with 'App::ElasticSearch::Utilities::QueryString::Plugin';

sub _build_priority { 25 }


sub handle_token {
    my ($self,$token) = @_;
    if( my ($term,$match) = split /\:/, $token, 2 ) {
        # These are not 100% accurate IP matchers, but they are fast
        if(     $match =~ m|^\d{1,3}(?:\.\d{1,3}){1,3}(?:/\d+)$|
            or  $match =~ m|^[0-9a-fA-F:]+(?:/\d+)$|
        ) {
            my $cidr = Net::CIDR::Lite->new();
            $cidr->add($match);
            my @range = split /-/, ($cidr->list_range)[0];
            return { condition => { range => { $term => { gte => $range[0], lte => $range[1] } } } };
        }
    }
    return;
}

1;

__END__

=pod

=head1 NAME

App::ElasticSearch::Utilities::QueryString::IP - Expand IP CIDR Notation to ES ranges

=head1 VERSION

version 7.8

=head1 SYNOPSIS

=head2 App::ElasticSearch::Utilities::QueryString::IP

If a field is an IP address uses CIDR Notation, it's expanded to a range query.

    src_ip:10.0/8 => src_ip:[10.0.0.0 TO 10.255.255.255]

=for Pod::Coverage handle_token

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
