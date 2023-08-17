package App::Followme::BinaryData;

use 5.008005;
use strict;
use warnings;
use integer;
use lib '../..';

use base qw(App::Followme::FileData);

our $VERSION = "2.03";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($self) = @_;

    return (
            extension => '',
           );
}

#----------------------------------------------------------------------
# Look in the file for the data (stub)

sub fetch_from_file {
    my ($self, $filename) = @_;
    return ();
}

#----------------------------------------------------------------------
# Get a url from a filename

sub get_url {
    my ($self, $filename) = @_;
    
    my $extension = $self->get_extension($filename);
    return $self->filename_to_url($self->{top_directory},
                                  $filename,
                                  $extension);
}

1;

=pod

=encoding utf-8

=head1 NAME

App::Followme::BinaryData - Read metadata from a binary file

=head1 SYNOPSIS

    use App::Followme::BinaryData;
    my $data = App::Followme::BinaryData->new();
    my $html = App::Followme::Template->new('example.htm', $data);

=head1 DESCRIPTION

This module is a stub for binary files whose metadata cannot be read 
from the file.

=head1 METHODS

All data classes are first instantiated by calling new and the object
created is passed to a template object. It calls the build method with an
argument name to retrieve that data item. The retrieve always fails for
a binary file.

=head1 VARIABLES

No variables are retrieved. It is assumed the format is opaque.

=head1 CONFIGURATION

This class has the following configuration variable:

=over 4

=item extension

The file extension of the binary file.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
