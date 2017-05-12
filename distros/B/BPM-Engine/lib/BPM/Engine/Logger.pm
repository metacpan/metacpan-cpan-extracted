package BPM::Engine::Logger;
BEGIN {
    $BPM::Engine::Logger::VERSION   = '0.01';
    $BPM::Engine::Logger::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

with qw/MooseX::LogDispatch::Levels MooseX::LogDispatch::Interface/;

$Log::Dispatch::Config::CallerDepth = 1;

has log_dispatch_conf => (
    is      => 'ro',
    lazy    => 1,
    default => '/etc/bpmengine/logger.conf'
    );

__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=head1 NAME

BPM::Engine::Logger - Engine and ProcessRunner logger object

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This module provides a logger object, and uses the L<MooseX::LogDispatch::Levels>
and L<MooseX::LogDispatch::Interface> roles.

=head1 ATTRIBUTES

=head2 log_dispatch_conf

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut