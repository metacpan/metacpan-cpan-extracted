package CGI::Session::Driver::aggregator;

# $Id$

use strict;
use Carp qw(croak);
use CGI::Session::Driver;

@CGI::Session::Driver::aggregator::ISA = ( "CGI::Session::Driver" );
$CGI::Session::Driver::aggregator::VERSION = "0.04";

sub drivers {
    my $self = shift;
    return @{ $self->{drivers} };
}

sub init {
    my $self = shift;
    unless (defined $self->{Drivers}) {
        return $self->set_error("init(): 'Drivers' attribute is required.");
    }

    my @drivers;
    $self->{drivers} ||= [];
    for my $d ( $self->{Drivers}->drivers ) {
        my $obj = $d->{package}->new($d->{args});
        push @drivers, $obj;
    }

    $self->{drivers} = \@drivers;

    return 1;
}

sub retrieve {
    my $self = shift;
    my ($sid) = @_;
    croak "retrieve(): usage error" unless $sid;

    for my $driver ($self->drivers) {
        if (my $data = $driver->retrieve(@_)) {
            return $data;
        }
    }

    return 0;
}

sub store {
    my $self = shift;
    my ($sid, $datastr) = @_;
    croak "store(): usage error" unless $sid && $datastr;

    for my $driver (reverse $self->drivers) {
        $driver->store(@_);
    }

    return 1;
}

sub remove {
    my $self = shift;
    my ($sid) = @_;
    croak "remove(): usage error" unless $sid;

    for my $driver (reverse $self->drivers) {
        $driver->remove(@_);
    }
    
    return 1;
}


sub DESTROY {
    my $self = shift;
}

sub traverse {
    my $self = shift;
    my ($coderef) = @_;

    unless ( $coderef && ref( $coderef ) && (ref $coderef eq 'CODE') ) {
        croak "traverse(): usage error";
    }

    for my $driver ($self->drivers) {
        $driver->traverse(@_);
    }

    return 1;
}

1;


=pod

=head1 NAME

CGI::Session::Driver::aggregator - CGI::Session driver to aggregate some CGI::Session drivers.

=head1 SYNOPSIS

    use CGI::Session;
    use CGI::Session::Driver::aggregator::Drivers;
    use DBI;

    $dbh = DBI->connect('DBI:mysql:cgi_session;host=localhost', 'root', '');
    $drivers = CGI::Session::Driver::aggregator::Drivers->new;
    $drivers->add('file', { Directory => '/tmp' });
    $drivers->add('mysql', { Handle => $dbh });
    $s = CGI::Session->new('driver:aggregator', $sid, { Drivers => $drivers });
    $s->param(hey => 'Blur blur blur!');
    # ----> Store datas into mysql and file!!
    
    $value = $s->param('hey');
    # ----> Read datas from file (When cannot find, then from mysql)

=head1 DESCRIPTION

B<aggregator> stores session data into anything to be set up.

=head1 DRIVER ARGUMENTS

The only supported driver argument is 'Drivers'. It's an instance of L<CGI::Session::Driver::aggregator::Drivers|CGI::Session::Driver::aggregator::Drivers>.

=head1 REQUIREMENTS

=over 4

=item L<CGI::Session>

=back

=head1 AUTHOR

Kazuhiro Oinuma <oinume@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 - 2006 Kazuhiro Oinuma <oinume@cpan.org>. All rights reserved. This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=cut

