package Data::Localize::Trait::WithStorage;
use Moo::Role;
use Data::Localize;

BEGIN {
    if (Data::Localize::DEBUG) {
        require Data::Localize::Log;
        Data::Localize::Log->import;
    }
}

has storage_class => (
    is => 'ro',
    default => sub {
        return '+Data::Localize::Storage::Hash';
    }
);

has storage_args => (
    is => 'ro',
    default => sub { +{} }
);

has 'load_from_storage' => (
    is      => 'ro',
    default => sub { [] },
);

has lexicon_map => (
    is => 'ro',
    default => sub { +{} },
);

after BUILD => sub {
    my $self = shift;

    my $langs = $self->load_from_storage;
    if (! $langs || ! @$langs) {
        if (Data::Localize::DEBUG) {
            debugf("No languages to load");
        }
        return;
    }
    my $storage_class = $self->_canonicalize_storage_class;
    my $storage_args  = $self->storage_args;
    if (Data::Localize::DEBUG) {
        debugf("Building lexicon map (%s)", $storage_class);
    }

    Module::Load::load( $storage_class );

    unless ( $storage_class->is_volatile ) {
        foreach my $lang ( @$langs ) {
            if (Data::Localize::DEBUG) {
                debugf("Loading storage for lang '%s'", $lang);
            }
            $storage_args->{lang} = $lang;

            $self->set_lexicon_map(
                $lang,
                $storage_class->new( $storage_args )
            );
        }
    }
};

sub get_lexicon_map {
    my ($self, $key) = @_;
    return $self->lexicon_map->{ $key };
}

sub set_lexicon_map {
    my ($self, $key, $value) = @_;
    return $self->lexicon_map->{ $key } = $value;
}

sub get_lexicon {
    my ($self, $lang, $id) = @_;
    my $lexicon = $self->get_lexicon_map($lang);
    return () unless $lexicon;
    $lexicon->get($id);
}

sub set_lexicon {
    my ($self, $lang, $id, $value) = @_;
    my $lexicon = $self->get_lexicon_map($lang);
    if (! $lexicon) {
        $lexicon = $self->_build_storage($lang);
        $self->set_lexicon_map($lang, $lexicon);
    }
    $lexicon->set($id, $value);
}

sub merge_lexicon {
    my ($self, $lang, $new_lexicon) = @_;

    if (Data::Localize::DEBUG) {
        debugf("Merging lexicon for lang '%s'", $lang);
    }
    my $lexicon = $self->get_lexicon_map($lang);
    if (! $lexicon) {
        $lexicon = $self->_build_storage($lang);
        $self->set_lexicon_map($lang, $lexicon);
    }
    while (my ($key, $value) = each %$new_lexicon) {
        if (Data::Localize::DEBUG) {
            debugf("Setting lexicon '%s' on '%s'", $key, Scalar::Util::blessed $lexicon);
        }
        $lexicon->set($key, $value);
    }
}

sub _build_storage {
    my ($self, $lang) = @_;

    my $class = $self->_canonicalize_storage_class;
    my $args  = $self->storage_args;

    Module::Load::load($class);

    $args->{lang} = $lang;

    if (Data::Localize::DEBUG) {
        debugf("Creating storage '%s'", $class);
    }
    return $class->new( $args );
}

sub _canonicalize_storage_class {
    my $self  = shift;
    my $class = $self->storage_class;
    if ($class !~ s/^\+//) {
        $class = "Data::Localize::Storage::$class";
    }
    $class;
}

no Moo::Role;

1;

__END__

=head1 NAME

Data::Localize::Trait::WithStorage - Localizer With Configurable Storage

=head1 METHODS

=head2 get_lexicon($lang, $id)

Gets the specified lexicon

=head2 set_lexicon($lang, $id, $value)

Sets the specified lexicon

=head2 merge_lexicon

Merges lexicon (may change...)

=head2 get_lexicon_map($lang)

Get the lexicon map for language $lang

=head2 set_lexicon_map($lang, \%lexicons)

Set the lexicon map for language $lang

=cut
