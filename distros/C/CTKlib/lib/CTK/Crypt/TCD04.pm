package CTK::Crypt::TCD04;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Crypt::TCD04 - TCD04 Crypt backend

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use CTK::Crypt::TCD04;

    my $tcd04 = CTK::Crypt::TCD04->new;

    my $code   = $tcd04->tcd04c('u');   # 1 char
    my $decode = $tcd04->tcd04d($code); # 1 word

    print $tcd04->decrypt( $tcd04->encrypt( 'Hello, World!' ) );

=head1 DESCRIPTION

TCD04 Crypt backend. Simple cryptografy's algorythm of D&D Corporation

=head1 METHODS

=over 8

=item B<new>

    my $tcd04 = CTK::Crypt::TCD04->new;

=item B<decrypt>

    $tcd04->decrypt( $tcd04->encrypt( 'Hello, World!' ) );

=item B<encrypt>

    my $words = $tcd04->encrypt( 'Hello, World!' );

=item B<tcd04c>

    my $code = $tcd04->tcd04c('u');   # 1 char

=item B<tcd04d>

    my $decode = $tcd04->tcd04d($code); # 1 word

=back

=head1 HISTORY

=over 8

=item B<1.00 / 1.00.0001 08.01.2007>

Init version on base mod_main 1.00.0002

=item B<1.01 Fri 26 Apr 12:05:51 MSK 2019>

Was moved from MPMinus project

=back

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Crypt>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses>

=cut

use vars qw/ $VERSION /;
$VERSION = 1.02;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self
}
sub encrypt {
    my $self = shift;
    my $string = shift;
    return '' if length $string == 0;
    return join "",map {$_=$self->tcd04c($_)} split //,$string;
}
sub decrypt {
    my $self = shift;
    my $string = shift;
    return '' if length $string == 0;
    my $ch2 ='';
    my $outstr = '';
    foreach (split //,$string) {
        $ch2.=$_;
        if (length($ch2) == 2) {
            $outstr.=$self->tcd04d($ch2);
            $ch2='';
        }
    }
    return $outstr;
}
sub tcd04c {
    my $self = shift;
    my $ch = shift;
    return '' if length $ch != 1;
    my $kod1 = ord($ch)>>4;
    my $kod2 = (ord($ch)&(2**4-1));
    return chr($kod1>0?int(rand 16)*15 + $kod1:0).chr($kod2>0?int(rand 16)*15 + $kod2:0);
}
sub tcd04d {
    my $self = shift;
    my $ch2 = shift;
    return '' if length $ch2 != 2;
    my ($kod1,$kod2) = map {(((ord($_)%15)==0)&&ord($_)>0)?15:ord($_)%15} split //,$ch2;
    return chr($kod1<<4|$kod2); #return sprintf "%X", $kod1<<4|$kod2;
}

1;

__END__
