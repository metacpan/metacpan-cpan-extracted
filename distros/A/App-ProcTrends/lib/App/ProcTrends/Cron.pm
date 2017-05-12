package App::ProcTrends::Cron;

use 5.006;
use strict;
use warnings;
use App::ProcTrends::Config;
use base qw(Class::Accessor::Fast);
use Carp;
use Data::Dumper;
use File::Path qw/make_path/;
use RRDs;
use RRD::Simple;
use autodie;
use Log::Log4perl qw/:easy/;
use App::ProcTrends::RRD;

=head1 NAME

App::ProcTrends::Cron - The great new App::ProcTrends::Cron!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use App::ProcTrends::Cron;

    my $ref = {
        rrd_dir => '/foo',
    };
    my $obj = App::ProcTrends::Cron->new( $ref );
    my $data = $obj->run_ps();
    my $rc = $obj->store_rrd( $data );

=head1 SUBROUTINES/METHODS

=head2 new

    The constructor.  Takes a hashref to override defaults.

=cut

sub new {
    my ( $class, $ref ) = @_;
    $ref = {} unless( ref( $ref ) eq 'HASH' );

    my $cfg = App::ProcTrends::Config->new();
    my $rrd = App::ProcTrends::RRD->new();
  
    my $self = {
        rrd_dir        => $cfg->RRD_DIR(),
        timeout        => $cfg->CRON_TIMEOUT(),
        ps_cmd         => $cfg->CRON_PS_CMD(),
        cpu_cores      => $cfg->CRON_CPU_CORES(),
        cpu_threshold  => $cfg->CRON_CPU_THRESHOLD(),
        rss_threshold  => $cfg->CRON_RSS_THRESHOLD(),
        rss_unit       => $cfg->CRON_RSS_UNIT(),
        rrd_rra        => $cfg->CRON_RRD_RRA(),
        rrd_ds         => $cfg->CRON_RRD_DS(),
        debug          => 0,
        rrd            => $rrd,
        %{ $ref },
    };

    bless $self, $class;

    alarm( $self->{ timeout } );
    Log::Log4perl->easy_init($DEBUG) if ( $self->{ debug } );
    $self->set_signal_handlers();

    __PACKAGE__->mk_ro_accessors( keys %{ $self } );
    return $self;
}

=head2 DESTROY

    Destructor.  Alarm should be cleared upon exit.

=cut

sub DESTROY {
    my ($self) = @_;
    alarm(0); # clearing alarm
}

=head2 run_ps

    Driver method to execute ps, parses the output and return data structure

=cut

sub run_ps {
    my $self = shift;

    my $cmd     =   $self->{ ps_cmd };
    my $cores   =   $self->{ cpu_cores };
    my $unit    =   $self->{ rss_unit };
    my $divisor =   $self->calc_rss_divisor( $unit );

    chomp( my @output = `$cmd` );
    croak "something went wrong: $!" if ( $? >> 8 );

    my $ref = {};
    
    for my $line ( @output ) {
        my ( $cpu, $rss, $command ) = $line =~ /(\d+\.\d)\s+(\d+)\s(.*)$/;
        next unless ( $cpu && $rss && $command );
        my $command_str = $self->sanitize_cmd( $command );
        
        # apparently, some combination results in empty string
        next unless( $command_str );
        $ref->{ cpu }->{ $command_str } += $cpu / $cores;
        $ref->{ rss }->{ $command_str } += $rss / $divisor;
    }
    
    $self->trim_below_threshold( $ref );
    return $ref;
}

=head2 sanitize_cmd

    Parses a command and turns into a valid RRD DS name.

=cut

sub sanitize_cmd {
    my ( $self, $cmd ) = @_;

    my @result;    
    my @fields = split( /\s+/, $cmd );
    
    foreach my $field ( @fields ) {
        if ( $field =~ m|^/| ) {
            # fetching the last field of absolute path for truncation
            my @paths = split( /\//, $field );
            $field = $paths[-1];
        }
        
        next if ( $field =~ /^-/ );     # skips options
        $field =~ s/-/_/g;              # converts hyphen to underscore for clarity
        $field =~ s/[^a-zA-Z0-9_]//g;   # removes RRD-invalid chars
        
        push @result, $field;
    }

    my $str = join( "_", @result );
    return substr( $str, 0, 19 );
}

=head2 trim_below_threshold

    Trims metrics <= threshold for cpu, rss

=cut

sub trim_below_threshold {
    my ( $self, $ref ) = @_;
    
    my $cpu_thresh = $self->{ cpu_threshold };
    my $rss_thresh = $self->{ rss_threshold };
    
    for my $metric ( 'cpu', 'rss' ) {
        for my $cmd ( keys %{ $ref->{ $metric } } ) {
            my $val = $ref->{ $metric }->{ $cmd };

            if ( $metric eq 'cpu' ) {
                delete $ref->{ $metric }->{ $cmd } unless ( $val >= $cpu_thresh );
            }
            else {
                delete $ref->{ $metric }->{ $cmd } unless ( $val >= $rss_thresh );
            }
        }
    }
}

=head2 calc_rss_divisor

    Returns what to divide the ps RSS output by.  For example, if the unit is MB then we would divide KB by 1024.

=cut

sub calc_rss_divisor {
    my ( $self, $unit ) = @_;
    
    croak "invalid unit" unless ( $unit && $unit =~ /^(kb|mb|gb|tb)$/i );
    
    return 1                    if ( $unit =~ /^kb$/i );
    return 1024                 if ( $unit =~ /^mb$/i );
    return 1024 * 1024          if ( $unit =~ /^gb$/i );
    return 1024 * 1024 * 1024   if ( $unit =~ /^tb$/i );
}

=head2 store_rrd

    Driver method to:
        1. create directories if they don't already exist.
        2. get a list of RRDs I already have (so that I can fill in with 0's to
            avoid spotty graphs)
        3. go through the current list of metrics
            a. create RRD if needed
            b. update RRD
            c. pop them from my list if exists
        4. go through the remaining RRDs from my list then fill with 0's 

=cut

sub store_rrd {
    my ( $self, $ref ) = @_;
    my $dir = $self->{ rrd_dir };

    for my $metric ( 'cpu', 'rss' ) {        
        my $metric_dir = $dir . "/$metric";
        make_path( $metric_dir ) unless( -d $metric_dir );
        
        my $rrds = $self->{ rrd }->find_rrds( $metric_dir );
        
        for my $proc ( keys %{ $ref->{ $metric } } ) {
            my $file = $metric_dir . "/$proc.rrd";
            my $value = $ref->{ $metric }->{ $proc };
            $self->create_rrd( $file, $proc ) unless( -f $file );
            $self->update_rrd( $file, $proc, $value );
            delete $rrds->{ $proc } if ( exists $rrds->{ $proc } );
        }
        
        # fills the remaining proces with 0's
        for my $proc ( keys %{ $rrds } ) {
            my $file = $rrds->{ $proc };
            $self->update_rrd( $file, $proc, 0 );
        }
    }
    return 1;
}

=head2 create_rrd

    Creates an RRD file.

=cut

sub create_rrd {
    my ( $self, $file, $proc ) = @_;
    
    my $rra = $self->{ rrd_rra };
    my $ds  = $self->{ rrd_ds };
    
    my $ds_line = "DS:$proc:" . $ds;
    my @params;
    push @params, $ds_line, @{ $rra };
    
    RRDs::create( $file, @params );
    my $ERR = RRDs::error;
    croak "error while creating $file: $ERR\n" if $ERR;
    return 1;
}

=head2 update_rrd

    Updates an rrd file

=cut

sub update_rrd {
    my ( $self, $file, $key, $value ) = @_;
    
    my $rrd = RRD::Simple->new( file => $file );
    $rrd->update( $key => $value );
}

=head2 alrm_handler

    Signal handler for alarm().  It is an instance method because I need access
    to the attributes.

=cut

sub alrm_handler {
    my $self = shift;

    DEBUG "DEBUG: alrm received, in alrm_handler()";
    # so clean up basically means I want to delete any temporary files lingering
    # around in the RRD directory
    my $dir = $self->{ rrd_dir };

    for my $metric ( "cpu", "rss" ) {
        my $m_dir = $dir . "/$metric";
        
        opendir( my $dh, $m_dir );
        while( my $file = readdir $dh ) {
            # skips .rrd or ., ..
            next if ( $file =~ /(\.rrd|\.{1,2})$/ );
            my $path = $m_dir . "/$file";
            unlink $path;
        }
    }
    exit(1);
}

=head2 set_signal_handlers

    Set signal handlers.  The only one I'm expecting is SIGALRM.

=cut

sub set_signal_handlers {
    my $self = shift;

    $SIG{ALRM} = sub {
        $self->alrm_handler();
    }
}

=head1 AUTHOR

Satoshi Yagi, C<< <satoshi.yagi at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-proctrends-cron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ProcTrends-Cron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ProcTrends::Cron


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

1; # End of App::ProcTrends::Cron
