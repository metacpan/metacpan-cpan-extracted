use v5.40;

package App::Gimei::Generators;

use Data::Gimei;

use Class::Tiny qw(
  body
);

sub BUILDARGS ($self) {
    return { body => [] };
}

sub push ( $self, $generator ) {
    CORE::push @{ $self->body }, $generator;
}

sub execute ($self) {
    my ( @words, %cache );
    foreach my $g ( @{ $self->body } ) {
        CORE::push( @words, $g->execute( \%cache ) );
    }
    return @words;
}

sub to_list ($self) {
    return @{ $self->body };
}
