package App::Bernard::Magic::Fuzzaccept;

use strict;
use warnings;

use Locale::PO::Callback;
use App::Bernard::Magic::Fuzzreview;
use App::Bernard::Magic::Single;

sub new {
    return bless {};
}

sub handle {

    my ($self, $settings) = @_;

    if ($settings->{'output'}) {
	open OUTPUT, ">$settings->{'output'}"
	    or die "Can't open $settings->{'output'}: $!";
	binmode OUTPUT, ":utf8";
    }

    $settings->{'print'} = sub {
	my ($text) = @_;

	if ($settings->{'output'}) {
	    print OUTPUT $text;
	} else {
	    print $text;
	}
    };

    my $rebuilder = Locale::PO::Callback::rebuilder($settings->{'print'});

    my $filter = sub {
	my ($element) = @_;

	if (App::Bernard::Magic::Fuzzreview::wanted($element)) {
	    delete $element->{'flags'}->{'fuzzy'};
	}

	$rebuilder->($element);
    };

    my $lpc = Locale::PO::Callback->new($filter);

    $lpc->read($settings->{'input'});

    App::Bernard::Magic::Single::replace_inplace($settings);
}

1;
