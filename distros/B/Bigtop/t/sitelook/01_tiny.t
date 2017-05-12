use strict;

use Test::More tests => 2;
use Test::Files;
use File::Spec;
use File::Find;

use Bigtop::Parser;

use lib 't';
use Purge;

my $play_dir = File::Spec->catdir( qw( t sitelook play ) );
my $html_dir = File::Spec->catdir(
        $play_dir, 'Apps-Checkbook', 'html', 'templates'
);
my $wrapper  = File::Spec->catfile( qw( t sitelook sample_wrapper.tt ) );

#-------------------------------------------------------------------
# build wrapper.tt
#-------------------------------------------------------------------

Purge::real_purge_dir( $play_dir );
mkdir $play_dir;

my $bigtop_string = <<"EO_Bigtop_File";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    SiteLook        GantryDefault {
        gantry_wrapper `$wrapper`;
    }
}
app Apps::Checkbook {
    location checks;
    controller is base_controller {
        page_link_label Home;
    }
    controller PayeeOr {
        rel_location    payeeor;
        page_link_label `Payee/Payor`;
    }
    controller Trans {
        location    trans;
    }
}
EO_Bigtop_File

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 'create',
        build_list    => [ 'SiteLook', ],
    }
);

my $correct_wrapper = << 'EO_WRAPPER';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>[% view.title %]</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<link rel="stylesheet" type="text/css" media="screen"
			title="Default" href="[% self.css_rootp %]/default.css" />

    </head>
    <body id="">
	
	<!-- START: top nav logo (using page element style) -->
	<div id="page">
		<img width="740" src="[% self.img_rootp %]/nav_banner3.jpg" 
			alt="Billing Logo" />
	</div>
	<!-- END: top nav logo -->

	<!-- START: top navigation -->
	<div id="nav">
		<div class="lowtech">Site Navigation:</div>	
		<ul>
            <li><a href='[% self.app_rootp %]/'>Home</a></li>
            <li><a href='[% self.app_rootp %]/checks/payeeor'>Payee/Payor</a></li>
            <!-- <li><a href='[% self.app_rootp %]/tasks'>Tasks</a></li> -->
		</ul>
	</div>
	<!-- END: top navigation -->
	
	<br /><br /><br />

	<!-- START: title bar -->
	<div id="title">
		<h1>[% title %]</h1>
		<p>&nbsp;</p>
		<!-- form method="get" action="[% app_rootp %]/search">
		<p>
			<input type="text" name="searchw" value="search" size="10" />
			<input type="submit" value="Disabled" />
		</p>
		</form -->
	</div>
	<!-- END: title bar -->
	
	<!-- START: page -->
	<div id="page">
	
		<!-- START: content -->
		<div id="content">
	
			[% content %]
			
			<br class="clear" />
		</div>
		<!-- END: content -->
	
	</div>
	<!-- END: page -->

	<!-- START: footer -->
	<div id="footer">
		[% USE Date %]
		<p>Page generated on [% Date.format(Date.now, "%A, %B %d, %Y at %l:%M %p") %]
		[% IF r.user; "for $r.user"; END; %]
		<br />
			
		This site is licensed under a 
		<a rel="license" href="http://creativecommons.org/licenses/by/2.0/">
		Creative Commons License</a>,<br />
		except where otherwise noted.
		<br />
		<a rel="license" href="http://creativecommons.org/licenses/by/2.0/">
		<img src="/images/cc.primary.srr.gif" width="88" 
			height="31" alt="Creative Commons License" border="0" /></a>

		</p>
	</div>
	<!-- END: footer -->
	
    </body>
</html>
EO_WRAPPER

my $gened_wrapper = File::Spec->catfile( $html_dir, 'genwrapper.tt' );

file_ok( $gened_wrapper, $correct_wrapper, 'site wrapper' );

Purge::real_purge_dir( $play_dir );

#-------------------------------------------------------------------
# build wrapper.tt without app base location
#-------------------------------------------------------------------

mkdir $play_dir;

$bigtop_string = <<"EO_Bigtop_File_No_Base_Loc";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    SiteLook        GantryDefault {
        gantry_wrapper `$wrapper`;
    }
}
app Apps::Checkbook {
    controller PayeeOr {
        rel_location    payeeor;
        page_link_label `Payee/Payor`;
    }
    controller Trans {
        location    trans;
    }
}
EO_Bigtop_File_No_Base_Loc

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 'create',
        build_list    => [ 'SiteLook', ],
    }
);

$correct_wrapper = << 'EO_WRAPPER';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>[% view.title %]</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<link rel="stylesheet" type="text/css" media="screen"
			title="Default" href="[% self.css_rootp %]/default.css" />

    </head>
    <body id="">
	
	<!-- START: top nav logo (using page element style) -->
	<div id="page">
		<img width="740" src="[% self.img_rootp %]/nav_banner3.jpg" 
			alt="Billing Logo" />
	</div>
	<!-- END: top nav logo -->

	<!-- START: top navigation -->
	<div id="nav">
		<div class="lowtech">Site Navigation:</div>	
		<ul>
            <li><a href='[% self.app_rootp %]/'>Home</a></li>
            <li><a href='[% self.app_rootp %]/payeeor'>Payee/Payor</a></li>
            <!-- <li><a href='[% self.app_rootp %]/tasks'>Tasks</a></li> -->
		</ul>
	</div>
	<!-- END: top navigation -->
	
	<br /><br /><br />

	<!-- START: title bar -->
	<div id="title">
		<h1>[% title %]</h1>
		<p>&nbsp;</p>
		<!-- form method="get" action="[% app_rootp %]/search">
		<p>
			<input type="text" name="searchw" value="search" size="10" />
			<input type="submit" value="Disabled" />
		</p>
		</form -->
	</div>
	<!-- END: title bar -->
	
	<!-- START: page -->
	<div id="page">
	
		<!-- START: content -->
		<div id="content">
	
			[% content %]
			
			<br class="clear" />
		</div>
		<!-- END: content -->
	
	</div>
	<!-- END: page -->

	<!-- START: footer -->
	<div id="footer">
		[% USE Date %]
		<p>Page generated on [% Date.format(Date.now, "%A, %B %d, %Y at %l:%M %p") %]
		[% IF r.user; "for $r.user"; END; %]
		<br />
			
		This site is licensed under a 
		<a rel="license" href="http://creativecommons.org/licenses/by/2.0/">
		Creative Commons License</a>,<br />
		except where otherwise noted.
		<br />
		<a rel="license" href="http://creativecommons.org/licenses/by/2.0/">
		<img src="/images/cc.primary.srr.gif" width="88" 
			height="31" alt="Creative Commons License" border="0" /></a>

		</p>
	</div>
	<!-- END: footer -->
	
    </body>
</html>
EO_WRAPPER

$gened_wrapper = File::Spec->catfile( $html_dir, 'genwrapper.tt' );

file_ok( $gened_wrapper, $correct_wrapper, 'site wrapper, no base location' );

Purge::real_purge_dir( $play_dir );

#-------------------------------------------------------------------
# There used to be a test based on Gantry's default.  When the test
# was written, the bigtop backend still modified it.  This test
# checked those mods.  Now the genwrapper is straight copy of the
# on in Gantry's root directory.  Thus there is nothing but file
# copying to test, and that was tested above.
#-------------------------------------------------------------------
