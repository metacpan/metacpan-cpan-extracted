#------------------------------------------------------------------------------
# $Id$

use strict;
use warnings;

# Test Modules
use Test::More tests => 17;
use Test::Exception;
use Test::Warn;

# Extra Modules
use File::Temp qw(tempfile);

# Local Modules;
use Authen::Prepare;

#------------------------------------------------------------------------------
# Setup

my %arg = (
    hostname => 'localhost',
    username => 'testuser',
);

#------------------------------------------------------------------------------
# Tests

test_check_passfile();

test_get_password_default();
test_get_password_nomatch_hostname();
test_get_password_handle_comment();

test_credentials();
test_credentials_with_prefix();

#------------------------------------------------------------------------------
# Subroutines

sub create_passfile {
    my ( $arg_ref, $callback ) = @_;
    my ( $fh,      $filename ) = tempfile();
    my $entry = join( q{:}, @$arg_ref{qw(hostname username)} ) . q{:testpass};

    open $fh, '>', $filename or die $!;

    print $fh qq{$entry\n};

    if ( defined $callback && ref $callback eq 'CODE' ) {
        $callback->($fh);
    }

    chmod oct('0600'), $filename;

    return $filename;
}

sub add_passfile_comment {
    my ($fh) = @_;
    print $fh qq{# commentedhost:user:wrongpass\n};
    print $fh qq{*:user:rightpass\n};

    return;
}

sub add_passfile_default {
    my ($fh) = @_;
    print $fh qq{*:defaultuser:defaultpass\n};

    return;
}

sub test_credentials {
    my $passfile = create_passfile( \%arg );
    my $authen   = Authen::Prepare->new( { %arg, passfile => $passfile } );
    my %cred     = $authen->credentials();

    is( $cred{hostname}, 'localhost', 'Hostname is correct' );
    is( $cred{username}, 'testuser',  'Username is correct' );
    is( $cred{password}, 'testpass',  'Password is correct' );
}

sub test_credentials_with_prefix {
    my $passfile = create_passfile( \%arg );
    my $authen   = Authen::Prepare->new(
        { %arg, passfile => $passfile, prefix => 'p ' } );

    warning_is { $authen->credentials(); } undef,
        'No warnings when using prefix';

    $authen->prefix(q{});
    warning_is { $authen->credentials(); } undef,
        'No warnings when using empty prefix';
}

sub test_get_password_handle_comment {
    my $passfile = create_passfile( \%arg, \&add_passfile_comment );
    my $authen = Authen::Prepare->new( { passfile => $passfile } );
    my $password = $authen->_get_password_for( '# commentedhost', 'user' );

    is( $password, 'rightpass', 'Handled comments' );

    unlink $passfile;
}

sub test_get_password_nomatch_hostname {
    my $passfile = create_passfile( \%arg );
    my $authen   = Authen::Prepare->new( { passfile => $passfile } );
    my $password = $authen->_get_password_for( 'otherhost', 'testuser' );

    ok( !defined $password,
        'Password undefined for matching user but non-matching host' );

    unlink $passfile;
}

sub test_get_password_default {
    my $passfile = create_passfile( \%arg, \&add_passfile_default );
    my $authen = Authen::Prepare->new( { passfile => $passfile } );
    my $password = $authen->_get_password_for( 'foobar', 'defaultuser' );

    ok( defined $password, 'Retrieved password' );
    is( $password, 'defaultpass', 'password is correct' );

    unlink $passfile;
}

sub test_check_passfile {
    my $passfile = create_passfile( \%arg );
    my $authen = Authen::Prepare->new( {%arg} );
    chmod oct('0000'), $passfile;

    throws_ok { $authen->_check_passfile() }
    qr{Unable to read unspecified password file},
        q{Dies with unspecified password file};

    $authen->passfile($passfile);
    my $err_prefix = qr{Unable to use password file};

    lives_ok { chmod oct('0604'), $passfile; } q{chmod 0644};
    throws_ok { $authen->_check_passfile() } qr/other/,
        q{Dies with 'other' permissions};

    lives_ok { chmod oct('0640'), $passfile; } q{chmod 0640};
    throws_ok { $authen->_check_passfile() } qr/group/,
        q{Dies with 'group' permissions};

    lives_ok { chmod oct('0600'), $passfile; } q{chmod 0640};
    lives_ok { $authen->_check_passfile() }
    q{Successfully reads password file};

    unlink $passfile;

    throws_ok { $authen->_check_passfile() } $err_prefix,
        q{Dies with unreadable password file};
}

#------------------------------------------------------------------------------

__END__
