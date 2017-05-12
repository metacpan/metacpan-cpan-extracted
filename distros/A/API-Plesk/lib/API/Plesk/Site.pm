
package API::Plesk::Site;

use strict;
use warnings;

use Carp;
use Data::Dumper;

use base 'API::Plesk::Component';

#TODO
sub add {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};
    my $gen_setup = $params{gen_setup} || confess "Required gen_setup parameter!";

    my @fields = (
        'name',
        [qw(webspace-name webspace-id webspace-guid)]
    );

    $self->check_required_params($gen_setup, @fields);
    $self->check_hosting(\%params);

    $params{gen_setup} = $self->sort_params($gen_setup, @fields);
    
    my $data = $self->sort_params(\%params, qw(gen_setup hosting prefs));

    return $bulk_send ? $data : 
        $self->plesk->send('site', 'add', $data);
}

sub get {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};
    my $dataset   = {gen_info => ''};
    
    if ( my $add = delete $filter{dataset} ) {
        $dataset = { map { ( $_ => '' ) } ref $add ? @$add : ($add) };
        $dataset->{gen_info} = '';
    }

    my $data = { 
        filter  => @_ > 2 ? \%filter : '',
        dataset => $dataset,
    };

    return $bulk_send ? $data : 
        $self->plesk->send('site', 'get', $data);
}

sub set {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send}; 
    my $filter    = delete $params{filter} || '';
    
    $self->check_hosting(\%params);


    my $data = {
        filter  => $filter,
        values  => $self->sort_params(\%params, qw(gen_setup prefs hosting disk_usage)),
    };

    return $bulk_send ? $data : 
        $self->plesk->send('site', 'set', $data);
}

sub del {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send}; 

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data : 
        $self->plesk->send('site', 'del', $data);
}

sub get_physical_hosting_descriptor {
    my ( $self, %filter ) = @_;
    my $bulk_send = delete $filter{bulk_send};
    
    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data :
        $self->plesk->send(
            'site', 
            'get-physical-hosting-descriptor', 
            $data
        );
}

1;

__END__

=head1 NAME

API::Plesk::Site -  Managing sites (domains).

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->site->get(..);

=head1 DESCRIPTION

Module manage sites (domains).

=head1 METHODS

=over 3

=item add(%params)

=item get(%params)

=item set(%params)

=item del(%params)

=item get_physical_hosting_descriptor(%params)

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
