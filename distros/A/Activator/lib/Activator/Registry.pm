package Activator::Registry;
use YAML::Syck;
use base 'Class::StrongSingleton';
use Activator::Log qw( :levels );
use Data::Dumper;
use Hash::Merge;
use Activator::Exception;
use Exception::Class::TryCatch;

=head1 NAME

Activator::Registry - provide a registry based on YAML file(s)

=head1 SYNOPSIS


  use Activator::Registry;

  #### register $value to $key in realm $realm
  Activator::Registry->register( $key, $value, $realm );

  #### register $value to $key in default realm
  Activator::Registry->register( $key, $value );

  #### get value for $key from $realm
  Activator::Registry->get( $key, $realm );

  #### get value for $key from default realm
  Activator::Registry->get( $key );

  #### get a deep value for $key from default realm
  #### this form throws exception for invalid keys
  $key = 'top->deep->deeper';
  try eval {
     Activator::Registry->get( $key );
  }

  #### register YAML file into realm
  Activator::Registry->register_file( $file, $realm );

  #### register hash into realm
  Activator::Registry->register_hash( $mode, $hashref, $realm );

  #### use ${} syntax in your registry for variables
  Activator::Registry->replace_in_realm( 'default', $replacements_hashref );

=head1 DESCRIPTION

This module provides global access to a registry of key-value pairs.
It is implemented as a singleton, so you can use this Object Oriented
or staticly with arrow notation. It supports getting and setting of
deeply nested objects. Setting can be done via YAML configuration
files.

=head1 CONFIGURATION FILES

Configuration files are YAML files.

=head2 Registry Within Another Configuration File

You can have a registry be a stand alone file, or live within a
configuration file used for other purposes. If you wish your registry
to be only a subset of a larger YAML file, put the desired hierarchy
in a top level key C<Activator::Registry>. If that key exists, only
that part of the YAML file will be registered.

=head2 Default Configuration File

Often, your project will have a central configuration file that you
always want to use. In these cases set the environment variable
C<ACT_REG_YAML_FILE>. All calls to L</new()>, L</load()> and
L</reload()> will register this file first, then any files passed as
arguments to those subroutines.

If you are utilizing this module from apache, this directive must be
in your httpd configuration:

  SetEnv ACT_REG_YAML_FILE '/path/to/config.yml'

If you are using this module from a script, you need to ensure that
the environment is properly set. This my require that you utilize a
BEGIN block BEFORE the C<use> statement of any module that C<use>s
C<Activator::Registry> itself:

  BEGIN{
      $ENV{ACT_REG_YAML_FILE} ||= '/path/to/reg.yml'
  }

Otherwise, you will get weirdness when all of your expected registry
keys are undef...

=head1 METHODS

=head2 new()

Returns a reference to a registry object. This is a singleton, so
repeated calls always return the same ref. This will load the file
specified by C<$ENV{ACT_REG_YAML_FILE}>, then C<$yaml_file>. If
neither are valid YAML files, you will have an object with an empty
registry. If the registry has already been loaded, DOES NOT RELOAD it.
use L</reload()> for that.

=cut

sub new {
    my ( $pkg, $yaml_file ) = @_;

    my $self = bless( {
          DEFAULT_REALM => 'default',
	  REGISTRY => { },

# TODO: consider using this custom precedence:
#          SAFE_LEFT_PRECEDENCE =>
#           {
#            'SCALAR' => {
#               'SCALAR' => sub { $_[0] },
#               'ARRAY'  => &die_array_scalar,
#               'HASH'   => &die_hash_scalar,
#              },
#            'ARRAY' => {
#               'SCALAR' => sub { [ @{ $_[0] }, $_[1] ] },
#               'ARRAY'  => sub { [ @{ $_[0] }, @{ $_[1] } ] },
		       #               'HASH'   => &die_hash_array,
#              },
#            'HASH' => {
#               'SCALAR' => &die_scalar_hash,
#               'ARRAY'  => &die_array_hash,
#               'HASH'   => sub { _merge_hashes( $_[0], $_[1] ) },
#              },
#	  },

		      }, $pkg);

    $self->_init_StrongSingleton();
    if ( $yaml_file ) {
	$self->load( $yaml_file )
    }
    else {
	$self->load();
    }
    return $self;
}

=head2 load()

Load a YAML file into the registry. Throws exception if the file has
already been successfully loaded.

=cut

sub load {
    my ( $pkg, $yaml_file, $reload ) = @_;
    my $self = $pkg->new();
    my $registered_something;

    if( $reload ) {
	$self->{REGISTRY_BACKUP} = $self->{REGISTRY};
	$self->{REGISTRY} = { };
    }

    if ( !keys( %{ $self->{REGISTRY} } ) ) {

	if( defined ( $ENV{ACT_REG_YAML_FILE} ) && -f $ENV{ACT_REG_YAML_FILE} ) {
	    $self->register_file( $ENV{ACT_REG_YAML_FILE} );
	    $registered_something = 1;
	}

	if ( defined( $yaml_file ) && -f $yaml_file ) {
	    $self->register_file( $yaml_file );
	    $registered_something = 1;
	}
    }

    else {
	# refuse to reload without flag
	WARN("Cowardly refusing to stomp registry without 'reload' flag");
	return;
    }

    if ( !$registered_something ) {

	my $action = 'load';
	if ( keys %{ $self->{REGISTRY_BACKUP} } ) {
	    $self->{REGISTRY} = $self->{REGISTRY_BACKUP};
	    $action = 'reload';
	}

	if ( $ENV{ACT_REG_YAML_FILE} || $yaml_file ) {
	    my $msg = "Registry $action failed." .
	    'Neither $ENV{ACT_REG_YAML_FILE} ('. ( $ENV{ACT_REG_YAML_FILE} || 'undef' ) .
	    ') nor $yaml_file ('. ( $yaml_file || 'undef' ) .
	    ') are a valid configuration file';

	    # TODO: figure out how to solve the cyclic dependancy problem.
	    # That is, Log depends on this file to find it's config, so
	    # when calling new, we can't be guranteed that log is loaded.
	    # We need to figure out if Log is loaded, then we can just
	    # warn for the outlier case where Log is configured to a bad
	    # filename.
	    warn( "[WARN] $msg" );
	}
	$registered_something = 0;
    }
    else {
	$registered_something = 1;
    }

    return $registered_something;
}

=head2 reload()

Reloads a specific configuration file. This nukes the existing registry.

=cut

sub reload {
    my ( $pkg, $yaml_file ) = @_;
    $pkg->load( $yaml_file, 1 );
}

=head2 register( $key, $value, $realm )

Register a key-value pair to C<$realm>. Registers to the default realm
if C<$realm> not defined. Returns true on success, false otherwise
(more specifically, the return value of the C<eq> operator when
testing the set value to the value passed in).

=cut

sub register {
  my ($pkg, $key, $value, $realm) = @_;
  my $self = $pkg->new();
  $realm ||= $self->{DEFAULT_REALM};

   my @keys = split( '->', $key );
   if ( @keys > 1 ) {
       my $setref = $self->{REGISTRY}->{ $realm };
       $self->_deep_register( \@keys, $value, $setref );
       return $self->get( $key ) eq $value;
   }
  else {
      $self->{REGISTRY}->{ $realm }->{ $key } = $value;
      return $self->{REGISTRY}->{ $realm }->{ $key } eq $value;
  }
}

sub _deep_register {
  my ($self, $keys, $value, $setref) = @_;
  my $curkey = shift @$keys;
  if ( @$keys == 0 ) {
      $setref->{ $curkey } = $value;
  }
  else {
      $self->_deep_register( $keys, $value, $setref->{ $curkey });
  }
}

=head2 register_file( $file, $realm)

Register the contents of the C<'Activator::Registry':> heirarchy from
within a YAML file, then merge it into the existing registry for the
default realm, or optionally C<$realm>.

=cut

sub register_file {
    my ( $pkg, $file, $realm ) = @_;
    my $self = $pkg->new();
    $realm ||= $reg->{DEFAULT_REALM};
    my $config = YAML::Syck::LoadFile( $file );

    # In pre 1.0 versions of this module, it was a top level key of
    # 'Activator::Registry' was required to allow registries to live
    # within other yml files. In common usage, this is not the normal
    # case. Here we support both.
    if ( $config->{'Activator::Registry'} ) {
	$self->register_hash( 'left', $config->{'Activator::Registry'}, $realm );
    }
    else {
	$self->register_hash( 'left', $config, $realm );
    }
}


=head2 register_hash( $mode, $right, $realm)

Set registry keys in C<$realm> from C<$right> hash using C<$mode>,
which can either be C<left> or C<right>. C<left> will only set keys
that do not exist, and C<right> will set or override all C<$right>
values into C<$realm>'s registry.

=cut

sub register_hash {
    my ( $pkg, $mode, $right, $realm ) = @_;
    if ( $mode eq 'left' ) {
	Hash::Merge::set_behavior( 'LEFT_PRECEDENT' );
    }
    elsif ( $mode eq 'right' ) {
	Hash::Merge::set_behavior( 'RIGHT_PRECEDENT' );
    }
    else {
	# TODO: consider using custom precedence
	#Hash::Merge::specify_behavior( $pkg->{SAFE_LEFT_PRECEDENCE} );

	Activator::Exception::Registry->throw( 'mode', 'invalid' );
    }
    my $reg = $pkg->new();
    $realm ||= $reg->{DEFAULT_REALM};
    if ( !exists( $reg->{REGISTRY}->{ $realm } ) ) {
	$reg->{REGISTRY}->{ $realm } = {};
    }
    my $merged = {};
    try eval {
	$merged = Hash::Merge::merge( $reg->{REGISTRY}->{ $realm }, $right );
    };
    # catch
    if ( catch my $e ) {
	Activator::Exception::Registry->throw( 'merge', 'failure', $e );
    }

    elsif( keys %$merged ) {
	$reg->{REGISTRY}->{ $realm } = $merged;
    }
}

=head2 get( $key, $realm )

Get the value for C<$key> within C<$realm>. If C<$realm> not defined
returns the value from the default realm. C<$key> can refer to a
deeply nested element. Returns undef if the key does not exist, or you
try to seek into an array. Some examples:

With a YAML config that produces:

  deep_list:
    level_1:
      - level_2_a
      - level_2_b
  key: value

You will get this behavior:

  Activator::Registry->get( 'key' );                           # returns 'value'
  Activator::Registry->get( 'deep_list' );                     # returns hashref
  Activator::Registry->get( 'deep_lost' );                     # returns undef
  Activator::Registry->get( 'deep_list->level_1' );            # returns arrayref
  Activator::Registry->get( 'deep_list->level_1->level_2_a' ); # returns undef
  Activator::Registry->get( 'deep_list->level_one' );          # returns undef

=cut

sub get {
   my ($pkg, $key, $realm) = @_;

   my $self = $pkg->new();
   $realm ||= $self->{DEFAULT_REALM};

   my @keys = split( '->', $key );
   if ( @keys > 1 ) {
       my $retval;
       try eval {
	   $retval = $self->_deep_get( \@keys, $realm, $self->{REGISTRY}->{ $realm } );
       };
       if ( catch my $e ) {
	   return;
       }
       return $retval;
   }
   return $self->{REGISTRY}->{ $realm }->{ $key };
}

sub _deep_get {
   my ($pkg, $keys, $realm, $reg_ref) = @_;
   my $key = shift @$keys;

   if ( @$keys == 0 ) {
       if ( exists( $reg_ref->{ $key } ) ) {
	   return $reg_ref->{ $key };
       }
       else {
	   Activator::Exception::Registry->throw( 'key', 'invalid', $key );
       }
   }

   if ( exists( $reg_ref->{ $key } ) ) {
       return $pkg->_deep_get( $keys, $realm, $reg_ref->{ $key } );
   }
   else {
       Activator::Exception::Registry->throw( 'key', 'invalid', $key );
   }
}

=head2 get_realm( $realm )

Return a reference to hashref for an entire C<$realm>.

=cut

sub get_realm {
   my ($pkg, $realm) = @_;

   my $self = $pkg->new();
   $realm ||= $self->{DEFAULT_REALM};
   return $self->{REGISTRY}->{ $realm };
}


=head2 set_default_realm( $realm )

Use C<$realm> instead of 'default' for default realm calls.

=cut

sub set_default_realm {
   my ($pkg, $realm) = @_;

   my $self = $pkg->new();
   $self->{DEFAULT_REALM} = $realm;
}

=head2 replace_in_realm( $realm, $replacements )

Replace variables matching C<${}> notation with the values in
C<$replacements>. C<$realm> must be specified. Use C<'default'> for
the default realm. Keys that refer to other keys in the realm are
processed AFTER the passed in C<$replacements> are processed.

=cut

sub replace_in_realm {
    my ($pkg, $realm, $replacements) = @_;
    my $self = $pkg->new();

    my $reg = $self->get_realm( $realm );
    if ( !keys %$reg ) {
	Activator::Exception::Registry->throw( 'realm', 'invalid', $realm );
    }

    TRACE("replacing (realm '$realm') ". Dumper($reg) . "\n ---- with ----\n". Dumper($replacements));
    $self->replace_in_hashref( $reg, $replacements );
    $self->replace_in_hashref( $reg, $reg );
    TRACE("Done replacing. End result: ". Dumper($reg));
}

=head2 replace_in_hashref( $hashref, $replacements )

Replace withing the values of C<$hashref> keys, variables matching
C<${}> notation with the values in C<$replacements>.

=cut

sub replace_in_hashref {
    my ( $pkg, $hashref, $replacements ) = @_;
    foreach my $key ( keys %$hashref ) {

	# if key is a hash, recurse
	if ( UNIVERSAL::isa( $hashref->{ $key }, 'HASH')) {
	    $pkg->replace_in_hashref( $hashref->{ $key }, $replacements );
	}

	# if key is an array, do replacements for each item
	elsif ( UNIVERSAL::isa( $hashref->{ $key }, 'ARRAY')) {
	    for( my $i = 0; $i < @{ $hashref->{ $key } }; $i++ ) {
		@{ $hashref->{ $key }}[ $i ] =
		  $pkg->do_replacements( @{ $hashref->{ $key }}[ $i ],
					 $replacements,
					 0 );
	    }
	}

	# if key is a string just do the replacment for the string
	else {
	    $hashref->{ $key } =
	      $pkg->do_replacements( $hashref->{ $key },
				     $replacements,
				     0 );
	}
    }
}

=head2 do_replacements ( $string, $replacements )

Helper subroutine to allow recursive replacements of C<${}> notation
with values in C<$replacements>. Returns the new value.

=cut

sub do_replacements {
    my ( $pkg, $string, $replacements, $depth ) = @_;

    my ( $replacement_str, $num_replaced ) = $pkg->get_replaced_string( $string, $replacements );

    if ( $num_replaced > 0 && $replacement_str =~ /\$\{[^\}]+\}/ ) {
	$replacement_str = $pkg->do_replacements( $replacement_str, $replacements, $depth+1 );
    }

    $string = $replacement_str;
    return $string;
}

=head2 get_replaced_string( $target, $replacements )

In scalar context, return the value of C<$target> after replacing
variables matching C<${}> notation with the values in
C<$replacements>. If a variable exists, but there is no replacement
value, it is not changed. In list context, returns the string and the
number of replacements.

=cut

sub get_replaced_string {
    my ( $pkg, $target, $replacements ) = @_;
    my $num_replaced = 0;
    my @matches = ( $target =~ /\$\{([^\}]+)/g );
    if ( @matches ) {
	TRACE( "found variables: (".join (',',@matches) . ") in target '$target'");
	map {
	    my $replace = $replacements->{ $_ };
	    if ( defined $replace ) {
		$target =~ s/\$\{$_\}/$replace/g;
		TRACE("Replaced '\${$_}' with '$replace'. target is '$target'");
		$num_replaced++;
	    } else {
		# TODO: figure out how to warn the context of this
		WARN("Skipped variable '$_'. Does not have a replacement value.");
	    }
	} @matches;
    }
    else {
	TRACE( "No variables to replace in '$target'");
    }
    return wantarray ? ( $target, $num_replaced ) : $target;
}

# register_hash helpers for when using SAFE_LEFT_PRECEDENCE merging
# TODO (not currently used)
sub die_array_scalar {

    die "Can't coerce ARRAY into SCALAR\n" .
      Data::Dumper->Dump( [ $_[0], $_[1] ],
			  [ qw( ARRAY SCALAR ) ] );
}

sub die_hash_scalar {
    die "Can't coerce HASH into SCALAR\n" .
      Data::Dumper->Dump( [ $_[0], $_[1] ],
			  [ qw( HASH SCALAR ) ] );
}

sub die_hash_array {
    die "Can't coerce HASH into ARRAY\n" .
      Data::Dumper->Dump( [ $_[0], $_[1] ],
			  [ qw( HASH ARRAY ) ] );
}

sub die_scalar_hash {
    die "Can't coerce SCALAR into HASH\n" .
      Data::Dumper->Dump( [ $_[0], $_[1] ],
			  [ qw( SCALAR HASH ) ] );
}

sub die_array_hash {
    die "Can't coerce ARRAY into HASH\n" .
      Data::Dumper->Dump( [ $_[0], $_[1] ],
			  [ qw( ARRAY HASH ) ] );
}



=head1 FUTURE WORK

=over

=item * Fix warning messages

If you create a script that uses this module (or some other activator
module that depends on this module), the warning messages are rather
arcane. This script:

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Activator::DB;
  Activator::DB->getrow( 'select * from some_table', [],  connect->'default');

Run this way:

  ./test.pl

Produces this error:

  activator_db_config missing You must define the key "Activator::DB" or "Activator->DB" in your project configuration

Probably should say something about the fact that you should have run it like this:

  ACT_REG_YAML_FILE=/path/to/registry.yml ./test.pl


=item * Utilize other merge methods

Only the default merge mechanism for L<Hash::Merge> is used. It'd be
more robust to support other mechanisms as well.

=back

=head1 See Also

L<Activator::Log>, L<Activator::Exception>, L<YAML::Syck>,
L<Exception::Class::TryCatch>, L<Class::StrongSingleton>

=head1 AUTHOR

Karim A. Nassar ( karim.nassar@acm.org )

=head1 License

The Activator::Registry module is Copyright (c) 2007 Karim A. Nassar.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, or as specified in the Perl README file.

=cut


1;
