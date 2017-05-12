package CPAN::Source::Dist;
use warnings;
use strict;
use base qw(Class::Accessor::Fast::XS);
__PACKAGE__->mk_accessors(qw(
    name 
    version_name 
    package_name
    version 
    maturity 
    filename 
    cpanid 
    extension 
    pathname
    source_path 
    _parent
));
use JSON::XS;
use YAML::XS;
use URI;
use overload '""' => \&to_string;

# CPAN::DistnameInfo compatible
sub dist { $_[0]->name; }

sub distvname { $_[0]->version_name; }

sub fetch_source_file { 
    my ($self,$file) = @_;
    return unless $self->source_path;
    my $uri = URI->new( $self->source_path . '/' . $file );
    return $self->_parent->http_get( $uri );
}

sub fetch_meta { 
    my $self = shift;
    my $yaml = $self->fetch_source_file( 'META.yml' );
    return YAML::XS::Load( $yaml );
}

sub fetch_readme { 
    my $self = shift;
    return $self->fetch_source_file( 'README' );
}

sub fetch_changes {
    my $self = shift;
    return $self->fetch_source_file( 'Changes' )
            || $self->fetch_source_file( 'Changelog' )
            || $self->fetch_source_file( 'CHANGELOG' );
}

sub fetch_todo {
    my $self = shift;
    return $self->fetch_source_file( 'TODO' )
        || $self->fetch_source_file( 'Todo' );
}

sub fetch_tarball {
    # TODO:
}

sub data { 
    my $self = shift;
    return {
        name  => $self->name,
        version_name  => $self->version_name,
        version => $self->version,
        maturity  => $self->maturity,
        filename  => $self->filename,
        cpanid    => $self->cpanid,
        extension => $self->extension,
        pathname  => $self->pathname,
        source_path => $self->source_path,
    };
}

sub to_string { 
    return encode_json( $_[0]->data );
}

1;
