use 5.006000;
use ExtUtils::MakeMaker;

use constant PROMPT_SKIP => 
'Using CSS selectors requires HTML::Selector::XPath.
Without it only XPath is available.
Do you want to use CSS selectors? [Y/n]';

use constant HAS_SELECTOR => eval {
    require HTML::Selector::XPath;
};

my $prereq_pm = {
    'XML::LibXML'	=> '0', 
    'Parse::RecDescent' => '0',
};

if (!HAS_SELECTOR) {
    my $skip = prompt(PROMPT_SKIP, 'y');
    if ($skip !~ /^n/i) {
        $prereq_pm->{'HTML::Selector::XPath'} = 0;
    }
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Cindy',
    VERSION_FROM      => 'lib/Cindy.pm', # finds $VERSION
    PREREQ_PM         => $prereq_pm, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Cindy.pm', # retrieve abstract from module
       AUTHOR         => 'JZOBEL (jz-2009@heute-morgen.de)') : ()),
);
