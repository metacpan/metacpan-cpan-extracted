package App::Bernard::Magic::Single;

use strict;
use warnings;
use File::MimeInfo;
use File::Slurp;

sub new {
    return bless {};
}

sub package_from_filetype {
    my ($filename) = @_;

    my $mimetype = mimetype($filename);
    
    my $pkg = $mimetype;
    $pkg =~ s/\b(.)/\U$1/g;
    $pkg =~ s/[^a-z]//gi;

    return ("App::Bernard::Filetype::$pkg", $mimetype);
}

sub replace_inplace {

    my ($settings) = @_;

    if ($settings->{'inplace'}) {
	rename $settings->{'output'}, $settings->{'input'};
    }
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

    die "File $settings->{'input'} does not exist\n" unless -e $settings->{'input'};
    my ($pkg, $mimetype) = package_from_filetype($settings->{'input'});

    # TODO: Probably should query the package
    # about whether it accepts --in-place
    die "--in-place can only be used with .po files"
	if $settings->{'inplace'} && $mimetype ne 'text/x-gettext-translation';

    eval {
	# okay, attempt to load the handler package
	my $filename = $pkg;
	$filename =~ s!::!/!g;
	require "$filename.pm";
    };
    if ($@) {
	die "$settings->{'file'} is of type $mimetype, which we cannot handle.\n";
    }

    $pkg->handle(scalar(read_file($settings->{'input'})),
		 $settings);

    close OUTPUT
	or die "Can't close $settings->{'output'}: $!"
	if $settings->{'output'};

    if ($settings->{'check'}) {
	my $result =
	    system "msgfmt -c $settings->{'output'} -o /dev/null";

	if ($result != 0) {
	    die "Check failed; aborting\n";
	}
    }

    replace_inplace($settings);
}

1;
