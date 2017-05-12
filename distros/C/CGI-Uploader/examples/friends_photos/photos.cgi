#!/usr/bin/perl
# arch-tag: e4d2fb56-ed1d-468d-8b54-96f1d6de9f78

# You may need to adjust to this to point to where your CGI::Uploader is stored.
use lib '../../lib';

use CGI::Carp qw(fatalsToBrowser);
package FriendsPhotos;
use strict;
use FriendsPhotos;

use File::Basename;
my $script_dir = dirname($0); 
my $script_url = dirname($ENV{SCRIPT_NAME});


use DBI;

# ADJUST ME
my $dbh = DBI->connect('dbi:Pg:dbname=mark','mark');

use CGI::Uploader::Transform::ImageMagick;
my $app = FriendsPhotos->new(
	PARAMS => {
		dbh => $dbh,
		uploader_args => {
			spec => {
				photo =>  {
                    gen_files => {
                        photo_thumbnail =>  gen_thumb({ w => 100, h => 100}),
                    }
                }
			},
			updir_url  => "$script_url/uploads",
			updir_path => "$script_dir/uploads",
			dbh        => $dbh, 
		},
	}

);

$app->run();

