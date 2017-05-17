use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use IO::String ();

sub implementations {
	qw(
		Benchmark::Featureset::ParamCheck::Implementation::DataValidator::Moose
		Benchmark::Featureset::ParamCheck::Implementation::DataValidator::Mouse
		Benchmark::Featureset::ParamCheck::Implementation::DataValidator::TypeTiny
		Benchmark::Featureset::ParamCheck::Implementation::MXPV::Moose
		Benchmark::Featureset::ParamCheck::Implementation::MXPV::TypeTiny
		Benchmark::Featureset::ParamCheck::Implementation::ParamsCheck::Perl
		Benchmark::Featureset::ParamCheck::Implementation::ParamsCheck::TypeTiny
		Benchmark::Featureset::ParamCheck::Implementation::Perl
		Benchmark::Featureset::ParamCheck::Implementation::PV
		Benchmark::Featureset::ParamCheck::Implementation::PV::TypeTiny
		Benchmark::Featureset::ParamCheck::Implementation::PVC::Moose
		Benchmark::Featureset::ParamCheck::Implementation::PVC::Specio
		Benchmark::Featureset::ParamCheck::Implementation::PVC::TypeTiny
		Benchmark::Featureset::ParamCheck::Implementation::RefUtilXS
		Benchmark::Featureset::ParamCheck::Implementation::TypeParams
	);
}

my $io = 'IO::String'->new;

my %trivial = ( integer => 0, hashes => [], object => $io );
my %complex = (
	integer => 1_234_567_890,
	hashes  => [ map { +{} } 1..10 ],
	object => $io,
);

sub trivial_named_data { \%trivial }
sub complex_named_data { \%complex }

my @trivial = map $trivial{$_}, qw(integer hashes object);
my @complex = map $complex{$_}, qw(integer hashes object);

sub trivial_positional_data { \@trivial }
sub complex_positional_data { \@complex }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Benchmark::Featureset::ParamCheck - compare different parameter validation modules

=head1 SYNOPSIS

  use Benchmark::Featureset::ParamCheck;
  use Module::Runtime qw(use_module);
  
  my @impl     = Benchmark::Featureset::ParamCheck->implementations;
  my $testdata = Benchmark::Featureset::ParamCheck->trivial_named_data;
  
  for my $i (@impl) {
    # Check the data 10,000 times.
    use_module($i)->run_named_check(10_000, $testdata);
  }

=head1 DESCRIPTION

A whole bunch of implementations for sub paramater checking.

Each implementation provides a method to check a hash of the form shown
in the example. It should have three keys, 'integer' (value should be
an integer), 'hashes' (value should be an arrayref of hashrefs), and
'object' (value should be an object with C<print> and C<close> methods).

This is intended for benchmarking.

=head2 Class Methods

=over

=item * C<implementations>

List of implementations. Each implementation is a subclass of
Benchmark::Featureset::ParamCheck::Base

=item * C<trivial_named_data>, C<trivial_positional_data>

Returns trivial test data.

=item * C<complex_named_data>, C<complex_positional_data>

Returns complex test data.

=back

=head2 Benchmark::Featureset::ParamCheck::Base

This class provides the following class methods:

=over

=item * C<< accept_array >>

=item * C<< accept_arrayref >>

=item * C<< accept_hash >>

=item * C<< accept_hashref >>

=item * C<< run_named_check($times, %parameters) >>, C<< run_named_check($times, \%parameters) >>

=item * C<< run_postional_check($times, @parameters) >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Benchmark-Featureset-ParamCheck>.

=head1 SEE ALSO

B<< Parameter validation libraries: >>
L<Data::Validator>,
L<MooseX::Params::Validate>,
L<Params::Check>,
L<Params::Validate>,
L<Params::ValidationCompiler>,
L<Ref::Util::XS>,
L<Type::Params>.

B<< Type constraint libraries: >>
L<Moose>,
L<Mouse>,
L<Specio>,
L<Type::Tiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

