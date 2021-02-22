package Class::DBI::Plugin::TO_JSON;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;

###############################################################################
# Export our methods.
###############################################################################
use base qw( Exporter );
our @EXPORT = qw(
    TO_JSON
    );

###############################################################################
# Version number.
###############################################################################
our $VERSION = '0.04';

###############################################################################
# Subroutine:   TO_JSON()
###############################################################################
# Turns the CDBI data record into a HASHREF suitable for use with 'JSON::XS'
###############################################################################
sub TO_JSON {
    my $self = shift;

    # get all of our data
    my @cols = $self->columns();
    my %data;
    @data{@cols} = $self->get(@cols);

    # deflate the data, giving us JUST a hash of the raw data
    foreach my $column (@cols) {
        my $name = $column->name();
        $data{$name} = $self->_deflated_column($column, $data{$name});
    }

    # return the data back to the caller.
    return \%data;
}

1;

=head1 NAME

Class::DBI::Plugin::TO_JSON - Help integrate Class::DBI with JSON::XS

=head1 SYNOPSIS

  package MY::DB;
  use base qw(Class::DBI);
  use Class::DBI::Plugin::TO_JSON;

=head1 DESCRIPTION

C<Class::DBI::Plugin::TO_JSON> helps integrate C<Class::DBI> with C<JSON::XS>,
by implementing a C<TO_JSON()> method which turns your data record into a
plain/raw HASHREF with no inflated values.

=head1 METHODS

=over

=item TO_JSON()

Turns the C<Class::DBI> data record into a HASHREF suitable for use with
C<JSON::XS>

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2008, Graham TerMarsch.  All rights reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<JSON::XS>,
L<Class::DBI>.

=cut
