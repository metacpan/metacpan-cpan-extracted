use ExtUtils::MakeMaker;


# The purpose of this section is to add "use utf8;" before the BEGIN
# statement of modules in Date-Ethiopic so that the package is forward
# and backward compatibily with Perl versions.

# if ( $] >= 5.006 ) {
if ( 0 ) {

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
			print $newh "use utf8;\n" if ( /^BEGIN/ );
			print $newh $_;
		}
		close ($newh);
		close ($oldh);
		rename ($newpm, $oldpm);
	}

}

} # end if ( $] >= 5.006 )



# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		=> 'DateTime::Calendar::Coptic',
	DISTNAME	=> 'DateTime-Calendar-Coptic',
	VERSION_FROM	=> 'lib/DateTime/Calendar/Coptic.pm', # finds $VERSION
	AUTHOR  	=> "Daniel Yacob <dyacob\@cpan.org>",
	ABSTRACT	=> "Coptic Calendar System.",
	PREREQ_PM 	=> { 'DateTime' => 0, 'Convert::Number::Coptic' => 0 },

	dist			=>	{
		COMPRESS        =>	"gzip -9f",
		SUFFIX          =>	"gz",
		POSTOP          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	}
);
