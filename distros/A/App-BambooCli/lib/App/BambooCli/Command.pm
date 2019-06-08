package App::BambooCli::Command;

# Created on: 2019-06-03 12:44:38
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Getopt::Alt;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

our $VERSION = version->new('0.0.1');

has [qw/ defaults options /] => (
    is => 'rw',
);

has bamboo => (
    is       => 'rw',
    required => 1,
    handles  => [qw/ config /],
);

sub get_sub_options {
    my ($self) = @_;
    my $module = ref $self;
    my $options = eval "\$${module}::OPTIONS"; ## no critic

    my $opt = get_options(@$options);
    $self->defaults({ %{ $self->defaults }, %{ $opt } });

    return $self;
}

sub auto_complete {
    my ($self) = @_;

    warn lc ( ref $self =~ /.*::/ ), " has no --auto-complete support\n";
    return;
}

1;

__END__

=head1 NAME

App::BambooCli::Command - The base module for individual subcommands

=head1 VERSION

This documentation refers to App::BambooCli::Command version 0.0.1

=head1 SYNOPSIS

   use App::BambooCli::Command;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<defaults>

=head2 C<options>

=head2 C<bamboo>

=head2 C<get_sub_options ()>

=head2 C<auto_complete ()>

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

Copyright (c) 2019 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
