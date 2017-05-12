package BPM::Engine::Store;
BEGIN {
    $BPM::Engine::Store::VERSION   = '0.01';
    $BPM::Engine::Store::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_namespaces();

1;
__END__

=pod

=head1 NAME

BPM::Engine::Store - Schema class for Workflow model

=head1 SYNOPSIS

    use BPM::Engine::Store;

    my $schema = BPM::Engine::Store->connect(
        $dsn, $user, $pass, {
            schema_name_postfix => '_dev'
            # ... Other options as desired ...
        });

    my $processes = $schema->resultset('Process')->search;

=head1 DESCRIPTION

BPM::Engine::Store provides the schema classes used to interact with the
database.

=head2 TABLES

The schema classes represent a number of tables, grouped by a three-letter
prefix.

=head3 Workflow Definition Tables

Prefix: wfd_

=over 4

=item * Package

=item * Participant

=item * Application

=item * Process

=item * Activity

=item * Performer

=item * ActivityTask

=item * ActivityDeadline

=item * Transition

=item * TransitionRef

=back

=head3 Workflow Execution Tables

Prefix: wfe_

=over 4

=item * ActivityInstance

=item * ActivityInstanceAttribute

=item * ActivityInstanceSplit

=item * ActivityInstanceState

=item * ProcessInstance

=item * ProcessInstanceAttribute

=item * ProcessInstanceState

=item * WorkItem

=back

=head1 INTERFACE

=head2 connect

=over 4

=item Arguments: $dsn, $user, $password, \%attr

=back

Creates a new schema instance and uses Exceptions to catch all db related
errors.

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
