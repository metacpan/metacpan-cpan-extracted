package App::pscan::Utils;
use warnings;
use strict;
use base qw(Exporter);
use Term::ANSIColor;
use URI;
use Net::DNS::Resolver;

use constant debug => $ENV{DEBUG};

our @EXPORT = qw(_debug
    info
    error
    notice
    print_list
    resolve
    generate_ports
);

sub _debug {
    print STDERR @_, "\n" if debug;
}

sub generate_ports {
    my $Port = shift;
    my $first;
    my $last;
    if ( $Port =~ /\*/ ) {
        $first = 1;
        $last  = 65536;
    }
    elsif ( $Port =~ /\-/ ) {
        ( $first, $last ) = split( /\-/, $Port );

    }
    elsif ( !defined($Port) ) {
        $first = $last = 80;
    }
    else {
        $first = $last = $Port;
    }
    return ( $first, $last );
}

sub resolve {

    my $IP   = shift;
    my $ResolvedIP;

    my $res = Net::DNS::Resolver->new( nameservers => [qw(8.8.8.8)] );

    my $query = $res->search($IP);

    if ($query) {
        foreach my $rr ( $query->answer ) {
            next unless $rr->type eq "A";
            return $rr->address;
            
        }
    }

    return undef;

}

sub print_list {
    my @lines = @_;

    my $column_w = 0;

    map { $column_w = length( $_->[0] ) if length( $_->[0] ) > $column_w; }
        @lines;

    my $screen_width = 92;

    for my $arg (@lines) {
        my $title   = shift @$arg;
        my $padding = int($column_w) - length($title);

        if ( $ENV{WRAP}
            && ( $column_w + 3 + length( join( " ", @$arg ) ) )
            > $screen_width )
        {
            # wrap description
            my $string
                = color('bold')
                . $title
                . color('reset')
                . " " x $padding . " - "
                . join( " ", @$arg ) . "\n";

            $string =~ s/\n//g;

            my $cnt       = 0;
            my $firstline = 1;
            my $tab       = 4;
            my $wrapped   = 0;
            while ( $string =~ /(.)/g ) {
                $cnt++;

                my $c = $1;
                print $c;

                if ( $c =~ /[ \,]/ && $firstline && $cnt > $screen_width ) {
                    print "\n" . " " x ( $column_w + 3 + $tab );
                    $firstline = 0;
                    $cnt       = 0;
                    $wrapped   = 1;
                }
                elsif ($c =~ /[ \,]/
                    && !$firstline
                    && $cnt > ( $screen_width - $column_w ) )
                {
                    print "\n" . " " x ( $column_w + 3 + $tab );
                    $cnt     = 0;
                    $wrapped = 1;
                }
            }
            print "\n";
            print "\n" if $wrapped;
        }
        else {
            print color 'bold';
            print $title;
            print color 'reset';
            print " " x $padding;
            print " - ";
            $$arg[0] = ' ' unless $$arg[0];
            print join " ", @$arg;
            print "\n";
        }

    }
}

sub error {
    my @msg = @_;
    print STDERR color 'red';
    print STDERR join( "\n", @msg ), "\n";
    print STDERR color 'reset';
}

sub info {
    my @msg = @_;
    print STDERR color 'green';
    print STDERR join( "\n", @msg ), "\n";
    print STDERR color 'reset';
}

sub notice {
    my @msg = @_;
    print STDERR color 'bold yellow';
    print STDERR join( "\n", @msg ), "\n";
    print STDERR color 'reset';
}

sub dialog_yes_default {
    my $msg = shift;
    local $|;
    print STDERR $msg;
    print STDERR ' (Y/n) ';

    my $a = <STDIN>;
    chomp $a;
    if ( $a =~ /n/ ) {
        return 0;
    }
    return 1 if $a =~ /y/;
    return 1;    # default to Y
}

1;
