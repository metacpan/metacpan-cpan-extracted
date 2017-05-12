#
# module for CelegansInteractome
#
# Copyright Damien O'Halloran
#
# You may distribute this module under the same terms as perl itself
# History
# December 2, 2016
# POD documentation - main docs before the code

=head1 NAME

CelegansInteractome - generates interactome graphs for a list of C.elegans genes

=head1 SYNOPSIS

 use CelegansInteractome;
 use GraphViz;
 
 my $tmp = CelegansInteractome->new();
 $tmp->load_interactome(
    wormbase_version    => $wormbase_version || "WS239",
    in_file             => $in_file,
    out_file            => $out_file,
    cleanup             => "0"
 );

 # print the interactome graph(s)
 $tmp->graph_interactome();
 

=head1 DESCRIPTION

This object downloads an interaction table for C.elegans from WormBase (www.wormbase.org), then parses the downloaded data and builds a seperate interactome for each gene in a supplied list to return graphical files for each interactome. The supplied list of gene names, should be a text file with one entry per line using WormBase common names. 

=head1 FEEDBACK

damienoh@gwu.edu

=head2 Mailing Lists

User feedback is an integral part of the evolution of this module. Send your comments and suggestions preferably to one of the mailing lists.  Your participation is much appreciated.
  
=head2 Support 

Please direct usage questions or support issues to:
<damienoh@gwu.edu>
Please include a thorough description of the problem with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the GitHub bug tracking system to help keep track of the bugs and their resolution.  Bug reports can be submitted via the GitHub page:

 https://github.com/dohalloran/CelegansInteractome/issues
  
=head1 AUTHORS - Damien OHalloran

Email: damienoh@gwu.edu

=head1 APPENDIX

The rest of the documentation details each of the object
methods.

=cut

# Let the code begin...

package CelegansInteractome;

use warnings;
use strict;
use GraphViz;
use LWP::Simple;

##################################
our $VERSION = '1.2';
##################################

=head2 new()

 Title   : new()
 Usage   : my $tmp = CelegansInteractome->new();
 Function: constructor routine
 Returns : a blessed object
 Args    : none 

=cut

##################################

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    return $self;
}

##################################

=head2 load_interactome()

 Title   : load_interactome()
 Usage   : my $tmp->load_interactome(
            wormbase_version    => $wb_version || "WS239",
            in_file             => $in_file,
            out_file            => $out_file,
            cleanup             => "0"
            );
 Function: Populates the user data into $self hash
 Returns : nothing returned
 Args    : 
 -wormbase_version, version of wormbase to get data from
 -in_file, the name of the files containing a list of genes 
 -out_file, name of the resulting graphical output file(s) 
 -cleanup, option to delete tmp file: 1=yes, 0=no

=cut

##################################

sub load_interactome {
    my ( $self, %arg ) = @_;
    if ( defined $arg{wormbase_version} ) {
        $self->{wormbase_version} = $arg{wormbase_version};
    }
    if ( defined $arg{in_file} ) {
        $self->{in_file} = $arg{in_file};
    }
    if ( defined $arg{out_file} ) {
        $self->{out_file} = $arg{out_file};
    }
    if ( defined $arg{cleanup} ) {
        $self->{cleanup} = $arg{cleanup};
    }
}

###################################

=head2 graph_interactome()

 Title   : graph_interactome()
 Usage   : graph_interactome();
 Function: starts a series of function calls beginning with a sub to download interactome data
 Returns : the interactome data 
 Args    : none

=cut

##################################

sub graph_interactome {
    my ( $self, %arg ) = @_;
    my $content;
    my $out;
    my $ftp_file = 'sample.txt';
    my $version  = $self->{wormbase_version};
    $version =~ s/\s//;
    $version =~ tr/a-z/A-Z/;

    print "Loading and retrieving the list of IDs from Wormbase " . $version
      . "...\n";
    $content = get(
'ftp://ftp.wormbase.org/pub/wormbase/species/c_elegans/annotation/gene_interactions/c_elegans.PRJNA13758.'
          . $version
          . '.gene_interactions.txt.gz' );

    die "Failed to download gene names!" unless $content;
    open( $out, '>:encoding(UTF-8)', $ftp_file )
      or die "Can't create the gene name file $ftp_file: $!\n";

    print $out "$content\n";
    print "\n\ndata successfully downloaded....\n\n";
    close $out;
    _parse_input( $self, %arg );
}

##################################

=head2 _parse_input()

 Title   : _parse_input()
 Usage   : _parse_input();
 Function: replace tabs with commas in downloaded file for easy regex fetching
 Returns : new txt with commas replacing tabs
 Args    : none 

=cut

##################################

sub _parse_input {
    my ( $self, %arg ) = @_;

    open( my $inFileHandle,  '<:encoding(UTF-8)', 'sample.txt' ) or die " $!";
    open( my $outFileHandle, '>:encoding(UTF-8)', 'new.txt' )    or die " $!";

    while ( my $line = <$inFileHandle> ) {
        $line =~ s/\t/,/g;
        print $outFileHandle $line;
    }
    close $inFileHandle;
    close $outFileHandle;
    _get_matches( $self, %arg );
}

##################################

=head2 _get_matches()

 Title   : _get_matches()
 Usage   : _get_matches();
 Function: retrives all the interactome matches for each gene in the input file
 Returns : new tmp txt file with list of matches
 Args    : none

=cut

##################################

sub _get_matches {
    my ( $self, %arg ) = @_;
    print "\n\ncollecting matches....\n\n";
    my $names_file   = $self->{in_file};
    my $new_ftp_file = "new.txt";
    my $outputfile   = "ordered.txt";

    open( my $fh_a, '<:encoding(UTF-8)', $names_file )
      or die "Could not open file $names_file $!";

    while ( my $line = <$fh_a> ) {
        my $id = $line;
        chomp $id;
        $id =~ s/\s//g;
        my $regex = $id;

        open( my $fr_b, '>>:encoding(UTF-8)', $outputfile )
          or die "Could not open file $outputfile $!";

        open( my $fr_c, '<:encoding(UTF-8)', $new_ftp_file )
          or die "Could not open file $new_ftp_file $!";

        while ( my $line = <$fr_c> ) {
            if ( $line =~ m/$regex,.+,.+,(.+),/i ) {
                print $fr_b "$regex\t$1\n";
            }
        }
    }
    close $fh_a;

    #close $fr_b;
    #close $fr_c;
    _sort_matches( $self, %arg );
}

##################################

=head2 _sort_matches()

 Title   : _sort_matches()
 Usage   : _sort_matches();
 Function: organizes matches from the _get_matches() subroutine into single lines
 Returns : a new tmp txt file that contains a list of all macthes to each gene on single lines
 Args    : none 

=cut

##################################

sub _sort_matches {
    my ( $self, %arg ) = @_;
    my $final_out_file = "outputs.txt";
    my %hash;

    sub uniq {
        return keys %{ { map { $_ => 1 } @_ } };
    }

    open( my $fh, '<:encoding(UTF-8)', 'ordered.txt' )
      or die "Could not open file 'ordered.txt' $!";

    open( my $fj, '>>:encoding(UTF-8)', $final_out_file )
      or die "Could not open file $final_out_file $!";

    foreach (<$fh>) {
        $hash{$1} .= $2 if /^(\S+)(\s.*?)[\n\r]*$/;
    }
    close $fh;

    foreach ( sort keys %hash ) {
        my @elements = uniq split /\t/, $hash{$_};
        print $fj "$_\t", join( ' ', sort @elements ), "\n";
    }
    close $fj;
    print "\n\nmatches successfully retrived and sorted....\n\n";
    _handle_graphs( $self, %arg );
}

##################################

=head2 _handle_graphs()

 Title   : _handle_graphs()
 Usage   : _handle_graphs();
 Function: build arrays for GraphViz containing matches
 Returns : a series of arrays are generated
 Args    : none 

=cut

##################################

sub _handle_graphs {
    my ( $self, %arg ) = @_;
    my $graph_file = $self->{out_file};

    my $filename = "outputs.txt";
    open( my $fh, '<:encoding(UTF-8)', $filename )
      or die "Could not open file '$filename' $!";

    while ( my $row = <$fh> ) {
        chomp $row;
        my @interactome_matches = split( / /, $row );
        my $hub = shift @interactome_matches;
        $hub =~ s/\s//g;
        open my $fviz, '>', $hub . $graph_file . ".png"
          or die "Can't open $hub.$graph_file.png, Perl says $!\n";

        my $g = GraphViz->new();

        for ( my $i = 0 ; $i < @interactome_matches ; $i++ ) {
            $g->add_edge( $hub => $interactome_matches[$i] );
        }

        binmode $fviz;
        print $fviz $g->as_png;
        close $fviz;

    }

    close $fh;
    _cleanup( $self, %arg );
}

##################################

=head2 _cleanup()

 Title   : _cleanup()
 Usage   : _cleanup();
 Function: option to delete tmp files
 Returns : nothing
 Args    : 1=yes, 0=no

=cut

##################################

sub _cleanup {
    my ( $self, %arg ) = @_;
    if ( $self->{cleanup} eq "1" ) {
        unlink "sample.txt";
        unlink "new.txt";
        unlink "ordered.txt";
        unlink "outputs.txt";
        print "\n\nall done....\n\n";
    }
    else {
        print "\n\nall done....\n\n";
    }
}

##################################

=head2 get_wormbase_version()

 Title   : get_wormbase_version()
 Usage   : my $get_wormbase_version= $tmp->get_wormbase_version();
 Function: Retrieves the wormbase version used
 Returns : A string of the version e.g. WS239
 Args    : none

=cut

##################################

sub get_wormbase_version {
    my ($self) = @_;
    return $self->{wormbase_version};
}

###################################

=head2 set_wormbase_version()

 Title   : set_wormbase_version()
 Usage   : my $set_wormbase_version = $tmp->set_wormbase_version("WS240");
 Function: Populates the $self->{wormbase_version} property
 Returns : $self->{wormbase_version}
 Args    : the version as a string

=cut

##################################

sub set_wormbase_version {
    my ( $self, $value ) = @_;
    $self->{wormbase_version} = $value;
    return $self->{wormbase_version};
}

###################################

=head2 get_out_file()

 Title   : get_out_file()
 Usage   : my $get_outfile = $tmp->get_out_file();
 Function: Retrieves the output filename
 Returns : A string containing filename
 Args    : none

=cut

##################################

sub get_out_file {
    my ($self) = @_;
    return $self->{out_file};
}

###################################

=head2 set_out_file()

 Title   : set_out_file()
 Usage   : my $set_output = $tmp->set_out_file("myOutPutFile");
 Function: Populates the $self->{out_file} property
 Returns : $self->{out_file}
 Args    : name of the resulting graphical output file(s)

=cut

##################################

sub set_out_file {
    my ( $self, $value ) = @_;
    $self->{out_file} = $value;
    return $self->{out_file};
}

###################################

=head2 get_in_file()

 Title   : get_in_file()
 Usage   : my $get_in_file = $tmp->get_in_file();
 Function: Retrieves the input filename
 Returns : A string containing filename
 Args    : none

=cut

##################################

sub get_in_file {
    my ($self) = @_;
    return $self->{in_file};
}

###################################

=head2 set_in_file()

 Title   : set_in_file()
 Usage   : my $set_in_file= $tmp->set_in_file("myOutPutFile.txt");
 Function: Populates the $self->{in_file} property
 Returns : $self->{in_file}
 Args    : name of the user provided input file

=cut

##################################

sub set_in_file {
    my ( $self, $value ) = @_;
    $self->{in_file} = $value;
    return $self->{in_file};
}

###################################

=head2 get_cleanup()

 Title   : get_cleanup()
 Usage   : my $get_cleanup = $tmp->get_cleanup();
 Function: returns the value option for cleanup
 Returns : 1 or 0
 Args    : none

=cut

###################################

sub get_cleanup {
    my ($self) = @_;
    return $self->{cleanup};
}

###################################

=head2 set_cleanup()

 Title   : set_cleanup()
 Usage   : my $set_cleanup = $tmp->set_cleanup("0");
 Function: Populates the $self->{cleanup} property
 Returns : $self->{cleanup}
 Args    : a command to execute cleanup or not: 1=yes, 0=no

=cut

###################################

sub set_cleanup {
    my ( $self, $value ) = @_;
    $self->{cleanup} = $value;
    return $self->{cleanup};
}

###################################

=head1 LICENSE AND COPYRIGHT

 Copyright (C) 2016 Damien M. O'Halloran
 GNU GENERAL PUBLIC LICENSE
 Version 2, June 1991
 
=cut

1;
