package Data::Localize::Format::Sprintf;
$Data::Localize::Format::Sprintf::VERSION = '0.001';
use Moo;

extends 'Data::Localize::Format';

sub format
{
	my ($self, $lang, $value, @args) = @_;

	return sprintf $value, @args;
}

1;

__END__

=head1 NAME

Data::Localize::Format::Sprintf - Format strings using regular sprintf

=head1 SYNOPSIS

	use Data::Localize;
	use Data::Localize::Format::Sprintf;

	my $loc = Data::Localize->new;

	$loc->add_localizer(
		class => 'YAML', # or any other
		path => 'i18n/*.yaml',
		formatter => Data::Localize::Format::Sprintf->new,
	);

=head1 DESCRIPTION

This is an extremely simple module which lets you use sprintf syntax in your
translation strings.

Using this formatter has following advantages:

=over

=item

this format is widely known so you don't have to learn it

=item

it's a single sprintf call, so it is bound to be faster than any custom
solutions

=item

it lets you use full range on characters (unlike Maketext formatter, which
currently doesn't let you use square brackets)

=back

Please note that sprintf also lets you specify the number of parameter which
you want to use with syntax C<%1$s>, C<%2$s> etc.

=head1 SEE ALSO

L<Data::Localize::Format::Maketext>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

