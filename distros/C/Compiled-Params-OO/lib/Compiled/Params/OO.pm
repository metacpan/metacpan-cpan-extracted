package Compiled::Params::OO;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.05';

use Type::Params qw/compile_named_oo compile/;
use Types::Standard qw/CodeRef/;
use base 'Import::Export';

our %EX = (
	cpo => [qw/all/]
);

sub cpo {
	my (%params, %compile, %build) = @_;
	for my $key (keys %params) {
		$compile{$key} = CodeRef;
		$build{$key} = ref $params{$key} eq 'HASH' 
			? compile_named_oo( map { ref $params{$key}{$_} eq 'HASH' 
				? ($_ => delete $params{$key}{$_}{type} => $params{$key}{$_})
				: ($_ => $params{$key}{$_})
			} keys %{$params{$key}})
			: compile(@{$params{$key}});
	}
	return compile_named_oo(%compile)->(%build);
}

1;

__END__

=head1 NAME

Compiled::Params::OO - compiled params object oriented.

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

	package Life;
	use Compiled::Params::OO qw/cpo/;
	use Types::Standard qw/Str Int/;
	our $validate;
	BEGIN {
		$validate = cpo(
			time => {
				testing => Int,
				me => {
					type => Str,
					default => sub {
						return 'insanity';
					}
				}
			},
			circles => [Str, Int]
		);
	}
	 
	sub new {
		return bless {}, $_[0];
	}
	 
	sub time {
		my $self = shift;
		my $params = $validate->time->(
			testing => 16000000,
		);
		return $params->me;
	}
	 
	sub circles {
		my $self = shift;
		my @params = $validate->circles->('dreaming', 211000000);
		return \@params;
	}

	1;

=head1 EXPORT

=head2 cpo

This package exports a single sub routine cpo (compiled params object) that is a wrapper around Type::Params
compile and compile_named_oo. It accepts a list where the key is the named accessor and the value is the params
that will be validated. The value can either be a hash reference to build a Type::Params::compile_name_oo call 
or an array reference of Type::Tiny Objects that will be passed directly to Type::Params::compile. If passed as 
a hash reference the value can either be a Type::Tiny object or another hash reference with two keys representing 
a type and default value.

	$validate = cpo(
		time => {
			testing => Int,
			me => {
				type => Str,
				default => sub {
					return 'house of lords';
				}
			}
		},
		circles => [Str, { default => sub { 'lucky buddha' } }, Int]
	);

=cut

=head1 Examples

=cut

=head2 Optional params

The following example demonstrates how to validate optional parameters.

	my $validate = cpo(
		new_pdf => {
			name => Optional->of(Str),
			page_size => {
				type => Optional->of(Enum[qw/A1 A2 A3 A4 A5/]), 
				default => sub { 'A4' },
			},
			pages => Optional->of(ArrayRef),
			num => {
				type => Optional->of(Int), 
				default => sub { 0 } 
			},
			page_args => Optional->of(HashRef), 
			plugins => Optional->of(ArrayRef) 
		},
		end_pdf => [Str, Optional->of(Int)]
	);

=cut

=head1 AUTHOR

lnation, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-compiled-params-oo at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Compiled-Params-OO>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Compiled::Params::OO

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Compiled-Params-OO>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Compiled-Params-OO>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Compiled-Params-OO>

=item * Search CPAN

L<https://metacpan.org/release/Compiled-Params-OO>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by lnation.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Compiled::Params::OO
