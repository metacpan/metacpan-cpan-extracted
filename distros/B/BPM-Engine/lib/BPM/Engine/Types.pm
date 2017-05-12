package BPM::Engine::Types;
BEGIN {
    $BPM::Engine::Types::VERSION   = '0.01';
    $BPM::Engine::Types::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw/ BPM::Engine::Types::Internal
        MooseX::Types::Moose
        MooseX::Types::UUID
        MooseX::Types::DBIx::Class
        /
        );

1;
__END__

=pod

=head1 NAME

BPM::Engine::Types - Exports BPM::Engine internal types as well as Moose types

=head1 VERSION

version 0.01

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
