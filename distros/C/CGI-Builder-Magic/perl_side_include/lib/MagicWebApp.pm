# this application responds to 3 page names:
# start, show_env and show_mix

package MagicWebApp ;
use Apache::CGI::Builder
  qw| CGI::Builder::Magic
    |;

# defaults are fine so nothing to define here

package MagicWebApp::Lookups ;
# all the runtime values of variables and subs
# will substituted in any template that uses
# a label or block with a matching identifier (name)
# look at the templates to see how they are used

our $app_name = 'MagicWebApp 1.0' ;

sub Time { scalar localtime }

sub page_name { $_[0]->page_name }

sub ENV_table {
    my @table ;
    while (my @line = each %ENV) {
        push @table, \@line
    }
    \@table
}
   
sub REQUEST_URI { $ENV{REQUEST_URI} }

1 ;
