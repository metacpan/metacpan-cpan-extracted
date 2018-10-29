package Locale::Maketext::Lexicon::CatmanduConfig;
use Catmandu::Sane;
use Catmandu;
use Catmandu::Util qw(data_at :is);
use Catmandu::Expander;

sub parse {
    my ($self, $key) = @_;
    my $hash = Catmandu::Util::data_at( $key, Catmandu->config() );
    Catmandu::Expander->collapse_hash(
        is_hash_ref($hash) ? $hash : +{}
    );
}

1;

=head1 NAME

Locale::Maketext::Lexicon::CatmanduConfig - Use Catmandu config files as a Maketext lexicon

=head1 SYNOPSIS

    Catmandu->{config}->{locale} = {
        en => {
            hello => "Hello"
        },
        _style => "gettext"
    };

    package MyI18N;
    use parent 'Locale::Maketext';
    use Locale::Maketext::Lexicon {
        en => [ CatmanduConfig => ["locale.en"] ],
        _style => "gettext"
    };

=head1 NOTES

* the value for CatmanduConfig is an array because L<Locale::Maketext::Lexicon> interprets regular strings as files (to be ignored)

* config parameter "_style" can be set to "gettext" to make use of placeholders like in L<Locale::Maketext::Lexicon::Gettext>

=cut
