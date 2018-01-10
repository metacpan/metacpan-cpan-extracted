package BioX::Workflow::Command::run::Rules::Directives::Walk;

use Moose::Role;
use namespace::autoclean;

use Data::Walk 2.01;
use Path::Tiny;

has 'errors' => (
   is => 'rw',
   isa => 'HashRef',
   default => sub {return {}},
);

sub walk_process_data {
    my $self = shift;
    my $keys = shift;

    foreach my $k ( @{$keys} ) {
        $DB::single = 2;
        next if ref($k);
        my $v = $self->$k;
        ##Leftover of backwards compatibility
        if ( $k eq 'find_by_dir' ) {
            $self->process_directive( $k, $v );
        }
        ##If its a type search for the type
        elsif ( $self->search_registered_process_directives( $k, $v ) ) {
            next;
        }
        else {
            $self->process_directive( $k, $v );
        }
    }
}

##TODO Combine this with search_registered_types
sub search_registered_process_directives {
    my $self = shift;
    my $k    = shift;
    my $v    = shift;

    foreach my $key ( keys %{ $self->register_process_directives } ) {
        $DB::single = 2;
        next unless exists $self->register_process_directives->{$key}->{lookup};
        next
          unless exists $self->register_process_directives->{$key}->{builder};
        my $lookup_ref = $self->register_process_directives->{$key}->{lookup};
        my $builder    = $self->register_process_directives->{$key}->{builder};

        foreach my $lookup ( @{$lookup_ref} ) {
            if ( $k =~ m/$lookup/ ) {
                $self->$builder( $k, $v );
                return 1;
            }
        }
    }

    return 0;
}

=head3 process_directive

=cut

sub process_directive {
    my $self = shift;
    my $k    = shift;
    my $v    = shift;
    my $path = shift;

    #TODO Need to keep track of errors here
    if ( ref($v) ) {
        walk {
            wanted => sub { $self->walk_directives(@_) }
          },
          $self->$k;
    }
    else {
        my $text = '';
        $text = $self->interpol_directive($v) if $v;
        $self->$k($text);
    }

}

=head3 walk_directives

Invoke with
  walk { wanted => sub { $self->directives(@_) } }, $self->other_thing;

Acts funny with $self->some_other_thing is not a reference

=cut

sub walk_directives {
    my $self = shift;
    my $ref  = shift;

    return if ref($ref);
    return unless $ref;

    my $text = '';
    $text = $self->interpol_directive($ref) if $ref;
    $self->update_directive($text);
}

=head3 update_directive

Take the values from walk_directive and update the directive

=cut

sub update_directive {
    my $self = shift;
    my $text = shift;

    my ( $key, $container, $index );

    $container = $Data::Walk::container;
    $key       = $Data::Walk::key;
    $index     = $Data::Walk::index;

    if ( $Data::Walk::type eq 'HASH' && $key ) {
        $container->{$key} = $text;
    }
    elsif ( $Data::Walk::type eq 'ARRAY' ) {
        $container->[$index] = $text;
    }
    else {
        #We are getting the whole hash, just return
        return;
    }
}

1;
