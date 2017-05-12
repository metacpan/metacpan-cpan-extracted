package Data::Phrasebook::Generic;
use strict;
use warnings FATAL => 'all';
use Data::Phrasebook::Loader;
use base qw( Data::Phrasebook::Debug );
use Carp qw( croak );

use vars qw($VERSION);
$VERSION = '0.35';

=head1 NAME

Data::Phrasebook::Generic - Base class for Phrasebook Models

=head1 SYNOPSIS

    use Data::Phrasebook;

    my $q = Data::Phrasebook->new(
        class  => 'Fnerk',
        loader => 'XML',
        file   => 'phrases.xml',
        dict   => 'English',
    );

=head1 DESCRIPTION

This module provides a base class for phrasebook implementations.

=head1 CONSTRUCTOR

=head2 new

C<new> takes an optional hash of arguments. Each value in the hash
is given as an argument to a method of the same name as the key.

This constructor should B<never> need to be called directly as
Phrasebook creation should go through the L<Data::Phrasebook> factory.

Subclasses should provide at least an accessor method to retrieve values for
a named key. Further methods can be overloaded, but must retain a standard
API to the overloaded method.

All, or at least I<most>, phrasebook implementations should inherit from
B<this> class.

=cut

sub new {
    my $class = shift;
    my %hash = @_;
	$hash{loader} ||= 'Text';

    if($class->debug) {
		$class->store(3,"$class->new IN");
		$class->store(4,"$class->new args=[".$class->dumper(\%hash)."]");
	}

	my $self = bless {}, $class;

    # set default delimiters, in case custom delimiters
    # are provided in the hash
    $self->{delimiters} = qr{ :(\w+) }x;

    foreach (keys %hash) {
        $self->$_($hash{$_});
    }

    return $self;
}

=head1 METHODS

=head2 loader

Set, or get, the loader class. Uses a default if none have been
specified. See L<Data::Phrasebook::Loader>.

=head2 unload

Called by the file() and dict() methods when a fresh file or dictionary is
specified, and reloading is required.

=head2 loaded

Accessor to determine whether the current dictionary has been loaded

=head2 file

A description of a file that is passed to the loader. In most cases,
this is a file. A loader that gets its data from a database could
conceivably have this as a hash like thus:

   $q->file( {
       dsn => "dbi:SQLite:dbname=bookdb",
       table => 'phrases',
   } );

That is, which loader you use determines what your C<file> looks like.

The default loader takes just an ordinary filename.

=head2 dict

Accessor to store the dictionary to be used.

=cut

sub loader {
    my $self = shift;
    my $load = @_ ? shift : defined $self->{loader} ? $self->{loader} : 'Text';
	$self->{loader} = $load;
}
sub unload {
    my $self = shift;
    $self->{loaded} = undef;
    $self->{'loaded-data'} = undef;
    return;
}

sub loaded {
    my $self = shift;
    my $load = @_ ? $self->{loaded} = shift : $self->{loaded} ;

	# ensure we know what loader class we are getting
	$self->loader($load->class)  if($load);
	return $load;
}
sub file {
    my $self = shift;
    if(@_) {
        my $file = shift;
        if(!$self->{file} || $file ne $self->{file}) {
            $self->unload();
            $self->{file} = $file;
        }
    }
    return $self->{file};
}

sub dict {
    my $self = shift;

    if(@_) {
        my $list1 = "@_";
        my $list2 = $self->{dict} ? "@{$self->{dict}}" : '';

        if($list1 ne $list2) {
            $self->unload();
            $self->{dict} = (ref $_[0] ? $_[0] : [@_]);
        }
    }

    return($self->{dict} ? @{$self->{dict}}     : ()    )   if(wantarray);
    return($self->{dict} ? $self->{dict}->[0]   : undef );
}

=head2 dicts

Having instantiated the C<Data::Phrasebook> object class, and using the C<file>
attribute as a directory path, the object can return a list of the current
dictionaries available (provided the plugin supports it) as:

  my $pb = Data::Phrasebook->new(
    loader => 'Text',
    file   => '/tmp/phrasebooks',
  );

  my @dicts = $pb->dicts;

or

  my @dicts = $pb->dicts( $path );

=cut

sub dicts {
    my $self = shift;

    my $loader = $self->loaded;
    unless($loader) {
        $self->store(4,"->dicts loader=[".($self->loader)."]")	if($self->debug);
        $loader = Data::Phrasebook::Loader->new(
            'class' => $self->loader,
            'parent' => $self,
        );
        $self->loader($loader->class);  # so we know what we've got
    }

    # just in case it doesn't use D::P::Loader::Base
    croak("dicts() unsupported in plugin")
        unless($loader->can("dicts"));

    return $loader->dicts(@_);
}

=head2 keywords

Having instantiated the C<Data::Phrasebook> object class, using the C<dict>
attribute as required, the object can return a list of the current keywords
available (provided the plugin supports it) as:

  my $pb = Data::Phrasebook->new(
    loader => 'Text',
    file   => '/tmp/phrasebooks',
    dict   => 'TEST',
  );

  my @keywords = $pb->keywords;

or

  my @keywords = $pb->keywords( $dict );

Note the list will be a combination of the default and any named dictionary.
However, not all Loader plugins may support the second usage.

=cut

sub keywords {
    my $self = shift;

    my $loader = $self->loaded;
    if(!defined $loader) {
        $self->store(4,"->keywords loader=[".($self->loader)."]")	if($self->debug);
        $loader = Data::Phrasebook::Loader->new(
            'class' => $self->loader,
            'parent' => $self,
        );
        $self->loader($loader->class);  # so we know what we've got
    }

    # just in case it doesn't use D::P::Loader::Base
    croak("keywords() unsupported in plugin")
        unless($loader->can("keywords"));

    return $loader->keywords(@_);
}

=head2 data

Loads the data source, if not already loaded, and returns the data block
associated with the given key.

    my $data = $self->data($key);

This is typically only used internally by implementations, not the end user.

=cut

sub data {
    my $self = shift;
    my $id = shift;

    if($self->debug) {
		$self->store(3,"->data IN");
		$self->store(4,"->data id=[$id]");
	}

    return  unless($id);

    my $loader = $self->loaded;
    if(!defined $loader) {
        if($self->debug) {
            $self->store(4,"->data loader=[".($self->loader)."]");
            $self->store(4,"->data file=[".($self->file||'undef')."]");
            $self->store(4,"->data dict=[".($self->dict||'undef')."]");
        }
        $loader = Data::Phrasebook::Loader->new(
            'class' => $self->loader,
            'parent' => $self,
        );
        $self->loader($loader->class);  # so we know what we've got
        $loader->load( $self->file, $self->dict );
        $self->loaded($loader);
    }

    return $self->{'loaded-data'}->{$id} ||= do { $loader->get( $id ) };
}

=head2 delimiters

Returns or sets the current delimiters for substitution variables. Must be a
regular expression with at least one capture group.

The example below shows the default ':variable' style regex.

   $q->delimiters( qr{ :(\w+) }x );

The example below shows a Template Toolkit style regex.

   $q->delimiters( qr{ \[% \s* (\w+) \s* %\] }x );

In addition to the delimiter pattern, an optional setting to suppress missing
value errors can be passed after the pattern. If set to a true value, will 
turn any unmatched delimiter patterns to an empty string.

=cut

sub delimiters {
    my $self = shift;
    if(@_) {
        $self->{delimiters} = shift;
        $self->{blank_args} = shift || 0;
    }
        
    return $self->{delimiters};
}

1;

__END__

=head1 SEE ALSO

L<Data::Phrasebook>,
L<Data::Phrasebook::Loader>.

=head1 SUPPORT

Please see the README file.

=head1 AUTHOR

  Original author: Iain Campbell Truskett (16.07.1979 - 29.12.2003)
  Maintainer: Barbie <barbie@cpan.org> since January 2004.
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003 Iain Truskett.
  Copyright (C) 2004-2013 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
