package App::Gimei::Runner;

use warnings;
use v5.22;
binmode STDOUT, ":utf8";

use Getopt::Long;
use Pod::Usage;
use Pod::Find qw( pod_where );

use App::Gimei;
use Data::Gimei;

use Class::Tiny;

#
# global vars
#

my %conf = ( POD_FILE => pod_where( { -inc => 1 }, 'App::Gimei' ) );

#
# methods
#

sub parse_option {
    my ( $self, $args_ref, $opts_ref ) = @_;

    $opts_ref->{n}   = 1;
    $opts_ref->{sep} = ', ';

    my $p = Getopt::Long::Parser->new( config => ["no_ignore_case"], );

    local $SIG{__WARN__} = sub { die "Error: $_[0]" };
    my $ok = $p->getoptionsfromarray( $args_ref, $opts_ref, "help|h", "version|v", "n=i",
        "sep=s", );

    if ( $opts_ref->{n} < 1 ) {
        die
          "Error: value $opts_ref->{n} invalid for option n (must be positive number)\n";
    }
}

sub execute {
    my ( $self, @args ) = @_;

    my %opts;
    $self->parse_option( \@args, \%opts );

    if ( $opts{version} ) {
        say "$App::Gimei::VERSION";
        return 0;
    }

    if ( $opts{help} ) {
        pod2usage( -input => $conf{POD_FILE}, -exitval => 'noexit' );
        return 0;
    }

    if ( !@args ) {
        push @args, 'name:kanji';
    }

    foreach ( 1 .. $opts{n} ) {
        my %words = (
            name    => Data::Gimei::Name->new(),
            male    => Data::Gimei::Name->new( gender => 'male' ),
            female  => Data::Gimei::Name->new( gender => 'female' ),
            address => Data::Gimei::Address->new()
        );

        my @results;
        foreach my $arg (@args) {
            my @tokens = split( /[-:]/, $arg );
            push @results, execute_tokens( \@tokens, \%words );
        }

        say join $opts{sep}, @results;
    }

    return 0;
}

#
# functions ...
#

# ARG:                   [WORD_TYPE] [':' WORD_SUB_TYPE] [':' RENDERING]
# WORD_TYPE:             'name'       | 'address'
# WORD_SUBTYPE(name):    'family'     | 'given'
# WORD_SUBTYPE(address): 'prefecture' | 'city'     | 'town'
# RENDERING:             'kanji'      | 'hiragana' | 'katakana' | 'romaji'
sub execute_tokens {
    my ( $tokens_ref, $words_ref ) = @_;
    my ( $word_type, $word, $token );

    $token = shift @$tokens_ref;
    if ( $token eq 'name' || $token eq 'male' || $token eq 'female' ) {
        ( $word, $word_type ) = subtype_name( $tokens_ref, $words_ref->{$token} );
    } elsif ( $token eq 'address' ) {
        ( $word, $word_type ) = subtype_address( $tokens_ref, $words_ref->{$token} );
    } else {
        die "Error: unknown word_type: $token\n";
    }

    return render( $tokens_ref, $word_type, $word );
}

sub subtype_name {
    my ( $tokens_ref, $word ) = @_;
    my ( $token, $subtype, $call, $word_type );

    my %map = (
        'family' => [ 'surname',  'name'   ],
        'last'   => [ 'surname',  'name'   ],
        'given'  => [ 'forename', 'name'   ],
        'first'  => [ 'forename', 'name'   ],
        'gender' => [ 'gender',   'gender' ],
        'sex'    => [ 'gender',   'gender' ],
    );

    $word_type = 'name';
    $token     = @$tokens_ref[0] // '';
    if ( my $m = $map{$token} ) {
        shift @$tokens_ref;
        $call      = $word->can( $m->[0] ) or die "system err";
        $word      = $word->$call();
        $word_type = $m->[1];
    }

    return ( $word, $word_type );
}

sub subtype_address {
    my ( $tokens_ref, $word ) = @_;

    my $token = @$tokens_ref[0] // '';
    if ( $token eq 'prefecture' || $token eq 'city' || $token eq 'town' ) {
        shift @$tokens_ref;
        my $call = $word->can($token);
        die "system error" if ( !$call );
        $word = $word->$call();
    }

    return ( $word, 'address' );
}

# romaji not supported in WORD_TYPE = 'address'
sub render {
    my ( $tokens_ref, $word_type, $word ) = @_;

    my $token = @$tokens_ref[0];
    if ( !$token || $token eq 'name' ) {
        $token = "kanji";
    }

    if ( $word_type eq 'address' && $token eq 'romaji' ) {
        die "Error: unknown subtype or rendering: $token\n";
    }

    if ( $word_type eq 'gender' ) {
        return $word;
    }

    my $call = $word->can($token);
    die "Error: unknown subtype or rendering: $token\n" if ( !$call );

    return $word->$call();
}

1;
