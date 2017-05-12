package Catalyst::Helper::Model::EVDB;

use strict;
use warnings;

=head1 NAME

Catalyst::Helper::Model::EVDB - Helper for EVDB models

=head1 SYNOPSIS

    script/myapp_create.pl model EVDB EVDB app_key username password

=head1 DESCRIPTION

Helper for the L<Catalyst> EVDB model.

=head1 USAGE

When creating a new EVDB model class using this helper, you can
specify much of the configuration and have it filled automatically.
Using the example from the L</SYNOPSIS> section:

=over

=item * C<EVDB>

The name of the model.  This is also used to determine the filename,
e.g. C<lib/MyApp/Model/EVDB.pm>.

=item * C<EVDB>

The helper to use, i.e. this one.

=item * C<app_key>

Your application key, as provided by EVDB.  Please see
L<http://api.evdb.com/> to obtain an application key.

=item * C<username>

(Optional) Your EVDB username.

=item * C<password>

(Optional) Your EVDB password.

=back

=head1 METHODS

=head2 mk_compclass

Makes the EVDB model class.

=cut

sub mk_compclass {
    my ($self, $helper, $app_key, $username, $password) = @_;

    $helper->{app_key}  = $app_key  || '';
    $helper->{username} = $username || '';
    $helper->{password} = $password || '';

    $helper->render_file('modelclass', $helper->{file});

    return 1;
}

=head2 mk_comptest

Makes tests for the EVDB model.

=cut

sub mk_comptest {
    my ($self, $helper) = @_;

    $helper->render_file('modeltest', $helper->{test});
}

=head1 SEE ALSO

=over 4

=item * L<Catalyst::Manual>

=item * L<Catalyst::Test>

=item * L<Catalyst::Helper>

=back

=head1 AUTHOR

Daniel Westermann-Clark E<lt>danieltwc@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__modelclass__
package [% class %];

use strict;
use warnings;
use base 'Catalyst::Model::EVDB';

__PACKAGE__->config(
    app_key  => '[% app_key %]',
    username => '[% username %]',
    password => '[% password %]',
);

=head1 NAME

[% class %] - EVDB Catalyst model component

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

EVDB Catalyst model component.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__modeltest__
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Catalyst::Test', '[% app %]');
use_ok('[% class %]');
