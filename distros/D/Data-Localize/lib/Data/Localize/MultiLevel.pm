package Data::Localize::MultiLevel;
use Moo;
use Config::Any;
use Data::Localize;
use MooX::Types::MooseLike::Base qw(ArrayRef);
BEGIN {
    if (Data::Localize::DEBUG) {
        require Data::Localize::Log;
        Data::Localize::Log->import;
    }
}

extends 'Data::Localize::Localizer';
with 'Data::Localize::Trait::WithStorage';

has paths => (
    is => 'ro',
    isa => ArrayRef,
    trigger => sub {
        my $self = shift;
        if ($self->initialized) {
            $self->load_from_path($_) for @{$_[0]};
        }
    },
);

after BUILD => sub {
    my $self = shift;
    my $paths = $self->paths;
    foreach my $path (@$paths) {
        $self->load_from_path($path);
    }
};

after register => sub {
    my ($self, $loc) = @_;
    $loc->add_localizer_map('*', $self);
    $loc->add_localizer_map( $_, $self )
        for keys %{ $self->lexicon_map }
};

around get_lexicon => sub{
    my ($next, $self, $lang, $key) = @_;

    my ($storage_key, @key_path) = split /\./, $key;
    my $lexicon = $self->$next($lang, $storage_key);

    return _rfetch( $lexicon, 0, \@key_path )
        if @key_path;

    return $lexicon;
};

around set_lexicon => sub {
    my ($next, $self, $lang, $key, $value) = @_;

    my ($storage_key, @key_path) = split /\./, $key;

    if ( @key_path ) {
        my $lexicon = $self->get_lexicon($lang, $storage_key);
        _rstore( $lexicon, 0, \@key_path, $value );
        $self->$next( $storage_key, $lexicon );
    }
    else {
        $self->$next( $storage_key, $value );
    }

    return;
};

sub _build_formatter {
    Module::Load::load('Data::Localize::Format::NamedArgs');
    return Data::Localize::Format::NamedArgs->new();
}

sub load_from_path {
    my ($self, $path) = @_;

    my @files = glob( $path );
    my $cfg = Config::Any->load_files({ files => \@files, use_ext => 1 });

    foreach my $x (@$cfg) {
        my ($filename, $lexicons) = %$x;
        # should have one root item
        my ($lang) = keys %$lexicons;

        if (Data::Localize::DEBUG) {
            debugf("load_from_path - Loaded %s for languages %s",
                Scalar::Util::blessed($self),
                $filename,
                $lang,
            );
        }

        $self->merge_lexicon($lang, $lexicons->{$lang});
        $self->_localizer->add_localizer_map($lang, $self) if $self->_localizer;
    }
}

sub _rfetch {
    my ($lexicon, $i, $keys) = @_;

    return unless $lexicon;

    my $thing = $lexicon->{$keys->[$i]};
    return unless defined $thing;

    my $ref   = ref $thing;
    return unless $ref || length $thing;

    if (@$keys <= $i + 1) {
        return $thing;
    }

    if ($ref ne 'HASH') {
        if (Data::Localize::DEBUG) {
            debugf("%s does not point to a hash",
                join('.', map { $keys->[$_] } 0..$i)
            );
        }
        return ();
    }

    return _rfetch( $thing, $i + 1, $keys )
}

sub _rstore {
    my ($lexicon, $i, $keys, $value) = @_;

    return unless $lexicon;

    if (@$keys <= $i + 1) {
        $lexicon->{ $keys->[$i] } = $value;
        return;
    }

    my $thing = $lexicon->{$keys->[$i]};

    if (ref $thing ne 'HASH') {
        if (Data::Localize::DEBUG) {
            debugf("%s does not point to a hash",
                join('.', map { $keys->[$_] } 0..$i)
            );
        }
        return ();
    }

    return _rstore( $thing, $i + 1, $keys, $value );
}

1;

__END__

=head1 NAME

Data::Localize::MultiLevel - Fetch Data From Multi-Level Data Structures

=head1 SYNOPSIS

    use Data::Localize;

    my $loc = Data::Localize->new();

    $loc->add_localizer(
        Data::Localize::MultiLevel->new(
            paths => [ '/path/to/lexicons/*.yml' ]
        )
    );

    $loc->localize( 'foo.key', { arg => $value, ... } );

    # above is internally...
    $loc->localize_for(
        lang => 'en',
        id => 'foo.key',
        args => [ { arg => $value } ]
    );
    # which in turn looks up...
    # $lexicons->{foo}->{key};

=head1 DESCRIPTION

Data::Localize::MultiLevel implements a "Rails"-ish I18N facility. Namely
it uses a multi-level key to lookup data from a hash, and uses the NamedArgs
formatter.

=head1 METHODS

=head2 get_lexicon

=head2 set_lexicon

=head2 load_from_path

=head2 register

=cut
