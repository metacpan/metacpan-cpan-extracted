package App::Zapzi::Distributors::Copy;
# ABSTRACT: distribute a published eBook by copying the file somewhere


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use Moo;
use App::Zapzi;
use Path::Tiny;

with 'App::Zapzi::Roles::Distributor';


sub name
{
    return 'Copy';
}


sub distribute
{
    my $self = shift;

    eval { path($self->file)->copy($self->destination) };
    if (! $@)
    {
        $self->_set_completion_message("File copied to '" .
                                       $self->destination .
                                       "' successfully.");
        return 1;
    }
    else
    {
        $self->_set_completion_message("Error copying file to '" .
                                       $self->destination .
                                       "': $!.");
        return 0;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Distributors::Copy - distribute a published eBook by copying the file somewhere

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class copies a published eBook. The destination passed in can
either be a directory, in which case the file will be copied there
with the same filename as the original, or a filename, in which case
the file will be copied to that name.

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
