package t::Utils;
use strict;
use warnings;
use parent 'Exporter';
use App::Prove::RunScripts;
use File::Temp qw(tempfile);

our @EXPORT_OK = qw/app_with_args file/;

sub app_with_args {
    my $args = shift;
    my $app  = App::Prove::RunScripts->new;
    $app->process_args(@$args);
    return $app;
}

sub file {
    my ( $script, $suffix ) = @_;
    my ( $fh, $filename ) = tempfile( SUFFIX => $suffix );
    print $fh $script;
    close $fh or die $!;
    return $filename;
}
1;
