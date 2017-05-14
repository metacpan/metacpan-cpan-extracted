# Author: Murat Uenalan (muenalan@cpan.org)
#
# Copyright (c) 2001 Murat Uenalan. All rights reserved.
#
# Note: This program is free software; you can redistribute
#
# it and/or modify it under the same terms as Perl itself.

package Class::Maker::Extension::Schema::Tangram;

require 5.005_62; use strict; use warnings;

use Exporter;

our $VERSION = '0.01_01';

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(schema) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $mappings =
{
	ARRAY =>
	{
		hash => 'flat_hash',

		array => 'flat_array',
	}
};

sub _map_to_tangram
{
	my $attribs = shift;

	my $mapping = shift;

		foreach my $type ( keys %$attribs )
		{
			if( my $what = $mappings->{ ref $attribs->{$type} }->{$type} )
			{
				$attribs->{ $what } = $attribs->{ $type };

				delete $attribs->{ $type };
			}
		}

return $attribs;
}

# Preloaded methods go here.

our $classname_separator = '_';

sub schema
{
	my %schema = ();

#	print "Gathering schema: ";

	foreach my $this ( @_ )
	{
		print "$this..\n";

		foreach my $class ( @{Class::Maker::Reflection::inheritance_isa( ref($this) || $this )} )
		{
				# main:: and :: prefix should be stripped from package identifier
				#
				# because of a bug in bless

			$class =~ s/^(?:main)?:://;

			print "\tbase $class detected\n" if $Class::Maker::DEBUG;

				# inefficient PROVISIONAL because below i tweak in the original CLASS info, instead of doing
				# it in the schema => but NOW i have not the time...

			my %copy = %{ Class::Maker::Reflection::reflect( $class )->definition };

			print "DUMPER: ";

			use Data::Dumper;

			print Dumper \%copy;

			my $reflex = \%copy;

			my $cfg = $reflex->{persistance};

			next if exists $cfg->{ignore};

			if( exists $cfg->{table} )
			{
				$schema{$class}->{table} = $cfg->{table};
			}
			elsif( 0 ) # $class =~ /::/ )	# because :: may conflict SQL
			{
				$schema{$class}->{table} = $class;

				$schema{$class}->{table} =~ s/::/$classname_separator/g;
			}

			if( exists $cfg->{abstract} )
			{
				$schema{$class}->{abstract} = $cfg->{abstract} if exists $cfg->{abstract};
			}
			else
			{
					# Translate fieldnames to tangram types (see above for Tangram Type Extension Modules 'use')

				foreach my $csection ( qw(public private protected) )
				{
						# look if we had a: type => [qw(eins zwei)]  ...or... type => { eins => 'Object::Eins', ...

					_map_to_tangram( $reflex->{$csection}, $mappings ) if exists $reflex->{$csection};

					$schema{$class}->{fields} = $reflex->{$csection} if exists $reflex->{$csection};

						# look into array and ref fields for classes to be included into the schema

					foreach my $obj_field ( qw(array ref) )
					{
						if( ref( $reflex->{$csection}->{$obj_field} ) eq 'HASH' )
						{
								# cylce to the references classes and if not already in schema -> add it..

							foreach ( values %{ $reflex->{$csection}->{$obj_field} } )
							{
								unless( exists $schema{ $_ } )
								{
										# catch schema of referenced classes

									my %classes = @{ schema( $_ ) };

									foreach my $class_key ( keys %classes )
									{
										$schema{ $class_key }= $classes{$class_key};
									}
								}
							}
						}
					}
				}

				my $isa = $cfg->{bases} || $reflex->{isa};

				$schema{$class}->{bases} = $isa if $isa;
			}
		}
	}

return [ %schema ];
}

1;

__END__


=head1 NAME

Class::Maker::Extension::Schema::Tangram - creates Tangram schema from a class hierarchy

=head1 SYNOPSIS

	use Class::Maker;

	use Class::Maker::Examples;

	use Class::Maker::Extension::Schema::Tangram qw(schema);

	my $class_schema = schema( 'User' );

	my $schema = Tangram::Relational->schema( { classes => $class_schema,normalize => sub { $_[0] =~ s/::/_/; $_[0] } } );

	my $dbh = DBI->connect( ) or die;

	{
		my $aref_result = $dbh->selectcol_arrayref( q{SHOW TABLES} ) or die $DBI::errstr;

		my %tables;

		@tables{ @$aref_result } = 1;

		Tangram::Relational->deploy( $schema, $dbh ) unless exists $tables{'tangram'};
	}

	# To delete all tangram tables of this schema
	#
	# Tangram::Relational->retreat( $schema, $dbh );

	@ENV{ qw(DBI_DSN DBI_USER DBI_PASS) } = ( 'DBI:mysql:localhost:tangram' );

	my $storage = Tangram::Relational->connect( $schema, @ENV{ qw(DBI_DSN DBI_USER DBI_PASS) }, { dbh => $dbh } ) or die;

	my $tbl = $storage->remote( 'Human::Group' );

	my ($group) = $storage->select( $tbl, $tbl->{name} eq 'dbadmin' );

	unless( $group )
	{
		$group = new Human::Group( -name => 'dbadmin', -desc => 'database administrators' );

		print Dumper $group;

		$storage->insert( $group );
	}

	and so forth...

=head1 DESCRIPTION

Class::Maker::Extension::Schema::Tangram uses reflection to get the appropriate information about a tree of
classes and then to convert this into a "schema" which can be deployed to Tangram (object persistance).

=head1 schema( $oref )

Determines the "Tangram::Schema" representation of a "class tree" including the complete inhereted objects.

Constructing Tangram Schema WHEN WE HAVE TO DEPLOY (first time registering persistance).

schema() scans recursivle through the inheritance tree and creates all parent schemas also (Cave: You should

configure tangram also via the "persistance =>" key in your class.

For comulative schema (incl. "User"`s parent "Human" class) ,+ the non-inheritated "Human::Group" Class::Maker::

	schema( 'User' , 'Human::Group' );

For single schema:

	User->schema();	#(incl. "User"`s parent "Human" class)

	or

	UserGroup->schema;	# no isa, no parent class schema`s !

=head1 $Class::Maker::Extension::Schema::Tangram::mappings

This is a hash which is used to map the Class::Maker attribute types to tangram types. While the first key
is determing whether the attribute type value was an ARRAY ( => [qw(one two)] ) or a HASH ( => { father => 'Human' } ).
Here is the default mapping table:

{
	ARRAY =>
	{
		hash => 'flat_hash',

		array => 'flat_array',
	}
}

=head1 EXAMPLE

=head2 Reflex

# Human
$VAR1 = {
          'configure' => {
                           'dtor' => 'delete',
                           'ctor' => 'new'
                         },
          'public' => {
                        'string' => [
                                      'coutrycode',
                                      'postalcode',
                                      'firstname',
                                      'lastname',
                                      'sex',
                                      'eye_color',
                                      'hair_color',
                                      'occupation',
                                      'city',
                                      'region',
                                      'street',
                                      'fax'
                                    ],
                        'int' => [
                                   'age'
                                 ],
                        'hash' => [
                                    'contacts',
                                    'telefon'
                                  ],
                        'array' => [
                                     'nicknames',
                                     'friends'
                                   ],
                        'time' => [
                                    'birth',
                                    'driverslicense',
                                    'dead'
                                  ]
                      }
        };

# User
$VAR1 = {
          'isa' => [
                     'Human'
                   ],
          'version' => '0.01',
          'public' => {
                        'string' => [
                                      'email',
                                      'lastlog',
                                      'registered'
                                    ],
                        'real' => [
                                    'konto'
                                  ],
                        'int' => [
                                   'logins'
                                 ],
                        'array' => {
                                     'cars' => 'Vehicle',
                                     'friends' => 'User'
                                   },
                        'ref' => {
                                   'group' => 'Human::Group'
                                 }
                      }
        };

# Vehicle

$VAR1 = {
          'public' => {
                        'string' => [
                                      'model'
                                    ],
                        'int' => [
                                   'wheels'
                                 ]
                      }
        };

#Human::Group

$VAR1 = {
          'public' => {
                        'string' => [
                                      'name',
                                      'desc'
                                    ]
                      }
        };

=head2 Result

$VAR1 = [
          [
            'Vehicle',
            {
              'fields' => {
                            'string' => [
                                          'model'
                                        ],
                            'int' => [
                                       'wheels'
                                     ]
                          }
            },
            'Human::Group',
            {
              'fields' => {
                            'string' => [
                                          'name',
                                          'desc'
                                        ]
                          }
            },
            'Human',
            {
              'fields' => {
                            'string' => [
                                          'coutrycode',
                                          'postalcode',
                                          'firstname',
                                          'lastname',
                                          'sex',
                                          'eye_color',
                                          'hair_color',
                                          'occupation',
                                          'city',
                                          'region',
                                          'street',
                                          'fax'
                                        ],
                            'flat_array' => [
                                              'nicknames',
                                              'friends'
                                            ],
                            'int' => [
                                       'age'
                                     ],
                            'flat_hash' => [
                                             'contacts',
                                             'telefon'
                                           ],
                            'time' => [
                                        'birth',
                                        'driverslicense',
                                        'dead'
                                      ]
                          }
            },
            'User',
            {
              'bases' => [
                           'Human'
                         ],
              'fields' => {
                            'string' => [
                                          'email',
                                          'lastlog',
                                          'registered'
                                        ],
                            'real' => [
                                        'konto'
                                      ],
                            'int' => [
                                       'logins'
                                     ],
                            'array' => {
                                         'cars' => 'Vehicle',
                                         'friends' => 'User'
                                       },
                            'ref' => {
                                       'group' => 'Human::Group'
                                     }
                          }
            }
          ]
        ];

=cut
