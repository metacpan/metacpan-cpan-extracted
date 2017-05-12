package CGI::Session::Driver::memcached;

# $Id$

use strict;

use Carp qw(croak);
use CGI::Session::Driver;

@CGI::Session::Driver::memcached::ISA = ( "CGI::Session::Driver" );
our $VERSION = "0.04";

sub init {
    my $self = shift;
    unless (defined $self->{Memcached}) {
        return $self->set_error("init(): 'Memcached' attribute is required.");
    }

    return 1;
}

sub retrieve {
    my $self = shift;
    my ($sid) = @_;
    croak "retrieve(): usage error" unless $sid;

    my $memcached = $self->{Memcached};
    my $rv = $memcached->get("$sid");
#warn "retrieve(): sid=$sid, $rv\n";

    return 0 unless (defined $rv);
    return $rv;
}


sub store {
    my $self = shift;
    my ($sid, $datastr) = @_;
    croak "store(): usage error" unless $sid && $datastr;

#warn "store(): sid=$sid, $datastr\n";
    my $memcached = $self->{Memcached};
    $memcached->set($sid, $datastr);

    return 1;
}

sub remove {
    my $self = shift;
    my ($sid) = @_;
    croak "remove(): usage error" unless $sid;

    $self->{Memcached}->delete($sid);
    
    return 1;
}


sub DESTROY {
    my $self = shift;
}

sub traverse {
    my $self = shift;
    my ($coderef) = @_;

#    unless ( $coderef && ref( $coderef ) && (ref $coderef eq 'CODE') ) {
#        croak "traverse(): usage error";
#    }

    # do nothing
    return 1;
}

1;


=pod

=head1 NAME

CGI::Session::Driver::memcached - CGI::Session driver for memcached

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Cache::Memcached; # or Cache::Memcached::Fast
    
    my $memcached = Cache::Memcached->new({
        servers => [ 'localhost:11211' ],
        debug   => 0,
        compress_threshold => 10_000,
    });
    my $session = CGI::Session->new( "driver:memcached", $sid, { Memcached => $memcached } );

=head1 DESCRIPTION

B<memcached> stores session data into memcached.

=head1 DRIVER ARGUMENTS

The only supported driver argument is 'Memcached'. It's an instance of L<Cache::Memcached|Cache::Memcached>.

=head1 REQUIREMENTS

=over 4

=item L<CGI::Session>

=item L<Cache::Memcached> or L<Cache::Memcached::Fast>

=back

=head1 TODO

=over 4

=item Implement traverse method!

But I don't know how to get all objects store in memcached.

=back

=head1 AUTHOR

Kazuhiro Oinuma <oinume@cpan.org>

=head1 REPOSITORY

  git clone git://github.com/oinume/p5-cgi-session-driver-memcached

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 - 2009 Kazuhiro Oinuma <oinume@cpan.org>. All rights reserved. This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=cut

