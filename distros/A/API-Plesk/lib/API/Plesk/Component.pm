package API::Plesk::Component;

use strict;
use warnings;

use Carp;

sub new {
    my ( $class, %attrs ) = @_;
    $class = ref $class || $class;

    confess "Required API::Plesk object!" unless $attrs{plesk};

    return bless \%attrs, $class;
}

# API::Plesk object
sub plesk { $_[0]->{plesk} }

sub check_required_params {
    my ( $self, $hash, @fields ) = @_;
    
    for my $key ( @fields ) {
        if ( ref $key ) {
            confess "Required any of this fields: " . join( ", ", @$key) . "!"
                unless grep { $hash->{$_} } @$key;
        } else {
            confess "Required field $key!" unless exists $hash->{$key};
        }
    }
}

# sort params in right order
sub sort_params {
    my ( $self, $params, @fields ) = @_;

    my @sorted;
    for my $key ( @fields ) {

        if ( ref $key ) {
            ($key) = grep { exists $params->{$_} } @$key 
        }
        push @sorted, {$key => $params->{$key}}
            if exists $params->{$key};

    }

    return \@sorted;
}

# check hosting xml section
sub check_hosting {
    my ( $self, $params, $required ) = @_;

    unless ( $params->{hosting} ) {
        confess "Required hosting!" if $required;
        return;
    }

    my $hosting = $params->{hosting};
    my $type = delete $hosting->{type};
    my $ip = delete $hosting->{ip_address};
    
    #confess "Required ip_address" unless $ip;
    
    if ( $type eq 'vrt_hst' ) {

        $self->check_required_params($hosting, qw(ftp_login ftp_password));

        my @properties;
        for my $key ( sort keys %$hosting ) {
            push @properties, { property => [
                {name => $key}, 
                {value => $hosting->{$key}} 
            ]};
            delete $hosting->{$key};
        }
        push(@properties, { ip_address => $ip }) if $ip;
        $hosting->{$type} = @properties ? \@properties : '';

        return;
    }

    elsif ( $type eq 'std_fwd' or $type eq 'frm_fwd' ) {
        
        confess "Required dest_url field!" unless $hosting->{dest_url};
        
        $hosting->{$type} = {
            dest_url => delete $hosting->{dest_url},
        };
        $hosting->{$type}->{ip_address} = $ip if $ip;

        return;
    }
    elsif ( $type eq 'none' ) {
        $hosting->{$type} = '';
        return;
    }

    confess "Unknown hosting type!";
}

sub prepare_filter {
    my ( $self, $filter, %opts ) = @_;

    my @filter;
    my $sort = $opts{sort_keys} || [keys %$filter];

    for my $key ( @$sort ) {
        if ( ref $filter->{$key} eq 'ARRAY' ) {
            for my $value ( @{$filter->{$key}} ) {
                push @filter, { $key => $value };
            }
        }
        else {
            push @filter, { $key => $filter->{$key} };
        }
    }

    return @filter ? \@filter : '';
}

1;

__END__

=head1 NAME

API::Plesk::Component -  Base class for components.

=head1 SYNOPSIS

package API::Plesk::Customer;

use base 'API::Plesk::Component';

sub get { ... }
sub set { ... }

1;

=head1 DESCRIPTION

Base class for components.

=head1 METHODS

=over 3

=item new(plesk => API::Plesk->new(...))

Create component object.

=item plesk()

    Referer to API::Plesk object.

=item

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
