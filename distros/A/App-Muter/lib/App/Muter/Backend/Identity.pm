package App::Muter::Backend::Identity;
# ABSTRACT: an identity transform for App::Muter
$App::Muter::Backend::Identity::VERSION = '0.003000';
use strict;
use warnings;

our @ISA = qw/App::Muter::Backend/;

sub encode {    ## no critic(RequireArgUnpacking)
    return $_[1];
}

{
    no warnings 'once';    ## no critic(ProhibitNoWarnings)

    *decode       = \&encode;
    *encode_final = \&encode;
    *decode_final = \&encode;
}

App::Muter::Registry->instance->register(__PACKAGE__);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Muter::Backend::Identity - an identity transform for App::Muter

=head1 VERSION

version 0.003000

=head1 AUTHOR

brian m. carlson <sandals@crustytoothpaste.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016–2017 by brian m. carlson.

This is free software, licensed under:

  The MIT (X11) License

=cut
