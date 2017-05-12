package MY::Build;
#
#   Alien::InteractiveBrokers -- Installer to download or install IB API
#
#   Copyright (c) 2010-2012 Jason McManus
#

use base qw( Module::Build );
use strict;
use warnings;
use vars qw( $VERSION );
BEGIN {
    $VERSION = '9.6602';
}

sub ACTION_code {
    my $self = shift;
    $self->SUPER::ACTION_code;
    $self->fetch_ibapi();
    $self->install_ibapi();
}

sub ibapi_archive {
    return 'twsapi_unixmac_966.jar';
}

sub ibapi_dir {
    return 'IBJts';
}

sub ibapi_target_dir {
    return 'blib/lib/Alien/InteractiveBrokers';
}

sub ibapi_url {
    my $self = shift;
    return 'http://www.interactivebrokers.com/download/'
            . $self->ibapi_archive();
}

sub fetch_ibapi {
    my $self = shift;
    return if( -f $self->ibapi_archive() );
    $|=1;

    print 'Local copy of ', $self->ibapi_archive(), " not found.\n";
    print 'GET ', $self->ibapi_url(), '... ';

    # Grab the file
    require HTTP::Tiny;
    my $http = HTTP::Tiny->new( timeout => 30 );
    my $response = $http->get(
        $self->ibapi_url(),
        {
            headers => {
                Connection => 'close',
                Accept     => '*/*',
            }
        }
    );

    unless( $response->{success} )
    {
        my $content = ( exists( $response->{content} ) and
                        defined( $response->{content} ) and
                        length( $response->{content} ) )
                          ? substr( $response->{content}, 0, 8*1024 )
                          : "empty";
        chomp $content;
        die sprintf( "\nUnable to fetch archive: %s %s; Content was%s\n",
                     $response->{status}, $response->{reason},
                     ":\n'" . $content . "'\n" );
    }

    # Write it to disk
    open my $fd, '>', $self->ibapi_archive()
        or die "\nCannot write to " . $self->ibapi_archive() . ": $!";
    binmode( $fd );
    my $bytes = syswrite( $fd, $response->{content} );
    die "\nError writing to " . $self->ibapi_archive() . ": $!"
        unless( $bytes == length( $response->{content} ) );
    close( $fd );

    print "OK\n";
}

sub install_ibapi {
    my $self = shift;
    return if( -d $self->ibapi_target_dir() );

    require Archive::Extract;
    no warnings 'once';
    $Archive::Extract::PREFER_BIN = 1;  # Archive::Zip has chmod perms issues
    use warnings;

    print 'EXTRACT ', $self->ibapi_archive(), '... ';
    my $zip;
    unless( $zip = Archive::Extract->new(
                            archive => $self->ibapi_archive() ) ) {
        die "unable to open IB API archive.\n";
    }
    unless( $zip->extract( to => $self->ibapi_target_dir() ) ) {
        die "unable to extract IB API archive.\n";
    }
    print "OK\n";
}

1;

__END__
