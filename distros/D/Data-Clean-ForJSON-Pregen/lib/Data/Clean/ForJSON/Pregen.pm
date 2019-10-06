package Data::Clean::ForJSON::Pregen;

our $DATE = '2019-09-08'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       clean_for_json_in_place
                       clone_and_clean_for_json
               );

sub _clone {
    if (eval { require Data::Clone; 1 }) {
        Data::Clone::clone(@_);
    } else {
        require Clone::PP;
        Clone::PP::clone(@_);
    }
}

 # generated with Data::Clean version 0.505, Data::Clean::ForJSON version 0.394
 sub clean_for_json_in_place { 
 state $sub_unbless = sub {     my $ref = shift;
 
     my $r = ref($ref);
     # not a reference
     return $ref unless $r;
 
     # return if not a blessed ref
     my ($r2, $r3) = "$ref" =~ /(.+)=(.+?)\(/
         or return $ref;
 
     if ($r3 eq 'HASH') {
         return { %$ref };
     } elsif ($r3 eq 'ARRAY') {
         return [ @$ref ];
     } elsif ($r3 eq 'SCALAR') {
         return \( my $copy = ${$ref} );
     } else {
         die "Can't handle $ref";
     }
  };
 my $data = shift;
 state %refs;
 state $ctr_circ;
 state $process_array;
 state $process_hash;
 if (!$process_array) { $process_array = sub { my $a = shift; for my $e (@$a) { my $ref=ref($e);
     if ($ref && $refs{ $e }++) { if (++$ctr_circ <= 1) { $e = _clone($e); redo } else { $e = 'CIRCULAR'; $ref = '' } }
     elsif ($ref eq 'DateTime') { $e = $e->epoch; $ref = ref($e) }
     elsif ($ref eq 'Math::BigInt') { $e = $e->bstr; $ref = ref($e) }
     elsif ($ref eq 'Regexp') { $e = "$e"; $ref = "" }
     elsif ($ref eq 'SCALAR') { $e = ${ $e }; $ref = ref($e) }
     elsif ($ref eq 'Time::Moment') { $e = $e->epoch; $ref = ref($e) }
     elsif ($ref eq 'version') { $e = "$e"; $ref = "" }
     elsif (Scalar::Util::blessed($e)) { $e = $sub_unbless->($e); $ref = ref($e) }
     my $reftype=Scalar::Util::reftype($e)//"";
     if ($reftype eq "ARRAY") { $process_array->($e) }
     elsif ($reftype eq "HASH") { $process_hash->($e) }
     elsif ($ref) { $e = $ref; $ref = "" }
 } } }
 if (!$process_hash) { $process_hash = sub { my $h = shift; for my $k (keys %$h) { my $ref=ref($h->{$k});
     if ($ref && $refs{ $h->{$k} }++) { if (++$ctr_circ <= 1) { $h->{$k} = _clone($h->{$k}); redo } else { $h->{$k} = 'CIRCULAR'; $ref = '' } }
     elsif ($ref eq 'DateTime') { $h->{$k} = $h->{$k}->epoch; $ref = ref($h->{$k}) }
     elsif ($ref eq 'Math::BigInt') { $h->{$k} = $h->{$k}->bstr; $ref = ref($h->{$k}) }
     elsif ($ref eq 'Regexp') { $h->{$k} = "$h->{$k}"; $ref = "" }
     elsif ($ref eq 'SCALAR') { $h->{$k} = ${ $h->{$k} }; $ref = ref($h->{$k}) }
     elsif ($ref eq 'Time::Moment') { $h->{$k} = $h->{$k}->epoch; $ref = ref($h->{$k}) }
     elsif ($ref eq 'version') { $h->{$k} = "$h->{$k}"; $ref = "" }
     elsif (Scalar::Util::blessed($h->{$k})) { $h->{$k} = $sub_unbless->($h->{$k}); $ref = ref($h->{$k}) }
     my $reftype=Scalar::Util::reftype($h->{$k})//"";
     if ($reftype eq "ARRAY") { $process_array->($h->{$k}) }
     elsif ($reftype eq "HASH") { $process_hash->($h->{$k}) }
     elsif ($ref) { $h->{$k} = $ref; $ref = "" }
 } } }
 %refs = (); $ctr_circ=0;
 for ($data) { my $ref=ref($_);
     if ($ref && $refs{ $_ }++) { if (++$ctr_circ <= 1) { $_ = _clone($_); redo } else { $_ = 'CIRCULAR'; $ref = '' } }
     elsif ($ref eq 'DateTime') { $_ = $_->epoch; $ref = ref($_) }
     elsif ($ref eq 'Math::BigInt') { $_ = $_->bstr; $ref = ref($_) }
     elsif ($ref eq 'Regexp') { $_ = "$_"; $ref = "" }
     elsif ($ref eq 'SCALAR') { $_ = ${ $_ }; $ref = ref($_) }
     elsif ($ref eq 'Time::Moment') { $_ = $_->epoch; $ref = ref($_) }
     elsif ($ref eq 'version') { $_ = "$_"; $ref = "" }
     elsif (Scalar::Util::blessed($_)) { $_ = $sub_unbless->($_); $ref = ref($_) }
     my $reftype=Scalar::Util::reftype($_)//"";
     if ($reftype eq "ARRAY") { $process_array->($_) }
     elsif ($reftype eq "HASH") { $process_hash->($_) }
     elsif ($ref) { $_ = $ref; $ref = "" }
 }
 $data
  }


sub clone_and_clean_for_json {
    my $data = _clone(shift);
    clean_for_json_in_place($data);
}

1;
# ABSTRACT: Clean data so it is safe to output to JSON

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Clean::ForJSON::Pregen - Clean data so it is safe to output to JSON

=head1 VERSION

This document describes version 0.001 of Data::Clean::ForJSON::Pregen (from Perl distribution Data-Clean-ForJSON-Pregen), released on 2019-09-08.

=head1 SYNOPSIS

 use Data::Clean::ForJSON::Pregen qw(clean_for_json_in_place clone_and_clean_for_json);

 clean_for_json_in_place($data);
 $cleaned = clone_and_clean_for_json($data);

=head1 DESCRIPTION

This has the same functionality as L<Data::Clean::ForJSON> except that the code
to perform the cleaning is pre-generated, so we no longer need L<Data::Clean> or
L<Data::Clean::ForJSON> during runtime.

=head1 FUNCTIONS

None of the functions are exported by default.

=head2 clean_for_json_in_place($data)

=head2 clone_and_clean_for_json($data) => $cleaned

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Clean-ForJSON-Pregen>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Clean-ForJSON-Pregen>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Clean-ForJSON-Pregen>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Clean::ForJSON>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
