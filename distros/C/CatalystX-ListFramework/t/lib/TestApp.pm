package TestApp;
use CatalystX::ListFramework;
use CatalystX::ListFramework::Helpers;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

use Catalyst qw/-Debug StackTrace
            
            HTML::Widget
            
            Static::Simple
           /;

our $VERSION = '0.01';
__PACKAGE__->config->{static}->{include_path} = [ 'static' ];
__PACKAGE__->config( name => 'TestApp' );

use FindBin qw($Bin);
# Path needs to vary depending on whether we're running live-test.t or lib/script/testapp_*.pl
foreach my $dir ('', '../..') {
    if (-x "$Bin/$dir/formdef") {
        __PACKAGE__->config( formdef_path => "$Bin/$dir/formdef" );
        __PACKAGE__->config( sql_path => "$Bin/$dir/sql" );
    }
}
# Start it up
__PACKAGE__->setup;

1;
