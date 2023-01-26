package Apache::Session::Store::NoSQL;

use strict;
use vars qw(@ISA $VERSION);

$VERSION = '0.2';

sub new {
    my ( $class, $session ) = @_;
    my $self;

    if ( $session->{args}->{Driver} ) {
      my $module = 'Apache::Session::Store::NoSQL::'
        . $session->{args}->{Driver};
      eval "require $module";
      if ($@) {
          die 'Unable to load ' . $module;
      }
      unless ( $self->{cache} = new $module ( $session ) ) {
          die 'Unable to instanciate ' . $module;
      }
    }
    else {
      die 'No driver specified.';
    }

    bless $self,$class;
}

sub insert {
    my ( $self, $session ) = @_;
    $self->{cache}->insert( $session );
}

sub update {
    my ( $self, $session ) = @_;
    $self->{cache}->update( $session );
}

sub materialize {
    my ( $self, $session ) = @_;
    $session->{serialized} = $self->{cache}->materialize( $session );
}

sub remove {
    my ( $self, $session ) = @_;
    $self->{cache}->remove( $session );
}

1;

__END__

=head1 NAME

Apache::Session::Store::NoSQL

Note: this module is deprecated, Prefer L<Apache::Session::Browseable>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Thomas Chemineau

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
