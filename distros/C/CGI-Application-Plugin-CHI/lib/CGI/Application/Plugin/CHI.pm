package CGI::Application::Plugin::CHI;

use strict;
use warnings;

use base 'Exporter';

use CHI;
use Scalar::Util 'blessed', 'reftype';
use Carp 'croak';

our $VERSION = 0.03;

# export by default since we're doing a mixin-style class
our @EXPORT = ( 'cache_config', 'cache_default', 'cache', 'rmcache', '__get_cache' );


my %CONFIG;

sub cache_config { 
    my $class = shift;

    if ( @_ == 1 ) { 
        croak 'first argument to cache_config() must be a hashref or cache name'
          unless reftype $_[0] eq 'HASH';

        return $CONFIG{default} = $_[0];
    } elsif ( @_ >= 2 ) { 
        my %args = @_;
        foreach my $key( keys %args ) { 
            croak 'multiple-argument form of cache_config() requires name => hashref pairs'
              unless ref( $args{$key} ) && reftype $args{$key} eq 'HASH';

            $CONFIG{named}{$key} = $args{$key};
        }

        return 1;
    }

    croak 'no arguments to cache_config()';
}

sub cache_default { 
    my $class = shift;

    croak 'cache_default requires one argument'
      unless @_ == 1;

    if ( my $def_conf = $CONFIG{named}{$_[0]} ) { 
        return $CONFIG{default} = $def_conf;
    }
  
    croak "no such cache named '$_[0]'";
}

sub cache { 
    my $self = shift;

    croak 'cache must be called as an object method' 
      unless ref $self;

    croak 'too many arguments to cache()'
      if @_ > 1;

    return $self->__get_cache( [ @_ ] );
}

sub rmcache { 
    my $self = shift;

    croak 'rmcache must be called as an object method'
      unless ref $self;

    my $ns = blessed( $self ) . '::' . $self->get_current_runmode;

    return $self->__get_cache( [ @_ ], $ns );
}


sub __get_cache { 
    my $self = shift;

    my @args = @{ $_[0] };
    my $ns   = $_[1] || '';

    if ( @args == 0 ) { 
        if ( my $conf = $CONFIG{default} ) { 
            return CHI->new( %$conf, 
                             $ns
                             ? ( namespace => $ns )
                             : ( )
                           );
                             
        } else { 
            croak "no default cache configured";
        }
    } elsif ( @args == 1 ) { 
        if ( my $conf = $CONFIG{named}{$args[0]} ) { 
            return CHI->new( %$conf,
                             $ns
                             ? ( namespace => $ns )
                             : ( )
                           );
        } 

        croak "no such cache '$args[0]' configured";        
    }

    die 'too many args for _get_cache';
}


# really only used for testing
sub _clean_conf { 
    %CONFIG = ( );
}


1;


__END__
=encoding utf-8

=head1 NAME

CGI::Application::Plugin::CHI - CGI-App plugin for CHI caching interface

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

  package My::WebApp;
  
  use strict;
  use warnings;
  
  use base 'CGI::Application';
  
  use CGI::Application::Plugin::CHI;
  
  __PACKAGE__->cache_config( { driver => 'File', root_dir => '/path/to/nowhere' } );
  
  ...
  
  # a runmode
  sub a_runmode { 
      my $self = shift;
      $self->cache->set( foo => 42 );
      return 'the value of foo is ' . $self->cache->get( 'foo' );
  }


=head1 EXPORT

This module exports the following methods into your L<CGI::Application> base class: C<cache_config>, C<cache_default>, C<cache>, C<rmcache> and C<__get_cache>. 

=head1 CLASS METHODS

=head2 cache_config

This method sets up all your caches and stores their configurations for later retrieval. You can call C<cache_config>
in two ways. The simple way sets up a default cache, and takes a single hashref which is passed directly to L<CHI>:

  __PACKAGE__->cache_config( { driver => 'File', root_dir => '/path/to/nowhere' } )

Once it's set up, this default cache can be accessed from anywhere that can call the C<cache> or C<rmcache> methods. 
(e.g. your web application class and any of its subclasses.)

Alternatively, you can pass in a list of name => hashref pairs to set up several caches with different names.

  __PACKAGE__->cache_config( ondisk       => { driver => 'File', root_dir => '/path/to/nowhere' },
                             inram        => { driver => 'Memory', datastore => \%hash },
                             distributed  => { driver => 'Memcached', ... } );

You can call C<cache_config> multiple times to add or overwrite additional cache configurations.

These caches can be accessed with the one-argument form of C<cache> and C<rmcache> described below.

=head2 cache_default

This method designates a named cache as the default cache. 

  __PACKAGE__->cache_default( 'foobar' );  # $self->cache() now returns the same as $self->cache( 'foobar' )

=head1 OBJECT METHODS

=head2 cache

This method instantiates and returns a cache which you have previously configured. With no arguments, it
returns the default cache, if there is one.

  my $cache = $self->cache;   # default cache

If there is no default cache, a fatal error occurs.

You can pass the name of a cache as an argument.

  my $cache = $self->cache( 'foobar' );   # the foobar cache

If there is no cache with that name, a fatal error occurs.

=head2 rmcache

This does the same thing as C<cache> above, except it performs the extra step of setting the cache's namespace
to a concatenation of the current class's name and the current runmode. You can use this to store per-runmode
data that you don't want crashing into other runmodes.

  sub runmode_foo { 
      my $self = shift;
      my $cache = $self->rmcache( 'foobar' );   # items stored here will be in  
                                                # their own namespace
  }

Just like C<cache>, you can call C<rmcache> with zero arguments to get the default cache with a namespace set.

Note that if you set a namespace when you called C<cache_config>, using C<rmcache> will override it.

=head2 __get_cache

This method is used internally by C<cache> and C<rmcache> to fetch and instantiate the proper cache
object. It will be exported to your application, but you should not call it directly. 

=head1 AUTHOR

Mike Friedman, C<< <friedo at friedo.com> >>

=head1 THANKS

Thanks to 黄叶 for pointing out some documentation bugs, and Jonathan Swartz, Perrin Harkins and the rest of the CHI team. 

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-application-plugin-chi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-CHI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::CHI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Application-Plugin-CHI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Application-Plugin-CHI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Application-Plugin-CHI>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Application-Plugin-CHI>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008 Mike Friedman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.



