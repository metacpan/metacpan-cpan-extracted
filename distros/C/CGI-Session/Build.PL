# $Id: Build.PL 336 2006-10-26 02:17:31Z markstos $

use strict;

use File::Spec;
use Module::Build;
use Text::Wrap;

# ------------------------------------------------

sub create_changelog_ini
{
	my($error);

	eval "require Module::Metadata::Changes";

	if ($@)
	{
		$error = $@;
	}
	else
	{
		# Ensure Changelog.ini is writable.

		if (-e 'Changelog.ini' && ! -w 'Changelog.ini')
		{
			$error = (chmod 0200, 'Changelog.ini' == 0) ? 'Could not make Changelog.ini writable' : '';
		}

		if (! $error)
		{
			eval
			{
				print "Regenerating Changelog.ini...\n";

				`ini.report.pl -c -i Changes`;

				if (! -e 'Changelog.ini')
				{
					# Warning: Can't use $@ to carry msg out of block(s).

					$error = 'Failed to generate Changelog.ini';
				}
				else
				{
					my(@stat) = stat 'Changelog.ini';

					# Was the file modified in the last 2 seconds?

					if ( (time() - $stat[9]) < 2)
					{
						# Yes. Do nothing.
					}
					else
					{
						$error = 'Failed to update Changelog.ini';
					}
				}
			};

			if ($@)
			{
				$error = $@;
			}
		}
	}

	# We ignore the precise value of $@ here.

	if ($error)
	{
		print "Warning: Module::Metadata::Changes's ini.report.pl failed to generate or update Changelog.ini. \n";
	}
	else
	{
		print "Changelog.ini generated or updated. \n";
	}

} # End of create_changelog_ini.

# ------------------------------------------------

# Some of the scripts need ./t/sessiondata to be present.

mkdir(File::Spec->catfile('t', 'sessiondata'));

print "-" x 40, "\n";
print fill("", "", <<'MESSAGE');
#### WARNING ####

If you are using custom CGI::Session drivers they may not be compatible with the current driver specifications. You will need to make some changes to your drivers' code before proceeding with this installation to make it compatible with CGI::Session 4.x.

Fortunately, current driver specifications are a lot easier to adapt to. Should you have any assistance re-coding your current drivers, please let me know.

Current driver specs are documented in CGI/Session/Driver.pm

#### TESTING #####

You are encouraged to run tests for the backend you will be using. The database backends that need a customized connection string won't run by default. To run them, some environment variables must be set.

The simplest method is to use the standard "DBI_DSN/DBI_USER/DBI_PASS" environment variables.

Otherwise, you can set these variables:
MESSAGE

print "
For PostgreSQL:
    CGISESS_PG_DSN
    CGISESS_PG_USER
    CGISESS_PG_PASS

For MySQL:
    CGISESS_MYSQL_DSN
    CGISESS_MYSQL_USER
    CGISESS_MYSQL_PASS
    CGISESS_MYSQL_SOCKET
";

print "\n";
print "-" x 40, "\n";

create_changelog_ini();
print "-" x 40, "\n";

Module::Build -> new
(
	module_name    => 'CGI::Session',
	license        => 'artistic',
	dist_abstract  => 'Persistent session data in CGI applications',
	dist_author    => 'Sherzod Ruzmetov <sherzodr@cpan.org>',
    configure_requires => { 'Module::Build' => 0.38 },
	build_requires =>
	{
#		'Test::Differences' => 0,
		'Test::More'        => 0,
	},
	requires =>
	{
        'CGI'          => 3.26,
		'Data::Dumper' => 0,
		'Digest::MD5'  => 0,
		'Scalar::Util' => 0,
	},
    no_index => {
        'package' => [ 
            'CGI::Session::Test::SimpleObjectClass',
            'CGI::Session::Test::Default',
            'OverloadedObjectClass',
            'OverloadedClass',
        ],
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/cromedome/cgi-session',
        },
        keywords => [
            'session','http',
        ],
    },
) -> create_build_script();
