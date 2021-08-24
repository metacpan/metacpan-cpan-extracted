package Config::XrmDatabase::Constants;

# ABSTRACT: Constants that won't change.

use strict;
use warnings;

our $VERSION = '0.02';

use Exporter 'import';

my %CONSTANTS;

BEGIN {
    %CONSTANTS = (
        TIGHT     => '.',
        SINGLE    => '?',
        LOOSE     => '*',
        VALUE     => '!!VALUE',
        MATCH_COUNT => '!!MATCH_COUNT',
    );
}

use constant \%CONSTANTS;

{
    no strict 'refs'; ## no critic(ProhibitNoStrict)
    *{$_} = \( $CONSTANTS{$_} ) for keys %CONSTANTS
}

our %EXPORT_TAGS = (
    scalar    => [ map "\$$_", keys( %CONSTANTS ) ],
    constants => [ keys( %CONSTANTS ) ],
);

our @EXPORT_OK = ( map { @$_ } values %EXPORT_TAGS );

$EXPORT_TAGS{all} = \@EXPORT_OK;

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Config::XrmDatabase::Constants - Constants that won't change.

=head1 VERSION

version 0.02

=for Pod::Coverage TIGHT
SINGLE
LOOSE
VALUE
MATCH_COUNT

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-config-xrmdatabase@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Config-XrmDatabase

=head2 Source

Source is available at

  https://gitlab.com/djerius/config-xrmdatabase

and may be cloned from

  https://gitlab.com/djerius/config-xrmdatabase.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Config::XrmDatabase|Config::XrmDatabase>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
