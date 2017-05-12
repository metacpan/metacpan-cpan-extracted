package App::Zapzi::Distributors::Script;
# ABSTRACT: distribute a published eBook by running a script


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use Moo;
use App::Zapzi;

with 'App::Zapzi::Roles::Distributor';


sub name
{
    return 'Script';
}


sub distribute
{
    my $self = shift;

    unless (-x $self->destination)
    {
        $self->_set_completion_message("Script does not exist");
        return 0;
    }

    open my $pipe, '-|', $self->destination, $self->file
        or return 0;

    my $message;
    while (<$pipe>)
    {
        $message .= $_;
    }

    $self->_set_completion_message($message);
    close $pipe;
    return $? == 0 ? 1 : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Distributors::Script - distribute a published eBook by running a script

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class runs a script on a completed eBook. The filename is passed
to the script as the first parameter. The script should return 0 on
success or any other code as failure. Any output from the script will
be passed back to the caller in the completion message.

=head1 METHODS

=head2 name

Name of distributor visible to user.

=head2 distribute

Distribute the file. Returns 1 if OK, undef if failed.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
