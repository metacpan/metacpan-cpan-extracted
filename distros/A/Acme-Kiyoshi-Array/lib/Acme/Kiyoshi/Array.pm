package Acme::Kiyoshi::Array;

use utf8;
use strict;
use warnings;

our $VERSION = "0.02";

BEGIN {
    *CORE::GLOBAL::push = sub(\@@) {
		my ($array, $value) = @_;
        my $res = CORE::push(@$array, $value);

		if (scalar(@$array) >= 5 && join('', @$array[-5..-1]) =~ /ズンズンズンズンドコ/) {
        	$res = CORE::push(@$array, "キ・ヨ・シ！");
		}

        return $res;
    };  
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::Kiyoshi::Array - It's new ZUNDOKO Kiyoshi Array

=head1 SYNOPSIS

    use Acme::Kiyoshi::Array;

    my @ary = ();
    push @ary, "ズン";
    push @ary, "ズン";
    push @ary, "ズン";
    push @ary, "ズン";
    push @ary, "ドコ";
    print @ary;


=head1 DESCRIPTION

Acme::Kiyoshi::Array is ...

=head1 LICENSE

Copyright (C) Masaaki Saito.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masaaki Saito E<lt>masakyst.public@gmail.comE<gt>

=cut
