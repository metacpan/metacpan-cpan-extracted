use v5.40;
use feature 'class';
no warnings 'experimental::class';

class App::Gimei::Generator {

    use Data::Gimei;

    field $word_class   : param : reader;
    field $gender       : param : reader = undef;
    field $word_subtype : param = undef;
    field $rendering    : param : reader = 'kanji';

    method execute ($cache) {
        my ($word);

        my $key = $word_class . ( $gender // '' );
        $word = $cache->{$key};
        if ( !defined $word ) {
            $word = $word_class->new( gender => $gender );
            $cache->{$key} = $word;
        }

        if ($word_subtype) {
            if ( $word_subtype eq 'gender' ) {
                return $word->gender;
            }
            my $call = $word->can($word_subtype);
            $word = $word->$call();
        }

        my $call = $word->can($rendering);
        $word = $word->$call();

        return $word;
    }
}

1;
