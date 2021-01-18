use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More tests => 3;
use CGI;
use Data::FormValidator;
BEGIN {
    use_ok( 'Data::FormValidator::Filters::WikiTrim', qw(wiki_trim) );
}

###############################################################################
# Data to filter, and expected results.
my $text = q{  
	
	  
  	
    * first
    * second
    * third
    
    };
my $expect = q{    * first
    * second
    * third};

###############################################################################
my $cgi = CGI->new( { 'text' => $text } );
my $profile = {
    'required' => 'text',
    'field_filters' => {
        'text' => [wiki_trim()],
        },
    };
my $results = Data::FormValidator->check( $cgi, $profile );
my $valid   = $results->valid();

ok( exists $valid->{'text'},    'text valid' );
is( $valid->{'text'}, $expect,  'text filtered correctly' );
