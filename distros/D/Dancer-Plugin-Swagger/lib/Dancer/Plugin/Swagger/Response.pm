package Dancer::Plugin::Swagger::Response;
our $AUTHORITY = 'cpan:YANICK';
$Dancer::Plugin::Swagger::Response::VERSION = '0.2.0';
use Dancer;

use Moo;

extends 'Dancer::Response';

use overload '&{}' => \&gen_from_example,
                '""' => sub { (shift)->{status} };

has desc    => ( is => 'ro' );
has example => ( is => 'ro' );

sub fill_example {
    my($var,$struct) = @_;

    if( ref $struct eq 'ARRAY' ) {
        return [ map { fill_example( $var, $_ ) } @$struct ]
    }

    if( ref $struct eq 'HASH' ) {
        return { map { fill_example( $var, $_ ) } %$struct }
    }

    if( $struct =~ /^\$\{(\w+):.*\}$/ ) {
        die "missing variable '$1'" unless exists $var->{$1};
        return $var->{$1};
    }

    return $struct;
}

sub gen_from_example {
    my $self = shift;
    sub {
        my %var = @_;

        my $content = fill_example( \%var, $self->example );

        status( $self->status // 200 );
        $content;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::Swagger::Response

=head1 VERSION

version 0.2.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
