package App::optex::help;

=head1 NAME

help - help module for optex

=head1 SYNOPSIS

optex -MB<help> [ I<options> ]

optex I<command> -MB<help> [ I<options> ]

=head1 OPTIONS

=over 7

=item -x

Show options without help.

=item -l

Show module path.

=item -m

Show module content.

=item -h, --man

Show document.

=back

=cut

use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $rcloader = $main::rcloader;

my $opt_with_help = 1;

sub usage {
    my $quote = qr/[\\(){}\|\*?]/;
    print "OPTIONS\n";
    for my $bucket ($rcloader->buckets) {
	my @options = $bucket->options or next;
	my $indent = " " x 4;
	my $title = do {
	    my $shown;
	    sub { $shown++ or print "${indent}$_[0] options:\n" };
	};
	my $option = sub {
	    printf "%s%-20s %s\n", $indent x 2, @_;
	};
	for my $name (@options) {
	    my $help = $opt_with_help ? $bucket->help($name) // "" : "";
	    next if $help eq 'ignore';
	    my @list = $bucket->getopt($name, ALL => 1);
	    $title->($bucket->title);
	    $option->($name, $help || join(' ', shellquote(@list)));
	}
	print "\n";
    }
}

##
## easy implementation. don't be serious.
##
sub shellquote {
    my $quote = qr/[\s\\(){}\|\*?]/;
    map { /^(-+\w+=)(.*$quote.*)$/
	      ? "$1\'$2\'"
	      :  /^(.*$quote.*)$/
	      ? "\'$1\'"
	      : $_ }
    @_;
}

sub perldoc {
    my %opt = @_;
    my @modules = do {
	grep { $_ ne 'default' }
	grep { $_ !~ m:^/: }
	map  { $_->module }
	$rcloader->buckets;
    } or die "No modules.\n";
    my $mod;
    while (@modules > 0) {
	last if ($mod = pop @modules) ne __PACKAGE__;
    }
    my @command = ("perldoc",
		   $opt{l} ? '-l' : (),
		   $opt{m} ? '-m' : (),
		   $mod);
    $ENV{PERL5LIB} = join ':', @INC;
    warn "exec @command\n" if $main::debug;
    exec @command or die $!;
}

sub initialize {
    my($rc, $argv) = @_;

    use Getopt::Long 'GetOptionsFromArray';
    Getopt::Long::Configure(qw"bundling require_order");
    my %opt;
    my @optargs = (
	"x"       => \$opt{x},
	"l"       => \$opt{l},
	"m"       => \$opt{m},
	"M"       => \$opt{M},
	"h|man"   => \$opt{man},
	"u|usage" => \$opt{usage},
	);
    # suppress unknown option message.
    for (sub { }, undef) {
	$SIG{__WARN__} = $_ or last;
	GetOptionsFromArray $argv, @optargs;
    }

    $opt_with_help = 0 if $opt{x};

    if (grep $opt{$_}, qw( l m man )) {
	perldoc %opt;
    }
    elsif ($opt{M}) {
	main::show_modules();
    } else {
	usage();
    }

    exit 0;
}

1;

__DATA__

option -x built-in	// omit option description
option -l built-in	// show module path
option -m built-in	// show module content
option --man built-in	// show document
option --usage built-in	// show usage (this)
