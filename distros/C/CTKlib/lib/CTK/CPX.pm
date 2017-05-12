package CTK::CPX; # $Id: CPX.pm 191 2017-04-28 18:29:58Z minus $
use Moose;
=head1 NAME

CTK::CPX - Converter between windows-1251 and your terminal encoding

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use CTK::CPX;
    tie *CP866, 'CTK::CPX'; # cp866 as default
    print CP866 "Privet","\n";

=head1 DESCRIPTION

Converter between windows-1251 and your terminal encoding.

No public subroutines

=head1 SEE ALSO

C<perl>, L<Moose>

=head1 DIAGNOSTICS

The usual warnings if it can't read or write the files involved.

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut
use namespace::autoclean;
extends qw/Tie::Handle/;
use Encode;
our $VERSION = '1.02';
sub TIEHANDLE {
    shift;
    my $incp = shift || 'cp866';
    return bless [$incp], __PACKAGE__;
}
sub PRINT {
    my $self = shift;
    my $cp = $self->[0] || 'cp866';
    for (@_) {
        print(STDOUT Encode::encode($cp, Encode::decode('Windows-1251',$_))) if defined;
    }
    1;
}
no Moose;
# Force constructor inlining
__PACKAGE__->meta->make_immutable(inline_constructor => 0); # replace_constructor => 1
1;
