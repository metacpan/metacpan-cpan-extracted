package Authen::Simple::Passwd;

use strict;
use warnings;
use bytes;
use base 'Authen::Simple::Adapter';

use Carp             qw[];
use Config           qw[];
use Fcntl            qw[LOCK_SH];
use IO::File         qw[O_RDONLY];
use Params::Validate qw[];

our $VERSION = 0.6;

__PACKAGE__->options({
    path => {
        type      => Params::Validate::SCALAR,
        optional  => 1
    },
    flock => {
        type      => Params::Validate::SCALAR,
        default   => ( $Config::Config{d_flock} ) ? 1 : 0,
        optional  => 1
    },
    passwd => {  # deprecated
        type      => Params::Validate::SCALAR,
        optional  => 1
    },
    allow => {   # deprecated
        type      => Params::Validate::ARRAYREF,
        optional  => 1,
    }
});

sub init {
    my ( $self, $params ) = @_;

    my $path = $params->{path} ||= delete $params->{passwd};

    unless ( -e $path ) {
        Carp::croak( qq/Passwd path '$path' does not exist./ );
    }

    unless ( -f _ ) {
        Carp::croak( qq/Passwd path '$path' is not a file./ );
    }

    unless ( -r _ ) {
        Carp::croak( qq/Passwd path '$path' is not readable by effective uid '$>'./ );
    }

    return $self->SUPER::init($params);
}

sub check {
    my ( $self, $username, $password ) = @_;

    if ( $username =~ /^-/ ) {

        $self->log->debug( qq/User '$username' begins with a hyphen which is not allowed./ )
          if $self->log;

        return 0;
    }

    my ( $path, $fh, $encrypted ) = ( $self->path, undef, undef );

    unless ( $fh = IO::File->new( $path, O_RDONLY ) ) {

        $self->log->error( qq/Failed to open passwd '$path'. Reason: '$!'/ )
          if $self->log;

        return 0;
    }

    unless ( !$self->flock || flock( $fh, LOCK_SH ) ) {

        $self->log->error( qq/Failed to obtain a shared lock on passwd '$path'. Reason: '$!'/ )
          if $self->log;

        return 0;
    }

    while ( defined( $_ = $fh->getline ) ) {

        next if /^#/;
        next if /^\s+/;

        chop;

        my (@credentials) = split( /:/, $_, 3 );

        if ( $credentials[0] eq $username ) {

            $encrypted = $credentials[1];

            $self->log->debug( qq/Found user '$username' in passwd '$path'./ )
              if $self->log;

            last;
        }
    }

    unless ( $fh->close ) {

        $self->log->warn( qq/Failed to close passwd '$path'. Reason: '$!'/ )
          if $self->log;
    }

    unless ( defined $encrypted ) {

        $self->log->debug( qq/User '$username' was not found in passwd '$path'./ )
          if $self->log;

        return 0;
    }

    unless ( length $encrypted ) {

        $self->log->debug( qq/Encrypted password for user '$username' is null./ )
          if $self->log;

        return 0;
    }

    unless ( $self->check_password( $password, $encrypted ) ) {

        $self->log->debug( qq/Failed to authenticate user '$username'. Reason: 'Invalid credentials'/ )
          if $self->log;

        return 0;
    }

    $self->log->debug( qq/Successfully authenticated user '$username'./ )
      if $self->log;

    return 1;
}

1;

__END__

=head1 NAME

Authen::Simple::Passwd - Simple Passwd authentication

=head1 SYNOPSIS

    use Authen::Simple::Passwd;
    
    my $passwd = Authen::Simple::Passwd->new( 
        path => '/etc/passwd'
    );
    
    if ( $passwd->authenticate( $username, $password ) ) {
        # successfull authentication
    }
    
    # or as a mod_perl Authen handler
    
    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::Passwd

    PerlSetVar AuthenSimplePasswd_path "/etc/passwd"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::Passwd
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>    

=head1 DESCRIPTION

Authenticate against a passwd file.

=head1 METHODS

=over 4

=item * new

This method takes a hash of parameters. The following options are valid:

=over 8

=item * path

Path to passwd file to authenticate against. Any standard passwd file that 
has records seperated with newline and fields seperated by C<:> is supported.
First field is expected to be username and second field, plain or encrypted 
password. Required.

    path => '/etc/passwd'
    path => '/var/www/.htpasswd'
    
=item * flock

A boolean to enable or disable the usage of C<flock()>. Defaults to C<d_flock> in L<Config>.

    flock => 0

=item * log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::Passwd')

=back

=item * authenticate( $username, $password )

Returns true on success and false on failure. Authentication attempts with a username that begins with a 
hyphen C<-> will always return false.

=back

=head1 SEE ALSO

L<Authen::Simple>.

L<Authen::Simple::Password>.

L<passwd(5)>.

=head1 AUTHOR

Christian Hansen C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
