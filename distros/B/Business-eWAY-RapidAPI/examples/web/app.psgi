#!/usr/bin/perl

use FindBin qw/$Bin/;
use Plack::App::CGIBin;
use Plack::App::File;
use Plack::Builder;

my $app = Plack::App::CGIBin->new( root => "$Bin/cgi-bin" )->to_app;
builder {
    mount "/cgi-bin" => $app;
    mount
      '/Images' => Plack::App::File->new( root => "$Bin/Images" ),
      mount
      '/Scripts' => Plack::App::File->new( root => "$Bin/Scripts" ),
      mount
      '/Styles' => Plack::App::File->new( root => "$Bin/Styles" ),

};
