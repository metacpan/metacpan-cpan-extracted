package App::showreverse;
$App::showreverse::VERSION = '0.0.3';
# ABSTRACT: given an ip block in cidr notation, show all reverse IP lookups
#
use strict;
use warnings;
use autodie qw( :default );

use 5.10.0;

use base qw(App::Cmd::Simple);

use Net::CIDR 0.18 qw/cidr2octets cidrvalidate/;
use Net::DNS 1.01;
use Net::Works::Network 0.21;

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} < 1 ) {
        $self->usage_error(
            'Try #sr showreverse <space separated cidr blocks>');
    }
    my @blocks = @{$args};
    for my $block (@blocks) {
        unless ( cidrvalidate($block) ) {
            $self->usage_error("$block is not a valid cidr block");
        }
    }
    return 1;
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    my @blocks = @{$args};

    my $resolver = Net::DNS::Resolver->new;
    $resolver->persistent_udp(1);

    for my $block (@blocks) {
        my $n = Net::Works::Network->new_from_string( string => $block );
        my $i = $n->iterator;
        while ( my $ip = $i->() ) {
            my $reverse
                = join( '.', reverse( split /\./, $ip ) ) . '.in-addr.arpa';
            if ( my $ap = $resolver->query( $reverse, 'PTR' ) ) {
                for my $pa ( $ap->answer ) {
                    say "$ip => " . $pa->ptrdname;
                }
            }
            else {
                say "$ip => NXDOMAIN";
            }
        }
    }

    return 1;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::showreverse - given an ip block in cidr notation, show all reverse IP lookups

=head1 VERSION

version 0.0.3

=head1 AUTHOR

Kevin Phair <phair.kevin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Kevin Phair.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
