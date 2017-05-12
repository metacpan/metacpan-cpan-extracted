package App::Standby::Cmd;
$App::Standby::Cmd::VERSION = '0.04';
BEGIN {
  $App::Standby::Cmd::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Command base class

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
extends 'MooseX::App::Cmd';
# has ...
# with ...
# initializers ...

# your code here ...

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Standby::Cmd - Command base class

=head1 SYNOPSIS

    use App::Standby::Cmd;
    my $Cmd = App::Standby::Cmd::->new();

=head1 DESCRIPTION

This class is the base class for any command implemented by its subclasses.

It is a mere requirement by App::Cmd. Don't mess with it.

=head1 NAME

App::Standby::Cmd - Command base class

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
