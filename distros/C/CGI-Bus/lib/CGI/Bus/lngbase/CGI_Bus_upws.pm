#!perl -w
#
# admiral 
# 01/01/2002
#
# 

package CGI::Bus::lngbase::CGI_Bus_upws; # Language base
use strict;

1;

sub lngbase {
 ('WorkSpace'   =>['WorkSpace', '']
 ,'Login'       =>['Login',     'Login to the System']
 ,'Home'        =>['Home',      'Home Page URL']
 ,'Overview'    =>['Overview',  'Overview Page or Frameset']
 ,'Index'       =>['Contents',  'Heading or Index page']
 ,'Search'      =>['Search',    'Find in $_ filesystem']
 ,'USites'      =>['HomePages', 'Users pages, create in your\'s publishing directory one of the files $_!']
 ,'USFHomes'    =>['GrpFiles',  'User\'s group files network home directory']
 ,'USFHome'     =>['PsnFiles',  'User\'s files network home directory']
 ,'Setup'       =>['Setup',     'User Setup of $_']
 ,'Logout'      =>['Logout',    'Logout from the System, became guest']
#,'Data Saved' 
#,'Data Loaded'
 ,'User'        =>['User',         'User name']
 ,'Managed'     =>['Managed',      'Managed Users, comma separated']
 ,'Groups'      =>['Groups',       'Groups user belongs to, comma separated']
 ,'HomeURL'     =>['HomeURL',      'URL to open at first; alternativelly the first screen may be defined as an \'Overview\' Frameset or HTML']
 ,'FramesetURLs'=>['OverviewURLs', '\'Overview\' frameset URLs, one URL per row, or \'Overview\' page HTML; this page may be opened as the first too']
 ,'FramesetRows'=>['FramesetRows', 'Heights of the frames, digits with % signs, delimited with commas']
 ,'FramesetCols'=>['FramesetCols', 'Widths of the frames, digits with % signs, delimited with commas']
 ,'FavoriteURLs'=>['FavoriteURLs', 'URLs for navigation pane, one URL per row as \'label|URL\', \'label|_blank|URL\', \'label|_parent|URL\', \'label|URL|_target|URL\', or HTML']
 ,'PrimaryRole' =>['PrimaryRole',  'Favorite, most oftenly used group user belongs to']
 ,'Read'        =>['Read',         'Read data']
 ,'Save'        =>['Save',         'Store data']
 ,'Refresh'     =>['Refresh',      'Reread or recalculate data']
 )
}

