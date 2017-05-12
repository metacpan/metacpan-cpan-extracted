package CatalystX::Features::Backend;
$CatalystX::Features::Backend::VERSION = '0.26';
use Class::MOP ();
use Moose;
use Path::Class;
use Module::Runtime qw(use_module);
use Carp;

has 'include_path'  => ( is => 'rw', isa => 'ArrayRef' );
has 'features'      => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'app'           => ( is => 'ro', isa => 'Any', required=>1 );
has 'feature_class' => ( is => 'rw', isa => 'Str' );
has '_find_cache'   => ( is => 'rw', isa => 'HashRef', default=>sub{{}} );

*list = \&_array;

with 'CatalystX::Features::Role::Backend';

sub init {
    my $self = shift;
    return if $ENV{CATALYSTX_NO_FEATURES};
    my $disabled = $CatalystX::Features::DISABLED;
    $disabled ||= [];
    carp '$CatalystX::Features::DISABLED must be an ARRAYREF' if ref $disabled ne 'ARRAY';
    $disabled = +{  map { $_ => 1 } @$disabled };
    for my $home ( @{ $self->include_path || [] } ) {
        my @features = $self->_find_features($home);
        foreach my $feature_path (@features) {

            my $feature_class = $self->config->{feature_class}
              || 'CatalystX::Features::Feature';

            $self->feature_class( $feature_class );

            # init feature
            use_module( $feature_class );
            my $feature = $feature_class->new(
                {
                    path    => "$feature_path",
                    backend => $self,
                }
            );
            $self->_push_feature($feature)
                if $feature->id !~ m/^#/
                && ! exists $disabled->{ $feature->name };
        }
    }
}

sub _find_features {
    my $self = shift;
    my $home = shift;
    my @features =
      map { Path::Class::dir($_) } grep { -d $_ } glob $home . '/*';
    return @features;
}

sub find {
    my ( $self, %args ) = @_;
    if( defined $args{file} ) {
        my $file = Path::Class::file( $args{file} );
		return $self->_find_cache->{$file}
			if exists $self->_find_cache->{$file};
        for my $feature ( $self->_array ) {
			if( -e Path::Class::file( $feature->path, $file ) ) {
				$self->_find_cache->{$file} = $feature;
				return $feature;
			}
        }

        # not found, return a fake feature for the app
        my $apphome = Path::Class::dir( $self->app->config->{home} );
        if( $apphome->contains( $file ) ) { 
            my $class = $self->feature_class;
            return $class->new({
                path => $apphome->stringify,
                backend => $self,
            });
        } else {
            confess "File " . $file->absolute . " is not in any feature or the main app."; 
        }
    }
}

sub _push_feature {
    my ( $self, $new_feature ) = @_;

    foreach my $feature_name ( keys %{ $self->features } ) {
        my $feature = $self->features->{$feature_name};
        if ( $feature->name eq $new_feature->name ) {
            if ( $feature->version eq 'max' || $feature->version_number > $new_feature->version_number ) {
                return 0;
            }
        }
    }
    $self->features->{ $new_feature->name } = $new_feature;
    return 1;
}

sub config {
    my $self = shift;
    return $self->app->config->{$CatalystX::Features::config_key} ||= {};
}

sub _array {
    my $self = shift;
    return map { $self->features->{$_} } keys %{ $self->features };
}

sub get {
    my $self = shift;
    return $self->features->{shift};
}

sub me {    #TODO
    my $self = shift;

    # get the callers' package

    # then find the file path for the package

    # then find the feature object from this path
}

1;

__END__

=pod 

=head1 NAME

CatalystX::Features::Backend - All the dirty work is done here

=head1 VERSION

version 0.26

=head1 SYNOPSIS

	my $backend = $c->features;

	$backend->list; # a list of features

	$backend->config; # my config 

=head1 METHODS

=head2 $c->features->config()

Returns the config hash part related to L<CatalystX::Features>.

=head2 $c->features->init()

Initializes the backend, searching for features and creating L<CatalystX::Features::Feature> instances for them. 

=head2 $c->features->find( file=>'filename.ext' )

Returns the feature that contains a file.

=head2 $c->features->list()

Returns an array with instances of all loaded features. If they have not changed via config, they'll be instances of the L<CatalystX::Features::Feature> class.

=head2 $c->features->get( $feature_name ) 

Get the object instance of a given feature name. 

=head2 $c->features->me()

Not implemented yet.

=head1 TODO 

=over

=item A $c->features->me method which can be called from within a feature to get it's own instance.

=back

=head1 AUTHORS

	Rodrigo de Oliveira (rodrigolive), C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
