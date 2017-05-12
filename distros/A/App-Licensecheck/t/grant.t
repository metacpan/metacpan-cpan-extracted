use strictures 2;

use Test::Roo;
use App::Licensecheck;

has encoding => ( is => 'ro' );
has license  => ( is => 'ro', required => 1 );
has corpus   => ( is => 'ro' );

sub _build_description { return shift->license }

test "Parse corpus" => sub {
	my $self = shift;

	my $app = App::Licensecheck->new;
	$app->lines(0);
	$app->deb_fmt(1);
	$app->encoding( $self->encoding ) if $self->encoding;

	foreach (
		ref( $self->corpus ) eq 'ARRAY' ? @{ $self->corpus } : $self->corpus )
	{
		my ( $license, $copyright ) = $app->parse("t/grant/$_");
		is( $license, $self->license, "Corpus file $_" );
	}
};

# AFL
run_me(
	{   license => 'AFL-2.0 and/or LGPL-2+',
		corpus  => 'AFL_and_more/xdgmime.c'
	}
);
TODO: {
	local $TODO = 'not yet handled';
	run_me(
		{   license => 'AFL-2.0 or LGPL-2+',
			corpus  => 'AFL_and_more/xdgmime.c'
		}
	);
}

# AGPL
run_me( { license => 'AGPL-3+', corpus => 'AGPL/fastx.c' } );
run_me( { license => 'AGPL-3+', corpus => 'AGPL/fet.cpp' } );
run_me( { license => 'AGPL-3+', corpus => 'AGPL/setup.py' } );

# Apache
run_me(
	{ license => 'Apache-2.0 or GPL-2', corpus => 'Apache_and_more/PIE.htc' }
);
run_me(
	{   license => 'Apache-2.0 or MIT~unspecified',
		corpus  => 'Apache_and_more/rust.lang'
	}
);
run_me(
	{   license => 'Apache-2.0 or GPL-2',
		corpus  => 'Apache_and_more/select2.js'
	}
);
run_me(
	{   license => 'Apache-2.0 or BSD-3-clause',
		corpus  => 'Apache_and_more/test_run.py'
	}
);

# CC-BY-SA
run_me(
	{   license => 'CC-BY-SA-3.0',
		corpus  => 'CC-BY-SA_and_more/WMLA'
	}
);
run_me(
	{   license => 'CC-BY-SA-2.0 or GPL-3',
		corpus  => 'CC-BY-SA_and_more/cewl.rb'
	}
);
run_me(
	{   license => 'CC-BY-SA-3.0 or LGPL-2',
		corpus  => 'CC-BY-SA_and_more/utilities.scad'
	}
);

# EPL
run_me(
	{   license => 'AGPL-3+ and/or Apache-2.0+ and/or LGPL-2.1+ or GPL-3+',
		corpus  => 'EPL_and_more/Base64Coder.java'
	}
);
TODO: {
	local $TODO = 'not yet handled';
	run_me(
		{   license => 'AGPL-3+ or Apache-2.0+ or GPL-3+ or LGPL-2.1+',
			corpus  => 'EPL_and_more/Base64Coder.java'
		}
	);
}

# LGPL
run_me( { license => 'LGPL-2.1', corpus => 'LGPL/Model.pm' } );
TODO: {
	local $TODO = 'not yet handled';
	run_me( { license => 'LGPL', corpus => 'LGPL/PKG-INFO' } );
}
run_me( { license => 'LGPL-2.1',  corpus => 'LGPL/criu.h' } );
run_me( { license => 'LGPL',      corpus => 'LGPL/dqblk_xfs.h' } );
run_me( { license => 'LGPL',      corpus => 'LGPL/exr.h' } );
run_me( { license => 'LGPL-2.1',  corpus => 'LGPL/gnome.h' } );
run_me( { license => 'LGPL',      corpus => 'LGPL/jitterbuf.h' } );
run_me( { license => 'LGPL-2.1',  corpus => 'LGPL/libotr.m4' } );
run_me( { license => 'LGPL-3',    corpus => 'LGPL/pic.c' } );
run_me( { license => 'LGPL-2.1+', corpus => 'LGPL/strv.c' } );
run_me( { license => 'LGPL-2+',   corpus => 'LGPL/table.py' } );
run_me(
	{ license => 'LGPL-2.1 or LGPL-3', corpus => 'LGPL/videoplayer.cpp' } );
run_me(
	{   license => 'LGPL-2.1 or GPL-2.0 and/or MPL-1.1',
		corpus  => 'LGPL_and_more/da.aff'
	}
);
TODO: {
	local $TODO = 'not yet handled';
	run_me(
		{   license => 'GPL-2 or LGPL-2.1 or MPL-1.1',
			corpus  => 'LGPL_and_more/da.aff'
		}
	);
}

# MPL
run_me(
	{   license => 'GPL-2+ or LGPL-2.1+ and/or MPL-1.1',
		corpus  => 'MPL_and_more/symbolstore.py'
	}
);
TODO: {
	local $TODO = 'not yet handled';
	run_me(
		{   license => 'GPL-2+ or LGPL-2.1+ or MPL-1.1',
			corpus  => 'MPL_and_more/symbolstore.py'
		}
	);
}

# misc
run_me(
	{   license => 'GPL-3 and/or LGPL-2.1 or LGPL-3',
		corpus  => 'misc/rpplexer.h'
	}
);
TODO: {
	local $TODO = 'not yet handled';
	run_me(
		{   license =>
				'GPL-3 or LGPL-2.1 with Qt exception or LGPL-3 with Qt exception or Qt',
			corpus => 'misc/rpplexer.h'
		}
	);
}

# MIT
run_me(
	{   license => 'MIT~old',
		corpus  => 'MIT/harfbuzz-impl.c'
	}
);
run_me(
	{   license => 'MIT~oldstyle~permission',
		corpus  => 'MIT/spaces.c'
	}
);

# NTP
run_me(
	{   license => 'NTP',
		corpus  => [
			qw<NTP/helvO12.bdf NTP/install.sh NTP/directory.h NTP/map.h NTP/monlist.c>
		]
	}
);
run_me(
	{   license => 'NTP~disclaimer',
		corpus  => 'NTP/gslcdf-module.c'
	}
);

# WTFPL
run_me(
	{   license => 'WTFPL-1.0',
		corpus  => 'WTFPL/COPYING.WTFPL'
	}
);

done_testing;
