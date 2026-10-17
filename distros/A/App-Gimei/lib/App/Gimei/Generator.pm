use v5.42;
use feature 'class';
no warnings 'experimental::class';

class App::Gimei::Generator {

    use Data::Gimei;

    #
    # instance variables
    #

    field $word_class   : param : reader;          # Name or Address
    field $word_subtype : param : reader = undef;  # 'gender', 'surname', 'forename',
                                                   # 'prefecture', 'city', 'town' or undef
    field $rendering    : param : reader =
      'kanji';    # 'kanji', 'hiragana', 'katakana' or 'romaji'
    field $gender : param : reader = undef;    # 'name', 'male', 'female' or undef

    #
    # instance methods
    #

    # Returns generated string if cache missed
    method execute ($cache) {
        my ($word);

        # Fetch from cache
        my $key = $word_class . ( $gender // '' );    # cache key
        $word = $cache->{$key};

        # Generate if chache missed
        if ( !defined $word ) {
            $word = $word_class->new( gender => $gender );
            $cache->{$key} = $word;                                   # cache it
        }

        # Extract subtype
        if ($word_subtype) {
            if ( $word_subtype eq 'gender' ) {
                return $word->gender;
            }
            my $call = $word->can($word_subtype);
            $word = $word->$call();
        }

        # Apply rendering
        my $call = $word->can($rendering);
        $word = $word->$call();

        return $word;
    }
}

1;
