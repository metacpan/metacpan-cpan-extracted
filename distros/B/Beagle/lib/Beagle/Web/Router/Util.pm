use strict;
use warnings;

package Beagle::Web::Router::Util;
use Beagle::Util;
use Router::Simple;
use JSON;
use base 'Exporter';
our @EXPORT =
  qw/handle request render get post any router admin from_json to_json prefix
  redirect process_fields add_attachments delete_attachments
  response status header headers content_type body
  /;

sub handle  { Beagle::Web->handle() }
sub request { Beagle::Web->request() }

sub response { Beagle::Web->response() }
sub status { response()->status( @_ ) }
sub header { response()->header( @_ ) }
sub headers { response()->headers( @_ ) }
sub content_type { response()->content_type( @_ ) }
sub content_encoding { response()->content_encoding( @_ ) }
sub body { response()->body( @_ ) }

sub prefix  { Beagle::Web->prefix }

sub process_fields { goto &Beagle::Web::process_fields };
sub add_attachments { goto &Beagle::Web::add_attachments };
sub delete_attachments { goto &Beagle::Web::delete_attachments };

sub redirect { goto \&Beagle::Web::redirect }
sub render   { goto \&Beagle::Web::render }

sub router {
    my $class = shift || router_package();
    no strict 'refs';
    return ${"${class}::ROUTER"};
}

sub admin {
    my $class = shift || router_package();
    no strict 'refs';
    return ${"${class}::ADMIN"};
}

sub import {
    init();
    __PACKAGE__->export_to_level( 1, @_ );
}

sub init {
    my $pkg = router_package();
    return unless $pkg;

    no strict 'refs';
    ${"${pkg}::ROUTER"} ||= Router::Simple->new();
    ${"${pkg}::ADMIN"}  ||= ${"${pkg}::ROUTER"}->submapper(
        '/admin',
        {},
        {
            on_match => sub {
                return web_admin() ? 1 : 0;
            },
        }
    );
}

sub router_package {
    my $pkg;
    for my $i ( 1 .. 10 ) {
        my $p = ( caller($i) )[0];
        if ( $p && $p =~ /::Router$/ ) {
            $pkg = $p;
        }
    }
    return $pkg;
}

sub any {
    my $methods;
    $methods = shift if @_ == 3;

    my $pattern = shift;
    my $code    = shift;
    my $dest    = { code => $code };
    my $opt     = { $methods ? ( method => $methods ) : () };

    my $router = router_package()->router;
    my $admin  = router_package()->admin;

    if ( $pattern =~ s{^/admin(?=/)}{} ) {
        $admin->connect( $pattern, $dest, $opt );
    }
    else {
        $router->connect( $pattern, $dest, $opt, );
    }
}

sub get {
    any( [qw/GET HEAD/], $_[0], $_[1] );
}

sub post {
    any( [qw/POST/], $_[0], $_[1] );
}

1;

__END__

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


