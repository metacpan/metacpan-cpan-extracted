package Data::Localize;
use Moo;
use Module::Load ();
use Scalar::Util ();
use I18N::LangTags ();
use I18N::LangTags::Detect ();
use 5.008;

our $VERSION = '0.00027';
our $AUTHORITY = 'cpan:DMAKI';

BEGIN {
    if (! defined &DEBUG) {
        require constant;
        constant->import(DEBUG => !!$ENV{DATA_LOCALIZE_DEBUG});
    }
}

BEGIN {
    if (DEBUG) {
        require Data::Localize::Log;
        Data::Localize::Log->import;
    }
}

has auto => (
    is => 'rw',
    default => sub { 1 },
);

has auto_localizer => (
    is => 'rw',
    lazy => 1,
    builder => "_build_auto_localizer",
    isa => sub { $_[0]->isa('Data::Localize::Auto') },
);

has _languages => (
    is => 'rw',
    lazy => 1,
    builder => "_build__languages",
    init_arg => 'languages',
);

has _fallback_languages => (
    is => 'rw',
    lazy => 1,
    builder => "_build__fallback_languages",
    init_arg => 'fallback_languages',
);

has _localizers => (
    is => 'rw',
    coerce => sub {
        if (ref $_[0] ne 'ARRAY') {
            Carp::croak("localizer list must be a list of Localizer objects");
        }

        # XXX Want to deprecate this auto-instantiation
        foreach my $args (@{$_[0]}) {
            if (Scalar::Util::blessed($args)) {
                next;
            }

            my $klass = delete $args->{class};
            if (! $klass) {
                Carp::croak("No class provided for localizer list");
            }
            if ($klass !~ s/^\+//) {
                $klass = "Data::Localize::$klass";
            }
            Module::Load::load($klass);
            $args = $klass->new(%$args);
        }
        $_[0];
    },
    default => sub { +[] },
    init_arg => 'localizers',
);

has localizer_map => (
    is => 'ro',
    default => sub { +{} },
);

sub BUILD {
    my $self = shift;

    if ($self->count_localizers > 0) {
        foreach my $loc (@{ $self->_localizers }) {
            $loc->register($self);
        }
    }
    return $self;
}

sub _build__fallback_languages {
    return [ 'en' ];
}

sub _build__languages {
    my $self = shift;
    $self->detect_languages();
}

sub _build_auto_localizer {
    my $self = shift;
    require Data::Localize::Auto;
    Data::Localize::Auto->new();
}

sub set_languages {
    my $self = shift;
    $self->_languages([ @_ > 0 ? @_ : $self->detect_languages ]);
};


sub add_fallback_languages {
    my $self = shift;
    push @{$self->_fallback_languages}, @_;
}

sub fallback_languages {
    my $self = shift;
    return @{$self->_fallback_languages};
}

sub languages {
    my $self = shift;
    return @{$self->_languages};
}

sub localizers {
    my $self = shift;
    return $self->_localizers;
}

sub count_localizers {
    my $self = shift;
    return scalar @{$self->_localizers};
}

sub grep_localizers {
    my ($self, $cb) = @_;
    grep { $cb->($_) } @{$self->_localizers};
}

sub get_localizer_from_lang {
    my ($self, $key) = @_;
    return $self->localizer_map->{$key};
}

sub set_localizer_map {
    my ($self, $key, $value) = @_;
    return $self->localizer_map->{$key} = $value;
}

sub detect_languages {
    my $self = shift;
    my @lang = I18N::LangTags::implicate_supers( 
        I18N::LangTags::Detect::detect() ||
        $self->fallback_languages,
    );
    if (DEBUG) {
        local $Log::Minimal::AUTODUMP = 1;
        debugf("detect_languages: auto-detected %s", \@lang);;
    }
    return wantarray ? @lang : \@lang;
}

sub detect_languages_from_header {
    my $self = shift;
    my @lang = I18N::LangTags::implicate_supers( 
        I18N::LangTags::Detect->http_accept_langs( $_[0] || $ENV{HTTP_ACCEPT_LANGUAGE}),
        $self->fallback_languages,
    );
    if (DEBUG) {
        local $Log::Minimal::AUTODUMP = 1;
        debugf("detect_languages_from_header detected %s", \@lang);
    }
    return wantarray ? @lang : \@lang;
}

sub localize {
    my ($self, $key, @args) = @_;

    if (DEBUG) {
        debugf("localize - Looking up key '%s'", $key);
    }
    my @languages = $self->languages ;
    if (DEBUG) {
        local $Log::Minimal::AUTODUMP = 1;
        debugf("localize - Loaded languages %s", \@languages);
    }
    foreach my $lang (@languages) {
        if (DEBUG) {
            debugf("localize - Attempting language '%s'", $lang);
        }
        my $localizers = $self->get_localizer_from_lang($lang) || [];
        if (DEBUG) {
            debugf("localize - Loaded %d localizers for lang %s",
                scalar @$localizers,
                $lang
            );
        }
        foreach my $localizer (@$localizers) {
            if (DEBUG) {
                local $Log::Minimal::AUTODUMP = 1;
                debugf("localize - Trying with %s", $localizer);
            }
            my $out = $localizer->localize_for(
                lang => $lang,
                id => $key,
                args => \@args
            );

            if ($out) {
                if (DEBUG) {
                    debugf("localize - Got localization: '%s'", $out);
                }
                return $out;
            }
        }
    }

    if (DEBUG) {
        debugf("localize - nothing found in registered languages");
    }

    # if we got here, we missed on all languages.
    # one last shot. try the '*' slot
    foreach my $localizer (@{$self->get_localizer_from_lang('*') || []}) {
        foreach my $lang ($self->languages) {
            if (DEBUG) {
                debugf("localize - trying %s for '*' with localizer %s",
                    $lang,
                    $localizer
                );
            }
            my $out = $localizer->localize_for(
                lang => $lang,
                id   => $key,
                args => \@args
            );
            if ($out) {
                if (DEBUG) {
                    debugf("localize - found for %s, adding to map", $lang);
                }

                # oh, found one? set it in the localizer map so we don't have
                # to look it up again
                $self->add_localizer_map($lang, $localizer);
                return $out;
            }
        }
    }

    # if you got here, and you /still/ can't find a proper localization,
    # then we fallback to 'auto' feature
    if ($self->auto) {
        if (DEBUG) {
            debugf("localize - trying auto-lexicon for '%s'", $key);
        }
        return $self->auto_localizer->localize_for(id => $key, args => \@args);
    }

    return ();
}

sub add_localizer {
    my $self = shift;

    my $localizer;
    if (@_ == 1) {
        $localizer = $_[0];
    } else {
        my %args = @_;

        my $klass = delete $args{class};
        if ($klass !~ s/^\+//) {
            $klass = "Data::Localize::$klass";
        }
        Module::Load::load($klass);
        if (Data::Localize::DEBUG) {
            local $Log::Minimal::AUTODUMP = 1;
            debugf("Creating localizer '%s' (%s)", $klass, \%args);
        }
        $localizer = $klass->new(%args);
    }

    if (! $localizer || ! Scalar::Util::blessed($localizer) || ! $localizer->isa( 'Data::Localize::Localizer' ) ) {
        Carp::confess("Bad localizer: '" . ( defined $localizer ? $localizer : '(null)' ) . "'");
    }

    if (DEBUG()) {
        debugf("add_localizer: %s", $localizer);
    }
    $localizer->register($self);
    push @{ $self->_localizers }, $localizer;
}

sub find_localizers {
    my ($self, %args) = @_;

    if (my $isa = $args{isa}) {
        return $self->grep_localizers(sub { $_[0]->isa($isa) });
    }
}

sub add_localizer_map {
    my ($self, $lang, $localizer) = @_;

    if (DEBUG) {
        debugf("add_localizer_map %s -> %s", $lang, $localizer);
    }
    my $list = $self->get_localizer_from_lang($lang);
    if (! $list) {
        $list = [];
        $self->set_localizer_map($lang, $list);
    }
    unshift @$list, $localizer;
}

1;

__END__

=head1 NAME

Data::Localize - Alternate Data Localization API

=head1 SYNOPSIS

    use Data::Localize;

    my $loc = Data::Localize->new();
    $loc->add_localizer(
        class      => "Namespace", # Locale::Maketext-style .pm files
        namespaces => [ "MyApp::I18N" ]
    );

    $loc->add_localizer( 
        class => "Gettext",
        path  => "/path/to/localization/data/*.po"
    );

    $loc->set_languages();
    # or explicitly set one
    # $loc->set_languages('en', 'ja' );

    # looks under $self->languages, and checks if there are any
    # localizers that can handle the job
    $loc->localize( 'Hellow, [_1]!', 'John Doe' );

    # You can enable "auto", which will be your last resort fallback.
    # The key you give to the localize method will be used as the lexicon
    $self->auto(1);

=head1 DESCRIPTION

Data::Localize is an object oriented approach to localization, aimed to
be an alternate choice for Locale::Maketext, Locale::Maketext::Lexicon, and
Locale::Maketext::Simple.

=head1 RATIONALE

Functionality-wise, Locale::Maketext does what it advertises to do.
Here's a few reasons why you might or might not choose Data::Localize
over Locale::Maketext-based localizers:

=head2 Object-Oriented

Data::Localize is completely object-oriented. YMMV.

=head2 Faster

On some my benchmarks, Data::Localize is faster than Locale::Maketext
by 50~80%. (But see PERFORMANCE)

=head2 Scalable For Large Amount Of Lexicons

Whereas Locale::Maketext generally stores the lexicons in memory,
Data::Localize allows you to store this data in alternate storage.
By default Data::Localize comes with a BerkeleyDB backend.

=head1 BASIC WORKING 

=head2 STRUCTURE

Data::Localize is a wrapper around various Data::Localize::Localizer 
implementers (localizers). So if you don't specify any localizers, 
Data::Localize will do... nothing (unless you specify C<auto>).

Localizers are the objects that do the actual localization. Localizers must
register themselves to the Data::Localize parent, noting which languages it
can handle (which usually is determined by the presence of data files like
en.po, ja.po, etc). A special language ID of '*' is used to accept fallback
cases. Localizers registered to handle '*' will be tried I<after> all other
language possibilities have been exhausted.

If the particular localizer cannot deal with the requested string, then
it simply returns nothing.

=head2 AUTO-GENERATING LEXICONS

Locale::Maketext allows you to supply an "_AUTO" key in the lexicon hash,
which allows you to pass a non-existing key to the localize() method, and
use it as the actual lexicon, if no other applicable lexicons exists.

Locale::Maketext attaches this to the lexicon hash itself, but Data::Localizer
differs in that it attaches to the Data::Localizer object itself, so you
don't have to place _AUTO everywhere.

    # here, we're deliberately not setting any localizers
    my $loc = Data::Localize->new(auto => 1);

    # previous auto => 1 will force Data::Localize to fallback to
    # using the key ('Hello, [_1]') as the localization token.
    print $loc->localize('Hello, [_1]', 'John Doe'), "\n";

=head1 UTF8

All data is expected to be in decoded utf8. You must "use utf8" or 
decode them to Perl's internal representation for all values
passed to Data::Localizer. We won't try to be smart for you. USE UTF8!

=over 4

=item Using Explicit decode()

    use Encode q(decode decode_utf8);
    use Data::Localizer;

    my $loc = Data::Localize->new(...);

    $loc->localize( $key, decode( 'iso-2022-jp', $value ) );

    # if $value is encoded utf8...
    # $loc->localize( $key, decode_utf8( $value ) );

=item Using utf8

"use utf8" is simpler, but do note that it will affect ALL your literal strings
in the current scope

    use utf8;

    $loc->localize( $key, "some-utf8-key-here" );

=back

=head1 USING ALTERNATE STORAGE

By default all lexicons are stored on memory, but if you're building an app
with thousands and thousands of long messages, this might not be the ideal
solution. In such cases, you can change where the lexicons get stored

    my $loc = Data::Localize->new();
    $loc->add_localizer(
        class         => 'Gettext',
        path          => '/path/to/data/*.po'
        storage_class => 'BerkeleyDB',
        storage_args  => {
            dir => '/path/to/really/fast/device'
        }
    );

This would cause Data::Localize to put all the lexicon data in several BerkeleyDB files under /path/to/really/fast/device

Note that this approach would buy you no gain if you use Data::Localize::Namespace, as that approach by default expects everything to be in memory.

=head1 DEBUGGING

=head2 DEBUG

To enable debug tracing, either set DATA_LOCALIZE_DEBUG environment variable,

    DATA_LOCALIZE_DEBUG=1 ./yourscript.pl

or explicitly define a function before loading Data::Localize:

    BEGIN {
        *Data::Localize::DEBUG = sub () { 1 };
    }
    use Data::Localize;

=head1 METHODS

=head2 add_localizer

Adds a new localizer. You may either pass a localizer object, or arguments
to your localizer's constructor:

    $loc->add_localizer( YourLocalizer->new );

    $loc->add_localizer(
        class => "Namespace",
        namespaces => [ 'Blah' ]
    );

=head2 localize

Localize the given string ID, using provided variables.

    $localized_string = $loc->localize( $id, @args );

=head2 detect_languages

Detects the current set of languages to use. If used in an CGI environment,
will attempt to detect the language of choice from headers. See
I18N::LanguageTags::Detect for details.

=head2 detect_languages_from_header 

Detects the language from the given header value, or from HTTP_ACCEPT_LANGUAGES environment variable

=head2 localizers

Return a arrayref of localizers

=head2 add_localizer_map

Used internally.

=head2 set_localizer_map

Used internally.

=head2 find_localizers 

Finds a localizer by its attribute. Currently only supports isa

    my @locs = $loc->find_localizers(isa => 'Data::Localize::Gettext');

=head2 set_languages

If used without any arguments, calls detect_languages() and sets the
current language set to the result of detect_languages().

=head2 languages

Gets the current list of languages

=head2 add_fallback_languages

=head2 fallback_languages

=head2 count_localizers()

Return the number of localizers available

=head2 get_localizer_from_lang($lang)

Get appropriate localizer for language $lang

=head2 grep_localizers(\&sub)

Filter localizers

=head1 PERFORMANCE 

tl;dr: Use one that fits your needs

=head2 Using explicit get_handle for every request

This benchmark assumes that you're fetching the lexicon anew for
every request. This allows you to switch languages for every request

Benchmark run with Mac OS X (10.8.2) perl 5.16.1

  Running benchmarks with
    Locale::Maketext: 1.23
    Data::Localize:   0.00023
                       Rate D::L(Namespace)   L::M D::L(Gettext) D::L(Gettext+BDB)
  D::L(Namespace)    5051/s              --   -65%          -73%              -73%
  L::M              14423/s            186%     --          -24%              -24%
  D::L(Gettext)     18868/s            274%    31%            --               -1%
  D::L(Gettext+BDB) 18987/s            276%    32%            1%                --

=head2 Using cached lexicon objects for all

This benchmark assumes that you're fetching the lexicon once for
a particular language, and you keep it in memory for reuse.
This does NOT allow you to switch languages for every request.

Benchmark run with Mac OS X (10.8.2) perl 5.16.1

  Running benchmarks with
    Locale::Maketext: 1.23
    Data::Localize:   0.00023
                        Rate D::L(Namespace) D::L(Gettext+BDB) D::L(Gettext)  L::M
  D::L(Namespace)     6023/s              --              -65%          -69%  -96%
  D::L(Gettext+BDB)  17202/s            186%                --          -12%  -87%
  D::L(Gettext)      19548/s            225%               14%            --  -86%
  L::M              135993/s           2158%              691%          596%    --

=head1 TODO

Gettext style localization files -- Make it possible to decode them

=head1 CONTRIBUTORS

Dave Rolsky

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 COPYRIGHT

=over 4

=item The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=back

=cut
