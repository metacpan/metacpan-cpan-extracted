package Code::TidyAll::Plugin::Go::Vet;

use strict;
use warnings;

our $VERSION = '0.04';

use Moo;
use namespace::autoclean;

use IPC::Run3 qw( run3 );

extends 'Code::TidyAll::Plugin';

sub _build_cmd { 'go tool vet' }

sub validate_file {
    my ( $self, $file ) = @_;

    my $cmd = join q{ }, $self->cmd, $self->argv, $file;

    my $output;
    run3( $cmd, \undef, \$output, \$output );
    if ( $? > 0 ) {
        $output ||= 'problem running ' . $self->cmd;
        die "$output\n";
    }
}

1;
