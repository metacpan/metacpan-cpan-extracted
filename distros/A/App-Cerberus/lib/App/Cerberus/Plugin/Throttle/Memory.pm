package App::Cerberus::Plugin::Throttle::Memory;
$App::Cerberus::Plugin::Throttle::Memory::VERSION = '0.11';
use strict;
use warnings;

#===================================
sub new {
#===================================
    my $class = shift;
    warn "WARNING: You should not use ".__PACKAGE__." in production\n";
    bless {}, $class;
}

#===================================
sub counts {
#===================================
    my ( $self, %keys ) = @_;
    map { $_ => $self->{ $keys{$_} } } keys %keys;
}

#===================================
sub incr {
#===================================
    my ( $self, %keys ) = @_;
    $self->{$_}++ for keys %keys;
    $self->_expire_old;
}

#===================================
sub _expire_old {
#===================================
    my $self = shift;
    my $now = join '', App::Cerberus::Plugin::Throttle::timestamp();
    for my $key ( keys %$self ) {
        my ($ts) = ( $key =~ m/(\d+)$/ );
        delete $self->{$key}
            if $ts < 0 + substr( $now, 0, length($ts) );
    }
}

1;

# ABSTRACT: A in-memory TESTING ONLY backend for the Throttle plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cerberus::Plugin::Throttle::Memory - A in-memory TESTING ONLY backend for the Throttle plugin

=head1 VERSION

version 0.11

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
