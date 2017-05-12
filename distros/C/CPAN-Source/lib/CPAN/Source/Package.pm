package CPAN::Source::Package;
use warnings;
use strict;
use base qw(Class::Accessor::Fast::XS);
__PACKAGE__->mk_accessors(qw(
    package
    version
    path
    dist
));

sub fetch_pm { 
    my $self = shift;
    my $path = $self->package;
    $path =~ s{::}{/}g;
    $path = 'lib/' . $path . '.pm';
    return $self->dist->fetch_source_file( $path );
}

sub data { 
    my $self = shift;
    my @attrs = $self->meta->get_all_attributes;
    my $data = {  };
    for my $attr ( @attrs ) {
        next if $attr->name =~ /^_/; # skip private attribute
        $data->{ $attr->name } = $attr->get_value( $self );
    }
    return $data;
}

1;
