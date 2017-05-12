package TestApp::Session::Session;
use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';
use File::Spec;
use Log::Log4perl qw( :easy );
use File::Temp qw( tempdir );

use base qw( Apache2::Controller::Session::Cookie );

my $tmpdir = tempdir( CLEANUP => 1 );

do {
    #DEBUG("Creating temp directory $_");
    mkdir $_ || die "Cannot create $_: $OS_ERROR\n";
} for grep !-d, 
    $tmpdir, 
    map File::Spec->catfile($tmpdir, $_), 
    qw( lock sess );
  # zwhoop!  beedododadado!

sub get_options {
    my ($self) = @_;
    return {
        Directory       => File::Spec->catfile($tmpdir, 'sess'),
        LockDirectory   => File::Spec->catfile($tmpdir, 'lock'),
    };
}

1;

