
# (c) 2009 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
# Author: Murat Uenalan (muenalan@cpan.org)
#
# Copyright (c) 2001 Murat Uenalan. All rights reserved.
#
# Note: This program is free software; you can redistribute
#
# it and/or modify it under the same terms as Perl itself.

package Class::Maker::Schema;

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

Class::Maker::Schema - "reflex to schema" mapper base class

=head1 SYNOPSIS

use Class::Maker::Schema;

=head1 DESCRIPTION

=head1 INTRODUCTION

=cut
