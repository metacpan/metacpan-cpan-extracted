package Child::Util;
use strict;
use warnings;
use Carp qw/croak/;

use Exporter 'import';
our @EXPORT = qw/add_accessors add_abstract/;

sub _abstract {
    my $class = shift;
    croak "$class does not implement this function."
}

sub add_abstract {
    my $caller = caller;
    no strict 'refs';
    *{"$caller\::$_"} = \&_abstract for @_;
}

sub add_accessors {
    my $class = caller;
    _add_accessor( $class, $_ ) for @_;
}

sub _add_accessor {
    my ( $class, $reader ) = @_;
    my $prop = "_$reader";

    my $psub = sub {
        my $self = shift;
        ($self->{ $prop }) = @_ if @_;
        return $self->{ $prop };
    };

    my $rsub = sub {
        my $self = shift;
        return $self->$prop();
    };

    no strict 'refs';
    *{"$class\::$reader"} = $rsub;
    *{"$class\::$prop"} = $psub;
}

1;

=head1 NAME

Child::Util - Utility functions for L>Child>

=head1 HISTORY

Most of this was part of L<Parallel::Runner> intended for use in the L<Fennec>
project. Fennec is being broken into multiple parts, this is one such part.

=head1 FENNEC PROJECT

This module is part of the Fennec project. See L<Fennec> for more details.
Fennec is a project to develop an extendable and powerful testing framework.
Together the tools that make up the Fennec framework provide a potent testing
environment.

The tools provided by Fennec are also useful on their own. Sometimes a tool
created for Fennec is useful outside the greater framework. Such tools are
turned into their own projects. This is one such project.

=over 2

=item L<Fennec> - The core framework

The primary Fennec project that ties them all together.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Child is free software; Standard perl licence.

Child is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
