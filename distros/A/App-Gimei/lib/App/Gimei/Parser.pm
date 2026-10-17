use v5.42;
use feature 'class';
no warnings 'experimental::class';

class App::Gimei::Parser {

    use App::Gimei::Generator;
    use App::Gimei::Generators;

    #
    # private instance methods
    #

    my method _subtype_name ($tokens_ref) {
        my $word_subtype;

        my %map = (
            'family' => 'surname',
            'last'   => 'surname',
            'given'  => 'forename',
            'first'  => 'forename',
            'gender' => 'gender',
            'sex'    => 'gender',
        );

        my $token = @$tokens_ref[0] // '';
        if ( $word_subtype = $map{$token} ) {
            shift @$tokens_ref;
        }

        return $word_subtype;
    }

    my method _subtype_address ($tokens_ref) {
        my ($word_subtype);

        my $token = @$tokens_ref[0] // '';
        if ( $token eq 'prefecture' || $token eq 'city' || $token eq 'town' ) {
            shift @$tokens_ref;
            $word_subtype = $token;
        }

        return $word_subtype;
    }

    my method _rendering ($tokens_ref) {
        my $rendering = 'kanji';

        my $token = @$tokens_ref[0] // '';
        if (   $token eq 'kanji'
            || $token eq 'hiragana'
            || $token eq 'katakana'
            || $token eq 'romaji' )
        {
            shift @$tokens_ref;
            $rendering = $token;
        }

        return $rendering;
    }

    # BNF-like notation
    #
    # ARG:             [WORD_TYPE]   [':' RENDERING]
    # WORD_TYPE:        TYPE_NAME    [':' SUBTYPE_NAME]
    #                 | TYPE_ADDRESS [':' SUBTYPE_ADDRESS]
    # TYPE_NAME:       'name'       | 'male'     | 'female'
    # SUBTYPE_NAME:    'family'     | 'given'
    # TYPE_ADDRESS:    'address'
    # SUBTYPE_ADDRESS: 'prefecture' | 'city'     | 'town'
    # RENDERING:       'kanji'      | 'hiragana' | 'katakana' | 'romaji'
    # (DO NOT support romaji rendering for type address)
    my method _parse_arg ($arg) {
        my ( $gen, @tokens, %params );

        @tokens = split( /[-:]/, $arg );

        my $token = shift @tokens;
        if ( $token eq 'name' || $token eq 'male' || $token eq 'female' ) {    # TYPE_NAME
            $params{word_class} = "Data::Gimei::Name";
            if ( $token ne 'name' ) {
                $params{gender} = $token;
            }
            $params{word_subtype} = $self->&_subtype_name( \@tokens );
        } elsif ( $token eq 'address' ) {    # TYPE_ADDRESS
            $params{word_class}   = "Data::Gimei::Address";
            $params{word_subtype} = $self->&_subtype_address( \@tokens );
        } else {
            die "Error: unknown word_type: $token\n";
        }

        $params{rendering} = $self->&_rendering( \@tokens );

        if (@tokens) {
            if ( defined $params{word_subtype} ) {
                die "Error: unknown rendering: $tokens[0]\n";
            } else {
                die "Error: unknown subtype or rendering: $tokens[0]\n";
            }
        }

        return App::Gimei::Generator->new(%params);
    }

    #
    # public class methods
    #

    sub parse ($aref) {
        my $p = App::Gimei::Parser->new();

        my $generators = App::Gimei::Generators->new();
        foreach my $arg ( @{$aref} ) {
            $generators->add_generator( $p->&_parse_arg($arg) );
        }

        return $generators;
    }
}

1;
