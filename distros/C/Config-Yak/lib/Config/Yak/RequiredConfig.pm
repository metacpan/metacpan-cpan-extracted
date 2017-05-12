package Config::Yak::RequiredConfig;
{
  $Config::Yak::RequiredConfig::VERSION = '0.23';
}
BEGIN {
  $Config::Yak::RequiredConfig::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a role to provide an required config attribute

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose::Role;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
# has ...
has 'config' => (
    'is'       => 'rw',
    'isa'      => 'Config::Yak',
    'required' => 1,
);

# with ...
# initializers ...
# requires ...

# your code here ...

no Moose::Role;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Config::Yak::RequiredConfig - a role to provide an required config attribute

=head1 SYNOPSIS

    use Moose;
    with 'Config::Yak::RequiredConfig';

=head1 DESCRIPTION

This role will require a Config::Yak object.

=head1 NAME

Config::Yak::RequiredConfig - A role which requires a Config::Yak object

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
