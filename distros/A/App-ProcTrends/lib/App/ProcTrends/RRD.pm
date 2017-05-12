package App::ProcTrends::RRD;

use 5.006;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp;
use App::ProcTrends::Config;
use RRDs;
use Data::Dumper;
use File::Temp qw/tempfile/;
use File::Slurp;

=head1 NAME

App::ProcTrends::RRD - The great new App::ProcTrends::RRD!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use App::ProcTrends::RRD;

    my $obj = App::ProcTrends::RRD->new();
    $obj->do_something();

=head1 SUBROUTINES/METHODS

=head2 new

    The constructor

=cut

sub new {
    my ( $class, $ref ) = @_;
    
    $ref = {} unless( $ref && ref( $ref ) eq 'HASH' );
    my $cfg = App::ProcTrends::Config->new();
    
    my $self = {
        rrd_dir     => $cfg->RRD_DIR(),
        start       => $cfg->RRD_START(),
        end         => $cfg->RRD_END(),
        line        => $cfg->RRD_LINE(),
        stack       => $cfg->RRD_STACK(),
        imgformat   => $cfg->RRD_IMGFORMAT(),
        title       => $cfg->RRD_TITLE(),
        width       => $cfg->RRD_WIDTH(),
        height      => $cfg->RRD_HEIGHT(),
        %{ $ref },
    };

    __PACKAGE__->mk_ro_accessors( keys %{ $self } );
    return bless $self, $class;
}

=head2 find_rrds

    Look for *.rrd files in a particular directory
    Notes: although this is an object method, it doesn't use object internals

=cut

sub find_rrds {
    my ( $self, $dir ) = @_;
     
    my $ref;
    opendir( my $dh, $dir ) or return;
    while( my $file = readdir $dh ) {
        next unless( $file =~ m/(.*?)\.rrd$/ );
        my $procname = $1;
        my $filename = $dir . "/$file";
        $ref->{ $procname } = $filename;
    }
    closedir $dh;

    return $ref;
}

=head2 gen_image

    Generates an image then return the graph data in a scalar.  Because RRDs is
    an XS module, this method actually creates a temp file, dump graph data then
    slurp back in.

=cut

sub gen_image {
    my ( $self, $metric, $process ) = @_;    Arguments: metric, arrayref of processes
    Returns: a scalar containing graph data.  0 on failure

    return 0 unless( $metric && $process );
    
    my $rrd_dir = $self->{ rrd_dir };
    my $path = $rrd_dir . "/$metric";  
    return 0 unless( -d $path );

    my $rrds = $self->find_rrds( $path );
    my $rrdfile = $rrds->{ $process };
    return 0 unless( $rrdfile );

    my $title = $self->{ title };
    $title =~ s/<%METRIC%>/$metric/;
    $title =~ s/<%PROCESS%>/$process/;
    my $line = $self->{ line };
    my $stack = $self->{ stack };

    my @params;
    push @params, "--start",        $self->{ start };
    push @params, "--end",          $self->{ end };
    push @params, "--imgformat",    $self->{ imgformat };
    push @params, "--width",        $self->{ width };
    push @params, "--height",       $self->{ height };
    push @params, "--title",        $title;
    push @params, "--alt-autoscale";
    push @params, "DEF:$process=$rrdfile:$process:AVERAGE";
    push @params, "$line:$process#FF0000:$process:$stack";
    push @params, "GPRINT:$process:AVERAGE:Avg %-8.0lf";

    my ( $fh, $filename ) = tempfile( DIR => $rrd_dir );
    RRDs::graph( $filename, @params );
    my $output = read_file( $filename );
    unlink( $filename );
    ( $output ) ? return $output : return 0;
}

=head2 gen_group_image

    Generates an image from bunch of processes

=cut

sub gen_group_image {
    my ( $self, $metric, $procs ) = @_;

    return 0 unless( $metric && $procs && ref( $procs ) eq 'ARRAY' );

    my $rrd_dir = $self->{ rrd_dir };
    my $path = $rrd_dir . "/$metric";  
    return 0 unless( -d $path );

    my $rrds = $self->find_rrds( $path );

    my $title = $self->{ title };
    $title =~ s/<%METRIC%>/$metric/;

    $title =~ s/<%PROCESS%>/processes/;
    my $line = $self->{ line };
    my $stack = $self->{ stack };

    my @params;
    push @params, "--start",        $self->{ start };
    push @params, "--end",          $self->{ end };
    push @params, "--imgformat",    $self->{ imgformat };
    push @params, "--width",        $self->{ width };
    push @params, "--height",       $self->{ height };
    push @params, "--title",        $title;
    push @params, "--alt-autoscale";
    
    for my $proc ( @{ $procs } ) {
        my $rrdfile = $rrds->{ $proc };
        return 0 unless( $rrdfile );
        
        push @params, "DEF:$proc=$rrdfile:$proc:AVERAGE";
        push @params, "$line:$proc#FF0000:$proc:$stack";
        push @params, "GPRINT:$proc:AVERAGE:Avg %-8.0lf";
    }

    my ( $fh, $filename ) = tempfile( DIR => $rrd_dir );
    RRDs::graph( $filename, @params );
    my $output = read_file( $filename );
    unlink( $filename );
    ( $output ) ? return $output : return 0;
}

=head1 AUTHOR

Satoshi Yagi, C<< <satoshi.yagi at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-proctrends-cron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ProcTrends-Cron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ProcTrends::RRD


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ProcTrends-Cron>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-ProcTrends-Cron>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-ProcTrends-Cron>

=item * Search CPAN

L<http://search.cpan.org/dist/App-ProcTrends-Cron/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Satoshi Yagi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of App::ProcTrends::RRD