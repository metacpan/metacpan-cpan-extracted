package Dwarf::Util::Xslate;
use Dwarf::Pragma;
use parent 'Exporter';
use HTML::FillInForm::Lite qw//;
use Text::Xslate qw/html_builder html_escape/;

our @EXPORT_OK = qw/reproduce_line_feed format_yen/;

sub reproduce_line_feed {
	return html_builder {
		my $text = shift // '';
		my $escaped = html_escape($text);
		$escaped =~ s|\n|<br />|g;
		return $escaped;
	};
}

sub format_yen {
	my ($options) = @_;
	return html_builder {
		my $price = shift // '';
		my $escaped = html_escape($price);
		return '' unless defined $price;
		1 while $price =~ s/(.*\d)(\d\d\d)/$1,$2/;
		return $price unless $options->{with_yen};
		return '&yen; ' . $price;
	};
}

sub fillinform {
	return html_builder(\&HTML::FillInForm::Lite::fillinform);
}

1;
