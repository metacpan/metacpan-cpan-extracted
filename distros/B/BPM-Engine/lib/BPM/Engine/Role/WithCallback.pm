package BPM::Engine::Role::WithCallback;
BEGIN {
    $BPM::Engine::Role::WithCallback::VERSION   = '0.01';
    $BPM::Engine::Role::WithCallback::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;
use BPM::Engine::Types qw/CodeRef/;

has 'callback' => (
    traits    => ['Code'],
    is        => 'rw',
    isa       => CodeRef,
    required  => 0,
    predicate => 'has_callback',
    handles   => { call_callback => 'execute', },
    );

no Moose::Role;

1;
__END__

=pod

=head1 NAME

BPM::Engine::Role::WithCallback - Engine and ProcessRunner role providing a callback

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This role provides a callback code reference to L<BPM::Engine> and 
L<BPM::Engine::ProcessRunner|BPM::Engine::ProcessRunner>.

=head1 ATTRIBUTES

=head2 callback

=head1 METHODS

=head2 has_callback

=head2 call_callback

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
