package App::Zapzi::Distribute;
# ABSTRACT: distribute published eBooks to a destination


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Module::Find 0.11;
our @_plugins;
BEGIN { @_plugins = sort(Module::Find::useall('App::Zapzi::Distributors')); }

use App::Zapzi;
use Carp;
use Moo;


has file => (is => 'ro', required => 1);


has method => (is => 'ro');


has destination => (is => 'ro');


has completion_message => (is => 'rwp', default => "");


sub distribute
{
    my $self = shift;

    # Do nothing if no distributor defined
    return 1 if ! $self->method || lc($self->method) eq 'nothing';

    my $module = $self->_find_module();
    if (! defined $module)
    {
        $self->_set_completion_message(
            "Distribution method '" . $self->method . "' not defined");
        return;
    }

    my $rc = $module->distribute();
    $self->_set_completion_message($module->completion_message);
    return $rc;
}

sub _find_module
{
    my $self = shift;

    for (@_plugins)
    {
        if (lc($self->method) eq lc($_->name))
        {
            return $_->new(file => $self->file,
                           destination => $self->destination);
        }
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Distribute - distribute published eBooks to a destination

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class takes a published eBook and distributes it. The
distribution method can either be set in the class attributes (eg
coming from the command line) or via config variables. Default if
neither is set is to not distribute the eBook further.

=head1 ATTRIBUTES

=head2 file

Completed eBook file to distribute.

=head2 method

Method to distribute file. If set, must be one of the defined
Distributer roles.

=head2 destination

Where to send the file to. The distribution role will validate this.

=head2 completion_message

Message from the distributer after completion - should be set in both
error and success cases, but blank if no distributer has been invoked.

=head1 METHODS

=head2 distribute

Distributes the file according to the method set on the class or the
default configured distribution. Returns 1 if OK (including no
distributor defined), undef on failure.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
