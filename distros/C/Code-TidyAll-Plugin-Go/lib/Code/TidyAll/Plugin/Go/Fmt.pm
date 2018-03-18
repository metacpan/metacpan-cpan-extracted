package Code::TidyAll::Plugin::Go::Fmt;

use strict;
use warnings;

our $VERSION = '0.04';

use Moo;
use namespace::autoclean;

use IPC::Run3 qw( run3 );

extends 'Code::TidyAll::Plugin';

sub _build_cmd { 'gofmt' }

sub transform_file {
    my ( $self, $file ) = @_;

    my $cmd = join q{ }, $self->cmd, $self->argv, $file;

    my $output;
    my $err;
    run3( $cmd, \undef, \$output, \$err );
    if ( $? > 0 ) {
        $err ||= 'problem running ' . $self->cmd;
        die "$err\n";
    }

    _write_file( $file, $output );
}

sub _write_file {
    my ( $file, $contents ) = @_;
    open( my $fh, '>', $file ) or die "could not open $file: $!";
    print {$fh} $contents or die $!;
}

1;
