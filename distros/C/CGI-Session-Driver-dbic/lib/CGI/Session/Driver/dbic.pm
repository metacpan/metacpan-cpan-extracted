package CGI::Session::Driver::dbic;

use warnings;
use strict;

use base 'CGI::Session::Driver';

=head1 NAME

CGI::Session::Driver::dbic - L<DBIx::Class> storage driver for L<CGI::Session>.

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

    use CGI::Session;

    my $schema = MyDB::Schema->connect($dbi_dsn, $user, $pass, \%dbi_params);
    my $dbic_rs = $schema->resultset('sessions');

    my $s = CGI::Session->new("driver:dbic", undef, {ResultSet => $dbic_rs});
    ...

=cut

sub init {
    my $self = shift;
    return $self->set_error('init(): ResultSet param not set')
        unless $self->{ResultSet};
    return 1;
}

sub store {
    my ($self, $sid, $datastr) = @_;
    # Store $datastr, which is an already serialized string of data.
    my $row = $self->{ResultSet}->update_or_create({
        id          => $sid,
        a_session   => $datastr,
        });
    return !(!$row);
}

sub retrieve {
    my ($self, $sid) = @_;
    # Return $datastr, which was previously stored using above store() method.
    # Return $datastr if $sid was found. Return 0 or "" if $sid doesn't exist
    my $row = $self->{ResultSet}->find($sid);
    return $row ? $row->a_session : '';
}

sub remove {
    my ($self, $sid) = @_;
    # Remove storage associated with $sid. Return any true value indicating success,
    # or undef on failure.
    return $self->{ResultSet}->search({id => $sid})->delete;
}

sub traverse {
    my ($self, $coderef) = @_;
    # execute $coderef for each session id passing session id as the first and the only
    # argument
    my $rs = $self->{ResultSet}->search->get_column('id');
    while (my $sid = $rs->next) {
        $coderef->($sid);
    }
    return 1;
}

=head1 STORAGE

The structure of the table is the same as in L<CGI::Session::Driver::DBI>.

    CREATE TABLE sessions (
        id CHAR(32) NOT NULL PRIMARY KEY,
        a_session TEXT NOT NULL
    );

DBIx::Class schema:

    package MyProject::DB::Session;
    use base qw/DBIx::Class/;

    __PACKAGE__->load_components(qw/Core/);
    __PACKAGE__->table('sessions');
    __PACKAGE__->add_columns(
        id        => { data_type => 'char', size => 32 },
        a_session => { data_type => 'bytea' },
    );
    __PACKAGE__->set_primary_key('id');

    1;

=head1 DRIVER ARGUMENTS

Following driver arguments are supported:

=over 4

=item ResultSet

L<DBIx::Class::ResultSet> for sessions table.

=back

=head1 AUTHOR

Sergey Homenkow, C<< <shomenkow at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-session-driver-dbic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Session-Driver-dbic>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Session::Driver::dbic


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Session-Driver-dbic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Session-Driver-dbic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Session-Driver-dbic>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Session-Driver-dbic/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Sergey Homenkow.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CGI::Session::Driver::dbic
