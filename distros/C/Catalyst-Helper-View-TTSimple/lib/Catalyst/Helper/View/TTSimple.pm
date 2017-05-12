package Catalyst::Helper::View::TTSimple;

use warnings;
use strict;
use File::Spec;

=head1 NAME

Catalyst::Helper::View::TTSimple - Simplified TT layout for building web sites.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

use the helper to build the view module and associated templates.

	$ script/myapp_create.pl view TT TTSimple

=head1 DESCRIPTION

This helper module creates a simple TT skeleton layout in your catalyst project. It goes further than Catalyst::Helper::View::TT and a bit less than Catalyst:Helper::View::TTSite in that it creates just the bare essentials to get you started.

=head2 What gets generated?

This creates a xhtml layout container, javascript directory, stylesheet directory and a TT index which would be encapsulated by the layout. If you have ever worked with Rails this should be very familiar to you.

	project_root/
		root/
			site/
				layout (the xhtml layout)
				wrapper (wraps content to layout)
			config/
				main  (main configuration processed before anything)
			src/
				index.tt2 (encapsulated index file)


=cut

=head2 METHODS

=head3 mk_compclass

Generates the component class.

=head3 mk_templates

Generates the templates.

=cut

sub mk_compclass {
    my ( $self, $helper, @args ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
    $self->mk_templates( $helper, @args );
}

sub mk_templates {
	my ($self,$helper)=@_;
	
	my $base = $helper->{base};
    my $stdir = File::Spec->catfile($base, 'root', 'static' , 'stylesheets');
    my $jtdir = File::Spec->catfile($base, 'root', 'static' , 'javascripts');
    my $idir = File::Spec->catfile($base,'root', 'static' , 'images');
    my $ldir = File::Spec->catfile( $base, 'root', 'lib' );
    my $sdir = File::Spec->catfile( $base, 'root', 'src' );
	my $cdir = File::Spec->catfile( $ldir, 'config' );
	my $sitedir = File::Spec->catfile( $ldir, 'site' );
	
    $helper->mk_dir($ldir);
    $helper->mk_dir($sdir);
    $helper->mk_dir($stdir);
    $helper->mk_dir($jtdir);
    $helper->mk_dir($cdir);
    $helper->mk_dir($sitedir);

    $helper->render_file( "config_main",
        File::Spec->catfile( $cdir, "main" ) );

    foreach my $file (qw( wrapper layout )) {
        $helper->render_file( "site_$file",
            File::Spec->catfile( $sitedir, $file ) );
    }
	
	$helper->mk_file(File::Spec->catfile($jtdir,'application.js'),'');
	$helper->mk_file(File::Spec->catfile($stdir,'master.css'),'');
	$helper->render_file("index.tt2", File::Spec->catfile($sdir,'index.tt2'));	
}

=head1 AUTHOR

Victor Igumnov, C<< <victori at lamer0.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-helper-view-ttsimple at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Helper-View-TTSimple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Helper::View::TTSimple

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Helper-View-TTSimple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Helper-View-TTSimple>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Helper-View-TTSimple>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Helper-View-TTSimple>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Victor Igumnov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    CATALYST_VAR => 'c',
    INCLUDE_PATH => [
        [% app %]->path_to( 'root', 'src' ),
        [% app %]->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    TIMER        => 0
});
 

=head1 NAME

[% class %] - Catalyst TTSimple View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst TTSimple View.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__config_main__
[% USE Date;
   year = Date.format(Date.now, '%Y');
-%]
[% TAGS star -%]
[% # config/main
   #
   # This is the main configuration template which is processed before
   # any other page, by virtue of it being defined as a PRE_PROCESS 
   # template.  This is the place to define any extra template variables,
   # macros, load plugins, and perform any other template setup.

   IF Catalyst.debug;
     # define a debug() macro directed to Catalyst's log
     MACRO debug(message) CALL Catalyst.log.debug(message);
   END;

   # define a data structure to hold sitewide data
   site = {
     title     => 'Catalyst::View::TTSimple Example Page',
     copyright => '[* year *] Your Name Here',
   };

-%]

__site_wrapper__
[% TAGS star -%]
[% IF template.name.match('\.(css|js|txt)');
     debug("Passing page through as text: $template.name");
     content;
   ELSE;
     debug("Applying HTML page layout wrappers to $template.name\n");
     content WRAPPER site/layout;
   END;
-%]

__site_layout__
[% USE Date;
   year = Date.format(Date.now, '%Y');
-%]
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<meta http-equiv="Content-type" content="text/html; charset=utf-8" />
		<meta http-equiv="Content-Language" content="en-us" />
		
		<meta name="ROBOTS" content="ALL" />
		<meta http-equiv="imagetoolbar" content="no" />
		<meta name="MSSmartTagsPreventParsing" content="true" />
		<meta name="Copyright" content="(c) [% year %] Copyright content:  Copyright design: your name" />
		<!-- (c) Copyright [% year %] by your name All Rights Reserved. -->
		
		<meta name="Keywords" content="__KEYWORDS__" />
		<meta name="Description" content="__DESCRIPTION__" />
		
		[% TAGS star -%]
		<title>[% site.title %]</title>
		
		<link href="/static/stylesheets/master.css" rel="stylesheet" type="text/css" media="all" />
		
		<!-- import the DOM logic from external javascript files -->
		<script type="text/javascript" src="/static/javascripts/application.js"></script>		
	</head>
	
	<body>
[% content %]
	</body>
</html>

__index.tt2__
<p>Welcome to your Simple TT View!</p>
