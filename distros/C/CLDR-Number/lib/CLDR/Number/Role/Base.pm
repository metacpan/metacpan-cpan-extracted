package CLDR::Number::Role::Base;

use v5.8.1;
use utf8;
use Carp;
use Scalar::Util qw( looks_like_number );
use CLDR::Number::Data::Base;
use CLDR::Number::Data::System;

use Moo::Role;

# This role does not have a publicly supported interface and may change in
# backward incompatible ways in the future. Please use one of the documented
# classes instead.

our $VERSION = '0.19';

requires qw( BUILD );

has version => (
    is      => 'ro',
    default => $VERSION,
);

has cldr_version => (
    is      => 'ro',
    default => $CLDR::Number::Data::Base::CLDR_VERSION,
);

has locale => (
    is      => 'rw',
    trigger => 1,
);

has default_locale => (
    is     => 'ro',
    coerce => sub {
        my ($locale) = @_;

        if (!defined $locale) {
            carp 'default_locale is not defined';
        }
        elsif (!exists $CLDR::Number::Data::Base::DATA->{$locale}) {
            carp "default_locale '$locale' is unknown";
        }
        else {
            return $locale;
        }

        return;
    },
);

has numbering_system => (
    is  => 'rw',
    isa => sub {
        carp 'numbering_system is not defined'
            unless defined $_[0];
        carp "numbering_system '$_[0]' is unknown"
            unless exists $CLDR::Number::Data::System::DATA->{$_[0]};
    },
    coerce  => sub { defined $_[0] ? lc $_[0] : $_[0] },
    trigger => 1,
);

has minimum_grouping_digits => (
    is => 'rw',
    isa => sub {
        croak "minimum_grouping_digits '$_[0]' is invalid"
            if defined $_[0] && !looks_like_number $_[0];
    },
);

# TODO: length NYI
has length => (
    is => 'rw',
);

has decimal_sign => (
    is => 'rw',
);

has group_sign => (
    is => 'rw',
);

has plus_sign => (
    is => 'rw',
);

has minus_sign => (
    is => 'rw',
);

has infinity => (
    is => 'rw',
);

has nan => (
    is => 'rw',
);

has _locale_inheritance => (
    is      => 'rw',
    default => sub { [] },
);

has _init_args => (
    is => 'rw',
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;

    return $class->$orig(@args) if @args % 2;
    return $class->$orig(@args, _init_args => {@args});
};

before BUILD => sub {
    my ($self) = @_;

    return if $self->_has_init_arg('locale');

    $self->_trigger_locale;
};

after BUILD => sub {
    my ($self) = @_;

    $self->_init_args({});
};

sub _has_init_arg {
    my ($self, $arg) = @_;

    return unless $self->_init_args;
    return exists $self->_init_args->{$arg};
}

sub _set_unless_init_arg {
    my ($self, $attribute, $value) = @_;

    return if $self->_has_init_arg($attribute);

    $self->$attribute($value);
}

sub _build_signs {
    my ($self, @signs) = @_;

    for my $sign (@signs) {
        my $attribute = $sign;

        next if $self->_has_init_arg($attribute);

        $sign =~ s{ _sign $ }{}x;

        $self->$attribute($self->_get_data(symbol => $sign));
    }
}

sub _trigger_locale {
    my ($self, $locale) = @_;
    my ($lang, $script, $region, $ext) = _split_locale($locale);

    if ($lang && exists $CLDR::Number::Data::Base::DATA->{$lang}) {
        $self->_locale_inheritance(
            _build_inheritance($lang, $script, $region, $ext)
        );
        $locale = $self->_locale_inheritance->[0];
    }
    elsif ($self->default_locale) {
        $locale = $self->default_locale;
        ($lang, $script, $region, $ext) = _split_locale($locale);
        $self->_locale_inheritance(
            _build_inheritance($lang, $script, $region, $ext)
        );
    }
    else {
        $locale = 'root';
        $self->_locale_inheritance( [$locale] );
    }

    if ($ext && $ext =~ m{ -nu- ( [^-]+ ) }x) {
        $self->numbering_system($1);
    }
    else {
        $self->_trigger_numbering_system;
    }

    $self->{locale} = $locale;

    $self->_build_signs(qw{
        decimal_sign group_sign plus_sign minus_sign infinity nan
    });

    $self->_set_unless_init_arg(
        minimum_grouping_digits => $self->_get_data(attr => 'min_group')
    );
}

sub _trigger_numbering_system {
    my ($self, $system) = @_;

    return if defined $system
           && exists $CLDR::Number::Data::System::DATA->{$system};

    $self->{numbering_system} = $self->_get_data(attr => 'system');
}

sub _split_locale {
    my ($locale) = @_;

    return unless defined $locale;

    $locale = lc $locale;
    $locale =~ tr{_}{-};

    my ($lang, $script, $region, $ext) = $locale =~ m{ ^
              ( [a-z]{2,3}          )     # language
        (?: - ( [a-z]{4}            ) )?  # script
        (?: - ( [a-z]{2} | [0-9]{3} ) )?  # country or region
        (?: - ( u- .+               ) )?  # extension
            -?                            # trailing separator
    $ }xi;

    $script = ucfirst $script if $script;
    $region = uc      $region if $region;

    return $lang, $script, $region, $ext;
}

sub _build_inheritance {
    my ($lang, $script, $region, $ext) = @_;
    my @tree;

    for my $subtags (
        [$lang, $region, $ext],
        [$lang, $script, $region],
        [$lang, $script],
        [$lang, $region],
        [$lang],
    ) {
        next if grep { !$_ } @$subtags;
        my $locale = join '-', @$subtags;
        next if !exists $CLDR::Number::Data::Base::DATA->{$locale};
        push @tree, $locale;

        if (my $parent = $CLDR::Number::Data::Base::PARENT->{$locale}) {
            push @tree, @{_build_inheritance(_split_locale($parent))};
            last;
        }
    }

    if (!@tree || $tree[-1] ne 'root') {
        push @tree, 'root';
    }

    return \@tree;
}

sub _get_data {
    my ($self, $type, $key) = @_;
    my $data = $CLDR::Number::Data::Base::DATA;

    for my $locale (@{$self->_locale_inheritance}) {
        return $data->{$locale}{$type}{$key}
            if exists $data->{$locale}
            && exists $data->{$locale}{$type}
            && exists $data->{$locale}{$type}{$key};
    }

    return undef;
}

1;
