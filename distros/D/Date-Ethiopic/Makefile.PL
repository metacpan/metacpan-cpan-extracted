use ExtUtils::MakeMaker;


# The purpose of this section is to add "use utf8;" before the BEGIN
# statement of modules in Date-Ethiopic so that the package is forward
# and backward compatibily with Perl versions.

if ( $] < 5.006 ) {

print "Adjusting for pre-Perl 5.6 ... ".

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



# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Date::Ethiopic',
	'DISTNAME'	=> 'Date-Ethiopic',
	'VERSION_FROM'	=> 'lib/Date/Ethiopic.pm', # finds $VERSION
	'AUTHOR'  	=> "Daniel Yacob <dyacob\@cpan.org>",
	'ABSTRACT'	=> "ICalendar for the Ethiopic Calendar System.",
	'dist'		=>	{
		'COMPRESS'        =>	"gzip -9f",
		'SUFFIX'          =>	"gz",
		'POSTOP'          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
	'PREREQ_PM' 	=> { 'Date::ICal' => 0, 'Convert::Number::Ethiopic' => '0.15' },
	'LICENSE'	=> 'perl',
	'MIN_PERL_VERSION' => '5.6.1'
);
