package Catalyst::Plugin::Config::Multi;

use strict;
use warnings;
use Config::Multi;
use NEXT;

our $VERSION ='0.02';

sub setup {
    my $c = shift;
    my %config = %{$c->config()->{'Plugin::Config::Multi'}} ;
    my $cm = Config::Multi->new( \%config );
    my $config = $cm->load();
    if( $c->debug ) {
        for my $file (  @{$cm->files} ) {
            $c->log->debug( 'Load Config ' . $file );
        }
    }
    $c->config( $config ) ;
    $c->NEXT::setup( @_ );
}

1;

=head1 NAME

Catalyst::Plugin::Config::Multi - Catalyst Config Plugin using L<Config::Multi>

=head1 SYNOPSIS

 package TestApp;
 
 use strict;
 use warnings;
 
 use Catalyst::Runtime '5.7008';
 
 use Catalyst qw/Config::Multi/;
 
 our $VERSION = '0.01';
 
 __PACKAGE__->config(
     'Plugin::Config::Multi' => { 
         dir => __PACKAGE__->path_to('./../conf'), 
         prefix => 'web', # optional
         app_name => 'testapp',
     },
 );
 
 __PACKAGE__->setup;
 
 1;
 
=head1 DESCRIPTION

This module load multiple config file using L<Config::Multi>. This module is useful when your have multiple catalyst applications or CLI interface and want to share your config files.

=head1 METHODS

=head2 setup

=head1 SEE ALSO

L<Config::Multi>

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

=head1 THANKS

woremacx

vkgtaro

=head1 COPYRIGHT

This module is copyright 2008 Tomohiro Teranishi. 

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

