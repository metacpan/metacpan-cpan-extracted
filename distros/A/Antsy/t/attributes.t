use utf8;
use Test::More;

my $class = 'Antsy';
BAIL_OUT( "Bail out! $class did not compile\n" ) unless use_ok( $class );

my %attributes = (
	# NAME             SGR
	reset            =>  0,
	reset_all        =>  0,
	normal           =>  0,
	bold             =>  1,
	dark             =>  2,
	dim              =>  2,
	faint            =>  2,
	italic           =>  3,
	underline        =>  4,
	blink            =>  5,
	rapid_blink      =>  6,
	reverse          =>  7,
	inverse          =>  7,
	reverse_video    =>  7,
	conceal          =>  8,
	hidden           =>  8,
	strikethrough    =>  9,
	normal_intensity => 22,
	no_bold          => 22,
	no_dark          => 22,
	no_dim           => 22,
	no_faint         => 22,
	no_italic        => 23,
	no_underline     => 24,
	no_blink         => 25,
	no_reverse       => 27,
	no_inverse       => 27,
	no_reverse_video => 27,
	reveal           => 28,
	no_strikethrough => 29,
	text_default     => 39,
	bg_default       => 49,
	);

# These have the same names as Perl builtins, so Antsy defines them
# but must not export them.
my %shadows_builtin = map { $_ => 1 } qw( reset reverse );

my %exportable = map { $_ => 1 } @Antsy::EXPORT_OK;

foreach my $name ( sort keys %attributes ) {
	subtest $name => sub {
		my $code = $class->can( $name );
		ok( defined $code, "$name is defined" ) or return;
		if( $shadows_builtin{$name} ) {
			ok( ! $exportable{$name}, "$name is not in \@EXPORT_OK" );
			my @tags = grep { grep { $_ eq $name } $Antsy::EXPORT_TAGS{$_}->@* } keys %Antsy::EXPORT_TAGS;
			is( scalar @tags, 0, "$name is not in any export tag" );
			}
		else {
			ok( $exportable{$name}, "$name is in \@EXPORT_OK" );
			}
		is( $code->(), "\e[$attributes{$name}m", "$name is SGR $attributes{$name}" );
		};
	}

subtest 'importing :all leaves the builtins alone' => sub {
	my @reversed = eval q{
		package Local::ImportAll;
		use Antsy qw(:all);
		reverse 1, 2, 3;
		};
	is( $@, '', 'code that imports :all compiles and runs' );
	is( "@reversed", '3 2 1', 'reverse is still the builtin' );
	};

done_testing();

__END__

=encoding utf8

=head1 NAME

t/attributes.t - check Antsy's text attribute functions

=head1 SYNOPSIS

	$ prove -l t/attributes.t

=head1 DESCRIPTION

Checks that each function that turns a text attribute on or off (such
as C<bold>, C<no_italic>, C<reveal>, and C<text_default>) is defined, is
in C<@EXPORT_OK>, and returns the right SGR sequence.

C<reset> and C<reverse> share their names with Perl builtins, so they
must be defined but must not be exportable. The test also checks that a
program that imports C<:all> still gets Perl's own C<reverse>.

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/briandfoy/antsy

=head1 AUTHOR

Claude Opus 5.5 (Anthropic), author

brian d foy, C<< <briandfoy@pobox.com> >>, supervisor

=head1 COPYRIGHT AND LICENSE

Copyright © 2026, brian d foy C<< <briandfoy@pobox.com> >>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut
