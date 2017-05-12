package Cache::Memcached::Tie;

use strict;
use warnings;
use 5.8.0;

use Cache::Memcached::Fast;
use vars qw($VERSION);
$VERSION = '0.09';

use fields qw(default_expire_seconds);

sub TIEHASH{
    my ($package, $default_expire_seconds, @params) = @_;
    my $self = {};
    bless $self, $package;
    my $memd = Cache::Memcached::Fast->new(@params);
    $self->{'memd'} = $memd;
    $self->{'default_expire_seconds'} = $default_expire_seconds;
    return $self;
}

sub memd {
    my $self = shift;
    return $self->{memd};
}

sub STORE{
    my ($self, $key, $value) = @_;
    $self->memd->set($key, $value, $self->{'default_expire_seconds'});
}

# Check for the existence of a value - same as fetch, but sadly this is
# necessary for when the hash is used by libraries that need EXISTS
# functionality
sub EXISTS {
    my ($self, $key) = @_;
    my $val = $self->FETCH($key);
    return defined($val);
}

# Returns value or hashref (key=>$value)
sub FETCH {
    my $self=shift;
    my @keys=split "\x1C", shift; # Some hack for multiple keys
    my $val;
    if (@keys==1){
        $val = $self->memd->get($keys[0]);
    } else {
        $val = $self->memd->get_multi(@keys);
    }
    return $val;
}

sub DELETE{
    my $self=shift;
    my $key=shift;
    $self->memd->delete($key);
}

sub UNTIE{
    my $self=shift;
    $self->disconnect_all();
}

sub CLEAR{
    my $self=shift;
    $self->memd->flush_all();
}

1;
__END__

=head1 NAME

Cache::Memcached::Tie - Use Cache::Memcached::Fast like a hash.

=head1 SYNOPSIS

    #!/usr/bin/perl -w
    use strict;
    use Cache::Memcached::Tie;
    
    my %hash;
    my $default_expiration_in_seconds = 60;
    my $memd = tie %hash,'Cache::Memcached::Tie', $default_expiration_in_seconds, {servers=>['192.168.0.77:11211']};
    $hash{b} = ['a', { b => 'a' }];
    print $hash{'a'};
    print $memd->memd->get('b');
    # Clears all data
    %hash = ()

    #Also we can work with a slices:
    @hash{ 'a' .. 'z' } = ( 1 .. 26 );
    print join ',', @hash{ 'a' .. 'e' }; 

=head1 DESCRIPTION

Memcached works like big dictionary... So why we can't use it as Perl hash?

=head1 AUTHOR

Andrii Kostenko E<lt>andrey@kostenko.nameE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
