package App::Bernard::Magic::Fuzzreview;

use strict;
use warnings;

use Locale::PO::Callback;

sub new {
    return bless {};
}

sub wanted {
    my ($element) = @_;
    
    # We don't want anything that's not fuzzy.
    return 0 unless $element->{'flags'}->{'fuzzy'};

    # Nor anything whose translation contains
    # Latin-alphabet characters.
    for my $key (keys %{$element}) {
	next unless $key =~ /^msgstr/;
	return 0 if $element->{$key} =~ /[a-z]/i;
    }

    return 1;
}

sub handle {

    my ($self, $settings) = @_;

    die "--in-place cannot be used with fuzzreview\n"
	if $settings->{'inplace'};

    my $rebuilder = Locale::PO::Callback::rebuilder();

    my $filter = sub {
	my ($element) = @_;

	$rebuilder->($element) if wanted($element);
    };

    my $lpc = Locale::PO::Callback->new($filter);

    $lpc->read($settings->{'input'});

}

1;
