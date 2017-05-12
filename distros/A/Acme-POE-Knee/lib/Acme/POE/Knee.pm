package Acme::POE::Knee;
BEGIN {
  $Acme::POE::Knee::VERSION = '1.12';
}

#ABSTRACT: Time sliced pony race using the POE kernel.

use strict;
use POE;

sub new {
    my $class   = shift;
    my %args    = @_;
    my $self    = { };
    my $data    = {
        dist    => 10,
        ponies  => {
            'dngor'     => 5,
            'Abigail'   => 5.2,
            'Co-Kane'   => 5.4,
            'MJD'       => 5.6,
            'acme'      => 5.8,
        },
    };

    ### check for wrong input ###
    for my $key ( keys %args ) {
        unless( exists $data->{$key} ) {
            print "WARNING! Option $key is not supported in $class!\n";
        }
    }

    ### bless the object into the class ###
    bless $self, $class;

    ### now we start adding the data ###
    for my $key (keys %$data) {
      if ( exists $args{$key} ) {
            $self->{$key} = $args{$key};
        } else {
            $self->{$key} = $data->{$key};
        }
    }

    ### fetch the data ###
    sub dist    { my $self = shift; $self->{dist}     }
    sub ponies  { my $self = shift; $self->{ponies}   }

    return $self;

}

sub _start {
    my ($kernel, $heap, $name, $delay, $dist) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];

    $heap->{name}   = $name;
    $heap->{delay}  = $delay;
    $heap->{dist}   = $dist;

    printf "Starting pony %10s\n", $heap->{name};
    $kernel->delay_add( run => rand($heap->{delay}) );
}

sub run {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    printf "Pony %10s has reached stage %3i\n", $heap->{name}, ++$heap->{stage};
    die "$heap->{name} won the race!\n" if $heap->{stage} > $heap->{dist};
    $kernel->delay_add( run => rand($heap->{delay}) );
}

sub race {
    my $self = shift;

    for my $name (@{[keys %{$self->ponies()}]} ) {

        POE::Session->create (
           inline_states => {
               _start  => \&_start,
               run     => \&run,
            },
            args => [ $name, $self->ponies()->{$name}, $self->dist() ],
        );
    }
    $poe_kernel->run();
}

q[POE::Knee!];


__END__
=pod

=head1 NAME

Acme::POE::Knee - Time sliced pony race using the POE kernel.

=head1 VERSION

version 1.12

=head1 SYNOPSIS

    #!/usr/bin/perl -w
    use strict;

    # Use POEny!
    use Acme::POE::Knee;

    # Every Acme::POE::Knee race will require a set of arguments.
    # There are defaults but it's just more fun to set these
    # yourselves. We set a distance the ponies must run and of course
    # we name our race ponies! You'll have to specify the maximum
    # delay a pony can have before reaching the next stage.
    # The lower the delay, the higher the chances are the pony will
    # win the race.

    my $pony = new Acme::POE::Knee (
	      dist   => 20,
        ponies  => {
            'dngor'     => 5,
            'Abigail'   => 5.2,
            'Co-Kane'   => 5.4,
            'MJD'       => 5.6,
            'acme'      => 5.8,
        },
    );

    # start the race
    $pony->race( );

    exit;

=head1 DESCRIPTION

POE::Knee is an acronym of "Pony".  We all like ponies. And wouldn't we
love to race ponies? Well, that's what Acme::POE::Knee is for!

It's great for those friday afternoons at the office, where you wonder
who will pay the beer tab. Whoever 'wins' the race, loses!

You specify a distance the ponies must run, and a maximum delay before
the pony will reach the next step. So, the bigger the delay, the bigger
the distance between multiple ponies can be.

Of course this wouldn't be any fun if we couldn't name the ponies
ourselves. Here, we simply put all our race ponies in an array
reference and the Acme::POE::Knee module will take care of the rest.

=for Pod::Coverage   new
  race
  dist
  ponies
  run

=head1 QUICK LINKS

Please see the samples directory in POE's distribution for several
well-commented sample and tutorial programs.

Please see <http://www.perl.com/pub/2001/01/poe.html> for an excellent,
and more importantly: gradual, introduction to POE.

=head1 USING Acme::POE::Knee

Using Acme::POE::Knee is really easy.
This simple progam would already suffice:

    use strict;
    use Acme::POE::Knee;

    my $pony = new Acme::POE::Knee;
    $pony->race();
    exit;

This will use the defaults of the POE::Knee module, but you can of
course specify your own arguments, as shown in the synopsis.

=head1 The Use of Acme::POE::Knee

Use, yes... Usefull? Probably not. This was written in response to a
rather persistant meme on #perl (you know who you are!).
Basicly, we all wanted ponies.
Well folks, here it is.

Its source might be interesting to look at for newcomers to POE to see
how this time slicing works.

=head1 Learning more about POE

=over 2

=item The POE Mailing List

POE has a mailing list at perl.org.  You can receive subscription
information by sending e-mail:

  To: poe-help@perl.org
  Subject: (anything will do)

  The message body is ignored.

All forms of feedback are welcome.

=item The POE Web Site

POE has a web site where the latest development snapshot, along with
the Changes file and other stuff may be found: <http://poe.perl.org/>

=back

=head1 AUTHORS

=over 4

=item *

Jos Boumans <kane@cpan.org>

=item *

Rocco Caputo <rcaputo@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jos Boumans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

