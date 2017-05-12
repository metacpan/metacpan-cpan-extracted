package Apache::AxKit::Plugins::Session;
use Apache::Session::Flex;
use Apache::Request;
use constant DEBUG => 0;
use lib qw( $VERSION %session );

$VERSION = 0.11;

sub handler
{
    my $r = Apache::Request->instance(shift);

    # Session handling code
    %session = ();
    my $no_cookie = 0;
    my $opts = {};

    # Load the configuration parameters
    my $cfgDataStore = $r->dir_config( 'SessionDataStore' );
    my $cfgLock      = $r->dir_config( 'SessionLock' );
    my $cfgGenerate  = $r->dir_config( 'SessionGenerate' );
    my $cfgSerialize = $r->dir_config( 'SessionSerialize' );

    my %flex_options = 
    (
        Store     => $cfgDataStore || 'DB_File',
        Lock      => $cfgLock      || 'Null',
        Generate  => $cfgGenerate  || 'MD5',
        Serialize => $cfgSerialize || 'Storable'
    );

    # Load session-type specific parameters
    foreach my $arg ( split( /\s*,\s*/, $r->dir_config( 'SessionArgs' ) ) )
    {
        my ($key, $value) = split( /\s*=>\s*/, $arg );
        $flex_options{$key} = $value;
    }

    # Read in the cookie if this is an old session
    my $cookie = $r->header_in('Cookie');
    {
        # eliminate logging of Apache::Session warn messages
        local $^W = 0;

        $cookie =~ s/SESSION_ID=(\w*)/$1/;
        if ( $cookie ) {
            print STDERR "Loading existing session: \"$cookie\"\n" if DEBUG;
            my $res = tieHash( $cookie, \%flex_options );
            print STDERR "The tie returned $res\n" if DEBUG and $res;
        }
        unless ( $session{_session_id} )
        {
            print STDERR "Creating a new session, since \"$session{_session_id}\" didn't work.\n" if DEBUG;
            my $res = tieHash( undef, \%flex_options );
            $no_cookie = 1;
        }
    }

    # Might be a new session, so lets give them a cookie
    if (!defined($cookie) || $no_cookie)
    {
        my $session_cookie = "SESSION_ID=$session{_session_id}";
        $r->header_out("Set-Cookie" => $session_cookie);
        $session{_creation_time} = time;
        print STDERR "Set a new header for the session cookie: \"$session_cookie\"\n" if DEBUG;
    }

    # Update the "Last Accessed" timestamp key
    $session{_last_accessed_time} = time;

    # This is to try using the pnotes table, passing as a ref
    $r->pnotes( xsp_session => \%session );
    $r->pnotes( xsp_session_ref => tied %session );
    print STDERR "Successfully set the session object in the pnotes table\n" if DEBUG;
    return OK;
}

sub tieHash
{
    my ( $id, $options ) = @_;
    eval
    {
        tie %session, 'Apache::Session::Flex', $id, $options;
    };
    return $@ if ( $@ );
}

1;

__END__

=head1 NAME

Apache::AxKit::Plugins::Session - AxKit plugin that handles setting / loading of Sessions

=head1 SYNOPSIS

    AxAddPlugin Apache::AxKit::Plugins::Session
    PerlSetVar SessionDataStore DB_File
    PerlSetVar SessionArgs FileName,/tmp/sessions

=head1 DESCRIPTION

Session is an AxKit plugin which automatically creates and manages
server-side user sessions.  Based on Apache::Session::Flex, this allows
you to specify all the parameters normally configurable through ::Flex.

=head1 Parameter Reference

=head2 C<SessionDataStore>

Sets the backend datastore module.  Default: DB_File

=head2 C<SessionLock>

Sets the record locking module.  Default: Null

=head2 C<SessionGenerate>

Sets the session id generation module.  Default: MD5

=head2 C<SessionSerialize>

Sets the hash serializer module.  Default: Storable

=head2 C<SessionArgs>

Comma-separated list of name/value pairs.  This is used to pass additional
parameters to Apache::Session::Flex for the particular modules you select.
For instance: if you use MySQL for your DataStore, you need to pass the
database connection information.  You could pass this by calling:

    PerlSetVar SessionArgs "DataSource => dbi:mysql:sessions, \
                            UserName   => session_user, \
                            Password   => session_password"

=head2 C<AxKit::XSP::Session Support>

This plugin was created to complement AxKit::XSP::Session, but can be used
without the taglib.  Special hooks have been put in place to put references
to the session hash in the mod_perl pnotes() table, so the XSP taglib can
fetch session parameters.

Every session access, the session key "_last_accessed_time" is set to the current
date-timestamp.  When a new session is created, the session key "_creation_time" is
set to the current date-timestamp.

=head1 ERRORS

To tell you the truth, I haven't tested this enough to know what happens when it fails.
I'll update this if any glaring problems are found.

=head1 AUTHOR

Michael A Nachbaur, mike@nachbaur.com

=head1 COPYRIGHT

Copyright (c) 2001 Michael A Nachbaur. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

AxKit, AxKit::XSP::Session, Apache::Session, Apache::Session::Flex

=cut
