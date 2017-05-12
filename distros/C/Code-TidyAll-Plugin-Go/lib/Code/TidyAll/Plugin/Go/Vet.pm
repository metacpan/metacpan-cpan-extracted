package Code::TidyAll::Plugin::Go::Vet;
$Code::TidyAll::Plugin::Go::Vet::VERSION = '0.02';
use strict;
use warnings;

use IPC::Run3 qw( run3 );
use Moo;

extends 'Code::TidyAll::Plugin';

sub _build_cmd { 'go vet' }

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
