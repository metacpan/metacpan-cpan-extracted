package Acme::MetaSyntactic::morning_musume;
use strict;
use Acme::MetaSyntactic::MultiList;
use Acme::MorningMusume;
our @ISA     = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '1.002';

	my $musume = Acme::MorningMusume->new;
	#my @all      = map { $_->name_en } $musume->members;
	my @active   = map { $_->name_en } $musume->members('active');
	my @graduate = map { $_->name_en } $musume->members('graduate');

__PACKAGE__->init(
    {   default => 'active',
        names   => {
			active => join (' ', @active),
			graduate => join (' ', @graduate),
        },
    }
);

1;

=head1 NAME

Acme::MetaSyntactic::morning_musume - The theme of Morning Musume

=head1 DESCRIPTION

The names (English transcription) of the Japanese Pop Idols Morning Musume

The list is provided by the module L<Acme::MorningMusume> from KENTARO.

Two themes are available: active (default), graduate

=head1 INSTALL

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Alternatively, to install with ExtUtils::MakeMaker, you can use the following commands:

    perl Makefile.PL
    make
    make test
    make install

=head1 CONTRIBUTOR

Laurent Boivin (elbeho)

=head1 CHANGES

=over 4

=item *

2013-06-16 - v1.002

Fix missing dependancies

2012-10-17 - v1.001

Fix documentation (pod and readme)

=item *

2012-10-13 - v1.000

First version of my first module

=back

=head1 SEE ALSO

L<Acme::MorningMusume>,
L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=head1 COPYRIGHT

Copyright (C) 2012-2013 Laurent Boivin (elbeho)

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

