=head1 NAME

AnyEvent::Impl::Prima - Prima event loop adapter for AnyEvent

=head1 SYNOPSIS

  use Prima;
  use AnyEvent::Impl::Prima;
  
  my $mw = Prima::MainWindow->new();
  
  my $timer = AnyEvent->timer(
      after => 10,
      cb => sub { $mw->close; },
  );

  Prima->run;
  
=cut

{

package AnyEvent::Impl::Prima; 
use strict;

use vars '$VERSION';
$VERSION = '0.02';

use AnyEvent;
require Prima;
require Prima::Application;


sub io { my ($s,%r) = @_;
    my $f = Prima::File->new(
        mask        => ("w" eq $r{poll} ? fe::Write() : fe::Read()),
        onRead      => $r{cb},
        onWrite     => $r{cb},
        onException => $r{cb}
    );
    if( ! ref $r{fh}) {
        $f->fd( $r{fh} )
    } else {
        $f->file( $r{fh} )
    };
    $f
} 

sub AnyEvent::Impl::Prima::Timer::DESTROY { ${$_[0]}->destroy if $_[0] and ${$_[0]} }

sub timer { my ( $s, %r ) = @_;
    my($c,$g) = $r{cb};
    
    my $next = $r{ after } || $r{ interval };
    my $repeat = delete $r{ interval };

    
    # Convert to miliseconds for Prima
    $next *= 1000;
    $repeat *= 1000 if $repeat;
    
    my %timer_params = (
        timeout => $next,
    );
    my $timer = Prima::Timer->new(
        timeout => $next,
        onTick  => sub {
            #warn "Timer $_[0] fired";
            if( $repeat ) {
                $_[0]->timeout( $repeat );
            } else {
                $_[0]->stop;
            };
            &$c()
        },
        onDestroy => sub { my ( $self ) = @_;
            #warn "Discarding $self";
            $self->stop;
        },
    );
    #warn "Starting new timer $res";
    $timer->start;
    return bless \ $timer, "AnyEvent::Impl::Prima::Timer";
}

sub poll {
    require Prima::Application;
    $::application->yield;
}

{
no warnings 'redefine';
sub AnyEvent::CondVar::Base::_wait {
    require Prima::Application;
    $::application->yield until exists $_[0]{_ae_sent};
}
}

push @AnyEvent::REGISTRY,["Prima",__PACKAGE__]; 

}
__END__

=head1 AUTHORS

Zsban Ambrus

Max Maischein

Dmitry Karasik

=cut
