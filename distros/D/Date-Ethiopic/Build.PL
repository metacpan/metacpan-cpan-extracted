use strict;
use warnings;
use Module::Build;

# The purpose of this section is to add "use utf8;" before the BEGIN
# statement of modules in Date-Ethiopic so that the package is forward
# and backward compatibily with Perl versions.

if ( $] < 5.006 ) {

print "Adjusting for pre-Perl 5.6 ... ";

my $fh;
open ( $fh, "MANIFEST" );
while ( <$fh> ) {
	if ( /lib/ ) {
		chomp;
		my $oldpm = $_;
		my $newpm = "$oldpm.utf8";
		my ($oldh, $newh);
		open ( $oldh, $oldpm );
		open ( $newh, ">$newpm" );
		while ( <$oldh> ) {
			$_ = "# $_" if ( (/^use utf8;/) || ( /use warnings;/ ) );
			print $newh $_;
		}
		close ($newh);
		close ($oldh);
		rename ($newpm, $oldpm);
	}

}

print "done!\n";

} # end if ( $] < 5.006 )

my $builder = Module::Build->new(
	module_name		=> 'Date::Ethiopic',
	dist_version_from	=> 'lib/Date/Ethiopic.pm',
	dist_author		=> 'Daniel Yacob <dyacob\@cpan.org>',
	dist_abstract		=> "ICalendar for the Ethiopic Calendar System.",
	release_status		=> 'stable',
	configure_requires	=> { 'Module::Build' => 0.42 },
	requires 		=> {
		'Date::ICal' => 0,
		'Convert::Number::Ethiopic' => '0.15'
	},
	license			=> 'perl',
	add_to_cleanup		=> [ 'Date-*' ],
	create_makefile_pl	=> 0,  # change to 1 if desired.
	meta_merge		=> {
        	resources => {
			bugtracker => 'https://github.com/dyacob/Date-Ethiopic/issues',
			repository => 'https://github.com/dyacob/Date-Ethiopic.git',
			homepage => 'https://github.com/dyacob/Date-Ethiopic'
		},
		x_authority	=> 'cpan:dyacob'
	}
);

$builder->create_build_script();
