package Code::TidyAll::Plugin::Go::Fmt;
$Code::TidyAll::Plugin::Go::Fmt::VERSION = '0.02';
use strict;
use warnings;

use IPC::Run3 qw( run3 );
use Moo;

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
    open( my $fh, ">", $file ) or die "could not open $file: $!";
    print $fh $contents;
}

1;
