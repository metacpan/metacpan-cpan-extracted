package App::BitBucketCli::Repository;

# Created on: 2015-09-16 16:41:19
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

our $VERSION = 0.007;

extends qw/App::BitBucketCli::Base/;

has [qw/
    state
    slug
    name
/] => (
    is  => 'rw',
);

sub self {
    my ($self) = @_;
    return $self->links->{self}[0]{href};
}

1;

__END__

=head1 NAME

App::BitBucketCli::Repository - Stores details of a repository

=head1 VERSION

This documentation refers to App::BitBucketCli::Repository version 0.007

=head1 SYNOPSIS

   use App::BitBucketCli::Repository;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<self ()>

Returns the "self" url.

=head2 C<TO_JSON ()>

Used by L<JSON::XS> for dumping the object

=head1 ATTRIBUTES

=head2 id

=head2 link

=head2 links

=head2 state

=head2 slug

=head2 name

The name of the repository

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
