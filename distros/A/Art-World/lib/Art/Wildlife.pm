package Art::Wildlife {

    use Zydeco;

    include Buyer;

    class Agent {
        has id!         ( type => Int );
        has name!       ( type => Str, required => 1 );
        has reputation ( type => Int );

        class Artist {

            has artworks   ( type => ArrayRef );
            has collectors ( type => ArrayRef );
            has collected  ( type => Bool, default => false );

            method create {
                say $self->name . " create !";
            }

            method have_idea {
                say $self->name . ' have shitty idea' if true;
            }

            method has_collectors {
                # if self.collectors.elems > 0 {
                # $!collected = True;
                # } else {
                # $!collected = False;
                # }
            }

            # method new ($id, $name, @artworks, @collectors) {
            #     self.bless(:$id, :$name, :@artworks, :@collectors);
            # }
        }

        include Collector;



    }
}

1;

#use Art::Behavior::Crudable;
# does Art::Behavior::Crudable;
# has relations


=begin pod

=head1 NAME

Agent - Activist of the Art World

=head1 SYNOPSIS

use Agent;

=head1 DESCRIPTION

Agent a generic entity that can be any activist of Art World

=head1 AUTHOR

Seb. Hu-Rillettes <shr@balik.network>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Seb. Hu-Rillettes

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
