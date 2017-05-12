package CPANPLUS::Backend::Test;

use warnings;
use strict;
use base qw(Object::Accessor);

use CPANPLUS::Configure;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( qw/ configure_object / );

    # Used in get_pkgbuild
    $self->configure_object( CPANPLUS::Configure->new() );

    return $self;
}

sub parse_module {
    
}

sub module_tree {

}

1;

package CPANPLUS::Module::Test;

# Module is the parent object for the CPANPLUS::Dist::Base.

use warnings;
use strict;
use base qw(Object::Accessor);

sub new {
    my $class = shift;
    my %opt   = @_;
    my $self  = $class->SUPER::new( qw{ name
                                        package package_name package_version
                                        parent status path description } );

    $self->status( Object::Accessor->new( qw{ prereqs installer_type
                                              dist_cpan extract } ));
    $self->status->dist_cpan( Object::Accessor->new( 'status' ));
    $self->status->dist_cpan->status( Object::Accessor->new( 'distdir' ));

    $opt{modname} ||= 'Fake::Package';
    $opt{name}    ||= 'Fake-Package';
    $opt{version} ||= '31337';
    $opt{prereqs} ||= { 'perl'        => '5.010' };
    $opt{desc}    ||= 'This is a "fake" package, for testing only.';

    # So that _translate_xs_deps does nothing...
    $opt{installer_type} ||= 'CPANPLUS::Dist::Build';

    # Used in get_cpandistdir
    $self->status->dist_cpan->status->distdir( "$opt{name}-$opt{version}" );

    # Used in _prepare_pkgdesc
    $self->description    ( $opt{desc} );

    # Used in _get_srcurl
    $self->path           ( 'J/JU/JUSTER' );
    $self->package        ( "$opt{name}-$opt{version}.tar.gz" );

    # Used in _translate_cpan_deps
    $self->name( $opt{modname} );

    # Used in get_pkgvars
    $self->package_name   ( $opt{name}    );
    $self->package_version( $opt{version} );
    # Used in _translate_cpan_deps
    $self->status->prereqs( $opt{prereqs} );
    # Used in _translate_xs_deps
    $self->status->installer_type( $opt{installer_type} );
    # Used in _prepare_cfgdeps
    $self->status->extract( 'asldfkjasldf' );

    $self->parent( CPANPLUS::Backend::Test->new() );

    return $self;
}

1;

package CPANPLUS::Dist::Base;

use warnings;
use strict;
use base qw(Object::Accessor);

# This is a fake version of CPANPLUS::Dist::Base so I can more easily run tests
# without being connected to the internet or using CPANPLUS's insane spaghetti code.

sub new {
    my $class = shift;
    my %opt   = @_;

    # Create accessors just like the real thing.
    my $self  = $class->SUPER::new( qw/ status parent / );
    bless $self, $class;

    # status is just an accessor.
    $self->status( Object::Accessor->new
                   ( qw/ prepared dist created installed / ));
    $self->parent( CPANPLUS::Module::Test->new( %opt ));

    # Call CPANPLUS::Dist::Arch->init()
    $self->init();
    return $self;
}

1;
