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

package App::Magpie::App::Command;
# ABSTRACT: base class for sub-commands
$App::Magpie::App::Command::VERSION = '2.010';
use App::Cmd::Setup -command;
use Moose;
use MooseX::Has::Sugar;

use App::Magpie;
use App::Magpie::Logger;


# -- public attributes


has magpie => (
    ro, lazy,
    isa     => "App::Magpie",
    default => sub { App::Magpie->new; }
);


# -- public methods


sub log_init {
    my ($self, $opts) = @_;

    my $logger =App::Magpie::Logger->instance;
    $logger->more_verbose for 0 .. $opts->{verbose};
    $logger->less_verbose for 0 .. $opts->{quiet};
}



sub verbose_options {
    my $logger    = App::Magpie::Logger->instance;
    my $log_level = ( qw{ quiet normal debug } )[ $logger->log_level ];
    return (
        [ "Logging options (default log level: $log_level)" ],
        [ 'verbose|v+' => "be more verbose (can be repeated)",  {default=>0} ],
        [ 'quiet|q+'   => "be less versbose (can be repeated)", {default=>0} ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::App::Command - base class for sub-commands

=head1 VERSION

version 2.010

=head1 DESCRIPTION

This module is the base class for all sub-commands. It provides some
methods to control logging.

=head1 ATTRIBUTES

=head2 magpie

The L<App::Magpie> object responsible for the real operations.

=head1 METHODS

=head2 log_init

    $cmd->log_init($opts);

Initializes the C<logger> attribute of C<magpie> depending on the
value of verbose options.

=head2 verbose_options

    my @opts = $self->verbose_options;

Return an array of verbose options to be used in a command's C<opt_spec>
method. Those options can then be used by C<log_init()>.

=for Pod::Coverage::TrustPod description
    opt_spec
    execute

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
