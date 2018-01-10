package App::BitBucketCli::Links;

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
use App::BitBucketCli::Link;

our $VERSION = 0.003;

has [qw/
    clone
    self
/] => (
    is => 'rw',
);

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;

    my $args
        = !@args     ? {}
        : @args == 1 ? { %{ $args[0] } }
        :              {@args};
    my $arg = {};

    for my $type (keys %{ $args }) {
        $arg->{$type} = [];
        for my $link (@{ $args->{$type} }) {
            push @{ $arg->{$type} }, App::BitBucketCli::Link->new($link);
        }
    }

    return $class->$orig($arg);
};

sub TO_JSON {
    my ($self) = @_;
    return { %{ $self } };
}

1;

__END__

=head1 NAME

App::BitBucketCli::Links - Stores a projects details

=head1 VERSION

This documentation refers to App::BitBucketCli::Links version 0.003

=head1 SYNOPSIS

   use App::BitBucketCli::Links;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<BUILDARGS ()>

=head2 C<TO_JSON ()>

Used by L<JSON::XS> for dumping the object

=head1 ATTRIBUTES

=head2 description

=head2 clone

=head2 self

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
