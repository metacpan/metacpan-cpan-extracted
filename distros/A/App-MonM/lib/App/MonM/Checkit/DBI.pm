package App::MonM::Checkit::DBI; # $Id: DBI.pm 78 2019-07-07 19:48:16Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Checkit::DBI - Checkit DBI subclass

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

    <Checkit "foo">
        Enable  yes
        Type    dbi
        DSN         DBI:mysql:database=DBNAME;host=127.0.0.1
        SQL         "SELECT 'OK' AS OK FROM DUAL" # By default
        User        USER
        Password    PASSWORD
        Timeout     15 # Connect and request timeout, secs
        Set RaiseError     0
        Set PrintError     0
        Set mysql_enable_utf8   0

        # . . .

    </Checkit>

=head1 DESCRIPTION

Checkit DBI subclass

=head2 check

Checkit method.
This is backend method of L<App::MonM::Checkit/check>

Returns:

=over 4

=item B<code>

The DBH error code ($dbh->err)

=item B<content>

The merged response content

=item B<message>

OK or ERROR value, see "status"

=item B<source>

DSN of DBI connection

=item B<status>

0 if error occured; 1 if no errors found

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.00';

use CTK::DBI;
use CTK::ConfGenUtil;
use App::MonM::Util qw/set2attr/;

use constant {
        DEFAULT_DSN     => "dbi:Sponge:",
        DEFAULT_TIMEOUT => 0,
        DEFAULT_SQL     => "SELECT 'OK' AS OK FROM DUAL",
    };

sub check {
    my $self = shift;
    my $type = $self->type;
    return $self->maybe::next::method() unless $type && $type eq 'dbi';

    # Init
    my $dsn = value($self->config, 'dsn') || DEFAULT_DSN;
       $self->source($dsn);
    my $timeout = value($self->config, 'timeout') || DEFAULT_TIMEOUT;
    my $attr = set2attr($self->config);
    my $sql = value($self->config, 'sql') // value($self->config, 'content') // DEFAULT_SQL;
    my $user = value($self->config, 'user');
    my $password = value($self->config, 'password');

    # DB
    my $db = new CTK::DBI(
        -dsn    => $dsn,
        -debug  => 0,
        -username => $user,
        -password => $password,
        -attr     => $attr,
        $timeout ? (
            -timeout_connect => $timeout,
            -timeout_request => $timeout,
        ) : (),
    );
    my $dbh = $db->connect if $db;

    # Connect
    my @resa = ();
    my $error = "";
    if (!$db) {
        $error = sprintf("Can't init database \"%s\"", $dsn);
    } elsif (!$dbh) {
        $error = sprintf("Can't connect to database \"%s\": %s", $dsn, $DBI::errstr || "unknown error");
    } else {
        my $sth = $db->execute($sql);
        $error = $dbh->errstr();
        if ($sth) {
            @resa = $sth->fetchrow_array;
            $sth->finish;
        }
    }

    # Result
    my $result = join("", @resa) // '';
       $self->content($result);
    my $status = (defined($error) && length($error)) ? 0 : 1;
       $self->status($status);
    $self->error($error) if defined($error) && length($error);
    $self->code($dbh ? $dbh->err || 0 : 0);
    $self->message($self->status ? "OK" : "ERROR");

    return;
}

1;

__END__
