
use ExtUtils::MakeMaker;

print <<'eof';
=======================================================================
           __      __    _     ___   _  _   ___   _  _    ___
           \ \    / /   /_\   | _ \ | \| | |_ _| | \| |  / __|
            \ \/\/ /   / _ \  |   / | .` |  | |  | .` | | (_ |
             \_/\_/   /_/ \_\ |_|_\ |_|\_| |___| |_|\_|  \___|

=======================================================================

 This module probably doesn't do what you expect it to do. Do not
 continue unless you have carefully read the documentation.

 Using this module can cause strange errors unless you understand it
 properly.

 Here's an example:

 $dt = new DateTime::LazyInit( year  => 2005, month => 32 );

 Normal DateTime will die at this point. However there is NO VALIDATION
 in this module. It WILL NOT DIE .. YET!

 $dt->month; # 32 -- sure it's illegal, but it's what we asked for.

 $dt->add( days => 1 ); # DIE #

 NOW it will die because we're doing something complex with the object
 and we've inflated it into a full DateTime object. Full DateTime
 objects validate the parameters and THERE IS NO month 32!

 This message is repeated in the README file.

=======================================================================
Press return to acknowledge that you've read this warning.
eof
{my $j=<>}


WriteMakefile(
    NAME              => 'DateTime::LazyInit',
    VERSION_FROM      => 'lib/DateTime/LazyInit.pm',
    PREREQ_PM         => {
		DateTime => 0.26,
	},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/DateTime/LazyInit.pm',
       AUTHOR         => 'Rick Measham <rickm@cpan.org>') : ()),
);
