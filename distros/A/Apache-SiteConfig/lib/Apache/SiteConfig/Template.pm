package Apache::SiteConfig::Template;
use warnings;
use strict;
use Moose;
use Apache::SiteConfig;
use Apache::SiteConfig::Root;


sub new_context {
    return Apache::SiteConfig::Root->new;
}

sub build {
    my ($self,%args) = @_;

    my $args = \%args;
    my $root = $self->new_context;
    my $vir = $root->add_section( 'VirtualHost' , '*:80' );

    for( grep { $args->{$_} } qw(ServerName ServerAlias DocumentRoot)) {
        $vir->add_directive( $_ , $args{$_} );
    }

    my $root_dir = $vir->add_section('Directory' , '/');
    $root_dir->add_directive( 'Options' , 'FollowSymLinks' );
    $root_dir->add_directive( 'AllowOverride' , 'None' );

    my $doc_root = $vir->add_section('Directory', $args{DocumentRoot} );
    $doc_root->add_directive( 'Options' , 'Indexes FollowSymLinks MultiViews' );
    $doc_root->add_directive( 'AllowOverride' , 'None' );
    $doc_root->add_directive( 'Order' , 'allow,deny' );
    $doc_root->add_directive( 'Allow' , 'from all' );

    $vir->add_directive( 'LogLevel'  , 'info' );
    $vir->add_directive( 'CustomLog' , [ $args{CustomLog} , 'combine' ] ) if $args{CustomLog};
    $vir->add_directive( 'ErrorLog' , $args{ErrorLog} ) if $args{ErrorLog};
    return $root;
}

1;
__END__


    $ git clone git@foo.com:projectA.git /var/sites/projectA

and will build site config args for template class:

    ServerName => 'foo.com',
    ServerAlias => 'bar.com',
    DocumentRoot => '/var/sites/projectA/webroot/'
    AccessLog => '/var/sites/projectA/apache2/logs/access.log',
    ErrorLog => '/var/sites/projectA/apache2/logs/error.log',

