use utf8;
use Test::More;

my $class = 'Antsy';
BAIL_OUT( "Bail out! $class did not compile\n" ) unless use_ok( $class );

my @basic_colors = qw( black red green yellow blue magenta cyan white );
my @extra_colors = qw( orange );

# gray and grey are aliases for bright black, so they're bright colors
my @gray_names = map { ( "text_$_", "bg_$_" ) } qw( gray grey );

my @names = (
	( map { ( "text_$_", "bg_$_", "text_bright_$_", "bg_bright_$_" ) } @basic_colors ),
	( map { ( "text_$_", "bg_$_" ) } @extra_colors ),
	@gray_names,
	);
my %is_bright = map { $_ => 1 } @gray_names, grep { /_bright_/ } @names;

my %exportable = map { $_ => 1 } @Antsy::EXPORT_OK;

foreach my $name ( @names ) {
	subtest $name => sub {
		ok( defined &{"${class}::$name"}, "$name is defined" );
		ok( $exportable{$name}, "$name is in \@EXPORT_OK" );

		my $code = $class->can( $name ) or return;
		like( $code->(), qr/\A\e\[[0-9;]+m\z/, "$name returns an SGR sequence" );
		};
	}

subtest 'export tags' => sub {
	my %in_tag;
	foreach my $tag ( keys %Antsy::EXPORT_TAGS ) {
		$in_tag{$tag}{$_}++ for $Antsy::EXPORT_TAGS{$tag}->@*;
		}

	foreach my $name ( @names ) {
		my( $tag ) = $name =~ /\A(text|bg)_/;
		ok( $in_tag{$tag}{$name}, "$name is in :$tag" );
		ok( $in_tag{all}{$name},  "$name is in :all" );
		next unless $is_bright{$name};
		ok( $in_tag{bright}{$name}, "$name is in :bright" );
		}

	ok( ! exists $Antsy::EXPORT_TAGS{'%s'}, 'there is no %s tag' );

	my $text_red = eval q{
		package Local::ImportText;
		use Antsy qw(:text);
		text_red();
		};
	is( $text_red, "\e[31m", 'importing :text provides text_red' );
	};

subtest 'no bare color names with a leading underscore' => sub {
	foreach my $color ( @basic_colors ) {
		my $name = "_$color";
		ok( ! defined &{"${class}::$name"}, "$name is not defined" );
		ok( ! $exportable{$name}, "$name is not in \@EXPORT_OK" );
		}
	};

done_testing();

__END__

=encoding utf8

=head1 NAME

t/colors.t - check that Antsy defines and exports every color function

=head1 SYNOPSIS

	$ prove -l t/colors.t

=head1 DESCRIPTION

For each of the eight basic colors, checks the C<text_>, C<bg_>,
C<text_bright_>, and C<bg_bright_> functions, and for each secondary
color (orange), checks the C<text_> and C<bg_> functions. Each one must
be defined, be listed in C<@EXPORT_OK>, and return an SGR escape
sequence (C<CSI ... m>).

It checks that each color is in the right export tag: C<:text> or
C<:bg>, C<:all>, and C<:bright> for the bright colors, and that
importing C<:text> really provides the text colors.

It also checks that there are no functions such as C<_black> and
C<_white>, which an old bug defined and exported, and which emitted
attribute codes (reset, bold, and so on) instead of colors.

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
