package Data::Clean::FromJSON::Pregen;

our $DATE = '2019-09-08'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       clean_from_json_in_place
                       clone_and_clean_from_json
               );

sub _clone {
    if (eval { require Data::Clone; 1 }) {
        Data::Clone::clone(@_);
    } else {
        require Clone::PP;
        Clone::PP::clone(@_);
    }
}

 # generated with Data::Clean version 0.505, Data::Clean::FromJSON version 0.394
 sub clean_from_json_in_place { 
 my $data = shift;
 state $process_array;
 state $process_hash;
 if (!$process_array) { $process_array = sub { my $a = shift; for my $e (@$a) { my $ref=ref($e);
     if ($ref eq 'JSON::PP::Boolean') { $e = ${ $e } ? 1:0; $ref = '' }
     if ($ref eq 'ARRAY') { $process_array->($e) }
     elsif ($ref eq 'HASH') { $process_hash->($e) }
 } } }
 if (!$process_hash) { $process_hash = sub { my $h = shift; for my $k (keys %$h) { my $ref=ref($h->{$k});
     if ($ref eq 'JSON::PP::Boolean') { $h->{$k} = ${ $h->{$k} } ? 1:0; $ref = '' }
     if ($ref eq 'ARRAY') { $process_array->($h->{$k}) }
     elsif ($ref eq 'HASH') { $process_hash->($h->{$k}) }
 } } }
 for ($data) { my $ref=ref($_);
     if ($ref eq 'JSON::PP::Boolean') { $_ = ${ $_ } ? 1:0; $ref = '' }
     if ($ref eq 'ARRAY') { $process_array->($_) }
     elsif ($ref eq 'HASH') { $process_hash->($_) }
 }
 $data
  }


sub clone_and_clean_from_json {
    my $data = _clone(shift);
    clean_from_json_in_place($data);
}

1;
# ABSTRACT: Clean data from JSON encoder

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Clean::FromJSON::Pregen - Clean data from JSON encoder

=head1 VERSION

This document describes version 0.001 of Data::Clean::FromJSON::Pregen (from Perl distribution Data-Clean-FromJSON-Pregen), released on 2019-09-08.

=head1 SYNOPSIS

 use Data::Clean::FromJSON::Pregen qw(clean_from_json_in_place clone_and_clean_from_json);

 clean_from_json_in_place($data);
 $cleaned = clone_and_clean_from_json($data);

=head1 DESCRIPTION

This has the same functionality as L<Data::Clean::FromJSON> except that the code
to perform the cleaning is pre-generated, so we no longer need L<Data::Clean> or
L<Data::Clean::FromJSON> during runtime.

=head1 FUNCTIONS

None of the functions are exported by default.

=head2 clean_from_json_in_place($data)

=head2 clone_and_clean_from_json($data) => $cleaned

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Clean-FromJSON-Pregen>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Clean-FromJSON-Pregen>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Clean-FromJSON-Pregen>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Clean::FromJSON>

L<Data::Clean::ForJSON::Pregen>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
