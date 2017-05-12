package MyBuilder;

use strict;
use warnings;

use base 'Module::Build';


# Create the DBIx::Class result classes
sub ACTION_result_classes {
    my $self = shift;

    local @INC = ("lib", @INC);

    require App::Cache;
    require BackPAN::Index::Database;
    require DBIx::Class::Schema::Loader;
    require File::Temp;

    # The SQL schema is in Database.pm.  Only regenerate the
    # result classes if its newer.
    return if $self->up_to_date(
	[
	    "lib/BackPAN/Index/Database.pm",
	],
	[
	    "lib/BackPAN/Index/Dist.pm",
	    "lib/BackPAN/Index/File.pm",
	    "lib/BackPAN/Index/Release.pm",
	],
    );

    my $db = BackPAN::Index::Database->new(
	# The normal cache location is in the home directory.
	# It would be impolite to write to it during build.
	App::Cache->new(
	    directory => File::Temp->new
	)
    );
    $db->create_tables;

    DBIx::Class::Schema::Loader::make_schema_at(
	# We need to customize the schema to only load certain classes.
	# There's no way to do that or tell it not to make the schema.
	# So make a throw away one.
	'BackPAN::Index::SchemaThrowaway',
	{
	    # We'll write our own POD
	    generate_pod        => 0,

	    result_namespace 	=> '+BackPAN::Index',
	    use_namespaces   	=> 1,

	    # Protect us from naming style changes
	    naming           	=> 'v7',

	    inflect_singular 	=> sub {
		my $word = shift;

		# Work around bug in Linua::EN::Inflect::Phrase
		if( $word =~ /^(first|second|third|fourth|fifth|sixth)_/ ) {
		    $word =~ s{s$}{};
		    return $word;
		}
		else {
		    return;
		}
	    },

	    debug 		=> 0,

	    dump_directory	=> 'lib',
	},
	[
	    $db->dsn, undef, undef
        ]
    );

    # Throw the generated schema away.
    unlink "lib/BackPAN/Index/SchemaThrowaway.pm";
}

1;
