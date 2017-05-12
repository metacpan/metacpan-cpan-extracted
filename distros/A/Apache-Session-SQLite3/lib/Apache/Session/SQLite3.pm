package Apache::Session::SQLite3;
$Apache::Session::SQLite3::VERSION = '0.03';

use strict;
use base 'Apache::Session';

use DBD::SQLite 1.00;
use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Store::SQLite3;
use Apache::Session::Generate::MD5;
use Apache::Session::Serialize::Storable;

sub populate {
    my $self = shift;
    
    $self->{object_store} = Apache::Session::Store::SQLite3->new($self);
    $self->{lock_manager} = Apache::Session::Lock::Null->new($self);
    $self->{generate}     = \&Apache::Session::Generate::MD5::generate;
    $self->{validate}     = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::Storable::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::Storable::unserialize;
    
    return $self;
}

1;

=head1 NAME

Apache::Session::SQLite3 - Use DBD::SQLite 1.x for Apache::Session storage

=head1 VERSION

This document describes version 0.03 of Apache::Session::SQLite3, released 
February 2, 2005.

=head1 SYNOPSIS

    use Apache::Session::SQLite3;

    tie %hash, 'Apache::Session::SQLite3', $id, {
        DataSource => 'dbi:SQLite:dbname=/tmp/session.db'
    };

    # to purge all sessions older than 30 days, do this:
    tied(%hash)->{object_store}{dbh}->do(qq[
        DELETE FROM Sessions WHERE ? > LastUpdated
    ], {}, time - (30 * 86400));

=head1 DESCRIPTION

This module is an implementation of Apache::Session.  It uses the DBD::SQLite
backing store.  It requires DBD::SQLite version 1.00 or above, due to its use
of SQLite3 API for BLOB support.  Also, an extra C<LastUpdated> field is
populated with the current C<time()>.

There is no need to create the data source file beforehand; this module creates
the C<session> table automatically.

=head1 AUTHOR

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004, 2005 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

L<Apache::Session>, L<Apache::Session::SQLite>, L<DBD::SQLite>

=cut
