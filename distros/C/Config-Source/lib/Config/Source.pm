package Config::Source;

use 5.14.0;
use strict;

use warnings FATAL => 'all';

use List::Util 1.35 qw( any none );

use Carp qw( croak );

=head1 NAME

Config::Source - manage a configuration from multiple sources

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Config::Source;

    my $config = Config::Source->new;
    $config->add_source( get_default_config() );
    
    # override values from the default keys with
    $config->add_source( File::Spec->catfile( $HOME, '.application', 'config' ) );
    
    # and now with
    $config->add_source( '/etc/application.config' );
    
    my $value = $config->get( 'user.key' );
    $config->set( 'user.key' => $value );
    
    $config->save_file( File::Spec->catfile( $HOME, '.application', 'config' ) );

    sub get_default_config {
        return {
            'app.name' => '...',
            'app.version' => 1,
            'user.key' => 'test',
            'user.array' => [ 200, 300 ],
            'user.deeper.struct' => { a => 'b', c => [ 'd', 'e' ] },
        };
    }

=head1 DESCRIPTION

This module allows defining and loading multiple sources to generate a configuration. 

Sometimes you want a configuration initially provided by your application, but partially or 
fully redefined at multiple locations. You can have a default configuration
distributed with your program and under your control as developer. 
On the first startup you want to generate a user configuration file to 
store individual relevant data. And for the administration, you want to provide a 
central configuration file indented to specify shared resources. You may also 
want a file which is only loaded on debug sessions.

This module uses Perl data structures for representing your configuration. It can also assure, 
that you only work with a true copy of the data.

=head1 CONFIGURATION FILE

Your configuration file must simply return an hash with the last
evaluated statement. Additionally, you can use all the perl code you want. 
But this code is discarded if you save your config back.

This module proposes a flat hash for storing your configuration. It treats
everything behind the first level of keys as a value.

instead of writing:

    {
        'log' => {
            'file' => 'path',
            'level' => 'DEBUG',
        },
    }
    
you should write:

    {
        'log.file' => 'path,
        'log.level' => 'DEBUG',
    }

Of course, you can use any separator in the string you want.

If you want get a more hierarchical access, take a look at 
Config::Source::Hierarchical (not implemented, currently only a throught).

=head1 METHODS

=head2 new( parameter => value, ... )

All the following parameter are optional.

=over 4

=item C<clone_get>

If true, then every time you try to C<get> a ref-data, a clone will performed, 
before returning it. Default is false.

=item C<clone_set>

If true, then every time you try to C<set> a ref-data, a clone will performed, 
before assign it to the key. Default is true. 

=back

=cut

sub new {
	my ( $class, %p ) = @_;
	
	# be sure, a clone module is set
	$class->import if not $class->can( 'clone' );

	my $this = bless {}, $class;
	
	$this->{clone_get} = $p{clone_get} // 0;
	$this->{clone_set} = $p{clone_set} // 1;
	
	return $this;
}

=head2 add_source( source, parameter => value, ... )

Loads the given source. This can either be a filepath, a hashref or a scalarref.

The following parameter are supportet:

=over 4

=item C<discard>

If you want to exclude some keys from loading from the given source, you can pass
a arrayref with these keys or regexes.

    $config->add_source( $source, discard => [ 'key.to.remove', qr/^match/ ] );

=item C<discard_additional_keys>

Discard all keys, which are not currently loaded by the configuration. Default is false 
for the first source you want to load and true for each subsequent one. Keys matched 
by C<discard> will always be discarded.

=item C<merge_values>

Takes a reference to a list of keys or regular expressions for merging. Keys matched 
by C<discard> will always be discarded.

I<currently not implemented>

=back

=cut

sub add_source {
	my ( $this, $source, %p ) = @_;
	
	$p{discard_additional_keys} //= 1;
	
	# load the source into a hashref
	my $hash = $this->_load_source( $source );
		
	# delete keys from discard
	if ( $p{discard} ) {
		for my $key ( keys %$hash ) {
			delete $hash->{ $key } if any { $key =~ $_ } @{ $p{discard} };
		}
	}

	# always alias
	# if currently no config
	if ( not defined $this->{_} ) {
		$this->{_} = $hash;
		return $this;
	}
	
	# delete additional key
	# if they should discarded
	# and always override the keys
	if ( $p{discard_additional_keys} ) {
		while ( my ( $key, $value ) = each %$hash ) {
			$this->{_}{ $key } = $value
				if exists $this->{_}{ $key }; 
		}
	} 
	else {
		while ( my ( $key, $value ) = each %$hash ) {
			$this->{_}{ $key } = $value; 
		}
	}
 		
	return $this;	
}

=head2 get( key )

Returns the value for the given key. 

Dies if the key is not found.

=cut

sub get {
	my ( $this, $key ) = @_;
	
	if ( ref $this->{_}{ $key } and $this->{clone_get} ) {
		return clone( $this->{_}{ $key } );
	}
	
	return 
		exists( $this->{_}{ $key } )
			? $this->{_}{ $key }
			: croak "config key: $key does not exist"
	;
}

=head2 set( key => value )

Set the key to the given value.

Dies if the key not exists.

Before setting deep data structures a copy with clone is performed by default.

=cut

sub set {
	my ( $this, $key, $value ) = @_;

	if ( $this->exists( $key ) ) {
		if ( ref $value and $this->{clone_set} ) {
			$this->{_}{ $key } = clone( $value );
		} else {
			$this->{_}{ $key } = $value;
		}
	} else {
		croak "key does not exist: $key";
	}

	1;
}


=head2 exists( key )

Return true, if the key exists. False otherwise.

=cut

sub exists {
	my ( $this, $key ) = @_;
	
	return 1 if exists $this->{_}{ $key };
	return 0;
}

=head2 keys( regex )

Returns all matching keys in sorted order, so you can 
easily iterate over it.

If Regex is omitted, all keys are returned.

=cut

sub keys {
	my ( $this, $regex ) = @_;
	
	return sort keys %{ $this->{_} } if not defined $regex;
	return sort grep { /$regex/ } keys %{ $this->{_} };
}

=head2 reset( key, source )

Resets the given key to the value in the given configs. 

Dies, if the key is not found either in the current config, or the source.  

=cut

sub reset {
	my ( $this, $key, $source ) = @_;
	
	# SMELL: hm... can we optimize this?
	# there possible a double clone!
	my $hash = $this->_load_source( $source );
	
	croak "key does not exist in source: $key"
		if not exists $hash->{ $key };
	
	$this->set( $key, $hash->{ $key } );
		
	1;
}

=head2 getall( parameter => value )

Returns a cloned copy from the configuration hash. This is a hashref.

You can restrict the given keys with the following parameters:

=over 4

=item C<include>

Arrayref with keys or regular expressions. Only the matched keys from the configuration will saved.

=item C<exclude>

Arrayref with keys or regular expressions. All matched keys will excluded from saving. 
Keys matched by include and exclude will excluded.

=back

=cut

sub getall {
	my ( $this, %p ) = @_;
	
	my $hash = clone( $this->{_} );
		
	# i use alway a tmp hash - because key should not
	# deleted in a loop around the hash
	if ( $p{include} ) {
		
		my $tmp_hash;
		
		while ( my ( $key, $value ) = each %$hash ) {
			if ( any { $key =~ $_ } @{ $p{include} } ) {
				$tmp_hash->{ $key } = $value;
			}
		}
		
		$hash = $tmp_hash;
	}

	if ( $p{exclude} ) {
		
		my $tmp_hash;
		
		while( my ( $key, $value ) = each %$hash ) {
			if ( none { $key =~ $_ } @{ $p{exclude} } ) {
				$tmp_hash->{ $key } = $value;
			}
		}
		
		$hash = $tmp_hash;
	}
	
	return $hash;
}

=head2 save_file( file, paramter => value, ... )

Saves the configuration to the given file.

Dies if no file spezified.

You can restrict the saved keys with the same parameters specified in C<getall>.

=cut

sub save_file {
	my ( $this, $file, %p ) = @_;
	
	croak 'No user file spezified' if not $file;
	
	# a little bit optimised ;) - but fragile base class!
	my $hash = ( $p{include} or $p{exclude} )
				? $this->getall( %p )
				: $this->{_}
	;
	
	require Data::Dumper;
	
	my $dumper = Data::Dumper->new( [ $hash ] );
	$dumper->Useperl( 1 );
	$dumper->Terse( 1 );
	$dumper->Sortkeys( 1 );

	open my $fh, '>', $file or croak $!;
	print $fh $dumper->Dump;
	close $fh;
	
	1;
}

=head1 INTERNAL METHODS

=head2 _load_source

=cut

sub _load_source {
	my ( $this, $source ) = @_;
	
	if ( ref $source eq 'HASH' ) {
		return clone( $source );
	} 
	elsif ( ref $source eq 'SCALAR' ) {
		return eval $$source;
		croak "error parsing scalar source: $@" if $@;
	}
	else {
		open my $fh, '<', $source or croak "error opening $source: $!";
		my $hash = eval do { local $/; <$fh> };
		croak "error parsing $source: $@" if $@;
		
		return $hash;
	}
}

=head1 ACCESSORS

=over 4

=item C<clone_get>

=item C<clone_set>

=back

=cut

# Code partly inspired from Object::Tiny and Object Tiny::RW
sub clone_get { if ( @_ > 1 ) { $_[0]->{clone_get} = $_[1] } ; return $_[0]->{clone_get} }
sub clone_set { if ( @_ > 1 ) { $_[0]->{clone_set} = $_[1] } ; return $_[0]->{clone_set} }

=head1 CLONING

You can change the cloning implementation with a package parameter:

    use Data::Clone;
    use Config::Source clone => \&Data::Clone::clone;

Or change it at any time with the class method C<import>. The default
implementation is Storables dclone.

=cut

sub import {
	my ( $class, %p ) = @_;
	
	my $sub = ref $p{clone} eq 'CODE' 
				? $p{clone} 
				: do { require Storable; \&Storable::dclone }
	;
	
	no strict 'refs';
	*{__PACKAGE__ . '::clone'} = $sub;
}

=head1 OTHER FILE FORMATS

Most of the config modules out there can return a simple hash 
of the configuration. The following example shows how 
to read a default configuration and a user configuration
with Config::General, as well as the saving of the
configuration file back.

    use Config::General;
    use Config::Source;
    
    my %default = Config::General->new( 'default_location' )->getall;
    my %user    = Config::General->new( 'user_location' )   ->getall;
    
    my $config = Config::Source->new
                 ->add_source( \%default )
                 ->add_source( \%user );
    
    # ...
    
    my $hash = $config->getall;
    
    Config::General->new->save_file( 'user_location', $hash );
    
Be sure the passed values are unblessed hash references. And know the limitations 
of the other modules.

Maybe i add the option to direct load these file formats in a future release.

=head1 AUTHOR

Tarek Unger, C<< <taunger at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-source at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Source>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Source


You can also look for information at:

=over 20

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Source>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Source>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-Source>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Source/>

=item * Repository

L<https://github.com/taunger/Config-Source>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013-2014 Tarek Unger.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Config::Source
