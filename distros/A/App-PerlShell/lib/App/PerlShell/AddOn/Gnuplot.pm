package App::PerlShell::AddOn::Gnuplot;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;
use Pod::Usage;
use Pod::Find qw( pod_where );

eval "use Chart::Gnuplot";
if ($@) {
    print "Chart::Gnuplot required.\n";
    return 1;
}

use Exporter;

our @EXPORT = qw(
  Gnuplot
  gnuplot
  gnuterm
  gnuscript
  chart
  dataset
);

our @ISA = qw ( Exporter );

# Set gnuplot global config
$ENV{PERLSHELL_GNUPLOT}      = 'gnuplot';
$ENV{PERLSHELL_GNUPLOT_TERM} = 'wxt';

# Update gnuplot program location for Windows by searching Path/PathExt
if ( $^O eq 'MSWin32' ) {
    my @paths = split /;/, $ENV{'PATH'};
    my @exts  = split /;/, $ENV{'PATHEXT'};
    my $FOUND = 0;
    for my $path (@paths) {
        $path =~ s/\\$//;
        $path .= "\\";
        for my $ext (@exts) {
            my $gnuplot = $path . $ENV{PERLSHELL_GNUPLOT} . "$ext";
            if ( -e $gnuplot ) {
                $ENV{PERLSHELL_GNUPLOT} = $gnuplot;
                $FOUND++;
                last;
            }
            if ($FOUND) { last }
        }
    }
}

sub Gnuplot {
    pod2usage(
        -verbose => 2,
        -exitval => "NOEXIT",
        -input   => pod_where( {-inc => 1}, __PACKAGE__ )
    );
}

########################################################

sub gnuplot {
    my %params = ( gnuplot => '' );

    if ( @_ == 1 ) {
        ( $params{gnuplot} ) = @_;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{gnuplot} = shift;
        }

        #%args = @_
    }

    if ( defined( $params{gnuplot} ) and ( $params{gnuplot} ne '' ) ) {
        $ENV{PERLSHELL_GNUPLOT} = $params{gnuplot};
    }
    if ( defined wantarray ) {
        return $ENV{PERLSHELL_GNUPLOT};
    } else {
        print $ENV{PERLSHELL_GNUPLOT} . "\n";
    }
}

sub gnuterm {
    my %params = ( gnuplot_term => '' );

    if ( @_ == 1 ) {
        ( $params{gnuplot_term} ) = @_;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{gnuplot_term} = shift;
        }

        #%args = @_
    }

    if ( defined( $params{gnuplot_term} )
        and ( $params{gnuplot_term} ne '' ) ) {
        $ENV{PERLSHELL_GNUPLOT_TERM} = $params{gnuplot_term};
    }
    if ( defined wantarray ) {
        return $ENV{PERLSHELL_GNUPLOT_TERM};
    } else {
        print $ENV{PERLSHELL_GNUPLOT_TERM} . "\n";
    }
}

sub gnuscript {
    my ($arg) = @_;

    if ( not defined $arg ) {
        _help( "COMMANDS/gnuscript - return Gnuplot script" );
        return;
    }

    my @rets;
    my $retType = wantarray;

    if ( ( ref $arg ) ne "" ) {
        if ( ( ref $arg ) =~ /^Chart::Gnuplot/ ) {
            if ( defined $retType ) {
                push @rets, $arg->{_script};
            } else {
                printf "%s\n", $arg->{_script};
            }
            my $fh;
            if ( not open( $fh, '<', $arg->{_script} ) ) {
                warn( "Cannot open file - `" . $arg->{_script} . "'" );
                return;
            }
            my @lines = <$fh>;
            close($fh);

            for my $line (@lines) {
                chomp $line;
                my @parts = split / /, $line;
                for my $part (@parts) {
                    if ( $part =~ /[\/\\]data['"]$/ ) {
                        $part =~ s/'//g;
                        $part =~ s/"//g;
                        if ( defined $retType ) {
                            push @rets, $part;
                        } else {
                            printf "%s\n", $part;
                        }
                    }
                }
            }

            if ( not defined $retType ) {
                return;
            } elsif ($retType) {
                return @rets;
            } else {
                return \@rets;
            }
        }
    }
}

########################################################

sub chart {
    my %params;

    if ( @_ == 1 ) {
        ( $params{title} ) = @_;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{title} = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    return Chart::Gnuplot->new(
        gnuplot  => $ENV{PERLSHELL_GNUPLOT},
        terminal => $ENV{PERLSHELL_GNUPLOT_TERM},
        %params
    );
}

sub dataset {
    my %params;

    if ( @_ == 1 ) {
        ( $params{ydata} ) = @_;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{ydata} = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    return Chart::Gnuplot::DataSet->new(%params);
}

sub _help {
    my ($section) = @_;

    pod2usage(
        -verbose  => 99,
        -exitval  => "NOEXIT",
        -sections => $section,
        -input    => pod_where( {-inc => 1}, __PACKAGE__ )
    );
}

1;

__END__

=head1 NAME

Gnuplot - Gnuplot

=head1 SYNOPSIS

 use App::PerlShell::AddOn::Gnuplot;

=head1 DESCRIPTION

This module implements Gnuplot integration with L<Chart::Gnuplot>.

=head1 COMMANDS

=head2 Gnuplot - provide help

Provides help from the shell.

=head2 gnuplot - get or set gnuplot program

 [$gnuplot =] gnuplot 'path_and_gnuplot_program'

Get or set B<gnuplot> program location.  No argument displays B<gnuplot> 
program location.  Single argument sets B<gnuplot> program location.  
Optional return value is B<gnuplot> program location.

=head2 gnuterm - get or set gnuplot terminal

 [$gnuterm =] gnuterm 'gnuplot_term_type'

Get or set B<gnuplot> terminal type.  No argument displays B<gnuplot> 
terminal type.  Single argument sets B<gnuplot> terminal type.  
Optional return value is B<gnuplot> terminal type.

=head2 gnuscript - return Gnuplot script

 [$script =] gnuscript $chart

Return the B<gnuplot> script created for $chart.  See B<chart> below.

=head1 METHODS

=head2 chart - create chart object

 [$chart =] chart [OPTIONS];

Create B<Chart::Gnuplot> object.  See B<Chart::Gnuplot> for B<OPTIONS>.  
Return B<Chart::Gnuplot> object.

Single option indicates B<title>.

=head2 dataset - create dataset object

 [$dataset =] dataset [OPTIONS];

Create B<Chart::Gnuplot::DataSet> object.  See B<Chart::Gnuplot> for B<OPTIONS>.  
Return B<Chart::Gnuplot::DataSet> object.

Single option indicates B<ydata>.

=head1 EXAMPLES

 chart->plot2d(dataset([0,1,2,3,4,5]));

=head1 SEE ALSO

L<Chart::Gnuplot>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2013, 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
