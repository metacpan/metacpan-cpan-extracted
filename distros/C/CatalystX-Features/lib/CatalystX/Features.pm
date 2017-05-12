package CatalystX::Features;
$CatalystX::Features::VERSION = '0.26';
use strict;
use warnings;
use Carp;
use base qw/Class::Accessor::Fast Class::Data::Inheritable/;
use MRO::Compat;
use Class::Inspector;
use Class::MOP;
use Path::Class;
use File::Spec;
use Module::Runtime qw(use_module);

our $config_key = 'CatalystX::Features';

sub path_to {
    my $c = shift;
    my ($cpackage, $cfile, $cline ) = caller;
    my @args = @_;
    my $file = Path::Class::file( @args );
    my $path_orig = $c->next::method( @args );
    return $path_orig if -e $path_orig;
    if( my $backend = $c->features ) {
        my ($feature, $path);
        eval {
            $feature = $backend->find( file=>$file );
            $path = File::Spec->catdir( $feature->path, @args ); 
        };
        if( $path and !$@ ) {
            return -d $path ? Path::Class::dir( $path ) : Path::Class::file( $path );
        }
    } 
    return $path_orig;
}

sub features_setup {
    my $c = shift;

    my $config = $c->config->{ $config_key };

    unless ( defined $config->{backend} ) {

        $config->{home} ||=
          [ Path::Class::dir( $c->config->{home} . "/features" )->stringify ];

        my $backend_class = $config->{backend_class}
          || 'CatalystX::Features::Backend';

        use_module($backend_class);

        my $backend = $backend_class->new(
            {
                include_path => $config->{home},
                app       => $c,
            }
        );
        $backend->init;
        $c->config->{$config_key}->{backend} = $backend;
        $c->_log_features_table;
    }
}

sub setup {
    my $c = shift;

    $c->next::method(@_);

    $c->features_setup;
    
    return $c;
}

sub features {
    my $c = shift;

    $c->features_setup; # make sure it's loaded

    return $c->config->{ $config_key }->{backend};
}

sub _log_features_table {
    my $c = shift;
    my $table = <<"";
Features Loaded:
.----------------------------------------+------------------------+----------.
| Home                                   | Name                   | Version  |
+----------------------------------------+------------------------+----------+

    foreach my $feature ( $c->features->list ) {
        $table .= sprintf("| %-38s ", $feature->id );
        $table .= sprintf("| %-22s ", $feature->name );
        $table .= sprintf("| %-8s |\n", $feature->version );
    }

    $table .= <<"";
.-----------------------------------------------------------------+----------.

    $c->log->debug( $table . "\n" )
		if $c->debug;
}

1;

__END__

=pod

=head1 NAME

CatalystX::Features - Merges different application directories into your app.

=head1 VERSION

version 0.26

=head1 SYNOPSIS

	package MyApp;
	use Catalyst qw/-Debug
                +CatalystX::Features
                +CatalystX::Features::Lib
                +CatalystX::Features::Plugin::ConfigLoader
                +CatalystX::Features::Plugin::Static::Simple/;

=head1 DESCRIPTION

The idea behind this module is to make it easier to spread your code outside of the main application directory, in the spirit of Eclipse features and Ruby on Rails plugins. 

It's mainly useful if you're working on a large application with distinct isolated features that are not tightly coupled with the main app and could be pulled off or eventually reused somewhere else. 

It also comes handy in a large project, with many developers working on specific application parts. And, say, you wish to split the functionality in diretories, or just want to keep them out of the application core files. 

=head1 USAGE

=over 

=item * Create a directory under your app home named /features

	mkdir /MyApp/features/

=item * Each feature home dir should be named something like:

	/MyApp/features/my.demo.feature_1.0.0

=back

It's a split on underscore C<_>, the first part is the feature name, the second is the feature version.

Also splits on a dash C<->, allowing the feature to be named as C<Feature-0.9123>.  

If a higher version of a feature is found, that's the one to be used, the rest is ignored

=over 

=item * a feature without a version is ok, it will be the highest version available - good for local dev and pushing to a repository.

=item * a debug box is printed on startup, so you can check which version is running:

	[debug] Features Loaded:
	.----------------------------------------+------------------------+----------.
	| Home                                   | Name                   | Version  |
	+----------------------------------------+------------------------+----------+
	| simple.feature_1.0.0                   | simple.feature         | 1.0.0    |
	.-----------------------------------------------------------------+----------.

=back 

=head2 Disabling features

If you need a feature to be ignored, append a hash C<#> sign in front of the directory name:

	Rename 

	/MyApp/features/FunnyFeature-1.0

	To

	/MyApp/features/#FunnyFeature-1.0

That way the feature folder will be ignored during the initialization phase.

You can also disable by setting the C<$CatalystX::Features::DISABLED> variable early
in your code:

    use Catalyst::Runtime 5.70;

    BEGIN {
        $CatalystX::Features::DISABLED = [ qw/simple.feature anotherone/ ];
    }
    
    # ...

=head1 CONFIGURATION

=head2 home

Let's you set a list of directories where your features are located. It expects full paths.

	<CatalystX::Features>
		home /opt/myapp_features
		home /somewhere/else
	</CatalystX::Features>

Defaults to:

	MyApp/features

=head2 backend_class

Sets an alternative class to use as a backend. The default is
L<CatalystX::Features::Backend>.

	<CatalystX::Features>
		backend_class MyApp::Features
	</CatalystX::Features>

=head2 feature_class

Sets an alternative class to represent a single feature. The default is
L<CatalystX::Features::Feature>. This class should implement the role L<CatalystX::Features::Role::Feature>.

	<CatalystX::Features>
		feature_class MyApp::Feature
	</CatalystX::Features>

=head1 METHODS

=head2 $c->setup

The plugin setup method. Loads features and prints the feature configuration table. 

=head2 $c->features

Returns the feature backend object.

=head2 $c->features->list

Returns an array of loaded features, which are instances of the L<CatalystX::Features::Feature> class.

=head2 $c->features_setup

Does the dirty setup work. Called from various C<CatalystX::Features::Plugin::*> to make sure features are loaded.

=head2 $c->path_to

A rewrite of Catalyst's path_to method, so that it will search for the file path within features.

If your feature has the following file:

	MyApp/features/my.feature_1.0/root/file.ext

You may get the path to it using path_to as usual from within your feature:

	my $path = $c->path_to( 'root', 'file.ext' );	

This will work from any feature or from the main app, but it B<does not> allow a
file in one feature to get a path to a file in another. 

=head1 TODO

These things here, and many, many more that I can't recall right now.

=over 4

=item * Check splicit dependencies among features (although Perl's implicit dependency checking is perfectly valid).

=item * Be able to run complete tests. 

=item * More plugins: TT::Alloy, Email::Template, etc.

=item * Deploy PAR/ZIP files automatically. 

=item * Delayed initialization into INC

=back

=head1 AUTHOR

	Rodrigo de Oliveira (rodrigolive), C<rodrigolive@gmail.com>

=head1 CONTRIBUTORS

    Robert Buels (rbuels), C<rbuels@cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
