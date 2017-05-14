name	launchers
--------
table	::Structure::Table::Format::Aggregate_MxOxN
source	::Source::Here::Plain
	*---------------+------------------------------+
	| program       | plugin                       |
	+===============+==============================+
#	| *             | ::User_n_Group               |
#	|               |         mica_env.            |
#	|               + - - - - - - - - - - - - - - -+
#	|               | ::Directory                  |
#	|               |         [=application_base=] |
#	|               + - - - - - - - - - - - - - - -+
#	|               | ::Environment                |
#	|               |         PATH=/bin            |
#	|               + - - - - - - - - - - - - - - -+
#	|               | ::Resource_Limits            |
#	|               |         virtual_memory=128M  |
	*---------------+------------------------------*
column	::Valued::Raw
column	::Valued::Raw

name	features
--------
table	::Structure::Table::Aggregated_MxOxN
source	::Source::Here::Plain
	*---------------+-------------------------*
	| program       | plugin                  |
	+===============+=========================+
	*---------------+-------------------------*
column	::Valued::Raw
column	::Valued::Perl::Package_Name::Wild_With_Parameters
