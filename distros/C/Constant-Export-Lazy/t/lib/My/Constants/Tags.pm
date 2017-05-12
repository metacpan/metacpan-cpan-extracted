package My::Constants::Tags;
use v5.10;
use strict;
use warnings;
use Constant::Export::Lazy (
    constants => {
        KG_TO_MG => sub { 10**6 },
        SQRT_2 => {
            call    => sub { sqrt(2) },
            options => {
                stash => {
                    export_tags => [ qw/:math/ ],
                },
            },
        },
        PI => {
            call    => sub { atan2(1,1) * 4 },
            options => {
                stash => {
                    export_tags => [ qw/:math/ ],
                },
            },
        },
        map(
            {
                my $t = $_;
                +(
                    $_ => {
                        call => sub { $t },
                        options => {
                            stash => {
                                export_tags => [ qw/:alphabet/ ],
                            },
                        }
                    }
                )
            }
            "A".."Z"
        ),
    },
    options => {
        buildargs => sub {
            my ($import_args, $constants) = @_;

            state $export_tags = do {
                my %export_tags;
                for my $constant (keys %$constants) {
                    my @export_tags = @{$constants->{$constant}->{options}->{stash}->{export_tags} || []};
                    push @{$export_tags{$_}} => $constant for @export_tags;
                }
                \%export_tags;
            };

            my @gimme = map {
                /^:/ ? @{$export_tags->{$_}} : $_
            } @$import_args;

            return \@gimme;
        },
    },
);

1;
