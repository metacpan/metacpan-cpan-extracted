# Copyright (c) 2023-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: format independent identifier object


package Data::Identifier::Wellknown;

use v5.14;
use strict;
use warnings;
use utf8;

use Carp;
use Fcntl qw(SEEK_SET);

use Data::Identifier;
use Data::Identifier::Generate;

use parent 'Data::Identifier::Interface::Known';

our $VERSION = v0.22;

use constant {
    WK_UUID => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', # uuid
    WK_SID  => 'f87a38cb-fd13-4e15-866c-e49901adbec5', # small-identifier
    WK_SNI  => '039e0bb7-5dd3-40ee-a98c-596ff6cce405', # sirtx-numerical-identifier
};

my %imported;
my %loaded = (wellknown => undef, registered => undef); # consider two loaded to begin with.
my $start_of_data = DATA->tell;

foreach my $class (keys %loaded) {
    foreach my $id (Data::Identifier->known($class)) {
        _add_classes($id, $class);
    }
}

sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    croak 'Unsupported options passed' if scalar(keys %opts);

    unless (exists $loaded{$class}) {
        __PACKAGE__->import($class);
    }

    if ($class eq 'wellknown' || $class eq 'registered' || $class eq ':all') {
        goto &Data::Identifier::_known_provider;
    } else {
        return ($imported{$class}, rawtype => 'Data::Identifier');
    }
}

sub import {
    my ($pkg, @args) = @_;
    my $id_type = Data::Identifier->new(wellknown => 'uuid');
    my $default_class;
    my %generator;
    my $namespace;
    my %found;
    my @extra_classes;

    return if exists $loaded{':all'}; # if we done :all we ... did all!

    @args = grep {!exists($loaded{$_})} @args;

    return unless scalar @args;

    DATA->seek($start_of_data, SEEK_SET);

    while (my $line = <DATA>) {
        my ($classes, $id, $displayname, $special);
        my @classes;
        my $found;

        $line =~ s/\s{2,}%.*$//;
        $line =~ s/^\s*%.*$//;
        $line =~ s/\s+$//;
        $line =~ s/^\s+//;
        $line =~ s/\r?\n$//;

        next if $line eq '';

        if ($line =~ /^\$/) {
            my ($command, $arg) = split(/\s+/, $line, 2);
            
            if ($command eq '$type') {
                if ($arg =~ /^(.+)=(.+)$/) {
                    $id_type = Data::Identifier->new($1, $2);
                } else {
                    $id_type = Data::Identifier->new(wellknown => $arg);
                }
                $namespace = undef;
            } elsif ($command eq '$class') {
                $default_class = $arg;
                @extra_classes = ();
            } elsif ($command eq '$extra_classes') {
                @extra_classes = split(/,/, $arg);
            } elsif ($command eq '$generator') {
                %generator = split(/[,=]/, $arg);
                $id_type = undef;
                $namespace = undef;
            } elsif ($command eq '$namespace') {
                $namespace = $arg;
            } elsif ($command eq '$end') {
                last;
            } else {
                croak 'BUG';
            }
            next;
        }

        ($classes, $id, $displayname, $special) = split(/\s{2,}/, $line, 4);
        if ($classes eq '.') {
            @classes = ($default_class);
        } else {
            @classes = split(',', $classes);
        }

        push(@classes, @extra_classes);

        foreach my $class_a (@classes) {
            foreach my $class_b (@args) {
                if ($class_a eq $class_b || $class_b eq ':all') {
                    $found = 1;
                    last;
                }
            }
        }
        next unless $found;

        {
            my $identifier;

            if (defined $id_type) {
                $identifier = Data::Identifier->new(
                    $id_type => $id,
                    (defined($displayname) && $displayname ne '.') ? (displayname => $displayname) : (),
                );
            } else {
                $identifier = Data::Identifier::Generate->generic(
                    %generator,
                    request => $id,
                    (defined($displayname) && $displayname ne '.') ? (displayname => $displayname) : (),
                );
            }

            if (defined $namespace) {
                my $uuid;

                if ($namespace =~ /^(.+),lc$/) {
                    $uuid = Data::Identifier::Generate->_uuid_v5($1, lc($id));
                } else {
                    $uuid = Data::Identifier::Generate->_uuid_v5($namespace, $id);
                }
                $identifier->{id_cache} //= {};
                $identifier->{id_cache}->{WK_UUID()} //= $uuid;
            }

            if (defined($special) && length($special)) {
                my %special = split(/[,=]/, $special);

                if (defined $special{sid}) {
                    $identifier->{id_cache} //= {};
                    $identifier->{id_cache}->{WK_SID()} //= $special{sid};
                }

                if (defined $special{sni}) {
                    $identifier->{id_cache} //= {};
                    $identifier->{id_cache}->{WK_SNI()} //= $special{sni};
                }
            }

            $identifier->register;

            foreach my $class (@classes) {
                $found{$class} = undef;
                $imported{$class} //= [];
                push(@{$imported{$class}}, $identifier);
            }

            _add_classes($identifier, @classes);
        }
    }

    # deduplicate:
    foreach my $class (keys %found) {
        my %tmp = map {$_ => $_} @{$imported{$class}};
        @{$imported{$class}} = values %tmp;
    }

    # Mark classes loaded that we found data for.
    foreach my $class (@args) {
        if (exists($found{$class}) || $class eq ':all') {
            $loaded{$class} = undef;
        } else {
            croak 'Unsupported class: '.$class;
        }
    }
}


sub classes_of {
    my ($pkg, $identifier) = @_;
    $identifier = Data::Identifier->new(from => $identifier);

    return keys %{$identifier->userdata(__PACKAGE__, 'classes') // {}};
}

# ---- Private helpers ----

sub _add_classes {
    my ($identifier, @classes) = @_;
    my $set = $identifier->userdata(__PACKAGE__, 'classes') // $identifier->userdata(__PACKAGE__, 'classes' => {});
    $set->{$_} = undef foreach @classes, ':all', 'registered';
}

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Identifier::Wellknown - format independent identifier object

=head1 VERSION

version v0.22

=head1 SYNOPSIS

    use Data::Identifier::Wellknown qw(classes...);

This package provides a simple list of well known identifiers.
Classes are loaded on demand. However for speedy lookup classes can
be imported (given via C<use> arguments).

If a class is already loaded, it is not reloaded.
If a program knows the classes it will use early it makes sense to
include this module in the main program (or root module) before other modules that make
use of this module are used with all the used classes listed.
This improves speed as it will reduce the read of the full list to a single pass.
In contrast if every use will only list a single class that is not yet loaded loading will be most in-efficient.

B<Note:>
This is an B<experimental> package. It may be changed, renamed, or removed without notice.

This package implements L<Data::Identifier::Interface::Known>.

=head1 METHODS

=head2 classes_of

    my @classes = Data::Identifier::Wellknown->classes_of($identifier);

Returns the classes the identifier is known for.
C<$identifier> is parsed as per C<from> of L<Data::Identifier/new>.

B<Note:>
This module does not guarantee any specific order of the returned list.

B<Note:>
Classes may not be included in returned list unless they (or C<:all>) have been
imported before.

B<Note:>
This is an B<experimental> method. It may be changed, renamed, or removed without notice.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__DATA__
$class abstract-colour
$extra_classes colour
$type uuid

.   fade296d-c34f-4ded-abd5-d9adaf37c284    black       sid=61
.   1a2c23fa-2321-47ce-bf4f-5f08934502de    white       sid=62
.   f9bb5cd8-d8e6-4f29-805f-cc6f2b74802d    grey        sid=63
.   c9ec3bea-558e-4992-9b76-91f128b6cf29    red         sid=119
.   c0e957d0-b5cf-4e53-8e8a-ff0f5f2f3f03    green       sid=120
.   3dcef9a3-2ecc-482d-a98b-afffbc2f64b9    blue        sid=121
.   abcbf48d-c302-4be1-8c5c-a8de4471bcbb    cyan        sid=122
.   a30d070d-9909-40d4-a33a-474c89e5cd45    magenta     sid=123
.   2892c143-2ae7-48f1-95f4-279e059e7fc3    yellow      sid=124
.   5c41829f-5062-4868-9c31-2ec98414c53d    orange      sid=125
.   c90acb33-b8ea-4f55-bd86-beb7fa5cf80a    savannah    sid=126
.   215d7fe0-8513-4e38-8477-bdcc3b277779    key
.   11a5ad35-251f-4ec8-b980-eee9ebf2dead    violet
.   f2e45f11-b1a8-421f-9c03-61a30bd23e78    brown
.   a84617a0-f6f9-4eff-94eb-96a341062e1c    lion


$class vga-colour
$extra_classes colour
$type uuid

.   32f5e924-0ddb-4427-ad81-2d099b590c68    black
.   2aeedebd-2814-41b3-9cfd-f992e9a60827    maroon
.   d045d86c-3437-4b42-aa77-2d7ac6ff1656    green
.   a64b447b-3eb3-4a71-92fe-f4399e845892    olive
.   f8ace5ee-45a9-4e46-8324-095b6ab452b5    navy
.   7cd1228f-b55b-4b86-a057-f620e7934f7f    purple
.   c7d4cc0e-dd3b-465c-b1ed-6fea3d424b9f    teal
.   aa82b49e-12c2-41a4-9fd8-800957be9161    gray
.   cdb01cbf-0eca-4aad-b732-caf55abc7566    silver
.   6d62509a-aac5-412b-953b-e002867090ef    red
.   18b0ad77-95a1-4ddc-8a3e-52fb1fca2ead    lime
.   b85fca40-ab8e-4ab3-b582-43cb0979b994    yellow
.   7f2e2d6a-ec70-417b-8418-a5d67c05b7e0    blue
.   465087e0-a8d0-4a42-8f05-a1aea0d53385    fuchsia
.   4feff8a2-dbe4-447b-b052-db333b9ebee3    aqua
.   a671d5f4-5a1d-498d-b3ec-52b92f15218e    white


$class rgb-colour
$extra_classes colour
$generator style=colour,namespace=88d3944f-a13b-4e35-89eb-e3c1fbe53e76

.   #000000     black
.   #ffffff     white
.   #ff0000     red
.   #008000     green
.   #0000ff     blue
.   #00ffff     cyan
.   #ff00ff     magenta
.   #ffff00     yellow
.   #808080     grey
.   #ff8000     orange
.   #decc9c     savannah


$class namespace
$type uuid

.   9e10aca7-4a99-43ac-9368-6cbfa43636df    Wikidata-namespace
.   5dd8ddbb-13a8-4d6c-9264-36e6dd6f9c99    integer-namespace
.   fc43fbba-b959-4882-b4c8-90a288b7d416    gregorian-date-namespace
.   d95d8b1f-5091-4642-a6b0-a585313915f1    gtin-namespace
.   2c829846-c745-4741-8f9e-5f7e761828d1    xkcd-namespace
.   6f758584-101d-4a12-bbb3-66a8e8bfd92a    iconclass-namespace
.   47dd950c-9089-4956-87c1-54c122533219    language-tag-namespace
.   02513f26-d6ff-4107-98a8-2c9cb492115b    body-namespace
.   bd3136b7-56f2-48a3-b206-fd2bd96551d5    character-namespace
.   f45de583-2851-44e7-a4b5-8a9c1a2128a9    birth-namespace
.   db8f1c33-6c3d-4c15-afd8-f5ecbce16eaf    death-namespace
.   6491f7a9-0b29-4ef1-992c-3681cea18182    factgrid-namespace
.   744eaf4e-ae93-44d8-9ab5-744105222da6    roaraudio-error-namespace
.   132aa723-a373-48bf-a88d-69f1e00f00cf    unicode-character-namespace
.   3be53c82-b542-478c-92c4-cfdaed047d83    unicode-block-namespace
.   eb239013-7556-4091-959f-4d78ca826757    dot-comments-category-namespace
.   4004c90f-fe88-4c2e-9f92-e678f54c6417    dot-comments-rating-namespace


$class subject-type
$type uuid

.   eacbf914-52cf-4192-a42c-8ecd27c85ee1    unicode-string              sid=11
.   928d02b0-7143-4ec9-b5ac-9554f02d3fb1    integer                     sid=12
.   dea3782c-6bcb-4ce9-8a39-f8dab399d75d    unsigned-integer            sid=13
.   52a516d0-25d8-47c7-a6ba-80983e576c54    proto-file                  sid=17
.   298ef373-9731-491d-824d-b2836250e865    proto-message               sid=21
.   7be4d8c7-6a75-44cc-94f7-c87433307b26    proto-entity                sid=22
.   59a5691a-6a19-4051-bc26-8db82c019df3    inode                       sid=37
.   b72508ba-7fb9-42ae-b4cf-b850b53a16c2    account                     sid=41
.   f6249973-59a9-47e2-8314-f7cf9a5f77bf    person                      sid=77
.   5501e545-f39a-4d62-9f65-792af6b0ccba    body                        sid=78
.   a331f2c5-20e5-4aa2-b277-8e63fd03438d    character                   sid=79
.   63c1da19-0dd6-4181-b3fa-742b9ceb2903    filesystem                  sid=98
.   83e3acbb-eb8d-4dfb-8f2f-ae81cc436d4b    batch                       sid=109
.   b17f36c6-c397-4e84-bd32-1eccb3f00671    set                         sid=110
.   aa9d311a-89b7-44cc-a356-c3fc93dfa951    category                    sid=111
.   e8c156be-4fe7-4b13-b4fa-e207213caef8    subject-type                sid=161

.   ea9f5f01-ea54-4da3-9721-15eb3fdd0cf0    universe
.   edb7f61a-5303-4b8d-b32c-a9b40e7c2325    subject
.   dd15b4dc-05a3-44ae-ad33-8bfd702dfe70    abstract-subject
.   7fb61871-3acf-4c1c-857c-fd44508ef78a    specific-subject

.   69c01148-aab1-4c72-b857-6e53a301c96f    species
.   63644280-affc-44fd-9911-bf36048a69e9    bodytype
.   03cadc6f-2609-4527-b296-2590d737e99a    taglist
.   a414c87d-efe0-4376-8eae-66aefa78cf92    date
.   c64b5209-b975-4e59-9467-3c3b3f136b4e    colour-value
.   d9bd807e-57cb-4736-9317-bf6bba5db48a    namespace

.   84402088-2d3b-49c2-af16-f7715b54f051    creative-work
.   68aa9198-110c-43bb-a8cc-e0a533e2341e    spacetime-subject

.   2a105a7d-c39c-4958-a7a2-f2bef3e84428    state
.   323146d5-17e4-4d05-8fa6-f7235d91e8c1    abstract-state
.   7b0ae21d-8d0a-4af1-8b0c-c2d0ab77c20d    specific-state

.   63da70a8-78a4-51b0-8b87-86872b474a5d    specific-proto-file-state
.   0406b78b-741d-48f4-9acd-5e27b5e29d48    directory
.   61fba55f-1ba3-460d-85a7-9262557f41c9    hardlink

$extra_classes identifier
.   8be115d2-dc2f-4a98-91e1-a6e3075cbc31    uuid                        sid=2,sni=119
.   bfae7574-3dae-425d-89b1-9c087c140c23    tagname                     sid=3
.   a8d1637d-af19-49e9-9ef8-6bc1fbcf6439    uri                         sid=5,sni=121
.   d08dc905-bbf6-4183-b219-67723c3c8374    oid                         sid=6,sni=120
.   d0a4c6e2-ce2f-4d4c-b079-60065ac681f1    language-tag-identifier     sid=8
.   ce7aae1e-a210-4214-926a-0ebca56d77e3    wikidata-identifier         sid=9,sni=123
.   2bffc55d-7380-454e-bd53-c5acd525d692    roaraudio-error-number      sid=26,sni=116
.   66beb503-9159-41cb-9e7f-2c3eb6b4b5ff    roaraudio-error-symbol      sni=117
.   f87a38cb-fd13-4e15-866c-e49901adbec5    small-identifier            sid=27,sni=115
.   2c7e15ed-aa2f-4e2f-9a1d-64df0c85875a    chat-0-word-identifier      sid=112,sni=118
.   82d529be-0f00-4b4f-a43f-4a22de5f5312    gtin                        sid=160
.   931f155e-5a24-499b-9fbb-ed4efefe27fe    doi                         sid=162

.   135032f7-cc60-46ee-8f64-1724c2a56fa2    x11-colour-name
.   f4b073ff-0b53-4034-b4e4-4affe5caf72c    ascii-code-point            sni=122
.   5f167223-cc9c-4b2f-9928-9fe1b253b560    unicode-code-point
.   5e80c7b7-215e-4154-b310-a5387045c336    sirtx-logical               sni=129
.   039e0bb7-5dd3-40ee-a98c-596ff6cce405    sirtx-numerical-identifier  sid=113,sni=10
.   d73b6550-5309-46ad-acc9-865c9261065b    sirtx-function-number       sni=127
.   d690772e-de18-4714-aa4e-73fd35e8efc9    sirtx-function-name         sni=128
.   b1418262-6bc9-459c-b4b0-a054d77db0ea    iban
.   c8a3a132-f160-473c-b5f3-26a748f37e62    bic

.   8db88212-69df-40f3-a5cf-105dcd853d44    standard-digest-algorithm-identifier
.   8238da08-ca93-4d67-bf40-54818aa94405    rfc9530-digest-identifier
.   0d4ef6fa-0f9a-4bc8-9fc1-e4f00725397e    openpgp-digest-identifier

.   95bd826b-bd3e-4b40-b16a-aa20c9f673e4    musicbrainz-identifier
.   310776dc-1433-4623-9ffa-42d038d400a4    british-museum-term
.   893a7d5c-124c-4ad6-9a56-0ea8be50b536    gnd-identifier
.   c036d4d9-d983-4322-917c-acbf6133df64    fellig-box-number
.   90ecb0c5-f99a-4702-8575-430247de8f48    fellig-identifier
.   0d88a8f0-0fce-41ae-beef-88d74d83eb32    youtube-video-identifier
.   da72fa90-5990-46b4-b4ca-05eaf68170a5    e621tagtype
.   a6b1a981-48a0-445e-adc7-11df14e91769    wikimedia-commons-identifier
.   4a7fc2e2-854b-42ec-b24f-c7fece371865    e621-post-identifier
.   6c09afad-0109-4a05-a430-f3bdade19c24    osm-node
.   01da1735-25b3-4560-9c8c-186e42dd8904    osm-way
.   bdd9b297-e0a8-427e-8487-83f600226f5b    osm-relation
.   943315e7-9efd-41df-b3f5-4a42b93df46d    xkcd-num
.   d576b9d1-47d4-43ae-b7ec-bbea1fe009ba    factgrid-identifier
.   685c7871-2965-4f0a-ac63-d6bacd1e575e    viaf-identifier
.   435f6b8c-cae4-4dcf-816a-1225fc35108f    open-library-identifier
.   3ff707af-1f72-4e1f-a81b-7871fb6079e1    unesco-thesaurus-identifier
.   a6de24d2-95a2-4577-870c-31ad10339f22    isni
.   e9c13254-831f-474c-8881-31012ca45a72    aev-identifier
.   a1cffa6b-6b78-4b11-9a6c-3673ec25c489    europeana-entity-identifier
.   8fb7807b-c15a-4ae1-8f15-4b3d8e4f5cef    ngv-artist-identifier
.   4d25c32b-a169-40f5-be88-3d609b7d05ff    ngv-artwork-identifier
.   02e34fcc-cf5e-445a-ba54-bf6df8ae036a    geonames-identifier
.   39ea7c88-3fc2-4a01-89f9-547f451764f7    find-a-grave-identifier
.   22a80a6d-0c69-41f5-b5be-6c889f8e601b    libraries-australia-identifier
.   fb3bac19-7d4e-4995-9ef0-08dbcea7f340    agsa-creator-identifier
.   0b907ca8-a84f-4780-b708-910a858228a8    amc-artist-identifier
.   5bafcbd4-5fcf-4823-848f-7eab8175a80c    a-p-and-p-artist-identifier
.   0edc2854-37bf-4562-a05b-ac4113ead938    nla-trove-people-identifier
.   b49d88ba-1b61-4f13-b5c9-73a09ffb2b3f    tww-artist-identifier
.   80c548f6-4d23-43c1-ab50-b4546319c752    grove-art-online-identifier
.   a6f7d17a-ced2-4cf7-8ce7-fcb4a98f7aa0    wikitree-person-identifier
.   241348a8-c5d0-4473-9ec1-de7c2ba00fbb    iconclass-identifier
.   c1166bf7-c4ab-40ad-9a92-a55103bec509    media-subtype-identifier


$class any-taxon
$type uuid

.   838eede5-3f93-46a9-8e10-75165d10caa1    cat                         sid=80
.   252314f9-1467-48bf-80fd-f8b74036189f    dog                         sid=81
.   571fe2aa-95f6-4b16-a8d2-1ff4f78bdad1    lion                        sid=82
.   36297a27-0673-44ad-b2d8-0e4e97a9022d    tiger                       sid=83
.   5d006ca0-c27b-4529-b051-ac39c784d5ee    fox                         sid=84
.   914b3a09-4e01-4afc-a065-513c199b6c24    squirrel                    sid=85
.   95f1b56e-c576-4f32-ac9b-bfdd397c36a6    wolf                        sid=86
.   dcf8f4f0-c15e-44bd-ad76-0d483079db16    human                       sid=87

.   f901e5e0-e217-41c8-b752-f7287af6e6c3    mammal                      sid=89
.   7ed4160e-06d6-44a2-afe8-457e2228304d    vertebrate                  sid=90
.   0510390c-9604-4362-b603-ea09e48de7b7    animal                      sid=91
.   bccdaf71-0c82-422e-af44-bb8396bf90ed    plant                       sid=92
.   a0b8122e-d11b-4b78-a266-0bb90d1c1cbe    fungus                      sid=93
.   3e92ac2d-f8fe-48bf-acd7-8505d23d07ab    organism                    sid=94


$class encoding
$type uuid

.   ec6cd46a-aef5-495d-830b-acb3347a34ec    utf-8-string-encoding
.   b448c181-606e-460a-a8cd-8b60aeefe6bb    string-ise-uuid-encoding
.   5af917c5-67fd-4019-be38-4093fde9b612    string-ise-oid-encoding
.   61ae4438-e519-4af2-9286-afe8e03bf932    ascii-uri-encoding
.   66d561ee-c06f-408f-a56c-a009439283bb    hex-rgb-encoding
.   84c0547d-4cce-4ece-8d47-57ca8b3a7763    ascii-decimal-integer-encoding


$class direction
$type uuid

.   4e855294-4b4f-443e-b67b-8cb9d733a889    backwards                   sid=43
.   6ad2c921-7a3e-4859-ae02-98e42522e2f8    forwards                    sid=44

.   5cbdbe1c-e8b6-4cac-b274-b066a7f86b28    left                        sid=192
.   3b1858a9-996b-4831-b600-eb55ab7bb0d1    right                       sid=193
.   f158e457-9a75-42ac-b864-914b34e813c7    up                          sid=194
.   4c834505-8e77-4da6-b725-e11b6572d979    down                        sid=195

.   fd324dee-4bc7-4716-bf0c-6d50a69961b7    north                       sid=208
.   8685e1d8-f313-403a-9f4d-48fce22f9312    east                        sid=209
.   c65c5baf-630e-4a28-ace5-1082b032dd07    south                       sid=210
.   7ed25dc4-5afc-4b39-8446-4df7748040a4    west                        sid=211

.   7ce365d8-71d2-4bd6-95c9-888a8f1d834c    northeast                   sid=212
.   39be7db6-1dc7-41c3-acd2-de19ad17a97f    northwest                   sid=213
.   33233365-20ec-4073-9962-0cb4b1b1e48d    southeast                   sid=214
.   b47ecfde-02b1-4790-85dd-c2e848c89d2e    southwest                   sid=215


$class tagpool
$type uuid

.   3f066699-48df-4250-846b-20f96ac708fa    tagpool-function
.   e08e6ffd-a8a4-4d52-8860-3e09f8956be8    tagpool-port

.   e5da6a39-46d5-48a9-b174-5c26008e208e    tagpool-source-format
.   11431b85-41cd-4be5-8d88-a769ebbd603f    tagpool-directory-info-format
.   25990339-3913-4b5a-8bcf-5042ef6d8b5e    tagpool-httpd-htdirectories-format
.   afdb46f2-e13f-4419-80d7-c4b956ed85fa    tagpool-taglist-format-v1

$extra_classes subject-type
.   6c38b812-7968-4eba-a3c5-866bd4fc5381    tagpool-tagtype
.   1f30649d-eb55-48cb-93d7-6d6fcba23909    tagpool-pool
.   af2d55cb-e742-4259-a8b0-73f0f41cf337    tagpool-host
.   4e4bbe45-f783-442d-8804-ac729f5cdec5    tagpool-file
.   8f4ddee0-0837-4add-ad50-a70ca833751e    tagpool-rule
.   de971d6d-7e9e-48f3-98e0-1c677934c397    tagpool-taglist
.   e9fbc62f-c908-4cef-9261-fdfd4698e362    tagpool-source
.   ff94a4aa-b751-4b45-b8be-24c73b45f016    tagpool-httpd-htdirectoy
.   103683a9-0737-4642-8e93-6224d5ae91cc    tagpool-sysfile-type

$extra_classes tagpool-sysfile-type
.   e6d6bb07-1a6a-46f6-8c18-5aa6ea24d7cb    regular
.   577c3095-922b-4569-805d-a5df94686b35    directory
.   76ae899c-ad0c-4bbc-b693-485f91779b9f    symlink
.   f1765bfc-96d5-4ff3-ba2e-16a2a9f24cb3    blockdevice
.   241431a9-c83f-4bce-93ff-0024021cd754    characterdevice
.   3d680b7b-115c-486a-a186-4ad77facc52e    fifo
.   3d1cb160-5fc5-4d8e-a8d3-3b0ec85bb000    socket
.   6644fd67-34e7-4401-b4be-aa2b3133576c    other

$extra_classes link
.   922257e5-8fda-405c-aced-44a378acbdcf    tagpool-tag-icontext
.   962af011-3e8e-4468-9b2e-9d4df93c0d9c    tagpool-type-icontext
.   361fda18-50ce-4421-b378-881179b0318a    tagpool-title
.   ca33b058-b4ce-4059-9f0b-61ca0fd39c35    tagpool-description
.   06706809-207b-4287-9775-6efa07f807dd    tagpool-comment
.   e0a61a3d-c466-44b9-a48a-a54dcb164b80    tagpool-documentation
.   703cbb5d-eb4a-4718-9e60-adbef6f71869    tagpool-tagged-as
.   0a5e125d-d863-4013-b961-648205c2c460    tagpool-description-uri
.   8c94a334-11fd-4fbe-9900-fbe0e2eb6720    tagpool-description-image-uri
.   f45fc596-d4f9-4f4e-9c9f-09caf84c07fe    tagpool-original-url
.   0458eb83-698e-4343-b812-ec67e00084ec    tagpool-original-description-url

$extra_classes rating
.   58a091be-789a-4996-99e1-8bdef6b34397    safe
.   98d500a3-5f94-4465-8cce-f64d2ea804df    questionable
.   56ad8ced-fd0e-4d6f-8681-e044b0d55492    explicit

$extra_classes rating-catalog-item
.   dc907374-2e32-42d8-afc5-07e0539e518a    nudity
.   97488b88-0549-4d60-b088-82ca41aab2a0    educational
.   e037a1a4-7dc0-4fa1-a160-87d862a61f0c    art

.   6aa37607-b852-4260-ad17-574df8dfeaa1    realistic-blood
.   aa36e064-5530-4dff-be78-685cf65c475f    suggestive
.   80027f82-bcb4-4db2-90e7-014086988488    slightly-fetish
.   6a40cbe6-3a19-443c-ac7c-8a99f3012051    fetish
.   750fdf52-2622-40bf-a7cb-4f1c7855257c    pubic-hair
.   a294c077-6f1d-4a87-8d6d-9497a8aa57ec    kissing
.   72e5274b-0287-407e-a029-b82e7732198e    deep-kissing
.   fae5cb24-5b3c-4cf9-a205-0ff4f5aceab9    teasing
.   83286420-1bbb-4217-8911-e5ba56f20380    politically-questionable
.   4f121e26-e771-47f8-b67b-f239d85d0ab0    politically-explicit
.   0d5ce978-cbf0-415a-a936-cd14b1e70de1    anthro-nudity
.   2c85d20a-ca26-4056-9854-3a9faded9020    strong-language
.   74956ff6-8ff7-42e3-a05d-363b5b6d76db    religious-context
.   0972615f-071a-4782-a5cc-a75db90d30de    drug-use
.   c47d9faa-e971-4ad3-a547-56a728ce18d2    weapon

.   f779cff7-35f8-4cbf-9001-b4d4d73f808b    suggestive-posing
.   470eec61-7b38-4798-9798-f81d87ece6c1    suggestive-language

.   7af2c490-c1df-42ab-af5b-5b5f0674cd60    smoking
.   45c24c4a-e554-4d84-94ea-4d2e69e355e3    alcohol-drinking

.   6f7856e6-d713-4614-9549-b13be9fe4d8e    extreme-blood
.   d592af53-85d5-44f4-b39b-93b4b34c4061    visible-genitals
.   316d0935-5e79-46ca-8eed-fc1651ccc30a    visible-orifices
.   bcfed864-3588-4abe-98fc-7db18b727700    sexuality
.   a0b95287-1812-4ef5-a35c-f0bc7241c7c7    body-fluids
.   97452ebf-3b3b-4566-ad80-e214e631efa9    sex-toys


$class gamebook
$type uuid

.   10a65258-237f-45f5-9d84-7287d62dcbb5    gamebook-application-context
.   bad2f56f-5ea7-4725-bcd0-60be71cf3768    gamebook-valuefile-format
.   4cb471e3-c921-44a6-9fba-3d19f45aab35    gamebook-vocabulary
.   330436f2-91f1-4422-8f0a-4b804a37f101    gamebook-vocabulary-base
.   1357f4c9-0419-4493-8d2c-97c6a40a9bc9    gamebook-has-title
.   def9538d-b193-4144-9389-008f3fb23633    gamebook-has-text
.   2b3b7539-4dc2-43d1-afb9-974cda48ae82    gamebook-has-content
.   564e3dc6-aef7-4103-863a-aa88dd04204c    gamebook-index-listed
.   c333b55a-77e6-4cda-bf36-73f6e99a20bc    gamebook-pagelike
.   82b47919-bc0c-47e0-953e-81f6c5833860    gamebook-eventlike

$extra_classes subject-type
.   3c9f48a4-5c35-49d0-8908-1c9e1853fa1e    gamebook-type
.   1acdb1f1-1b0f-42ba-9de7-a8f4e0f4d6c1    gamebook-relation
.   ef7b2199-7cca-4efb-96bb-d18795546973    gamebook-role-marker
.   c9eec21d-a9b0-4818-99fe-fa4d24c43352    gamebook-book
.   316850a0-abf1-4b07-abeb-1386c2f19a0f    gamebook-story
.   39a3b6ae-0388-4ae5-97a6-1938b7a41db7    gamebook-scene
.   148c356a-ce5e-4a72-9e1e-7f30d3d38e21    gamebook-exit
.   f66e0cd2-852e-4a01-8c52-881430f4d8b3    gamebook-object-group

$extra_classes marker
.   d8273dea-3cb2-48f1-8f50-559bbb12bf69    gamebook-scroll-thru
.   53b7716b-65b1-4268-88e5-81f4c997f0ea    gamebook-direct-speech
.   d4fad62f-7e02-49ac-b9c6-4417aca0c45e    gamebook-direction-marker

$extra_classes link
.   8b919a2a-1dee-458d-b2fe-f646573ad4e6    gamebook-title
.   0678cfe2-1386-43db-86a9-6c491b2df64c    gamebook-text
.   ee451ce6-fa8e-4879-ad02-18e480ee3da7    gamebook-role
.   26541fcc-3248-48c8-a157-efb263b5d719    gamebook-contains
.   9bfe73f4-c3ca-464c-8e46-548931aa1571    gamebook-target
.   64df20b4-3a22-4054-881c-e750cdabf850    gamebook-direction
.   103769a6-efdc-4088-a128-fc655da2d2ae    gamebook-available-context
.   95fc948e-b9a3-46b8-a120-68858df1c96e    gamebook-uses-vocabulary
.   f6c29c2e-d667-44fb-b1fb-4b18e1a5ef7d    gamebook-uses-cache-vocabulary


$class link
$type uuid

.   ddd60c5c-2934-404f-8f2d-fcb4da88b633    also-shares-identifier      sid=1
.   7f265548-81dc-4280-9550-1bd0aa4bf748    has-type                    sid=4
.   923b43ae-a50e-4db3-8655-ed931d0dd6d4    specialises                 sid=10
.   1cd4a6c6-0d7c-48d1-81e7-4e8d41fdb45d    final-file-size             sid=18
.   4c9656eb-c130-42b7-9348-a1fee3f42050    also-list-contains-also     sid=20
.   a1c478b5-0a85-4b5b-96da-d250db14a67c    flagged-as                  sid=24
.   59cfe520-ba32-48cc-b654-74f7a05779db    marked-as                   sid=25
.   d2750351-aed7-4ade-aa80-c32436cc6030    also-has-role               sid=28
.   448c50a8-c847-4bc7-856e-0db5fea8f23b    final-file-encoding         sid=32
.   79385945-0963-44aa-880a-bca4a42e9002    final-file-hash             sid=33
.   ae8ec1de-38ec-4c58-bbd7-7ff43e1100fc    in-reply-to                 sid=38
.   8a31868b-0a26-42e0-ac54-819a9ed9dcab    in-response-to              sid=39
.   ffa893a2-9a0e-4013-96b4-307e2bca15b9    has-message-body            sid=40
.   e425be57-58cb-43fb-ba85-c1a55a6a2ebd    ancestor-of                 sid=52
.   cdee05f4-91ec-4809-a157-8c58dcb23715    descendant-of               sid=53
.   26bda7b1-4069-4003-925c-2dbf47833a01    sibling-of                  sid=54
.   a75f9010-9db3-4d78-bd78-0dd528d6b55d    see-also                    sid=55
.   d1963bfc-0f79-4b1a-a95a-b05c07a63c2a    also-at                     sid=56
.   c6e83600-fd96-4b71-b216-21f0c4d73ca6    also-shares-colour          sid=57
.   a942ba41-20e6-475e-a2c1-ce891f4ac920    also-identifies-as          sid=58
.   ac14b422-e7eb-4e5b-bccd-ad5a65aeab96    also-is-identified-as       sid=59
.   5ecb4562-dad7-431d-94a6-d301dcea8d37    parent                      sid=99
.   1a9215b2-ad06-4f4f-a1e7-4cbb908f7c7c    child                       sid=100
.   a7cfbcb0-45e2-46b9-8f60-646ab2c18b0b    displaycolour               sid=101
.   d926eb95-6984-415f-8892-233c13491931    tag-links                   sid=103
.   2c07ddc1-bdb8-435a-9614-4e6782a5101f    tag-linked-by               sid=104
.   4efce01d-411e-5e9c-9ed9-640ecde31d1d    parallel                    sid=105
.   9aad6c99-67cd-45fd-a8a6-760d863ce9b5    also-where                  sid=106
.   8efbc13b-47e5-4d92-a960-bd9a2efa9ccb    generated-by                sid=107
.   caf11e36-d401-4521-8f10-f6b36125415c    icon                        sid=132
.   e7330249-53b8-4dab-aa43-b5bfa331a8e5    thumbnail                   sid=133
.   3c9f40b4-2b98-44ce-b4dc-97649eb528ae    using-namespace             sid=190
.   bc2d2e7c-8aa4-420e-ac07-59c422034de9    for-type                    sid=191

.   079ab791-784e-4bb9-ae2d-07e01710a60c    relates-to

.   c8530d1b-d600-47e5-bc06-7b01416c79eb    generalises
.   4c771f95-9c12-4fc7-9cf6-1d5dee7024f9    has-colour-value
.   d0421d68-8d37-4f78-b800-cae3e896bea5    primary-colour
.   30710bdb-6418-42fb-96db-2278f3bfa17f    also-has-description
.   1eae4688-f66c-4c77-bc9b-bb38be88240a    inverse-relation
.   ddd1ca08-2b4a-4818-a3d8-de86921f07e2    also-shares-first-name
.   31ea2111-e233-488d-883a-4c1e6083a652    also-shares-last-name
.   756e3502-4f23-4b4b-b205-e1adaf520a85    also-shares-nickname
.   e48cd5c6-83d7-411e-9640-cb370f3502fc    implies
.   0a9c6e4e-0dc3-4467-a95a-d97e32d6c13c    also-has-commissioner
.   94a4ce85-dda0-433e-8b57-949a20606d7f    also-has-artist
.   164ffdf5-f272-409c-91cf-a34702d01872    also-has-emblem
.   f61caf39-b5e1-48f3-9a68-2a70b132db55    also-has-profile-image
.   11d8962c-0a71-4d00-95ed-fa69182788a8    also-has-comment
.   a845bfb7-130f-4f55-8a6d-ea3e5b1c2a09    also-has-proto-title
.   f7fd59e6-6727-4128-a0a7-cbc702dc09b8    also-has-title
.   df70343f-0c5f-4d76-93b6-4376f680f567    also-has-subtitle
.   96674c6c-cf5e-40cd-af1e-63b86e741f4f    fetch-file-uri
.   09e5c669-3cbd-4b6a-9ccc-bea559b738c0    in-context-after
.   4dbbc93a-83f3-4c1f-bbf6-c726ab5adeac    in-context-before
.   a47f35b0-6eb5-4eef-97a7-acadfb92e086    met
.   60f4f214-9efe-4741-b541-e5c8b8b72d92    also-likes-subject
.   8a228e56-8ecc-4578-93d8-e197fa87b962    also-dislikes-subject
.   293cd87a-d053-43fb-a061-23d2bf92886b    also-interested-in-subject
.   2618db7c-c73e-5195-bfc8-470da8f1f8b5    when
.   3d737a5c-9389-4ae7-80ff-5f64c6b3b7f1    encoding-file-name-extension
.   ab573786-73bc-4f5c-9b03-24ef8a70ae45    generator-request
.   7f55c943-06a4-42e4-9c02-f8d2d00479a0    has-prime-factor
.   87c4892f-ae39-476e-8ed0-d9ed321dafe9    default-type
.   8440eabd-5d73-4679-8f06-abaa06cf04ac    default-encoding
.   0ad7f760-8ee7-4367-97f2-ada06864325e    tag-owned-by

.   4c426c3c-900e-4350-8443-e2149869fbc9    also-has-state
.   55e0384d-842a-48e5-869f-eb0c196e0ab3    has-inital-state
.   54d30193-2000-4d8a-8c28-3fa5af4cad6b    has-final-state
.   2b7e341c-2397-4903-95d4-991c04f7b6f3    other-state
.   03d22b14-5094-46d3-9516-aecaa7ee565c    derived-from
.   689e0d21-1581-4c56-a2f4-87fc91ad63e7    derived-by-transformation

.   ed73cac4-a9b7-40ee-bad1-54e8eaa259ce    begins-after-beginning-of
.   9e6a2d96-e6db-46f7-924f-cf55d1582432    begins-after-end-of
.   1e92aba4-46ef-4d71-8193-dd23f2e9435d    begins-before-beginning-of
.   d1c1bf2f-ebea-438b-a701-fb8a7c2cd79e    begins-before-end-of
.   5a7d78c5-ed34-4b96-ab4e-fd4b07fa24b2    begins-not-after-beginning-of
.   98b1fcc0-138c-49d2-b4ff-59c9fbd539d7    begins-not-after-end-of
.   f0ee676c-94c6-403d-bea0-38ac0a4412bc    begins-not-before-beginning-of
.   c27da118-f40c-4730-b5c2-0849c0b51f99    begins-not-before-end-of

.   6b9bcc35-ea45-4b1a-b93b-c18ede89df0f    ends-after-beginning-of
.   f2209134-39f0-43d1-8913-148c437622bb    ends-after-end-of
.   47511eec-c7c8-4c38-be68-390cbffc273f    ends-before-beginning-of
.   8a319eef-f8ab-449a-9345-7b8cfbbd3769    ends-before-end-of
.   b185b957-9417-4a54-8cad-327aac595589    ends-not-after-beginning-of
.   c05e5c13-28e6-454b-b0d1-d59743bd53fc    ends-not-after-end-of
.   2935b16f-a871-4f03-9585-61912662bb35    ends-not-before-beginning-of
.   63436577-9fca-4e26-8cf4-d169e3304b56    ends-not-before-end-of

.   c920f202-ee31-413b-b6b2-b36641cf2d7f    role-requires-link
.   2947980d-dc8f-4b0c-84e9-ebe87a55ec97    role-requires-relation
.   9403b428-b455-4700-9026-f8ad5c334123    role-requires-metadata
.   03be610a-489f-4613-a364-93c714b27e9a    role-recommends-link
.   93d0f590-b856-4cf7-a769-c9886cbcc575    role-recommends-relation
.   2ba4e16f-bfcd-4c9b-85ce-d0695ed3d3c8    role-recommends-metadata
.   d0b1aaee-5750-4490-a484-fe0688739e45    role-permits-link
.   1370bbfa-1395-41d2-95b1-4129bb0455bc    role-permits-relation
.   fc1973e3-4c21-430e-87bd-6167b29bf1cb    role-permits-metadata
.   619af08e-7c28-4da4-a5c1-1ebc992e39a6    role-permits-subtag-of-namespace


$class gender
$type uuid

.   3694d8ca-c969-5705-beca-01f17b1487e8    male
.   25dfeb8e-ef9a-52a1-b5f1-073387734988    female


$class sex
$type uuid

.   ae1072ef-0865-5104-b257-0d45441fa5e5    male
.   3c4b6cdf-f5a8-50d6-8a3a-b0c0975f7e69    female

$class gender-or-sex
$type uuid

.   d642eff3-bee6-5d09-aea9-7c47b181dd83    male                        sid=75
.   db9b0db1-a451-59e8-aa3b-9994e683ded3    female                      sid=76


$class flag
$type uuid

.   e6135f02-28c1-4973-986c-ab7a6421c0a0    important
.   05648b38-e73c-485c-b536-286ce0918193    no-direct


$class service
$type uuid

.   198bc92a-be09-42d2-bf96-20a177294b79    wikidata
.   43e7f8fe-2b90-4a5d-88e2-b1d46856d942    fellig
.   de49b663-ff54-428b-ac56-d1950fb3cec7    youtube
.   c7acc624-de92-4480-8a21-31186e8bef54    youtube-nocookie
.   f8022569-fdc0-4922-8a95-3de51be087aa    dropbox
.   b279726c-a349-4d87-b87c-929319a20b3e    0wx
.   9bde88c4-1784-4756-b009-6111b4a69f96    e621
.   1c5eb5fb-3f2a-4a5a-9b28-9fba163873a0    dnb
.   ac0cad64-4bf2-4924-a855-bc4147f6cdb3    britishmuseum
.   fcb39c86-34f6-481c-9bb7-63c4a7c2256b    musicbrainz
.   a283b6cb-c8c5-4b5d-8a58-e0327e087e50    wikimedia-commons
.   1262f7fe-2d98-42aa-9ed5-5cc5182fc4f4    wikipedia
.   66c2ac78-936b-4241-b041-567080db3f6a    noembed.com
.   fdb14a39-f175-4aba-bcec-53c4683b72bd    osm
.   5350885e-92f5-4aee-b72e-dd9d95c6700a    overpass
.   6d90e7e2-c193-4e96-8d0a-c9a3d42beecf    xkcd
.   65a5000f-c37f-4fa1-9ad0-c9682fcd8756    Data::URIID
.   b542f123-b304-4f60-a2a9-15a0cc62e25d    viaf
.   2ddf371f-20b5-4fdb-99d5-934b212ed596    europeana
.   173f7237-9ca0-490d-8a98-6a04c386769a    open-library
.   01aa1e39-6d90-41c6-a010-f3850844f2e1    ngv
.   2860d918-ac49-42a1-818d-68abd84972b3    geonames
.   30deaf5b-470b-46da-8af1-6e5174d0eaf4    find-a-grave
.   0715561c-0189-4c1f-99bf-21cc6746f5ee    National Library of Australia
.   a61dda0f-b914-496a-b473-2a333b9f0f9f    Art Gallery of South Australia
.   fec16f49-a9fe-4d89-bad2-7dbb44860e83    Australian Music Centre
.   91a4981f-c1c7-4136-9e2f-39f2cd2eda7f    Australian Prints + Printmaking
.   aafdcd22-828b-413e-be0c-ed9a92d941db    The Watercolour World
.   9a6b8382-c004-458a-bf2a-68f03d863282    FactGrid
.   be8b12e5-b32d-4b89-9301-84827a79589e    Grove Art Online
.   70b9de08-2b73-4c0d-91d2-e89561cf94d2    WikiTree
.   60387716-fa98-4c92-ae2b-7f4496d6f9be    doi.org
.   75cbefbb-e622-4b72-9829-348f3986d709    iconclass.org
.   f11657cc-95da-4eae-95fc-62d16fecf473    iana.org
.   772aa1ed-9a3a-4806-94a1-42cbc0e9f962    uriid.org
.   b5a63482-f92c-4ed5-8ec3-49caa0bafa66    oidref.com


$class action
$type uuid

% Human readable:
.   b75354b2-a43b-44d9-99d5-9c0ec4fa5287    documentation
.   01fc3e42-7b5c-403e-94fb-a4fa7990c0ed    manage
.   b608ad23-e61a-4ab3-a1ca-f3f4e269b03b    render
.   0fecb446-89a9-4b0c-a7db-e83b5acec419    embed
.   478bc202-51ac-4c5e-9f9a-38e233a42dfb    info
.   e775b770-90eb-4b2f-9b78-26021688722d    edit
% Machine readable:
.   4ab02627-c452-4f4e-a9c0-4bde8f1e6b0e    fetch
.   a3b66e23-15f2-4bc6-b22e-8f072ba839e7    file-fetch
.   4060a966-9fae-4d43-9006-2288b58afabb    stream-fetch
.   6f1c921b-e0bb-4449-911f-a00719e91a1e    metadata


$class boolean
$type uuid

.   6d34d4a1-8fbc-4e22-b3e0-d50f43d97cb1    false   sid=45,sni=189
.   eb50b3dc-28be-4cfc-a9ea-bd7cee73aed5    true    sid=46,sni=190


$class integer
$generator style=integer-based,namespace=5dd8ddbb-13a8-4d6c-9264-36e6dd6f9c99

.   -1  .       sid=47
.   0   zero    sid=48
.   1   one     sid=49
.   2   two     sid=50
.   3   three   sid=144
.   4   four    sid=145


$class digest-algorithm
$type uuid=8db88212-69df-40f3-a5cf-105dcd853d44
$namespace 34f1f1d2-51be-4754-9585-83e33c5cb7e8

.   md-4-128
.   md-5-128
.   ripemd-1-160
.   tiger-1-192
.   tiger-2-192
.   sha-1-160       .   sni=185
.   sha-2-224
.   sha-2-256
.   sha-2-384
.   sha-2-512
.   sha-3-224
.   sha-3-256
.   sha-3-384
.   sha-3-512       .   sni=186


$class rdf
$type uri
$namespace 6ba7b811-9dad-11d1-80b4-00c04fd430c8

$extra_classes rdf-syntax
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#Alt                    Alt
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag                    Bag
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#CompoundLiteral        CompoundLiteral
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#HTML                   HTML
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#JSON                   JSON
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#List                   List
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#PlainLiteral           PlainLiteral
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#Property               Property
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq                    Seq
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement              Statement
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral             XMLLiteral
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#direction              direction
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#first                  first
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#langString             langString
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#language               language
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#nil                    nil
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#object                 object
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate              predicate
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#rest                   rest
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#subject                subject
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#type                   type
.   http://www.w3.org/1999/02/22-rdf-syntax-ns#value                  value

$extra_classes rdf-schema
.   http://www.w3.org/2000/01/rdf-schema#Class                        Class
.   http://www.w3.org/2000/01/rdf-schema#Container                    Container
.   http://www.w3.org/2000/01/rdf-schema#ContainerMembershipProperty  ContainerMembershipProperty
.   http://www.w3.org/2000/01/rdf-schema#Datatype                     Datatype
.   http://www.w3.org/2000/01/rdf-schema#Literal                      Literal
.   http://www.w3.org/2000/01/rdf-schema#Resource                     Resource
.   http://www.w3.org/2000/01/rdf-schema#comment                      comment
.   http://www.w3.org/2000/01/rdf-schema#domain                       domain
.   http://www.w3.org/2000/01/rdf-schema#isDefinedBy                  isDefinedBy
.   http://www.w3.org/2000/01/rdf-schema#label                        label
.   http://www.w3.org/2000/01/rdf-schema#member                       member
.   http://www.w3.org/2000/01/rdf-schema#range                        range
.   http://www.w3.org/2000/01/rdf-schema#seeAlso                      seeAlso
.   http://www.w3.org/2000/01/rdf-schema#subClassOf                   subClassOf
.   http://www.w3.org/2000/01/rdf-schema#subPropertyOf                subPropertyOf


$class dublin-core
$type uri
$namespace 6ba7b811-9dad-11d1-80b4-00c04fd430c8

.   http://purl.org/dc/dcam/VocabularyEncodingScheme                  VocabularyEncodingScheme
.   http://purl.org/dc/dcam/domainIncludes                            domainIncludes
.   http://purl.org/dc/dcam/memberOf                                  memberOf
.   http://purl.org/dc/dcam/rangeIncludes                             rangeIncludes
.   http://purl.org/dc/dcmitype/Collection                            Collection
.   http://purl.org/dc/dcmitype/Dataset                               Dataset
.   http://purl.org/dc/dcmitype/Event                                 Event
.   http://purl.org/dc/dcmitype/Image                                 Image
.   http://purl.org/dc/dcmitype/InteractiveResource                   InteractiveResource
.   http://purl.org/dc/dcmitype/MovingImage                           MovingImage
.   http://purl.org/dc/dcmitype/PhysicalObject                        PhysicalObject
.   http://purl.org/dc/dcmitype/Service                               Service
.   http://purl.org/dc/dcmitype/Software                              Software
.   http://purl.org/dc/dcmitype/Sound                                 Sound
.   http://purl.org/dc/dcmitype/StillImage                            StillImage
.   http://purl.org/dc/dcmitype/Text                                  Text

$extra_classes dublin-core-elements
.   http://purl.org/dc/elements/1.1/contributor                       contributor
.   http://purl.org/dc/elements/1.1/coverage                          coverage
.   http://purl.org/dc/elements/1.1/creator                           creator
.   http://purl.org/dc/elements/1.1/date                              date
.   http://purl.org/dc/elements/1.1/description                       description
.   http://purl.org/dc/elements/1.1/format                            format
.   http://purl.org/dc/elements/1.1/identifier                        identifier
.   http://purl.org/dc/elements/1.1/language                          language
.   http://purl.org/dc/elements/1.1/publisher                         publisher
.   http://purl.org/dc/elements/1.1/relation                          relation
.   http://purl.org/dc/elements/1.1/rights                            rights
.   http://purl.org/dc/elements/1.1/source                            source
.   http://purl.org/dc/elements/1.1/subject                           subject
.   http://purl.org/dc/elements/1.1/title                             title
.   http://purl.org/dc/elements/1.1/type                              type

$extra_classes dublin-core-terms
.   http://purl.org/dc/terms/Agent                                    Agent
.   http://purl.org/dc/terms/AgentClass                               AgentClass
.   http://purl.org/dc/terms/BibliographicResource                    BibliographicResource
.   http://purl.org/dc/terms/FileFormat                               FileFormat
.   http://purl.org/dc/terms/Frequency                                Frequency
.   http://purl.org/dc/terms/Jurisdiction                             Jurisdiction
.   http://purl.org/dc/terms/LicenseDocument                          LicenseDocument
.   http://purl.org/dc/terms/LinguisticSystem                         LinguisticSystem
.   http://purl.org/dc/terms/Location                                 Location
.   http://purl.org/dc/terms/LocationPeriodOrJurisdiction             LocationPeriodOrJurisdiction
.   http://purl.org/dc/terms/MediaType                                MediaType
.   http://purl.org/dc/terms/MediaTypeOrExtent                        MediaTypeOrExtent
.   http://purl.org/dc/terms/MethodOfAccrual                          MethodOfAccrual
.   http://purl.org/dc/terms/MethodOfInstruction                      MethodOfInstruction
.   http://purl.org/dc/terms/PeriodOfTime                             PeriodOfTime
.   http://purl.org/dc/terms/PhysicalMedium                           PhysicalMedium
.   http://purl.org/dc/terms/PhysicalResource                         PhysicalResource
.   http://purl.org/dc/terms/Policy                                   Policy
.   http://purl.org/dc/terms/ProvenanceStatement                      ProvenanceStatement
.   http://purl.org/dc/terms/RightsStatement                          RightsStatement
.   http://purl.org/dc/terms/SizeOrDuration                           SizeOrDuration
.   http://purl.org/dc/terms/Standard                                 Standard
.   http://purl.org/dc/terms/abstract                                 abstract
.   http://purl.org/dc/terms/accessRights                             accessRights
.   http://purl.org/dc/terms/accrualMethod                            accrualMethod
.   http://purl.org/dc/terms/accrualPeriodicity                       accrualPeriodicity
.   http://purl.org/dc/terms/accrualPolicy                            accrualPolicy
.   http://purl.org/dc/terms/alternative                              alternative
.   http://purl.org/dc/terms/audience                                 audience
.   http://purl.org/dc/terms/available                                available
.   http://purl.org/dc/terms/bibliographicCitation                    bibliographicCitation
.   http://purl.org/dc/terms/conformsTo                               conformsTo
.   http://purl.org/dc/terms/contributor                              contributor
.   http://purl.org/dc/terms/coverage                                 coverage
.   http://purl.org/dc/terms/created                                  created
.   http://purl.org/dc/terms/creator                                  creator
.   http://purl.org/dc/terms/date                                     date
.   http://purl.org/dc/terms/dateAccepted                             dateAccepted
.   http://purl.org/dc/terms/dateCopyrighted                          dateCopyrighted
.   http://purl.org/dc/terms/dateSubmitted                            dateSubmitted
.   http://purl.org/dc/terms/description                              description
.   http://purl.org/dc/terms/educationLevel                           educationLevel
.   http://purl.org/dc/terms/extent                                   extent
.   http://purl.org/dc/terms/format                                   format
.   http://purl.org/dc/terms/hasFormat                                hasFormat
.   http://purl.org/dc/terms/hasPart                                  hasPart
.   http://purl.org/dc/terms/hasVersion                               hasVersion
.   http://purl.org/dc/terms/identifier                               identifier
.   http://purl.org/dc/terms/instructionalMethod                      instructionalMethod
.   http://purl.org/dc/terms/isFormatOf                               isFormatOf
.   http://purl.org/dc/terms/isPartOf                                 isPartOf
.   http://purl.org/dc/terms/isReferencedBy                           isReferencedBy
.   http://purl.org/dc/terms/isReplacedBy                             isReplacedBy
.   http://purl.org/dc/terms/isRequiredBy                             isRequiredBy
.   http://purl.org/dc/terms/isVersionOf                              isVersionOf
.   http://purl.org/dc/terms/issued                                   issued
.   http://purl.org/dc/terms/language                                 language
.   http://purl.org/dc/terms/license                                  license
.   http://purl.org/dc/terms/mediator                                 mediator
.   http://purl.org/dc/terms/medium                                   medium
.   http://purl.org/dc/terms/modified                                 modified
.   http://purl.org/dc/terms/provenance                               provenance
.   http://purl.org/dc/terms/publisher                                publisher
.   http://purl.org/dc/terms/references                               references
.   http://purl.org/dc/terms/relation                                 relation
.   http://purl.org/dc/terms/replaces                                 replaces
.   http://purl.org/dc/terms/requires                                 requires
.   http://purl.org/dc/terms/rights                                   rights
.   http://purl.org/dc/terms/rightsHolder                             rightsHolder
.   http://purl.org/dc/terms/source                                   source
.   http://purl.org/dc/terms/spatial                                  spatial
.   http://purl.org/dc/terms/subject                                  subject
.   http://purl.org/dc/terms/tableOfContents                          tableOfContents
.   http://purl.org/dc/terms/temporal                                 temporal
.   http://purl.org/dc/terms/title                                    title
.   http://purl.org/dc/terms/type                                     type
.   http://purl.org/dc/terms/valid                                    valid


$class foaf
$type uri
$namespace 6ba7b811-9dad-11d1-80b4-00c04fd430c8

.   http://xmlns.com/foaf/0.1/account                                 account
.   http://xmlns.com/foaf/0.1/accountName                             accountName
.   http://xmlns.com/foaf/0.1/accountServiceHomepage                  accountServiceHomepage
.   http://xmlns.com/foaf/0.1/age                                     age
.   http://xmlns.com/foaf/0.1/aimChatID                               aimChatID
.   http://xmlns.com/foaf/0.1/based_near                              based_near
.   http://xmlns.com/foaf/0.1/birthday                                birthday
.   http://xmlns.com/foaf/0.1/currentProject                          currentProject
.   http://xmlns.com/foaf/0.1/depiction                               depiction
.   http://xmlns.com/foaf/0.1/depicts                                 depicts
.   http://xmlns.com/foaf/0.1/dnaChecksum                             dnaChecksum
.   http://xmlns.com/foaf/0.1/familyName                              familyName
.   http://xmlns.com/foaf/0.1/family_name                             family_name
.   http://xmlns.com/foaf/0.1/firstName                               firstName
.   http://xmlns.com/foaf/0.1/focus                                   focus
.   http://xmlns.com/foaf/0.1/fundedBy                                fundedBy
.   http://xmlns.com/foaf/0.1/geekcode                                geekcode
.   http://xmlns.com/foaf/0.1/gender                                  gender
.   http://xmlns.com/foaf/0.1/givenName                               givenName
.   http://xmlns.com/foaf/0.1/givenname                               givenname
.   http://xmlns.com/foaf/0.1/holdsAccount                            holdsAccount
.   http://xmlns.com/foaf/0.1/homepage                                homepage
.   http://xmlns.com/foaf/0.1/icqChatID                               icqChatID
.   http://xmlns.com/foaf/0.1/img                                     img
.   http://xmlns.com/foaf/0.1/interest                                interest
.   http://xmlns.com/foaf/0.1/isPrimaryTopicOf                        isPrimaryTopicOf
.   http://xmlns.com/foaf/0.1/jabberID                                jabberID
.   http://xmlns.com/foaf/0.1/knows                                   knows
.   http://xmlns.com/foaf/0.1/lastName                                lastName
.   http://xmlns.com/foaf/0.1/logo                                    logo
.   http://xmlns.com/foaf/0.1/made                                    made
.   http://xmlns.com/foaf/0.1/maker                                   maker
.   http://xmlns.com/foaf/0.1/mbox                                    mbox
.   http://xmlns.com/foaf/0.1/mbox_sha1sum                            mbox_sha1sum
.   http://xmlns.com/foaf/0.1/member                                  member
.   http://xmlns.com/foaf/0.1/membershipClass                         membershipClass
.   http://xmlns.com/foaf/0.1/msnChatID                               msnChatID
.   http://xmlns.com/foaf/0.1/myersBriggs                             myersBriggs
.   http://xmlns.com/foaf/0.1/name                                    name
.   http://xmlns.com/foaf/0.1/nick                                    nick
.   http://xmlns.com/foaf/0.1/openid                                  openid
.   http://xmlns.com/foaf/0.1/page                                    page
.   http://xmlns.com/foaf/0.1/pastProject                             pastProject
.   http://xmlns.com/foaf/0.1/phone                                   phone
.   http://xmlns.com/foaf/0.1/plan                                    plan
.   http://xmlns.com/foaf/0.1/primaryTopic                            primaryTopic
.   http://xmlns.com/foaf/0.1/primaryTopicOf                          primaryTopicOf
.   http://xmlns.com/foaf/0.1/publications                            publications
.   http://xmlns.com/foaf/0.1/schoolHomepage                          schoolHomepage
.   http://xmlns.com/foaf/0.1/sha1                                    sha1
.   http://xmlns.com/foaf/0.1/skypeID                                 skypeID
.   http://xmlns.com/foaf/0.1/status                                  status
.   http://xmlns.com/foaf/0.1/surname                                 surname
.   http://xmlns.com/foaf/0.1/theme                                   theme
.   http://xmlns.com/foaf/0.1/thumbnail                               thumbnail
.   http://xmlns.com/foaf/0.1/tipjar                                  tipjar
.   http://xmlns.com/foaf/0.1/title                                   title
.   http://xmlns.com/foaf/0.1/topic                                   topic
.   http://xmlns.com/foaf/0.1/topic_interest                          topic_interest
.   http://xmlns.com/foaf/0.1/weblog                                  weblog
.   http://xmlns.com/foaf/0.1/workInfoHomepage                        workInfoHomepage
.   http://xmlns.com/foaf/0.1/workplaceHomepage                       workplaceHomepage
.   http://xmlns.com/foaf/0.1/yahooChatID                             yahooChatID

$extra_classes subject-type
.   http://xmlns.com/foaf/0.1/Agent                                   Agent
.   http://xmlns.com/foaf/0.1/Document                                Document
.   http://xmlns.com/foaf/0.1/Group                                   Group
.   http://xmlns.com/foaf/0.1/Image                                   Image
.   http://xmlns.com/foaf/0.1/LabelProperty                           LabelProperty
.   http://xmlns.com/foaf/0.1/OnlineAccount                           OnlineAccount
.   http://xmlns.com/foaf/0.1/OnlineChatAccount                       OnlineChatAccount
.   http://xmlns.com/foaf/0.1/OnlineEcommerceAccount                  OnlineEcommerceAccount
.   http://xmlns.com/foaf/0.1/OnlineGamingAccount                     OnlineGamingAccount
.   http://xmlns.com/foaf/0.1/Organization                            Organization
.   http://xmlns.com/foaf/0.1/Person                                  Person
.   http://xmlns.com/foaf/0.1/PersonalProfileDocument                 PersonalProfileDocument
.   http://xmlns.com/foaf/0.1/Project                                 Project


$class dot-comments
$type uuid

$extra_classes subject-type
.   6c680be4-c28e-409c-9ba4-4e92683e99a1    dot-comments-tagtype
.   7fd39494-fd30-440e-b76b-864b07ab137c    dot-comments-category
.   ce51f96b-056c-47c1-bf33-b19c95f4d967    dot-comments-rating

$extra_classes generator
.   32016c93-0480-4c31-9f6f-3c9a9f862ec0    dot-comments-category-generator
.   e6574a69-8a2c-409c-9d63-ca0e64cccd7d    dot-comments-rating-generator

$extra_classes namespace
.   eb239013-7556-4091-959f-4d78ca826757    dot-comments-category-namespace
.   4004c90f-fe88-4c2e-9f92-e678f54c6417    dot-comments-rating-namespace

$extra_classes rating
.   06813a68-06f2-5d42-b230-28445e5f5dc1    0
.   4b31eb8c-546a-578b-83bb-e5d6e6a53263    1
.   bb986cde-9f2e-5c1d-9f56-cb3fa019077d    2
.   c7ea5002-eed0-58f6-9707-edfd673c6e02    3
.   a0e425a4-a447-5b54-bafc-46ea54eb9d55    4
.   14c1ebe1-9901-534d-b837-ea22cba1adfe    5


$class language
$extra_classes languoid
$type sid=8
$namespace 47dd950c-9089-4956-87c1-54c122533219

.   af      Afrikaans       sid=240
.   ar      Arabic          sid=243
.   bn      Bengali         sid=245
.   de      German          sid=71
.   en      English         sid=70
.   eo      Esperanto
.   es      Spanish         sid=73
.   fi      Finnish
.   fr      French          sid=244
.   he      Hebrew
.   hi      Hindi           sid=242
.   ia      Interlingua
.   id      Indonesian      sid=248
.   ie      Interlingue
.   it      Italian
.   ja      Japanese        sid=250
.   mi      Maori           sid=254
.   mr      Marathi         sid=251
.   nl      Dutch           sid=72
.   no      Norwegian
.   pt      Portuguese      sid=246
.   ru      Russian         sid=247
.   sv      Swedish
.   sw      Swahili         sid=241
.   te      Telugu
.   th      Thai
.   ur      Urdu            sid=249
.   vi      Vietnamese      sid=252
.   zh      Chinese         sid=74
.   zu      Zulu            sid=253


$class mediatype
$generator style=name-based,namespace=38ef9f1b-1cea-4173-953e-4fdee539010d

.   application
.   audio
.   example
.   font
.   haptics
.   image
.   message
.   model
.   multipart
.   text
.   video


$class mediasubtype
$generator style=name-based,namespace=50d7c533-2d9b-4208-b560-bcbbf75ce3f9

.   application/gzip
.   application/http
.   application/json
.   application/ld+json
.   application/octet-stream                                    .   sid=224,sni=197
.   application/ogg
.   application/pdf                                             .   sid=229
.   application/vnd.debian.binary-package
.   application/vnd.oasis.opendocument.base
.   application/vnd.oasis.opendocument.chart
.   application/vnd.oasis.opendocument.chart-template
.   application/vnd.oasis.opendocument.formula
.   application/vnd.oasis.opendocument.formula-template
.   application/vnd.oasis.opendocument.graphics
.   application/vnd.oasis.opendocument.graphics-template
.   application/vnd.oasis.opendocument.image
.   application/vnd.oasis.opendocument.image-template
.   application/vnd.oasis.opendocument.presentation
.   application/vnd.oasis.opendocument.presentation-template
.   application/vnd.oasis.opendocument.spreadsheet
.   application/vnd.oasis.opendocument.spreadsheet-template
.   application/vnd.oasis.opendocument.text
.   application/vnd.oasis.opendocument.text-master
.   application/vnd.oasis.opendocument.text-master-template
.   application/vnd.oasis.opendocument.text-template
.   application/vnd.oasis.opendocument.text-web
.   application/vnd.sirtx.vmv0                                  .   sni=198
.   application/xhtml+xml
.   application/xml
.   audio/flac
.   audio/matroska
.   audio/ogg
.   image/bmp                                                   .   sni=209
.   image/gif
.   image/jpeg
.   image/png                                                   .   sid=227
.   image/svg+xml                                               .   sid=228
.   image/vnd.microsoft.icon
.   image/vnd.wap.wbmp                                          .   sni=199
.   image/webp
.   message/http
.   text/html                                                   .   sid=226
.   text/plain                                                  .   sid=225
.   video/matroska
.   video/matroska-3d
.   video/ogg
.   video/webm


$class wikidata
$type wd
% We only include a small selection here

.   Q1      Universe
.   Q2      Earth
.   Q3      life
.   Q4      death
.   Q5      human
% Unassigned: Q6 - Q7
.   Q8      happiness
.   Q15     Africa
.   Q18     South America
.   Q19     cheating
.   Q46     Europe
.   Q48     Asia
.   Q51     Antarctica
.   Q56     lolcat
.   Q64     Berlin
.   Q68     computer
.   Q73     Internet Relay Chat
.   Q75     Internet
.   Q81     carrot
.   Q405    Moon
.   Q16521      taxon
.   Q6581072    female
.   Q6581097    male
.   Q15632617   fictional human

$extra_classes link
.   P6      head of government
.   P10     video
.   P17     country
.   P18     image
.   P19     place of birth
.   P20     place of death
.   P21     sex or gender
.   P22     father
.   P25     mother
.   P26     spouse
.   P27     country of citizenship
.   P30     continent
.   P31     instance of
.   P35     head of state
.   P36     capital
.   P37     official language
.   P38     currency
.   P39     position held
.   P40     child
.   P41     flag image
.   P47     shares border with
.   P50     author
.   P51     audio
.   P53     family
.   P279    subclass of
.   P465    sRGB color hex triplet
.   P487    Unicode character
.   P569    date of birth
.   P570    date of death
.   P734    family name
.   P735    given name
.   P1696   inverse property
.   P1963   properties for this type
.   P3373   sibling
.   P6364   official color


$class factgrid
$type uuid=d576b9d1-47d4-43ae-b7ec-bbea1fe009ba
$namespace 6491f7a9-0b29-4ef1-992c-3681cea18182,lc

.   Q17     Female gender
.   Q18     Male gender

$extra_classes link
.   P2      Instance of
.   P3      Subclass of
.   P141    Father
.   P142    Mother
.   P150    Child
.   P154    Gender
.   P247    Surname
.   P248    Given name(s)
.   P696    Hex color
.   P899    Object properties


$class _other
$type uuid

.   54bf8af4-b1d7-44da-af48-5278d11e8f32    ValueFile
.   f7674607-ae49-4a5a-bb2c-6392beeb9928    nowhere
.   92292a4e-b060-417e-a90c-a270331259e9    needstagging
.   7e5d56d4-98e6-4205-89c0-763e1d729531    utf-8-marker
.   2ec67bbe-4698-4a0c-921d-1f0951923ee6    dot-repeat-marker

$extra_classes generator
.   97b7f241-e1c5-4f02-ae3c-8e31e501e1dc    gregorian-date-generator
.   55febcc4-6655-4397-ae3d-2353b5856b34    rgb-colour-generator
.   913ee958-fda7-48ff-a57a-e34d11dc3273    gtin-generator
.   d511f370-0e49-42d5-ad18-bf280dc97e08    body-generator
.   bd1a1966-2e71-43cc-a7ce-f7a4547df450    character-generator
.   2b85ca08-921c-4683-a102-f18748c88fda    birth-generator
.   3e1c709e-32bf-4943-a9fa-8c25cb37dc92    death-generator
.   39f643aa-37ab-413d-87d7-4260bb1785b9    roaraudio-error-generator
.   d74f8c35-bcb8-465c-9a77-01010e8ed25c    unicode-character-generator
.   a649d48d-35b0-4454-81af-c5fd2eb40373    media-sub-type-generator
.   5c8c072e-f1a2-4824-9721-d57e811b6b4f    media-super-type-generator


$class _leftover_sids
$type uuid

% Handled above: 1 - 6
% Unassigned: 7
% Handled above: 8 - 13
% Unassigned: 14 - 15
.   6ba648c2-3657-47c2-8541-9b73c3a9b2b4    default-context             sid=16
% Handled above: 17 - 18
.   6085f87e-4797-4bb2-b23d-85ff7edc1da0    text-fragment               sid=19
% Handled above: 20 - 22
.   65bb36f2-b558-48af-8512-bca9150cca85    proxy-type                  sid=23
% Handled above: 24 - 28
% Unassigned: 29 - 31
% Handled above: 32 - 33
.   3fde5688-6e34-45e9-8f33-68f079b152c8    SEEK_SET                    sid=34
.   bc598c52-642e-465b-b079-e9253cd6f190    SEEK_CUR                    sid=35
.   06aff30f-70e8-48b4-8b20-9194d22fc460    SEEK_END                    sid=36
% Handled above: 37
% Unassigned: 38 - 40
% Handled above: 41
% Unassigned: 42
% Handled above: 43-44
% Handled above: 45 - 50
% Unassigned: 51
% Handled above: 52 - 59
.   3c2c155f-a4a0-49f3-bdaf-7f61d25c6b8c    Earth                       sid=60
% Handled above: 60 - 63
.   dd708015-0fdd-4543-9751-7da42d19bc6a    Sun                         sid=64
.   23026974-b92f-4820-80f6-c12f4dd22fca    Luna                        sid=65
% Reserved: 66
% Unassigned: 67 - 76
% Handled above: 77 - 87
% Unassigned: 88
% Handled above: 89 - 94
.   115c1bcf-02cd-4a57-bd02-1d9f1ea8dd01    any-taxon                   sid=95
.   d2526d8b-25fa-4584-806b-67277c01c0db    inode-number                sid=96
.   cd5bfb11-620b-4cce-92bd-85b7d010f070    also-on-filesystem          sid=97
% Handled above: 98 - 101
% Reserved: 102
% Handled above: 103 - 107
% Reserved: 108
% Handled above: 109 - 113
% Unassigned: 114 - 118
% Handled above: 119 - 126
% Reserved: 127 - 131
% Handled above: 132 - 133
.   2ec4a6b0-e6bf-40cd-96a2-490cbc8d6c4b    empty-set                   sid=134
.   99437f71-f1b5-4a50-8ecf-882b61b86b1e    final-file-charset          sid=135
% Unassigned: 136 - 142
.   807e485f-8b3a-5483-8bb5-d58648acaa8f    UTF-8                       sid=143
% Handled above: 144 - 145
% Unassigned: 146 - 158
.   7cb67873-33bc-4a93-b53f-072ce96c6f1a    hrair                       sid=159
% Handled above: 160 - 162
% Unassigned: 163 - 175
.   c44ee482-0fb7-421b-9aad-a6c8f099a4b6    Universe                    sid=176
.   0ac40a25-d20f-42ed-ae1c-64e62a56d673    Observable universe         sid=177
% Reserved: 178
% Unassigned: 179 - 188
.   8a1cb2d6-df2f-46db-89c3-a75168adebf6    generator                   sid=189
% Handled above: 190 - 195
% Unassigned: 196 - 207
% Handled above: 208 - 215
% Unassigned: 216 - 223
% Handled above: 224 - 229
% Unassigned: 230 - 239
% Handled above: 240 - 254
% Reserved: 255

$end
