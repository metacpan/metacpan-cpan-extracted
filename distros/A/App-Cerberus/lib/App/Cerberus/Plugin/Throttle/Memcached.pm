package App::Cerberus::Plugin::Throttle::Memcached;
$App::Cerberus::Plugin::Throttle::Memcached::VERSION = '0.11';
use strict;
use warnings;
use Cache::Memcached::Fast();

#===================================
sub new {
#===================================
    my ( $class, $conf ) = @_;
    my $cache = Cache::Memcached::Fast->new($conf);
    bless { cache => $cache }, $class;
}

#===================================
sub counts {
#===================================
    my ( $self, %keys ) = @_;
    my %reverse;
    my @ids = values %keys;
    @reverse{@ids} = keys %keys;

    my $result = $self->{cache}->get_multi(@ids);
    my %result = map { $reverse{$_} => $result->{$_} } @ids;
}

#===================================
sub incr {
#===================================
    my ( $self, %keys ) = @_;
    my @set = map [ $_, 1, $keys{$_} ], keys %keys;
    my $result = $self->{cache}->add_multi(@set);
    for ( keys %$result ) {
        $self->{cache}->incr($_)
            unless $result->{$_};
    }

}

1;

# ABSTRACT: A Memcached backend for the Throttle plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cerberus::Plugin::Throttle::Memcached - A Memcached backend for the Throttle plugin

=head1 VERSION

version 0.11

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
