package Catalyst::Model::CacheFunky::Loader;

use strict;
use warnings;
use base qw/Catalyst::Model/;
use NEXT;
use Module::Recursive::Require;
use Carp;

our $VERSION = '0.06';

sub new {
    my $self  = shift->NEXT::new(@_);
    my $c     = shift;
    my $class = ref($self);

    my $funky_class  = $self->{class};
    my $funky_config = $self->{initialize_info};
    my $mrr_args     = $self->{mrr_args} || {};

    croak 'You must set class and initialize_info'
        unless $funky_class && $funky_config;

    my @funkies = Module::Recursive::Require->new($mrr_args)
        ->require_by($funky_class);

    no strict 'refs';
    for my $funky (@funkies) {

        $funky->setup( %{$funky_config} );

        my $funky_short = $funky;
        $funky_short =~ s/^$funky_class\:\://g;
        my $classname = "${class}::$funky_short";

        *{"${funky}::context"} = sub {$c};
        *{"${classname}::ACCEPT_CONTEXT"} = sub {
            return $funky;
        };
    }

    return $self;
}

1;

=head1 NAME

Catalyst::Model::CacheFunky::Loader - Load Cache::Funky Modules.

=head1 SYNOPSIS

    package MyApp::Model::Funky;
    
    use strict;
    use warnings;
    use base qw/Catalyst::Model::CacheFunky::Loader/;
    
    __PACKAGE__->config(
        class => 'MyApp::CacheFunky', # read all module under MyApp::CacheFunky::*
        initialize_info => { 'Storage::Simple' => {} },
        mrr_args => { path => '/var/www/Common/lib/' } , # option. SEE L<Module::Recursive::Require> new(\%args)
    );
    
    1;
    
    package MyApp::CacheFunky::Foo;
    
    use strict;
    use warnings;
    use qw/Cache::Funky/;
    
    __PACKAGE__->register( 'foo', sub {`date`} );
    
    1;
    
    package MyAPpCacheFunky::Users;
    
    use strict;
    use warnings;
    use qw/Cache::Funky/;
    
    __PACKAGE__->register( 'user_count',
        sub { __PACKAGE__->context()->model('DB::Users')->count(); } );
    
    1;
    
    package MyApp::Controller::FooBar;
    
    sub foo : Local {
        my ( $s, $c ) = @_;
    
        $c->log->debug( $c->model('Funky::Foo')->foo() );
        sleep(1);
        $c->log->debug( $c->model('Funky::Foo')->foo() );
        sleep(1);
        $c->model('Funky::Foo')->delete('foo');
        $c->log->debug( $c->model('Funky::Foo')->foo() );
    }
    
    1;
    
    [ %c . forward( 'Model::Funky::Foo', 'foo' ) % ]
    
=head1 DESCRIPTION

Load L<Cache::Funky> modules and make them ready for you.

=head1 METHOD

=head2 new

=head1 SEE ALSO

L<Module::Recursive::Require>

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tomohiro Teranishi, All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.  See L<perlartistic>.

=cut

