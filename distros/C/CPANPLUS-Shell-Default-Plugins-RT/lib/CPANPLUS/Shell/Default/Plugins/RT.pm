package CPANPLUS::Shell::Default::Plugins::RT;

use strict;
use LWP::Simple                 qw[get];
use Data::Dumper;
use Params::Check               qw[check];
use CPANPLUS::Error             qw[error msg];
use Locale::Maketext::Simple    Class => 'CPANPLUS', Style => 'gettext';

use vars qw[$VERSION];
$VERSION = '0.01';

my $ListUri = 'http://rt.cpan.org/NoAuth/bugs.tsv?Dist=';
my $ShowUri = 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=';
my $Format  = "  [%6d] [%4s] %s\n";
my $Address = "bug-%s\@rt.cpan.org";

local $Data::Dumper::Indent = 1;

sub plugins { ( rt => 'rt' ) }

sub rt { 
    my $class   = shift;
    my $shell   = shift;
    my $cb      = shift;
    my $cmd     = shift;
    my $input   = shift || '';
    my $opts    = shift || {};

    my $report;
    my $tmpl = {
        report  => { default => 0, store => \$report },
    };
    
    check( $tmpl, $opts ) or (
        error( Params::Check->last_error ),
        return
    );        

    ### no input? wrong usage, show help
    if ( not length $input ) {
        print __PACKAGE__->rt_help;
        return;
    }

    ### find the first module in the list
    ### also gets rid of trailing whitespace
    my @list = split /\s+/, $input;

    ### multiple entries not supported (yet)
    if( @list > 1 ) {
        error(loc("Viewing multiple distributions at once is not supported"));        
    }

    ### use the frontmost instead
    my $try = $list[0];

    if( $try =~ /^\d+$/ ) {
        error(loc("Viewing tickets not yet supported"));
        return;

    ### fetching by name or reporting...
    } else {        

        my $mod = $cb->module_tree( $try ) or (
            error(loc("Could not find '%1' in the module tree", $try )),
            return
        );
        
        ### the package this module is in
        my $dist = $mod->package_name;
        
        ### not reporting, just display the list
        unless( $report ) {
            my $url     = $ListUri . $dist;
            
            msg(loc("Fetching bug list for '%1' from '%2'", $dist, $url ));
            
            my $content = get( $url );
            
            ### some error occurred
            unless( defined $content ) {
                error(loc("Failed to fetch content from '%1'", $url));
                return;
            }                
    
            ### no bugs reported
            if( not length $content ) {
                print "\n", loc("No bugs reported for '%1'", $dist);
                print "\n\n";
    
            ### list the bugs
            } else {
                print "\n", loc("Bug list for '%1':", $dist), "\n\n";
                
                my @list = 
                    sort { $a->[1] <=> $b->[1] }
                    map { [ /^\s*(\S+)\s+(\d+)\s+(.+?)\s+(\w+)\s*$/ ] }
                    split /\n/, $content;
                
                for my $aref ( @list ) {
                    my( $link, $id, $topic, $status ) = @$aref;
                
                    printf $Format, $id, $status, $topic;
                }     
                
                print "\n\n  Web Url: $ShowUri$dist\n\n"; 
            }

        } else {

            error(loc("Submitting reports not yet supported"));
            return;

        }
    }        
}

sub rt_help {
    return loc(
    "    /rt Module::Name\n" .
    "       Retrieves the open bug reports for this module from rt.cpan.org\n".
    "       Viewing a specific bug ticket and reporting a bug are not yet\n" .
    "       supported, but will be in the future\n"
    );    
}

1;
