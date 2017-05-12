package App::Zapzi::Folders;
# ABSTRACT: routines to access Zapzi folders


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(is_system_folder get_folder add_folder delete_folder
                    folders_summary);

use App::Zapzi;
use Carp;


sub is_system_folder
{
    my ($name) = @_;

    return $name eq 'Inbox' || $name eq 'Archive';
}


sub get_folder
{
    my ($name) = @_;

    my $rs = _folders()->find({name => $name});
    return $rs;
}


sub add_folder
{
    my ($name) = @_;
    croak 'New folder name not provided' unless $name;

    if (get_folder($name) || ! _folders()->create({name => $name}))
    {
        croak("Could not add folder $name");
    }
}


sub delete_folder
{
    my ($name) = @_;
    my $folder = get_folder($name);

    # Ignore if the folder does not exist
    return 1 unless $folder;

    return $folder->delete;
}


sub folders_summary
{
    my $rs = _folders()->search(undef, {prefetch => [qw(articles)]});

    my $summary;
    while (my $folder = $rs->next)
    {
        $summary->{$folder->name} = $folder->articles->count;
    }

    return $summary;
}

# Convenience function to get the DBIx::Class::ResultSet object for
# this table.

sub _folders
{
    return App::Zapzi::get_app()->database->schema->resultset('Folder');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Folders - routines to access Zapzi folders

=head1 VERSION

version 0.017

=head1 DESCRIPTION

These routines allow access to Zapzi folders via the database.

=head1 METHODS

=head2 is_system_folder(name)

Returns true if the folder is used by the system eg Inbox.

=head2 get_folder(name)

Returns the database resultset for the folder called C<name>.

=head2 add_folder(name)

Adds a new folder called C<name>. Will return false if it exists
already, otherwise the result of the DB add function.

=head2 delete_folder(name)

Deletes folder C<name> if it exists. Returns the DB result status for
the deletion.

=head2 folders_summary

Returns a ref to a hash where keys are the folder names and value is
the article count.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
