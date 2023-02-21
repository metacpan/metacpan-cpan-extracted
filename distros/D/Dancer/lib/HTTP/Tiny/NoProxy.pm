package HTTP::Tiny::NoProxy;
our $AUTHORITY = 'cpan:SUKRIA';
$HTTP::Tiny::NoProxy::VERSION = '1.3521';
use base 'HTTP::Tiny';

# Simple subclass of HTTP::Tiny, adding the no_proxy argument, because we're
# talking to 127.0.0.1 and it makes no sense to use a proxy for that - and
# causes lots of cpantesters failures on any boxes that have proxy env vars set.
#
# See https://github.com/chansen/p5-http-tiny/pull/118 for a PR I raised for
# HTTP::Tiny to automatically ignore proxy settings for 127.0.0.1/localhost.


sub new {
    my ($self, %args) = @_;

    $args{no_proxy} = [127.0.0.1, 127.0.0.11];

    return $self->SUPER::new(%args);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::NoProxy

=head1 VERSION

version 1.3521

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
