package EventTest;

use strict;
use App::Info::Handler;
use vars qw(@ISA);
@ISA = 'App::Info::Handler';

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(@_);
    $self->{req} = [];
    return $self;
}

sub request {
    return shift @{$_[0]->{req}};
}

sub requests {
    my @reqs = @{$_[0]->{req}};
    @{$_[0]->{req}} = ();
    return wantarray ? @reqs : \@reqs;
}

sub message {
    my $req = shift->request or return;
    return $req->message;
}

sub handler {
    my $self = shift;
    push @{$self->{req}}, shift;
    1;
}
