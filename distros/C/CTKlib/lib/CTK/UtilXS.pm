package CTK::UtilXS;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::UtilXS - CTK XS Utilities

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use CTK::UtilXS qw/shred wipe/;

    shred( "/path/to/file" ) or die("Can't shred file");
    wipe( "/path/to/file" ) or die("Can't wipe file");

=head1 DESCRIPTION

CTK XS Utilities

=head2 shred

    shred( "/path/to/file" ) or die("Can't shred file");

Wipes file and remove it.

Do a more secure overwrite of given files or devices, to make it harder for even very
expensive hardware probing to recover the data.

=head2 wipe

    wipe( "/path/to/file" ) or die("Can't wipe file");

Wipes file

=head2 wipef, xstest, xsver

Internal use only

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK::Util>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses>

=cut

use vars qw($VERSION @EXPORT_OK);
$VERSION = '1.00';

use base qw/ Exporter /;
@EXPORT_OK = qw/ xstest shred wipe /;

use XSLoader;
XSLoader::load("CTK", $VERSION);

use Carp;
use File::Spec::Functions qw/ splitpath catpath /;
use File::Copy qw/ move /;

sub wipe($) {
    my $fn = shift // '';
    my $sz = (length($fn) && -e $fn) ? (-s $fn) : 0;
    return 0 unless $sz;
    return 0 unless wipef($fn, $sz);
    return 1;
}
sub shred($) {
    my $fn = shift // '';
    my $sz = (length($fn) && -e $fn) ? (-s $fn) : 0;
    return 0 unless $sz;
    return 0 unless wipef($fn, $sz);

    my ($vol,$dir,$file) = splitpath( $fn );

    my $nn = '';
    for (my $i = 0; $i < 5; $i++) {
        $nn = catpath($vol, $dir, sprintf("%s.%s", _sr(8), _sr(3)));
        last unless -e $nn;
        $nn = '';
    }
    unless ($nn) {
        carp("Can't rename file \"$file\". Undefined new file");
        return 0;
    }

    move($fn, $nn) or do { carp("Can't move file \"$file\""); return 0; };
    unlink($nn) or do { carp("Can't unlink file \"$nn\": $!"); return 0; };
    return 1;
}
sub _sr {
    my $l = shift || return '';
    my @as = ('a'..'z','A'..'Z');
    my $rst = '';
    $rst .= $as[(int(rand($#as+1)))] for (1..$l);
    return $rst;
}

1;

__END__

perl -Iblib/lib -Iblib/arch t/03-xsutil.t
