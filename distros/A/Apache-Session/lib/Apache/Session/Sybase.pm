#############################################################################
#
# Apache::Session::Sybase
# Apache persistent user sessions in a Sybase database
# Copyright(c) 1998, 1999, 2000 Jeffrey William Baker (jwbaker@acm.org)
# Modified from Apache::Session::MySQL by Chris Winters (chris@cwinters.com)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Sybase;

use strict;
use vars qw( @ISA $VERSION );

use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Store::Sybase;
use Apache::Session::Generate::MD5;
use Apache::Session::Serialize::Sybase;

$VERSION = '1.00';
@ISA     = qw( Apache::Session );

sub populate {
    my $self = shift;

    $self->{object_store} = new Apache::Session::Store::Sybase $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Apache::Session::Generate::MD5::generate;
    $self->{validate}     = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::Sybase::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::Sybase::unserialize;

    return $self;
}

1;

=pod

=head1 NAME

Apache::Session::Sybase - An implementation of Apache::Session

=head1 SYNOPSIS

 use Apache::Session::Sybase;

 # if you want Apache::Session to open new DB handles:

 tie %hash, 'Apache::Session::Sybase', $id, {
    DataSource => 'dbi:Sybase:database=sessions;server=SYBASE',
    UserName   => $db_user,
    Password   => $db_pass,
    Commit     => 1,
 };

 # or, if your handle is already opened:

 tie %hash, 'Apache::Session::Sybase', $id, {
    Handle     => $dbh,
    Commit     => 0,    
 };

=head1 DESCRIPTION

This module is an implementation of Apache::Session.  It uses the
Sybase backing store and the Null locking scheme.  See the example,
and the documentation for Apache::Session::Store::Sybase (also for the
parameters that get passed to the backing store along with the schema
necessary to save the sessions) and Apache::Session::Lock::Null for
more details.

=head1 AUTHOR

This module was based on L<Apache::Session::MySQL> which was written
by Jeffrey William Baker <jwbaker@acm.org>; it was modified by Chris
Winters <chris@cwinters.com>.

=head1 SEE ALSO

L<Apache::Session>

=cut
