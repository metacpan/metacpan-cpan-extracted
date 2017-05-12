package Authen::Simple::DBM;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

use Carp             qw[];
use Fcntl            qw[];
use Params::Validate qw[];

our $VERSION = 0.2;

__PACKAGE__->options({
    path => {
        type      => Params::Validate::SCALAR,
        optional  => 0
    },
    type => {
        type      => Params::Validate::SCALAR,
        default   => 'SDBM',
        optional  => 1,
        callbacks => {
            'is either DB, GDBM, NDBM or SDBM' => sub {
                $_[0] =~ qr/^CDB|DB|GDBM|NDBM|SDBM$/;
            }
        }
    }
});

sub init {
    my ( $self, $params ) = @_;

    my $type  = $params->{type};
    my $path  = $params->{path};
    my $class = sprintf( '%s_File', $type );

    unless ( -e $path || -e "$path.db" || -e "$path.pag" ) {
        Carp::croak( qq/Database path '$path' does not exist./ );
    }

    unless ( -f _ ) {
        Carp::croak( qq/Database path '$path' is not a file./ );
    }

    unless ( -r _ ) {
        Carp::croak( qq/Database path '$path' is not readable by effective uid '$>'./ );
    }

    unless ( eval "require $class;" ) {
        Carp::croak( qq/Failed to load class '$class' for DBM type '$type'. Reason: '$@'/ );
    }

    my $dbm = $self->_open_dbm( $type, $path )
      or Carp::croak( qq/Failed to open database '$path'. Reason: '$!'/ );

    return $self->SUPER::init($params);
}

sub _open_dbm {
    my $self  = shift;
    my $type  = shift || $self->type;
    my $path  = shift || $self->path;

    my $flags = $type eq 'GDBM' ? &GDBM_File::GDBM_READER : &Fcntl::O_RDONLY;
    my $class = sprintf( '%s_File', $type );
    my @args  = ( $path );

    unless ( $type eq 'CDB' ) {
        push( @args, $flags, 0644 );
    }

    return $class->TIEHASH(@args);
}

sub check {
    my ( $self, $username, $password ) = @_;

    my ( $path, $dbm, $encrypted ) = ( $self->path, undef, undef );

    unless ( $dbm = $self->_open_dbm ) {

        $self->log->error( qq/Failed to open database '$path'. Reason: '$!'/ )
          if $self->log;

        return 0;
    }

    unless (    defined( $encrypted = $dbm->FETCH( $username        ) )
             || defined( $encrypted = $dbm->FETCH( $username . "\0" ) ) ) {

        $self->log->debug( qq/User '$username' was not found in database '$path'./ )
          if $self->log;

        return 0;
    }

    chop($encrypted) if substr( $encrypted, -1 ) eq "\0";

    $encrypted = ( split( ':', $encrypted, 3 ) )[0];

    unless ( defined $encrypted && length $encrypted ) {

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

Authen::Simple::DBM - Simple DBM authentication

=head1 SYNOPSIS

    use Authen::Simple::DBM;
    
    my $dbm = Authen::Simple::DBM->new(
        path => '/var/db/www/passwd'
    );
    
    if ( $dbm->authenticate( $username, $password ) ) {
        # successfull authentication
    }
    
    # or as a mod_perl Authen handler

    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::DBM

    PerlSetVar AuthenSimpleDBM_path "/var/db/www/passwd"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::DBM
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>

=head1 DESCRIPTION

DBM authentication.

=head1 METHODS

=over 4

=item * new

This method takes a hash of parameters. The following options are
valid:

=over 8

=item * path

Path to DBM file. Usually specified without trailing C<.db>, C<.pag> 
or C<.dir> suffix. Required.

    path => '/var/db/www/passwd'

=item * type

DBM type. Valid options are: C<DB>, C<GDBM>, C<NDBM> and C<SDBM>. Defaults to C<SDBM>.

    type => 'NDBM'

=over 12

=item * CDB

Constant Database

=item * DB 

Berkeley DB

=item * GDBM 

GNU Database Mandager

=item * NDBM 

New Database Mandager. C<path> should be specified without a trailing C<.db> 
suffix.

=item * SDBM

Substitute Database Mandager. Comes with both with perl and Apache. C<path> 
should be specified without a trailing C<.pag> or C<.dir> suffix.

=back

=item * log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::DBM')

=back

=item * authenticate( $username, $password )

Returns true on success and false on failure.

=back

=head1 SEE ALSO

L<Authen::Simple>.

L<Authen::Simple::Password>.

L<htdbm(1)>

L<dbmmanage(1)>

L<http://www.unixpapa.com/incnote/dbm.html> - Overview of various DBM's.

L<http://cr.yp.to/cdb.html> - CDB

L<AnyDBM_File> - Compares different DBM's

=head1 AUTHOR

Christian Hansen C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
