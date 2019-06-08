package App::BambooCli::Config;

# Created on: 2019-06-03 12:55:20
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
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Net::Bamboo;

our $VERSION = version->new('0.0.1');

has name => (
    is      => 'rw',
    default => sub {
        return -f '.bamboo' ? '.bamboo' : "$ENV{HOME}/.bamboo";
    },
);
has bamboo => (
    is      => 'rw',
    lazy    => 1,
    builder => '_bamboo',
);
has [qw/ hostname username password debug /] => (
    is      => 'rw',
);

sub _bamboo {
    my ($self) = @_;
    my $bamboo = new Net::Bamboo;

    $bamboo->hostname($self->hostname);
    $bamboo->debug($self->debug);

    if ($self->username && $self->password) {
        $bamboo->username($self->username);
        $bamboo->password($self->password);
    }

    return $bamboo;
}

1;

__END__

=head1 NAME

App::BambooCli::Config - Stores the configuration for the bamboo commands

=head1 VERSION

This documentation refers to App::BambooCli::Config version 0.0.1

=head1 SYNOPSIS

   use App::BambooCli::Config;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<name>

=head2 C<bamboo>

=head2 C<hostname>

=head2 C<username>

=head2 C<password>

=head2 C<debug>

=head2 C<_bamboo>

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
