package TestCandy::Schema::Candy;

use base 'DBIx::Class::Candy';

sub base { $_[1] || 'DBIx::Class::Core' }

sub autotable { 1 }

sub parse_arguments {
    my $self = shift;
    my $args = $self->next::method(@_);
    push @{$args->{components}}, 'Schema::Versioned::Inline::Candy';
    return $args;
}

1;
