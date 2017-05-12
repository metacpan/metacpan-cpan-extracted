use strict;
use warnings;

package Data::Remember::Hybrid;
{
  $Data::Remember::Hybrid::VERSION = '0.140490';
}
# ABSTRACT: a brain for Data::Remember with multiple personalities

use Carp;
use Data::Remember::Util 
    process_que => { -as => '_process_que' },
    init_brain  => { -as => '_init_brain' };


sub new {
    my $class = shift;
    my @table = @_;

    my $self = bless { root => undef, mounts => {} }, $class;

    while (my ($que, $config) = splice @table, 0, 2) {
        $self->register_brain($que, $config);
    }

    croak 'No root brain was registered!'
        unless defined $self->{root};

    return $self;
}


sub register_brain {
    my $self   = shift;
    my $que    = shift;
    my $config = shift;

    croak "You must give a que." unless defined $que;
    croak "You must give a configuration." unless defined $config;

    $que    = _process_que($que);
    $config = [ $config ] unless ref $config;

    if (scalar(@$que) == 0) {
        $self->{root} = _init_brain(@$config);
    }

    else {
        my $object = $self->{mounts};
        for my $que_entry (@$que) {
            croak 'You ran amuck of my secret special que name "__BRAIN". '
                . 'I cannot work with such a que name.'
                    if $que_entry eq '__BRAIN';

            if (defined $object->{$que_entry}) {
                $object = $object->{$que_entry};
            }
            else {
                $object = $object->{$que_entry} = {};
            }
        }

        $object->{__BRAIN} = _init_brain(@$config);
    }
}


sub unregister_brain {
    my $self = shift;
    my $que  = shift;

    croak "You must give a que." unless defined $que;

    $que = _process_que($que);

    if (scalar(@$que) == 0) {
        croak 'You cannot unregister the root. You may, however, replace it '
            . 'using register_brain()';
    }

    my $object = $self->{mounts};
    for my $que_entry (@$que) {
        croak 'You ran amuck of my secret special que name "__BRAIN". '
            . 'I cannot work with such a que name.'
                if $que_entry eq '__BRAIN';

        if (defined $object->{$que_entry}) {
            $object = $object->{$que_entry};
        }
        else {
            return;
        }
    }

    return scalar defined delete $object->{__BRAIN};
}


sub brain_for {
    my $self = shift;
    my $que  = shift;

    $que = Data::Remember::Class::_process_que($que);
    push @$que, 'X';

    my ($best_brain) = $self->_best_brain($que);
    return scalar $best_brain;
}


sub _best_brain {
    my $self = shift;
    my $que  = shift;

    my @sub_que  = @$que;
    my $last_que = pop @sub_que;
    my $object   = $self->{mounts};

    my $best_brain = $self->{root};
    my $best_que   = [ @$que ];

    while (my $que_entry = shift @sub_que) {
        if (defined $object->{$que_entry}) {
            $object = $object->{$que_entry};

            if (defined $object->{__BRAIN}) {
                $best_brain = $object->{__BRAIN};
                $best_que   = [ @sub_que, $last_que ];
            }
        }
        else {
            last;
        }
    }

    return ($best_brain, $best_que);
}

sub remember {
    my $self = shift;
    my $que  = shift;
    my $fact = shift;

    my ($best_brain, $best_que) = $self->_best_brain($que);
    return $best_brain->remember($best_que, $fact);
}


sub recall {
    my $self = shift;
    my $que  = shift;

    my ($best_brain, $best_que) = $self->_best_brain($que);
    return $best_brain->recall($best_que);
}


sub forget {
    my $self = shift;
    my $que  = shift;

    my ($best_brain, $best_que) = $self->_best_brain($que);
    return $best_brain->forget($best_que);
}


1

__END__

=pod

=head1 NAME

Data::Remember::Hybrid - a brain for Data::Remember with multiple personalities

=head1 VERSION

version 0.140490

=head1 SYNOPSIS

  use Data::Remember Hybrid =>
      [ ]                   => [ 'Memory' ],
      'config'              => [ YAML => file => 'config.yml' ],
      [ data => 'persist' ] => [ DBM  => file => 'state.db'   ],
      [ data => 'temp'    ] => [ 'Memory' ],
      ;

  my $config_opt = recall [ config => 'SomeOption' ];

  remember [ data => persist => 'something' ] => 'what?';
  remember [ data => temp    => 'forgetful' ] => 'huh?';

  remember anything_else => 'blah';

=head1 DESCRIPTION

Sometimes (or frequently, in my case) you really need easy access to different kinds of storage in one brain. This is what the hybrid brain does. You can basically specify that any key and all subkeys are handled by a specific brain. 

Arguments to the hybrid brain are basically an alternating set of ques and brain configurations. You must always at least specify the special que "[]", which refers to the root brain.

=head1 METHODS

=head2 new TABLE

The TABLE argument is required. It contains a list of brains to configure with the hybrid brain. The table alternates between ques and brain configurations. The special que "[]" must be given to specify which brain configuration will be used when no other key set matches (the root brain).

Each pair is setup so that any que specified for C<remember>, C<forget>, or C<recall> will be evaluated against the list of ques in the mount table. The longest que in the mount table matching a prefix of the que specified will be picked. If no que prefix matches, then the fallback "[]" will be used.

The ques may be given in any way that L<Data::Remember> would accept them.

The configurations are given wrapped in "[]", but should be exactly the same otherwise.

=head2 register_brain QUE CONFIG

This allows you to add additional sub-brains to the hybrid brain after it has been initialized. If you reuse a que that has already been registered using this method or during initialization, that brain will be completely replaced.

If you want to remove a brain you will want to see L</unregister_brain>.

=head2 unregister_brain QUE

Removes a brain configuration from the given QUE. This method returns true if a configuration was actually unregistered or false otherwise.

=head2 brain_for QUE

Returns a sub-brain that would serve the given C<QUE>.

=head2 remember QUE, FACT

Stores the given FACT in the appropriate brain according to QUE.

=head2 recall QUE

Recalls the fact stored at QUE in one of the hybrid's brains.

=head2 forget QUE

Forgets the fact stored at QUE in one of the hybrid's brains.

=head1 SEE ALSO

L<Data::Remember>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
