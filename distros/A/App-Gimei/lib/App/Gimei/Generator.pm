use v5.40;

package App::Gimei::Generator;

use Data::Gimei;

use Class::Tiny qw(
  word_class
  gender
  word_subtype
  rendering
);

sub BUILDARGS ( $class, %args ) {
    for my $arg (qw/word_class/) {
        die "$arg arg required" unless exists $args{$arg};
    }

    $args{rendering} //= 'kanji';

    return \%args;
}

sub execute ( $self, $cache ) {
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

    my $call = $word->can( $self->rendering );
    $word = $word->$call();

    return $word;
}
