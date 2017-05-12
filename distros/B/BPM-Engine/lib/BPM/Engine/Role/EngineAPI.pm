package BPM::Engine::Role::EngineAPI;
BEGIN {
    $BPM::Engine::Role::EngineAPI::VERSION   = '0.01';
    $BPM::Engine::Role::EngineAPI::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;

requires qw(
    new
    new_with_config

    logger
    log_dispatch_conf

    log
    debug
    info
    notice
    warning
    error
    critical
    alert
    emergency

    schema
    connect_info

    callback

    get_packages
    create_package
    delete_package
    get_process_definitions
    get_process_definition

    get_process_instances
    create_process_instance
    get_process_instance
    start_process_instance
    terminate_process_instance
    abort_process_instance
    delete_process_instance
    process_instance_attribute
    change_process_instance_state

    get_activity_instances
    get_activity_instance
    change_activity_instance_state
    activity_instance_attribute

    runner
    );

no Moose::Role;

1;
__END__

=pod

=head1 NAME

BPM::Engine::Role::EngineAPI - Engine API inventory

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This Moose role requires all documented API methods for L<BPM::Engine>.

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut