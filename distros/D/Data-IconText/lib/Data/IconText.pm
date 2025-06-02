# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with icon text

package Data::IconText;

use v5.20;
use strict;
use warnings;

use Carp;
use Scalar::Util qw(looks_like_number weaken);
use Data::Identifier v0.12;

use constant {
    WK_UNICODE_CP               => Data::Identifier->new(uuid => '5f167223-cc9c-4b2f-9928-9fe1b253b560')->register, # unicode-code-point
    WK_ASCII_CP                 => Data::Identifier->new(uuid => 'f4b073ff-0b53-4034-b4e4-4affe5caf72c')->register, # ascii-code-point
    WK_FREEDESKTOP_ICON_NAME    => Data::Identifier->new(uuid => '560906df-ebd1-41f6-b510-038b30522051')->register, # freedesktop-icon-name
};

use overload '""' => sub {$_[0]->as_string};

our $VERSION = v0.03;

my %_types = (
    db          => 'Data::TagDB',
    extractor   => 'Data::URIID',
    fii         => 'File::Information',
    store       => 'File::FStore',
);

my %_for_version = (
    v0.01 => {
        default_unicode => 0x2370, # U+2370 APL FUNCTIONAL SYMBOL QUAD QUESTION
        media_type => {
            text  => 0x270D,
            audio => 0x266B,
            video => 0x2707,
            image => 0x1F5BB,
        },
        media_subtype => {
            'application/pdf'                           => 0x1F5BA,
            'application/vnd.oasis.opendocument.text'   => 0x1F5CE,
        },
        special => {
            directory           => 0x1F5C0,
            parent_directory    => 0x2B11,
            regular             => 0x2299,
            regular_not_in_pool => 0x2298,
        },
        identifier => {},
    },
    v0.02 => {
        parent => v0.01,
        identifier => {
            '8be115d2-dc2f-4a98-91e1-a6e3075cbc31' => { # uuid
                '3c2c155f-a4a0-49f3-bdaf-7f61d25c6b8c' => 0x1F30D,
                '7b177183-083c-4387-abd3-8793eb647373' => 0x21E5,
                '4dc9fd07-7ef3-4215-8874-31d78ed55c22' => 0x21A3,
                '3877b2ef-6c77-423f-b15f-76508fbd48ed' => 0x21A6,
                'bccdaf71-0c82-422e-af44-bb8396bf90ed' => 0x1F331,
                '0a24c834-90bd-4abd-ad97-4bd3ca7e784a' => 0x1F332,
                '85061c8c-be7a-4171-a008-f2035a4b8b61' => 0x1F333,
                'eba923c3-a425-425d-80ab-0064258d108a' => 0x1F334,
                '571fe2aa-95f6-4b16-a8d2-1ff4f78bdad1' => 0x1F981,
                '3694d8ca-c969-5705-beca-01f17b1487e8' => 0x2642,
                'ae1072ef-0865-5104-b257-0d45441fa5e5' => 0x2642,
                'd642eff3-bee6-5d09-aea9-7c47b181dd83' => 0x2642,
                '25dfeb8e-ef9a-52a1-b5f1-073387734988' => 0x2640,
                '3c4b6cdf-f5a8-50d6-8a3a-b0c0975f7e69' => 0x2640,
                'db9b0db1-a451-59e8-aa3b-9994e683ded3' => 0x2640,
                '310f2b49-73a8-5f27-aeaf-5f34bc8e583f' => 0x26A5,
                '036c0fe8-5189-5134-99ec-0b1b05c7bbf4' => 0x26A5,
            },
        },
    },
    v0.03 => {
        parent => v0.02,
        identifier => {
            '560906df-ebd1-41f6-b510-038b30522051' => { # freedesktop-icon-name
                # 'address-book-new'                          => 0x0,
                # 'application-exit'                          => 0x0,
                # 'appointment-new'                           => 0x0,
                # 'call-start'                                => 0x0,
                # 'call-stop'                                 => 0x0,
                # 'contact-new'                               => 0x0,
                # 'document-new'                              => 0x0,
                # 'document-open'                             => 0x0,
                # 'document-open-recent'                      => 0x0,
                # 'document-page-setup'                       => 0x0,
                # 'document-print'                            => 0x0,
                # 'document-print-preview'                    => 0x0,
                # 'document-properties'                       => 0x0,
                # 'document-revert'                           => 0x0,
                # 'document-save'                             => 0x0,
                # 'document-save-as'                          => 0x0,
                # 'document-send'                             => 0x0,
                # 'edit-clear'                                => 0x0,
                # 'edit-copy'                                 => 0x0,
                # 'edit-cut'                                  => 0x0,
                # 'edit-delete'                               => 0x0,
                # 'edit-find'                                 => 0x0,
                # 'edit-find-replace'                         => 0x0,
                # 'edit-paste'                                => 0x0,
                # 'edit-redo'                                 => 0x0,
                # 'edit-select-all'                           => 0x0,
                'edit-undo'                                 => 0x238C,
                # 'folder-new'                                => 0x0,
                # 'format-indent-less'                        => 0x0,
                # 'format-indent-more'                        => 0x0,
                # 'format-justify-center'                     => 0x0,
                # 'format-justify-fill'                       => 0x0,
                # 'format-justify-left'                       => 0x0,
                # 'format-justify-right'                      => 0x0,
                # 'format-text-direction-ltr'                 => 0x0,
                # 'format-text-direction-rtl'                 => 0x0,
                # 'format-text-bold'                          => 0x0,
                # 'format-text-italic'                        => 0x0,
                # 'format-text-underline'                     => 0x0,
                # 'format-text-strikethrough'                 => 0x0,
                # 'go-bottom'                                 => 0x0,
                # 'go-down'                                   => 0x0,
                # 'go-first'                                  => 0x0,
                # 'go-home'                                   => 0x0,
                # 'go-jump'                                   => 0x0,
                # 'go-last'                                   => 0x0,
                # 'go-next'                                   => 0x0,
                # 'go-previous'                               => 0x0,
                'go-top'                                    => 0x1F51D,
                # 'go-up'                                     => 0x0,
                # 'help-about'                                => 0x0,
                # 'help-contents'                             => 0x0,
                # 'help-faq'                                  => 0x0,
                # 'insert-image'                              => 0x0,
                # 'insert-link'                               => 0x0,
                # 'insert-object'                             => 0x0,
                # 'insert-text'                               => 0x0,
                # 'list-add'                                  => 0x0,
                # 'list-remove'                               => 0x0,
                # 'mail-forward'                              => 0x0,
                # 'mail-mark-important'                       => 0x0,
                # 'mail-mark-junk'                            => 0x0,
                # 'mail-mark-notjunk'                         => 0x0,
                # 'mail-mark-read'                            => 0x0,
                # 'mail-mark-unread'                          => 0x0,
                # 'mail-message-new'                          => 0x0,
                # 'mail-reply-all'                            => 0x0,
                # 'mail-reply-sender'                         => 0x0,
                'mail-send'                                 => 0x1F4E9,
                # 'mail-send-receive'                         => 0x0,
                'media-eject'                               => 0x23CF,
                'media-playback-pause'                      => 0x23F8,
                'media-playback-start'                      => 0x23F5,
                'media-playback-stop'                       => 0x23F9,
                'media-record'                              => 0x23FA,
                'media-seek-backward'                       => 0x23EA,
                'media-seek-forward'                        => 0x23E9,
                'media-skip-backward'                       => 0x23EE,
                'media-skip-forward'                        => 0x23ED,
                # 'object-flip-horizontal'                    => 0x0,
                # 'object-flip-vertical'                      => 0x0,
                # 'object-rotate-left'                        => 0x0,
                # 'object-rotate-right'                       => 0x0,
                'process-stop'                              => 0x1F5D9,
                # 'system-lock-screen'                        => 0x0,
                # 'system-log-out'                            => 0x0,
                # 'system-run'                                => 0x0,
                # 'system-search'                             => 0x0,
                # 'system-reboot'                             => 0x0,
                # 'system-shutdown'                           => 0x0,
                # 'tools-check-spelling'                      => 0x0,
                # 'view-fullscreen'                           => 0x0,
                'view-refresh'                              => 0x1F5D8,
                # 'view-restore'                              => 0x0,
                # 'view-sort-ascending'                       => 0x0,
                # 'view-sort-descending'                      => 0x0,
                'window-close'                              => 0x1F5D9,
                # 'window-new'                                => 0x0,
                # 'zoom-fit-best'                             => 0x0,
                # 'zoom-in'                                   => 0x0,
                # 'zoom-original'                             => 0x0,
                # 'zoom-out'                                  => 0x0,
                # 'process-working'                           => 0x0,
                'accessories-calculator'                    => 0x1F5A9,
                # 'accessories-character-map'                 => 0x0,
                # 'accessories-dictionary'                    => 0x0,
                # 'accessories-screenshot-tool'               => 0x0,
                # 'accessories-text-editor'                   => 0x0,
                # 'help-browser'                              => 0x0,
                'multimedia-volume-control'                 => 0x1F39B,
                # 'preferences-desktop-accessibility'         => 0x0,
                # 'preferences-desktop-font'                  => 0x0,
                # 'preferences-desktop-keyboard'              => 0x0,
                # 'preferences-desktop-locale'                => 0x0,
                # 'preferences-desktop-multimedia'            => 0x0,
                # 'preferences-desktop-screensaver'           => 0x0,
                # 'preferences-desktop-theme'                 => 0x0,
                # 'preferences-desktop-wallpaper'             => 0x0,
                # 'system-file-manager'                       => 0x0,
                # 'system-software-install'                   => 0x0,
                # 'system-software-update'                    => 0x0,
                # 'utilities-system-monitor'                  => 0x0,
                # 'utilities-terminal'                        => 0x0,
                # 'applications-accessories'                  => 0x0,
                # 'applications-development'                  => 0x0,
                # 'applications-engineering'                  => 0x0,
                # 'applications-games'                        => 0x0,
                # 'applications-graphics'                     => 0x0,
                # 'applications-internet'                     => 0x0,
                # 'applications-multimedia'                   => 0x0,
                # 'applications-office'                       => 0x0,
                # 'applications-other'                        => 0x0,
                # 'applications-science'                      => 0x0,
                # 'applications-system'                       => 0x0,
                # 'applications-utilities'                    => 0x0,
                # 'preferences-desktop'                       => 0x0,
                # 'preferences-desktop-peripherals'           => 0x0,
                # 'preferences-desktop-personal'              => 0x0,
                # 'preferences-other'                         => 0x0,
                # 'preferences-system'                        => 0x0,
                # 'preferences-system-network'                => 0x0,
                # 'system-help'                               => 0x0,
                # 'audio-card'                                => 0x0,
                'audio-input-microphone'                    => 0x1F399,
                # 'battery'                                   => 0x0,
                'camera-photo'                              => 0x1F4F7,
                'camera-video'                              => 0x1F4F9,
                # 'camera-web'                                => 0x0,
                # 'computer'                                  => 0x0,
                # 'drive-harddisk'                            => 0x0,
                # 'drive-optical'                             => 0x0,
                # 'drive-removable-media'                     => 0x0,
                # 'input-gaming'                              => 0x0,
                'input-keyboard'                            => 0x2328,
                'input-mouse'                               => 0x1F5B1,
                # 'input-tablet'                              => 0x0,
                # 'media-flash'                               => 0x0,
                'media-floppy'                              => 0x1F4BE,
                'media-optical'                             => 0x1F4BF,
                'media-tape'                                => 0x1F5AD,
                'modem'                                     => 0xF580,
                # 'multimedia-player'                         => 0x0,
                # 'network-wired'                             => 0x0,
                # 'network-wireless'                          => 0x0,
                # 'pda'                                       => 0x0,
                'phone'                                     => 0x1F4DE,
                'printer'                                   => 0x1F5A8,
                # 'scanner'                                   => 0x0,
                # 'video-display'                             => 0x0,
                # 'emblem-default'                            => 0x0,
                # 'emblem-documents'                          => 0x0,
                # 'emblem-downloads'                          => 0x0,
                # 'emblem-favorite'                           => 0x0,
                # 'emblem-important'                          => 0x0,
                # 'emblem-mail'                               => 0x0,
                # 'emblem-photos'                             => 0x0,
                # 'emblem-readonly'                           => 0x0,
                # 'emblem-shared'                             => 0x0,
                # 'emblem-symbolic-link'                      => 0x0,
                # 'emblem-synchronized'                       => 0x0,
                # 'emblem-system'                             => 0x0,
                # 'emblem-unreadable'                         => 0x0,
                # 'face-angel'                                => 0x0,
                # 'face-angry'                                => 0x0,
                # 'face-cool'                                 => 0x0,
                # 'face-crying'                               => 0x0,
                # 'face-devilish'                             => 0x0,
                # 'face-embarrassed'                          => 0x0,
                # 'face-kiss'                                 => 0x0,
                # 'face-laugh'                                => 0x0,
                # 'face-monkey'                               => 0x0,
                # 'face-plain'                                => 0x0,
                # 'face-raspberry'                            => 0x0,
                # 'face-sad'                                  => 0x0,
                # 'face-sick'                                 => 0x0,
                # 'face-smile'                                => 0x0,
                # 'face-smile-big'                            => 0x0,
                # 'face-smirk'                                => 0x0,
                # 'face-surprise'                             => 0x0,
                # 'face-tired'                                => 0x0,
                # 'face-uncertain'                            => 0x0,
                # 'face-wink'                                 => 0x0,
                # 'face-worried'                              => 0x0,
                # 'flag-aa'                                   => 0x0,
                # 'application-x-executable'                  => 0x0,
                # 'audio-x-generic'                           => 0x0,
                # 'font-x-generic'                            => 0x0,
                # 'image-x-generic'                           => 0x0,
                # 'package-x-generic'                         => 0x0,
                # 'text-html'                                 => 0x0,
                # 'text-x-generic'                            => 0x0,
                # 'text-x-generic-template'                   => 0x0,
                # 'text-x-script'                             => 0x0,
                # 'video-x-generic'                           => 0x0,
                # 'x-office-address-book'                     => 0x0,
                # 'x-office-calendar'                         => 0x0,
                # 'x-office-document'                         => 0x0,
                # 'x-office-presentation'                     => 0x0,
                # 'x-office-spreadsheet'                      => 0x0,
                'folder'                                    => 0x1F4C1,
                # 'folder-remote'                             => 0x0,
                # 'network-server'                            => 0x0,
                # 'network-workgroup'                         => 0x0,
                # 'start-here'                                => 0x0,
                # 'user-bookmarks'                            => 0x0,
                # 'user-desktop'                              => 0x0,
                # 'user-home'                                 => 0x0,
                'user-trash'                                => 0x1F5D1,
                # 'appointment-missed'                        => 0x0,
                # 'appointment-soon'                          => 0x0,
                'audio-volume-high'                         => 0x1F50A,
                'audio-volume-low'                          => 0x1F508,
                'audio-volume-medium'                       => 0x1F509,
                'audio-volume-muted'                        => 0x1F507,
                # 'battery-caution'                           => 0x0,
                'battery-low'                               => 0x1FAAB,
                'dialog-error'                              => 0x1F6D1,
                'dialog-information'                        => 0x1F6C8,
                # 'dialog-password'                           => 0x0,
                'dialog-question'                           => 0x2BD1,
                'dialog-warning'                            => 0x26A0,
                # 'folder-drag-accept'                        => 0x0,
                # 'folder-open'                               => 0x0,
                # 'folder-visiting'                           => 0x0,
                # 'image-loading'                             => 0x0,
                # 'image-missing'                             => 0x0,
                # 'mail-attachment'                           => 0x0,
                # 'mail-unread'                               => 0x0,
                # 'mail-read'                                 => 0x0,
                # 'mail-replied'                              => 0x0,
                # 'mail-signed'                               => 0x0,
                # 'mail-signed-verified'                      => 0x0,
                'media-playlist-repeat'                     => 0x1F501,
                'media-playlist-shuffle'                    => 0x1F500,
                # 'network-error'                             => 0x0,
                # 'network-idle'                              => 0x0,
                # 'network-offline'                           => 0x0,
                # 'network-receive'                           => 0x0,
                # 'network-transmit'                          => 0x0,
                # 'network-transmit-receive'                  => 0x0,
                # 'printer-error'                             => 0x0,
                # 'printer-printing'                          => 0x0,
                # 'security-high'                             => 0x0,
                # 'security-medium'                           => 0x0,
                # 'security-low'                              => 0x0,
                # 'software-update-available'                 => 0x0,
                # 'software-update-urgent'                    => 0x0,
                # 'sync-error'                                => 0x0,
                # 'sync-synchronizing'                        => 0x0,
                # 'task-due'                                  => 0x0,
                # 'task-past-due'                             => 0x0,
                # 'user-available'                            => 0x0,
                # 'user-away'                                 => 0x0,
                # 'user-idle'                                 => 0x0,
                # 'user-offline'                              => 0x0,
                # 'user-trash-full'                           => 0x0,
                'weather-clear'                             => 0x1F323,
                # 'weather-clear-night'                       => 0x0,
                'weather-few-clouds'                        => 0x1F324,
                # 'weather-few-clouds-night'                  => 0x0,
                'weather-fog'                               => 0x1F32B,
                # 'weather-overcast'                          => 0x0,
                # 'weather-severe-alert'                      => 0x0,
                'weather-showers'                           => 0x1F327,
                'weather-showers-scattered'                 => 0x01F326,
                'weather-snow'                              => 0x1F328,
                'weather-storm'                             => 0x1F329,
            },
        }
    },
);

while (1) {
    my $found = 0;

    foreach my $v (keys %_for_version) {
        my $parent = $_for_version{$v}->{parent} // next;
        next if defined $_for_version{$parent}->{parent};

        delete $_for_version{$v}->{parent};

        _merge(\%_for_version, \%_for_version, $v, $parent);

        $found++;
    }

    last unless $found;
}

my %_type_to_special = (
    '577c3095-922b-4569-805d-a5df94686b35' => 'directory',
    'e6d6bb07-1a6a-46f6-8c18-5aa6ea24d7cb' => 'regular',
);

my %_idtype_to_uuid = (
    uuid => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31',
    oid  => 'd08dc905-bbf6-4183-b219-67723c3c8374',
    uri  => 'a8d1637d-af19-49e9-9ef8-6bc1fbcf6439',
    sid  => 'f87a38cb-fd13-4e15-866c-e49901adbec5',
);



sub new {
    my ($pkg, %opts) = @_;
    my $self = bless {for_version => (delete($opts{for_version}) // $VERSION)}, $pkg;
    my $for_version_info = $self->_find_for_version_info;
    my @mimetypes;

    if (defined(my $unicode = delete $opts{unicode})) {
        if (looks_like_number($unicode)) {
            $self->{unicode} //= int($unicode);
        } elsif ($unicode =~ /^U\+([0-9a-fA-F]{4,7})$/) {
            $self->{unicode} //= hex($1);
        } elsif (scalar(eval {$unicode->isa('Data::Identifier')}) && $unicode->type->eq(WK_UNICODE_CP) && $unicode->id =~ /^U\+([0-9a-fA-F]{4,7})$/) { # XXX: Experimental!
            $self->{unicode} //= hex($1);
        } else {
            croak 'Passed unicode value is in wrong format';
        }
    }

    if (defined(my $raw = delete $opts{raw})) {
        croak 'Raw has wrong length' unless length($raw) == 1;
        $self->{unicode} //= ord($raw);
    }

    if (defined(my $from = delete $opts{from})) {
        my $type;
        my $id;

        unless (eval {$from->isa('Data::Identifier')}) {
            $from = Data::Identifier->new(from => $from);
        }

        $type = $from->type;
        $id   = $from->id // croak 'Bad identifier';

        if ($type->eq(WK_UNICODE_CP) && $id =~ /^U\+([0-9a-fA-F]{4,7})$/) {
            $self->{unicode} //= hex($1);
        } elsif ($type->eq(WK_ASCII_CP) && int($id) >= 0 && int($id) <= 127) {
            $self->{unicode} //= int($id);
        }
    }

    if (defined(my $for = delete $opts{for})) {
        state $running = undef;

        unless ($running) {
            local $@ = undef;

            unless (ref $for) {
                $for = Data::Identifier->new(from => $for);
            }

            if (defined(my $table = $for_version_info->{identifier}{$for->type->uuid})) {
                $self->{unicode} //= $table->{$for->id};
            }

            if (!defined($self->{unicode}) && $for->type->eq(WK_FREEDESKTOP_ICON_NAME)) {
                if ($for->id =~ /^flag-([a-z]{2})$/) {
                    $opts{flag} //= $1;
                }
            }

            unless (defined $self->{unicode}) {
                state $sid_forceloaded;

                if (!$sid_forceloaded && defined(my $sid = $for->sid(default => undef))) {
                    unless (defined($for->uuid(default => undef))) {
                        require Data::Identifier::Wellknown;
                        Data::Identifier::Wellknown->import(':all');
                        $for = Data::Identifier->new($for->type => $for->id);
                        $sid_forceloaded = 1;
                    }
                }

                foreach my $type (keys %_idtype_to_uuid) {
                    my $v = $for->as($type, default => undef) // next;
                    if (defined(my $table = $for_version_info->{identifier}{$_idtype_to_uuid{$type}})) {
                        $self->{unicode} //= $table->{$v};
                    }
                    last if defined $self->{unicode};
                }
            }

            $running = 1;
            eval {
                if ($for->isa('Data::URIID::Base') && !$for->isa('Data::URIID::Result')) {
                    $for = $for->as('Data::Identifier');
                }

                if ($for->isa('Data::Identifier')) {
                    if (defined(my $db = $opts{db})) {
                        my $f = eval { $db->tag_by_id($for) };
                        $for = $f if defined $f;
                    }
                }

                if ($for->isa('Data::Identifier')) {
                    if (defined(my $store = $opts{store})) {
                        my $f = eval {$store->query(ise => $for)};
                        $for = $f if defined $f;
                    }
                }

                if ($for->isa('Data::Identifier')) {
                    if (defined(my $fii = $opts{fii})) {
                        my $f = eval {$fii->for_identifier($for)};
                        $for = $f if defined $f;
                    }
                }

                if ($for->isa('Data::Identifier')) {
                    if (defined(my $extractor = $opts{extractor})) {
                        my $f = $extractor->lookup($for);
                        $for = $f if defined $f;
                    }
                }

                if ($for->isa('File::FStore::File')) {
                    my $v;

                    push(@mimetypes, $v) if defined($v = eval {$for->get(properties => 'mediasubtype')});
                    $opts{special} //= 'regular';
                } elsif ($for->isa('File::Information::Base')) {
                    my $type;
                    my $v;

                    push(@mimetypes, $v) if defined($v = $for->get('mediatype', default => undef));

                    unless (defined($opts{special})) {
                        require File::Spec;

                        if ($for->get('link_basename', default => '') eq File::Spec->updir) {
                            $opts{special} //= 'parent-directory';
                        }
                    }

                    unless (defined($opts{special})) {
                        $type   = $for->get('tagpool_inode_type', default => undef, as => 'uuid');
                        $type //= eval { $for->inode->get('tagpool_inode_type', default => undef, as => 'uuid') };

                        $opts{special} //= $_type_to_special{$type} if defined $type;
                    }
                } elsif ($for->isa('Data::TagDB::Tag')) {
                    require Encode;

                    my $icontext = $for->icontext(default => undef);
                    $self->{unicode} //= ord(Encode::decode('UTF-8' => $icontext)) if defined $icontext;
                } elsif ($for->isa('Data::URIID::Result')) {
                    my $icontext = $for->attribute('icon_text', default => undef);
                    $self->{unicode} //= ord($icontext) if defined $icontext;
                } elsif ($for->isa('Data::Identifier')) {
                    # no-op, handled above.
                } else {
                    croak 'Invalid object passed for "for"';
                }
            };
            $running = undef;
            die $@ if $@;
        }
    }

    if (defined(my $flag = delete $opts{flag})) {
        if ($flag =~ /^[a-zA-Z]{2}$/) {
            $self->{unicode} = [map {0x1F1E6 - 0x61 + ord} split //, lc $flag];
        #} elsif ($flag =~ /^[a-zA-Z]+$/) {
            #$self->{unicode} = [0x1F3F4, (map {0xE0061 - 0x61 + ord} split //, lc $flag), 0xE007F];
            #warn join(' ', map {sprintf('U+%04X', $_)} @{$self->{unicode}});
        } else {
            croak 'Invalid format for flag';
        }
    }

    {
        my $v;

        push(@mimetypes, $v)      if defined($v = delete($opts{mediasubtype}));
        push(@mimetypes, $v.'/*') if defined($v = delete($opts{mediatype}));
        push(@mimetypes, $v)      if defined($v = delete($opts{mimetype}));

        foreach my $mimetype (@mimetypes) {
            $mimetype = lc($mimetype);

            $self->{unicode} //= $for_version_info->{media_subtype}{$mimetype};
            $self->{unicode} //= $for_version_info->{media_type}{$1} if $mimetype =~ m#^([a-z]+)/#;

            last if defined $self->{unicode};
        }
    }

    if (defined(my $special = delete $opts{special})) {
        $self->{unicode} //= $for_version_info->{special}{$special =~ s/-/_/gr};
    }

    if (delete $opts{no_defaults}) {
        return undef unless defined $self->{unicode};
    } else {
        $self->{unicode} //= $for_version_info->{default_unicode};
    }

    # Attach subobjects:
    $self->attach(map {$_ => delete $opts{$_}} keys(%_types), 'weak');

    croak 'Stray options passed' if scalar keys %opts;

    return $self;
}


sub unicode {
    my ($self, @args) = @_;

    croak 'Stray options passed' if scalar @args;
    croak 'Bad object' if ref $self->{unicode};

    return $self->{unicode};
}


sub as_string {
    my ($self, @args) = @_;
    my $unicode = $self->{unicode};

    croak 'Stray options passed' if scalar @args;

    if (ref $unicode) {
        return join '' => map{chr} @{$unicode};
    } else {
        return chr($unicode);
    }
}


sub for_version {
    my ($self, @args) = @_;

    croak 'Stray options passed' if scalar @args;

    return $self->{for_version};
}


sub as {
    my ($self, $as, %opts) = @_;

    require Data::Identifier::Generate;
    $self->{identifier} //= Data::Identifier::Generate->unicode_character(unicode => $self->unicode);

    $opts{$_} //= $self->{$_} foreach keys %_types;

    return $self->{identifier}->as($as, %opts);
}


sub ise {
    my ($self, %opts) = @_;

    return ($self->{identifier} // $self->as('Data::Identifier'))->ise(%opts);
}


sub attach {
    my ($self, %opts) = @_;
    my $weak = delete $opts{weak};

    foreach my $key (keys %_types) {
        my $v = delete $opts{$key};
        next unless defined $v;
        croak 'Invalid type for key: '.$key unless eval {$v->isa($_types{$key})};
        $self->{$key} //= $v;
        croak 'Missmatch for key: '.$key unless $self->{$key} == $v;
        weaken($self->{$key}) if $weak;
    }

    croak 'Stray options passed' if scalar keys %opts;

    return $self;
}

# ---- Private helpers ----
sub _find_for_version_info {
    my ($self) = @_;
    my $for_version = $self->for_version;
    my $ret = $_for_version{$for_version};

    return $ret if defined $ret;

    if ($for_version le $VERSION) {
        foreach my $version (sort {$b cmp $a} keys %_for_version) {
            return $_for_version{$version} if $version le $for_version;
        }
    }

    croak 'Unsupported version given: '.sprintf("v%u.%u", unpack("cc", $for_version));
}

sub _merge {
    my ($d, $s, $dkey, $skey) = @_;

    $skey //= $dkey;

    if (exists $d->{$dkey}) {
        my $nd = $d->{$dkey};
        my $ns = $s->{$skey};

        foreach my $key (keys %{$ns}) {
            if (exists $nd->{$key}) {
                _merge($nd, $ns, $key);
            } else {
                $nd->{$key} = $ns->{$key};
            }
        }
    } else {
        $d->{$dkey} = $s->{$skey};
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::IconText - Work with icon text

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use Data::IconText;

Allows icon text (single character text icons) to be handled in a nice way.

=head1 METHODS

=head2 new

    my Data::IconText $icontext = Data::IconText->new(unicode => 0x1F981);
    # or:
    my Data::IconText $icontext = Data::IconText->new(raw => 'X');

Creates a new icon text object.

The icon text is tried to calculate from the options in the following order (first one wins):
C<unicode>, C<raw>, C<from>, C<for>, C<flag>, C<mediasubtype>, C<mediatype>, C<mimetype>, C<special>.
If none is found a fallback is used.

The following options are supported.

=over

=item C<unicode>

The unicode value (e.g. C<0x1F981>). May also be a string in standard format (e.g. C<'U+1F981'>).

=item C<raw>

The character as a raw perl string. Must be exactly one character long.

=item C<from>

Another object that represents the character.
If the object passed is not a L<Data::Identifier> it is passed via L<Data::Identifier/new> with C<from>.

Currently only identifiers of type unicode code point or ascii code point are supported.

See also:
L<Data::Identifier::Generate/unicode_character>.

=item C<flag>

A flag for a two letter country code (ISO 3166-1 alpha-2 codes).

=item C<for>

An object to find the icon text for.
Currently supported are objects of the following packages:
L<File::FStore::File>,
L<File::Information::Base>,
L<Data::TagDB::Tag>,
L<Data::URIID::Base>,
L<Data::Identifier>.

If the value is a plain string it is tried to be converted to a L<Data::Identifier> first.

If a L<Data::Identifier> is passed, a lookup is performed using the passed subobjects.

If the value passed has a I<small-identifier> but no I<uuid> a force load of L<Data::Identifier::Wellknown> with C<:all> may happen.
This can be be avoided by ensuring all objects that have a I<small-identifier> set also have a I<uuid> set.

=item C<mediasubtype>

The media subtype (e.g. C<audio/flac>). Only values assigned by IANA are valid.

=item C<mediatype>

The media type (e.g. C<audio>). Only values assigned by IANA are valid.

=item C<mimetype>

A low quality value that I<looks like> a mediasubtype (e.g. provided via HTTP's C<Content-type> or by type guessing modules).

=item C<special>

One of: C<directory>, C<parent-directory>, C<regular>, C<regular-not-in-pool>.

=item C<for_version>

The version of this module to use the rules for calculation of the icon text from.
Defaults to the current version of this module.
If a given version is not supported, this method C<die>s.

B<Note:>
This option alters only the rules for finding an icon text for a B<valid> input.
If an input is invalid but was erroneously accepted in an earlier version newer versions may still C<die> or behave differently.

=item C<no_defaults>

If set true and no match was found return C<undef> instead of the default character.

=back

Additionally subobjects can be attached:

=over

=item C<db>

A L<Data::TagDB> object.

=item C<extractor>

A L<Data::URIID> object.

=item C<fii>

A L<File::Information> object.

=item C<store>

A L<File::FStore> object.

=item C<weak>

Marks the value for all subobjects as weak.
If only a specific one needs needs to be weaken use L</attach>.

=back

=head2 unicode

    my $unicode = $icontext->unicode;

This returns the numeric unicode value (e.g. 0x1F981) of the icon text.
If there is no single value associated with the icon text, this method C<die>s.

=head2 as_string

    my $str = $icontext->as_string;

Gets the icon text as a perl string.

=head2 for_version

    my $version = $icontext->for_version;

The version of this module from which the rules where used.

=head2 as

    my $xxx = $icontext->as($as, %opts);

This is a proxy for L<Data::Identifier/as>.

This method automatically adds all attached subobjects (if not given via C<%opts>).

=head2 ise

    my $ise = $icontext->ise(%opts);

THis is a proxy for L<Data::Identifier/ise>.

=head2 attach

    $icontext->attach(key => $obj, ...);
    # or:
    $icontext->attach(key => $obj, ..., weak => 1);

Attaches objects of the given type.
Takes the same list of objects as L</new>.

If an object is allready attached for the given key this method C<die>s unless the object is actually the same.

If C<weak> is set to a true value the object reference becomes weak.

Returns itself.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
