package App::Bernard::Magic::Gnome;

use strict;
use warnings;

use LWP::UserAgent;
use File::Slurp;

use App::Bernard::Magic::Single;

sub new {
    return bless {};
}

sub fetch {
    my ($self, $url, $target) = @_;

    my $ua = LWP::UserAgent->new;

    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);

    die "HTTP error: " . $res->status_line. "\n"
	unless $res->is_success;

    write_file ($target, $res->content);
}

sub process_file {
    my ($self, $filename, $settings) = @_;

    print "Processing file: $filename\n";

    # Can't rely on file headers to work out
    # the package name (at the moment).

    my @elements = split(m!/!, $filename);

    pop @elements; # lose "en@shaw.po"
    my $po_type = pop @elements; # usually "po", but could be "po-properties"
    my $pkg = pop @elements;

    my $extra = '';
    # Special case for GTK+:
    $extra .= '-properties' if $po_type eq 'po-properties';

    my $pot_url = "http://l10n.gnome.org/POT/$pkg.master/$pkg$extra.master.pot";
    my $pot_local = $filename . rand() . '.pot';

    print "Fetch: $pot_url\n";
    $self->fetch($pot_url, $pot_local);

    print "Merging: ";
    system("msgmerge -U $filename $pot_local");

    unlink $pot_local;

    print "Transliterating: ";

    $settings->{'inplace'} = 1;
    $settings->{'check'} = 1;
    $settings->{'input'} = $filename;
    $settings->{'output'} = $filename.rand().'.po';

    my $single = App::Bernard::Magic::Single->new();
    $single->handle($settings);

    print "done.\n";
}

sub handle {

    my ($self, $settings) = @_;

    # Make sure "GNOME" is spelt correctly
    $settings->{'defines'}->{'gnome'} =
	chr(0xB7).chr(0x1045C).chr(0x1046F).chr(0x10474).chr(0x10465)
	unless defined $settings->{'defines'}->{'gnome'};

    # Is this a directory, or a single file?

    if (-d $settings->{'input'}) {

	# A directory.

	for my $pkg (glob($settings->{'input'}.'/*')) {

	    for my $suffix ('/po/en@shaw.po',
			    '/po-properties/en@shaw.po') {
		if (-e $pkg.$suffix) {
		    $self->process_file(
			$pkg.$suffix,
			$settings);
		}
	    }
	}

    } else {

	# Just one file.

	$self->process_file(
	    $settings->{'input'},
	    $settings);
    }
}

1;
