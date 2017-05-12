package App::Bernard::Filetype::TextXGettextTranslation;

use strict;
use warnings;

use Locale::PO::Callback;

sub handle {

    my ($class, $input, $settings) = @_;

    my $transliterate = $settings->{'transliterate'};
    my $target = $settings->{'print'};

    $settings->{'underscore'} = 1;

    my $rebuilder = Locale::PO::Callback::rebuilder($target);

    my $maybe_transliterate = sub {
	my ($item) = @_;

	if ($item->{'type'} eq 'header') {

	    $item->{'headers'}->{'language-team'} =
		'Shavian <ubuntu-l10n-en-shaw@launchpad.net>';
	    $item->{'headers'}->{'content-type'} =
		'text/plain; charset=UTF-8';
	    $item->{'headers'}->{'plural-forms'} =
		'nplurals=2; plural=n!=1;';

	    $settings->{'defines'} = {
		%{$settings->{'defines'}},
		$item->{'comments'} =~ m/Transliterate (.*) as (.*)\n/gi,
	    };

	} elsif ($item->{'type'} eq 'translation') {

	    my $has_content = 0;

	    for my $key (keys %{$item}) {
		if ($key =~ /^msgstr/) {
		    if ($item->{$key} ne '') {
			$has_content = 1;
		    }
		}
	    }

	    my $should_change = (!$has_content) ||
		(defined $item->{'flags'}->{'fuzzy'});

	    if ($should_change) {
		
		$item->{'flags'}->{'fuzzy'} = 1;
		
		for my $key (keys %{$item}) {
		    if ($key =~ /^msgstr/) {
			undef $item->{$key};
		    }
		}

		if (defined $item->{'msgid_plural'}) {
		    $item->{'msgstr[0]'} = $transliterate->($item->{'msgid'});
		    $item->{'msgstr[1]'} = $transliterate->($item->{'msgid_plural'});
		} else {
		    $item->{'msgstr'} = $transliterate->($item->{'msgid'});
		}
	    }

	}
	$rebuilder->($item);
    };

    my $dater = Locale::PO::Callback::set_date($maybe_transliterate);

    my $lcp = Locale::PO::Callback->new($dater);

    $lcp->read_string($input);
}

1;
