package Blosxom::Component;
use strict;
use warnings;
use Carp qw/croak/;

my ( %attribute_of, %requires, %component_of );

sub load_components {
    my ( $class, @components ) = @_;
    push @{ $component_of{$class} ||= [] }, @_;
}

sub requires {
    my ( $class, @methods ) = @_;
    push @{ $requires{$class} ||= [] }, @methods;
}

sub mk_accessors {
    my $class = shift;
    while ( @_ ) {
        my $field = shift;
        my $default = ref $_[0] eq 'CODE' ? shift : undef;
        $attribute_of{ $class }{ $field } = $default;
    }
}

sub init {
    my $class  = shift;
    my $caller = shift;
    my $stash  = do { no strict 'refs'; \%{"$class\::"} };

    if ( my $components = $component_of{$class} ) {
        my @args = @{ $components };
        while ( @args ) {
            my $component = shift;
            my $config = ref $args[0] eq 'HASH' ? shift @args : undef;
            $caller->add_component( $component => $config );
        }
    }

    if ( my $requires = $requires{$class} ) {
        if ( my @methods = grep { !$caller->can($_) } @{$requires} ) {
            my $methods = join ', ', @methods;
            croak "Can't apply '$class' to '$caller' - missing $methods";
        }
    }

    if ( my $attribute = $attribute_of{$class} ) {
        while ( my ($field, $default) = each %{$attribute} ) {
            $caller->add_attribute( $field, $default );
        }
    }

    # NOTE: use keys() instead
    while ( my ($name, $glob) = each %{$stash} ) {
        if ( defined *{$glob}{CODE} and $name ne 'init' ) {
            $caller->add_method( $name => *{$glob}{CODE} );
        }
    }

    return;
}

1;

__END__

=head1 NAME

Blosxom::Component - Base class for Blosxom components

=head1 SYNOPSIS

  package MyComponent;
  use parent 'Blosxom::Component';

=head1 DESCRIPTION

Base class for Blosxom components.

=head2 METHODS

=over 4

=item $class->requires

Declares a list of methods that must be defined to load this component.

  __PACKAGE__->requires(qw/req1 req2/);

=item $class->mk_accessors

  __PACKAGE__->mk_accessors(qw/foo bar baz/);

=item $class->init

  sub init {
      my ( $class, $caller, $config ) = @_;
      # do something
      $class->SUPER::init( $caller );
  }

=back

=head1 SEE ALSO

L<Blosxom::Plugin>, L<Role::Tiny>

=head1 AUTHOR

Ryo Anazawa

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

