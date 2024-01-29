use v5.36;

package App::Gimei::Generator;

use Class::Tiny qw(
  word_class
  gender
  word_subtype
  render
  cache
);
use Data::Gimei;

sub BUILDARGS {
    my ( $class, %args ) = @_;

    for my $arg (qw/word_class/) {
        die "$arg arg required" unless exists $args{$arg};
    }

    $args{render} //= 'kanji';

    return \%args;
}

sub execute {
    my ( $self, $cache ) = @_;
    my ($word);

    my $key = $self->word_class . ( $self->gender // '' );
    $word = $cache->{$key};
    if ( !defined $word ) {
        $word = $self->word_class->new( gender => $self->gender );
        $cache->{$key} = $word;
    }

    if ( $self->word_subtype ) {
        if ( $self->word_subtype eq 'gender' ) {
            return $word->gender;
        }
        my $call = $word->can( $self->word_subtype );
        $word = $word->$call();
    }

    my $call = $word->can( $self->render );
    $word = $word->$call();

    return $word;
}

1;
