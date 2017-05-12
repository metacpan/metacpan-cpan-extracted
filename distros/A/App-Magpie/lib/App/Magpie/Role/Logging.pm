#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::Role::Logging;
# ABSTRACT: sthg that can log
$App::Magpie::Role::Logging::VERSION = '2.010';
use Moose::Role;
use MooseX::Has::Sugar;

use App::Magpie::Logger;


# -- public attributes

  
has logger => (
    ro, lazy,
    isa     => "App::Magpie::Logger",
    handles => [ qw{ log log_debug log_fatal } ],
    default => sub { App::Magpie::Logger->instance }
);

 
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Role::Logging - sthg that can log

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    with 'App::Magpie::Role::Logging';
    $self->log_fatal( "die!" );

=head1 DESCRIPTION

This role is meant to provide easy logging for classes consuming it.
Logging itself is done through L<App::Magpie::Logger>.

=head1 ATTRIBUTES

=head2 logger

The C<App::Magpie::Logger> object used for logging.

=head1 METHODS

=head2 log

=head2 log_debug

=head2 log_fatal

Those methods are provided by a L<App::Magpie::Logger> object. Refer to
the corresponding documentation for more information.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
