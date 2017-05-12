package Clone::Util;

our $DATE = '2016-03-10'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use Function::Fallback::CoreOrPP qw(clone);

use Exporter qw(import);
our @EXPORT_OK = qw(clone modclone sclone);

sub modclone(&$;@) {
    my $code = shift;
    my $data = shift;
    my $clone = clone($data);
    local $_ = $clone;
    $code->($clone);
    if (@_ || wantarray) {
        return ($clone, @_);
    } else {
        return $clone;
    }
}

sub sclone($) {
    my $data = shift;
    my $ref = ref($data);
    if ($ref eq 'ARRAY') {
        return [@$data];
    } elsif ($ref eq 'HASH') {
        return {%$data};
    } else {
        die "Cannot shallow clone $data ($ref)";
    }
}

1;
# ABSTRACT: Utilities related to cloning

__END__

=pod

=encoding UTF-8

=head1 NAME

Clone::Util - Utilities related to cloning

=head1 VERSION

This document describes version 0.03 of Clone::Util (from Perl distribution Clone-Util), released on 2016-03-10.

=head1 SYNOPSIS

 use Clone::Util qw(modclone sclone);

 my $row = {name=>'ujang', gender=>'m', nationality=>'id'};
 my $table = [
     $row,
     modclone { $_->{name} = 'budi' } $row,
     modclone { $_->{name} = 'asep' } $row,
     modclone { $_->{name} = 'rini'; $_->{gender} = 'f' } $row,
 ];

 my $shallow_clone = sclone($data);

=head1 FUNCTIONS

None of the functions are exported by default, but they are exportable.

=head2 clone($data) => $cloned

This is just re-exported L<Function::Fallback::CoreOrPP>'s C<clone()>.

=head2 modclone(\&code, $data) => $clone

Clone C<$data> and then run code. Code will be given the clone of data. For
convenience, C<$_> will also be localized and set to the clone of data. So you
can access the clone using C<$_> in addition to C<$_[0]>.

=head2 sclone($data) => $clone

Shallow-clone C<$data>, which must be an arrayref or a hashref. Shallow cloning
means only copying the first level of data.

 my $array = [0,1,2,[3]];
 my $clone = sclone $array; # => [0,1,2,[3]], but [3] is still the same reference

 $clone->[3][0] = "three"; # $clone as well as $array become [0,1,2,["three"]]

 $clone->[0] = "zero"; # $clone becomes ["zero",1,...] but $array still [0,1,...]

You can perform shallow copying trivially yourself using:

 my $cloned_array = [@$array];
 my $cloned_hash  = {%$hash};

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Clone-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Clone-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Clone-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Function::Fallback::CoreOrPP>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
