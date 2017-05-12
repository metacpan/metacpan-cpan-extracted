package App::ProcTrends::Commandline;

use 5.006;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp;
use App::ProcTrends::Config;
use App::ProcTrends::RRD;
use Data::Dumper;
use RRDTool::OO;
use File::Path qw/make_path/;
use RRDs;

=head1 NAME

App::ProcTrends::Commandline - The great new App::ProcTrends::Commandline!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use App::ProcTrends::Commandline;

    my $ref = {
        start   => '-1d',
        end     => 'now'
    };
    
    my $obj = App::ProcTrends::Commandline->new( $ref );
    my $value = $obj->generate_table_data();

=head1 SUBROUTINES/METHODS

=head2 new

    The constructor.

=cut

sub new {
    my ( $class, $ref ) = @_;
    $ref = {} unless( $ref && ref( $ref ) eq 'HASH' );
    
    my $cfg = App::ProcTrends::Config->new();
    my $rrd = App::ProcTrends::RRD->new();

    my $self = {
        start       => $cfg->COMMANDLINE_START(),
        end         => $cfg->COMMANDLINE_END(),
        interval    => $cfg->COMMANDLINE_INTERVAL(),
        procs       => $cfg->COMMANDLINE_PROCS(),
        command     => $cfg->COMMANDLINE_COMMAND(),
        rrd_dir     => $cfg->RRD_DIR(),
        out_dir     => $cfg->RRD_DIR(),
        rrd         => $rrd,
        %{ $ref },
    };

    __PACKAGE__->mk_ro_accessors( keys %{ $self } );
    return bless $self, $class;
}

=head2 table_handler

    Generates a table from RRD data

=cut

sub table_handler {
    my $self = shift;

    my $dir         = $self->{ rrd_dir };
    my $start       = $self->{ start };
    my $end         = $self->{ end };
    my $interval    = $self->{ interval } * 60; # minutes => seconds
    my $procs       = $self->{ procs };
    my @procs       = split( /,\s*/, $procs ) if ( $procs );

    my $result;

    for my $metric ( 'cpu', 'rss' ) {
        my $path = $dir . "/$metric";
        croak "$path does not exist" unless( -d $path );
        my $rrds = $self->{ rrd }->find_rrds( $path );
        next unless( $rrds );
        
        for my $proc ( sort keys %{ $rrds } ) {
            if ( @procs ) {
                next unless( grep( /^$proc$/, @procs ) );
            }
            
            my $file = $rrds->{ $proc };
            my $rrd_obj = RRDTool::OO->new( file => $file );
            $rrd_obj->fetch_start( start => $start, end => $end );
            
            # accounts for undefs with respect to start time, but not end time.
            #$rrd_obj->fetch_skip_undef();

            # tracks the offset
            my $next_time = 0;

            while( my ( $time, $value ) = $rrd_obj->fetch_next() ) {
                $next_time = $time if ( $next_time == 0 );
                
                if ( $time == $next_time ) {
                    push @{ $result->{ $metric }->{ $proc } }, { time => $time, value => $value };
                    $next_time += $interval;
                }
            }
        }
    }
    
    return $self->print_table( $result );
}

=head2 print_table 

    Parses a hashref and prints out on the screen.

=cut

sub print_table {
    my ( $self, $ref ) = @_;
    
    for my $metric ( sort keys %{ $ref } ) {
        for my $proc ( sort keys %{ $ref->{ $metric } } ) {
            print "$metric for $proc\n";
            print "=" x 50, "\n";

            for my $hashref ( @{ $ref->{ $metric }->{ $proc } } ) {
                my ( $time, $value ) = ( $hashref->{ time }, $hashref->{ value } );
                $value = "-" unless( $value );
                my $t_string = localtime( $time );
                print $t_string, " " x 20, $value, "\n";
            }
            print "\n";
        }
    }
    return 1;
}

=head2 list_handler

    Return $ref->{ 'cpu', 'rss' } = [ procs ]

=cut

sub list_handler {
    my $self = shift;

    my $rrd_dir = $self->{ rrd_dir };
    my $rrd = $self->{ rrd };
    my $result;
    
    for my $metric ( 'cpu', 'rss' ) {
        my $path = $rrd_dir . "/$metric";
        
        my $ref = $rrd->find_rrds( $path );
        $result->{ $metric } = [ sort keys %{ $ref } ];
    }
    return $self->print_list( $result );
}

=head2 print_list 

    Prints the list (output from list method) on screen

=cut

sub print_list {
    my ( $self, $arg ) = @_;
    
    for my $metric ( 'cpu', 'rss' ) {
        my @procs = @{ $arg->{ $metric } };
        print "$metric processes:\n";
        print "=" x 19 . "\n";

        for my $proc ( @procs ) {
            print $proc, "\n";
        }
        print "\n";
    }
    return 1;
}

=head2 img_handler

    Generates png image files using object params, and store them in $self->{ out_dir }

=cut

sub img_handler {
    my $self = shift;
    
    my $rrd_dir = $self->{ rrd_dir };
    my $out_dir = $self->{ out_dir };
    my $rrd     = $self->{ rrd };
    my $procs   = $self->{ procs };
    my @procs   = split( /,\s*/, $procs ) if ( $procs );
    my $start   = $self->{ start };
    my $end     = $self->{ end };
    
    make_path( $out_dir ) unless( -d $out_dir );
    
    for my $metric ( 'cpu', 'rss' ) {
        my $path = $rrd_dir . "/$metric";
        my $ref = $rrd->find_rrds( $path );

        for my $process ( keys %{ $ref } ) {
            if ( @procs ) {
                next unless ( grep( /^$process$/, @procs ) );
            }
            my $rrdfile = $ref->{ $process };
            my $filename = $out_dir . "/${metric}_$process.png";
            my @params;

            push @params, $filename;
            push @params, "-s $start";
            push @params, "-e $end";
            push @params, "DEF:mydata=$rrdfile:$process:AVERAGE";
            push @params, "AREA:mydata#0000FF:foo";
            RRDs::graph( @params );
        }
    }
    return 1;
}

=head1 AUTHOR

Satoshi Yagi, C<< <satoshi.yagi at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-proctrends-cron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ProcTrends-Cron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ProcTrends::Commandline


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

1; # End of App::ProcTrends::Commandline