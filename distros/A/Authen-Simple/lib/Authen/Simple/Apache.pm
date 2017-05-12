package Authen::Simple::Apache;

use strict;
use warnings;
use Authen::Simple::Adapter;

BEGIN {

    unless ( $INC{'mod_perl.pm'} ) {

        my $class = 'mod_perl';

        if ( exists $ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2 ) {
            $class = 'mod_perl2';
        }

        eval "require $class";
    }

    my @import = qw( OK HTTP_UNAUTHORIZED SERVER_ERROR AUTH_REQUIRED );

    if ( $mod_perl::VERSION >= 1.999022 ) { # mod_perl 2.0.0 RC5
        require Apache2::RequestRec;
        require Apache2::RequestUtil;
        require Apache2::RequestIO;
        require Apache2::Log;
        require Apache2::Connection;
        require Apache2::Const;
        require Apache2::Access;
        Apache2::Const->import(@import);
     }
     elsif ( $mod_perl::VERSION >= 1.99 ) {
        require Apache::RequestRec;
        require Apache::RequestUtil;
        require Apache::RequestIO;
        require Apache::Log;
        require Apache::Connection;
        require Apache::Const;
        require Apache::Access;
        Apache::Const->import(@import);
    }
    else {
        require Apache;
        require Apache::Log;
        require Apache::Constants;
        Apache::Constants->import(@import);
    }
}

use constant MP2 => $mod_perl::VERSION >= 1.99 ? 1 : 0;

sub handler_mp1 ($$)     { &handle; }
sub handler_mp2 : method { &handle; }

*Authen::Simple::Adapter::handler = MP2 ? \&handler_mp2 : \&handler_mp1;

sub handle {
    my ( $class, $r ) = @_;

    my( $rc, $password ) = $r->get_basic_auth_pw;

    unless ( $rc == OK ) {
        return $rc;
    }

    my $username = MP2 ? $r->user : $r->connection->user;

    unless ( defined($username) && length($username) ) {
        $r->note_basic_auth_failure;
        $r->log->error("PerlAuthenHandler $class - No username was given.");
        return HTTP_UNAUTHORIZED;
    }

    unless ( defined($password) && length($password) ) {
        $r->note_basic_auth_failure;
        $r->log->error("PerlAuthenHandler $class - No password was given.");
        return HTTP_UNAUTHORIZED;
    }

    ( my $prefix = $class ) =~ s/://g;

    my %params = (
        log => $r->log
    );

    while ( my ( $option, $spec ) = each( %{ $class->options } ) ) {

        next if $option =~ /^(cache|callback|log)$/;

        my $required = $spec->{default} ? 0 : $spec->{optional} ? 0 : 1;
        my $config   = $prefix . '_' . $option;
        my $value    = $r->dir_config($config);

        if ( $required && !defined($value) ) {
            $r->log->error( "PerlAuthenHandler $class - Required parameter '$config' is not set." );
            return SERVER_ERROR;
        }

        $params{ $option } = $value if defined($value);
    }

    my ( $self, $success );

    eval { $self = $class->new(%params); };

    if ( $@ ) {
        $r->log->error( "PerlAuthenHandler $class - Couldn't create a new instance. Reason: '$@'" );
        return SERVER_ERROR;
    }

    eval { $success = $self->authenticate( $username, $password ); };

    if ( $@ ) {
        $r->log->error( "PerlAuthenHandler $class - Couldn't authenticate. Reason: '$@'" );
        return SERVER_ERROR;
    }

    if (!$success) {
        $r->note_basic_auth_failure;
        return AUTH_REQUIRED;
    }

    return OK;
}

1;

__END__

=head1 NAME

Authen::Simple::Apache - PerlAuthenHandler handler for Apache

=head1 SYNOPSIS
    
=head1 DESCRIPTION

=head1 METHODS

=over 4

=item * handle( $class, $r )

=item * handler_mp1

=item * handler_mp2

=back

=head1 LIMITATIONS

Currently only basic authentication is supported.

=head1 SEE ALSO

L<Authen::Simple>.

L<Authen::Simple::ActiveDirectory>.

L<Authen::Simple::CDBI>.

L<Authen::Simple::DBI>.

L<Authen::Simple::FTP>.

L<Authen::Simple::HTTP>.

L<Authen::Simple::Kerberos>.

L<Authen::Simple::LDAP>.

L<Authen::Simple::NIS>.

L<Authen::Simple::PAM>.

L<Authen::Simple::Passwd>.

L<Authen::Simple::POP3>.

L<Authen::Simple::RADIUS>.

L<Authen::Simple::SMB>.

L<Authen::Simple::SMTP>.

L<Authen::Simple::SSH>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
