use strict;
use warnings;

package Data::Remember::Memory;
{
  $Data::Remember::Memory::VERSION = '0.140490';
}
# ABSTRACT: a short-term memory brain plugin for Data::Remember

use Scalar::Util qw/ reftype /;


sub new {
    my $class = shift;
    bless { brain => {} }, $class;
}


sub remember {
    my $self = shift;
    my $que  = shift;
    my $fact = shift;

    my $last_que = pop @$que;
    my $que_remaining = scalar @$que;

    my $object = $self->{brain};
    for my $que_entry (@$que) {
        if (defined $object->{$que_entry}) {

            if ($que_remaining == 0 
                    or (ref $object->{$que_entry} 
                        and reftype $object->{$que_entry} eq 'HASH')) {
                $object = $object->{$que_entry};
            }
            
            # overwrite previous non-hash fact with something more agreeable
            else {
                $object = $object->{$que_entry} = {}
            }
        }

        else {
            $object = $object->{$que_entry} = {};
        }

        $que_remaining--;
    }

    $object->{$last_que} = $fact;
}


sub recall {
    my $self = shift;
    my $que  = shift;

    my $object = $self->{brain};
    for my $que_entry (@$que) {
        return unless ref $object and reftype $object eq 'HASH';

        if (defined $object->{$que_entry}) {
            $object = $object->{$que_entry};
        }

        else {
            return;
        }
    }

    return scalar $object;
}


sub forget {
    my $self = shift;
    my $que  = shift;

    my $last_que = pop @$que;

    my $object = $self->{brain};
    for my $que_entry (@$que) {
        if (defined $object->{$que_entry}) {
            $object = $object->{$que_entry};
        }
        else {
            return;
        }
    }

    delete $object->{$last_que};
}


1;

__END__

=pod

=head1 NAME

Data::Remember::Memory - a short-term memory brain plugin for Data::Remember

=head1 VERSION

version 0.140490

=head1 SYNOPSIS

  use Data::Remember 'Memory';

  remember something => 'what?';

=head1 DESCRIPTION

This is a very simple brain for L<Data::Remember> that just stores everything in Perl data structures in memory.

=head1 METHODS

=head2 new

Takes no arguments or special parameters. Any parameters will be ignored.

=head2 remember QUE, FACT

Stores the given FACT in a Perl data structure under QUE.

=head2 recall QUE

Recalls the fact stored at QUE.

=head2 forget QUE

Forgets the fact stored at QUE.

=head1 SEE ALSO

L<Data::Remember>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
