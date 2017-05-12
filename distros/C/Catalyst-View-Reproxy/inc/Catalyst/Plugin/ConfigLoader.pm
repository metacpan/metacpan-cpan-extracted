#line 1
package Catalyst::Plugin::ConfigLoader;

use strict;
use warnings;

use Config::Any;
use NEXT;
use Data::Visitor::Callback;

our $VERSION = '0.14';

#line 46

sub setup {
    my $c     = shift;
    my @files = $c->find_files;
    my $cfg   = Config::Any->load_files( {
        files   => \@files, 
        filter  => \&_fix_syntax,
        use_ext => 1
    } );

    # split the responses into normal and local cfg
    my $local_suffix = $c->get_config_local_suffix;
    my( @cfg, @localcfg );
    for( @$cfg ) {
        if( ( keys %$_ )[ 0 ] =~ m{ $local_suffix \. }xms ) {
            push @localcfg, $_;
        } else {
            push @cfg, $_;
        }
    }
    
    # load all the normal cfgs, then the local cfgs last so they can override
    # normal cfgs
    $c->load_config( $_ ) for @cfg, @localcfg;

    $c->finalize_config;
    $c->NEXT::setup( @_ );
}

#line 81

sub load_config {
    my $c   = shift;
    my $ref = shift;
    
    my( $file, $config ) = each %$ref;
    
    $c->config( $config );
    $c->log->debug( qq(Loaded Config "$file") )
        if $c->debug;

    return;
}

#line 102

sub find_files {
    my $c = shift;
    my( $path, $extension ) = $c->get_config_path;
    my $suffix     = $c->get_config_local_suffix;
    my @extensions = @{ Config::Any->extensions };
    
    my @files;
    if ($extension) {
        next unless grep { $_ eq $extension } @extensions;
        push @files, $path, "${path}_${suffix}";
    } else {
        @files = map { ( "$path.$_", "${path}_${suffix}.$_" ) } @extensions;
    }

    @files;
}

#line 142

sub get_config_path {
    my $c       = shift;
    my $appname = ref $c || $c;
    my $prefix  = Catalyst::Utils::appprefix( $appname );
    my $path    = $ENV{ Catalyst::Utils::class2env( $appname ) . '_CONFIG' }
        || $c->config->{ file }
        || $c->path_to( $prefix );

    my( $extension ) = ( $path =~ m{\.(.{1,4})$} );
    
    if( -d $path ) {
        $path  =~ s{[\/\\]$}{};
        $path .= "/$prefix";
    }
    
    return( $path, $extension );
}

#line 177

sub get_config_local_suffix {
    my $c       = shift;
    my $appname = ref $c || $c;
    my $suffix  = $ENV{ CATALYST_CONFIG_LOCAL_SUFFIX }
        || $ENV{ Catalyst::Utils::class2env( $appname ) . '_CONFIG_LOCAL_SUFFIX' }
        || $c->config->{ config_local_suffix }
        || 'local';

    return $suffix;
}

sub _fix_syntax {
    my $config     = shift;
    my @components = (
        map +{
            prefix => $_ eq 'Component' ? '' : $_ . '::',
            values => delete $config->{ lc $_ } || delete $config->{ $_ }
        },
        grep {
            ref $config->{ lc $_ } || ref $config->{ $_ }
        }
        qw( Component Model M View V Controller C )
    );

    foreach my $comp ( @components ) {
        my $prefix = $comp->{ prefix };
        foreach my $element ( keys %{ $comp->{ values } } ) {
            $config->{ "$prefix$element" } = $comp->{ values }->{ $element };
        }
    }
}

#line 224

sub finalize_config {
    my $c = shift;
    my $v = Data::Visitor::Callback->new(
        plain_value => sub {
            return unless defined $_;
            s{__HOME__}{ $c->path_to( '' ) }e;
            s{__path_to\((.+)\)__}{ $c->path_to( split( '/', $1 ) ) }e;
        }
    );
    $v->visit( $c->config );
}

#line 282

1;
