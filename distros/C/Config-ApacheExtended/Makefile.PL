use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Config::ApacheExtended',
#    VERSION_FROM => 'lib/Config/ApacheExtended.pm', # finds $VERSION
    VERSION_FROM => 'VERSION', # finds $VERSION
    AUTHOR       => 'Michael Grubb (mgrubb-cpan@fifthvision.net)',
    ABSTRACT_FROM	=> 'lib/Config/ApacheExtended.pm',
    PREREQ_PM    => {
					 'Carp'						=> '0',
					 'File::Spec::Functions'	=> '1.1',
					 'IO::File'					=> '1.07',
					 'Parse::RecDescent'		=> '1.94',
					 'Scalar::Util'				=> '1.07',
                     'Test::More'				=> '0.44',
					 'Text::Balanced'			=> '1.89',
                    },
);

# This is a convenience target for rebuilding the lexer
package MY;
sub constants
{
	my $inherited = shift->SUPER::constants(@_);
	return
		"GRAMMAR_FILE = grammar.prd\n" .
		"GRAMMAR_SCRIPT = scripts/create_parser.pl\n" .
		$inherited;
}

sub top_targets
{
	my $inherited = shift->SUPER::top_targets(@_);
	return
		"$inherited\n" .
		"rebuild_grammar :: \$(GRAMMAR_FILE) \$(GRAMMAR_SCRIPT)\n" .
		"\t\@\$(GRAMMAR_SCRIPT) lib \$(GRAMMAR_FILE) '\$(NAME)::Grammar'\n";
}
