package Argon::Types;
# ABSTRACT: TypeConstraints used by Argon classes
$Argon::Types::VERSION = '0.18';

use strict;
use warnings;
use Moose::Util::TypeConstraints;
use Path::Tiny qw(path);
use Argon::Constants qw(:commands :priorities);


class_type 'AnyEvent::CondVar';


union 'Ar::Callback', ['CodeRef', 'AnyEvent::CondVar'];


subtype 'Ar::FilePath', as 'Str', where { $_ && path($_)->is_file };


enum 'Ar::Command', [$ID, $PING, $ACK, $ERROR, $QUEUE, $DENY, $DONE, $HIRE];


enum 'Ar::Priority', [$HIGH, $NORMAL, $LOW];

no Moose::Util::TypeConstraints;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon::Types - TypeConstraints used by Argon classes

=head1 VERSION

version 0.18

=head1 DESCRIPTION

Type constraints used by Ar classes.

=head1 TYPE CONSTRAINTS

=head2 AnyEvent::Condvar

See L<AnyEvent/CONDITION VARIABLES>.

=head2 Ar::Callback

A code reference or condition variable.

=head2 Ar::FilePath

A path to an existing, accessible file.

=head2 Ar::Command

An Ar command verb. See L<Argon::Constants/:commands>.

=head2 Ar::Priority

An L<Argon::Message> priority. See L<Argon::Constants/:priorities>.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
