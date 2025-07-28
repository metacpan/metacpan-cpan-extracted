package App::Greple::pw;

our $VERSION = "1.01";

=head1 NAME

pw - Interactive password and ID information extractor for greple


=head1 SYNOPSIS

    # Basic usage
    greple -Mpw pattern file

    # Search in encrypted files
    greple -Mpw password ~/secure/*.gpg

    # Configure options
    greple -Mpw --no-clear-screen --chrome password data.txt
    greple -Mpw --config timeout=600 --config debug=1 password file.txt


=head1 VERSION

Version 1.01


=head1 DESCRIPTION

The B<pw> module is a B<greple> extension that provides secure, interactive
handling of sensitive information such as passwords, user IDs, and account
details found in text files. It is designed with security in mind, ensuring
that sensitive data doesn't remain visible on screen or in terminal history.

=head2 Key Features

=over 4

=item * B<Interactive password handling>

Passwords are masked by default and can be safely copied to clipboard
without displaying the actual content on screen.

=item * B<Secure cleanup>

Terminal scroll buffer and screen are automatically cleared when the
command exits, and clipboard content is replaced with a harmless string
to prevent sensitive information from persisting.

=item * B<Encrypted file support>

Seamlessly works with PGP encrypted files using B<greple>'s standard
features. Files with "I<.gpg>" extension are automatically decrypted,
and the B<--pgp> option allows entering the passphrase once for
multiple files.

=item * B<Intelligent pattern recognition>

Automatically detects ID and password information using configurable
keywords like "user", "account", "password", "pin", etc. Custom
keywords can be configured to match your specific data format.

=item * B<Browser integration>

Includes browser automation features for automatically filling web
forms with extracted credentials.

=back

Some banks use random number matrices as a countermeasure for tapping.
If the module successfully guesses the matrix area, it blacks out the
table and remembers them.

    | A B C D E F G H I J
  --+--------------------
  0 | Y W 0 B 8 P 4 C Z H
  1 | M 0 6 I K U C 8 6 Z
  2 | 7 N R E Y 1 9 3 G 5
  3 | 7 F A X 9 B D Y O A
  4 | S D 2 2 Q V J 5 4 T

Enter the field positions to get the cell items like:

    > E3 I0 C4

and you will get the answer:

    9 Z 2

Case is ignored and white space is not necessary, so you can type like
this as well:

    > e3i0c4


=head1 INTERFACE

=begin comment

=head2 Internal Functions (for developers)

=over 7

=item B<pw_print>

Data print function.  This function is set for the B<--print> option of
B<greple> by default, and users don't have to care about it.

=item B<pw_epilogue>

Epilogue function.  This function is set for the B<--end> option of
B<greple> by default, and users don't have to care about it.

=back

=end comment

=over 7

=item B<config>

Module parameters can be configured using the B<config> interface from
L<Getopt::EX::Config>.  There are three ways to configure parameters:

=over 4

=item Module configuration syntax

Use the B<::config=> syntax directly with the module:

    greple -Mpw::config=clear_screen=0

=item Command-line config option

Use the B<--config> option to set parameters:

    greple -Mpw --config clear_screen=0 --

Multiple parameters can be set:

    greple -Mpw --config clear_screen=0 --config debug=1 --

=item Direct command-line options

Many parameters have direct command-line equivalents:

    greple -Mpw --no-clear-screen --debug --browser=safari --

=back

Currently following configuration options are available:

    clear_clipboard
    clear_string
    clear_screen
    clear_buffer
    goto_home
    browser
    timeout
    debug
    parse_matrix
    parse_id
    parse_pw
    id_keys
    id_chars
    id_color
    id_label_color
    pw_keys
    pw_chars
    pw_color
    pw_label_color
    pw_blackout

=back

=head3 Parameter Details

=over 4

=item B<Option naming>

Configuration parameters use underscores (C<clear_screen>, C<id_keys>), while 
command-line options use hyphens (C<--clear-screen>, C<--id-keys>).

=item B<Boolean parameters>

Parameters like B<clear_screen>, B<debug> can be set to 0/1. Command-line 
options support negation with C<--no-> prefix (e.g., C<--no-clear-screen>).

=item B<List parameters>

B<id_keys> and B<pw_keys> are lists of keywords separated by spaces:

    --config id_keys="USER ACCOUNT LOGIN EMAIL"
    --config pw_keys="PASS PASSWORD PIN SECRET"

=item B<Password display control>

B<pw_blackout> controls password display:
0=show passwords, 1=mask with 'x', >1=fixed length mask.

=item B<PwBlock integration>

Parameters B<parse_matrix>, B<parse_id>, B<parse_pw>, B<id_*>, and B<pw_*> 
are passed to the PwBlock module for pattern recognition and display control.

=back

=over 4

=item B<pw_status>

Print current configuration status. Next command displays current settings:

    greple -Mpw::pw_status= dummy /dev/null

This shows which parameters are set to non-default values and which are using defaults.

=back

=head1 BROWSER INTEGRATION

The pw module includes browser integration features for automated input.
Browser options are available:

=over 4

=item B<--browser>=I<name>

Set the browser for automation (chrome, safari, etc.):

    greple -Mpw --browser=chrome

=item B<--chrome>, B<--safari>

Shortcut options for specific browsers:

    greple -Mpw --chrome     # equivalent to --browser=chrome
    greple -Mpw --safari     # equivalent to --browser=safari

=back

During interactive mode, you can use the C<input> command to send
data to browser forms automatically.

=head1 EXAMPLES

=over 4

=item Search for passwords in encrypted files

    greple -Mpw password ~/secure/*.gpg

=item Use with specific browser and no screen clearing

    greple -Mpw --chrome --no-clear-screen password data.txt

=item Configure custom keywords and timeout

    greple -Mpw --config id_keys="LOGIN EMAIL USER" --config timeout=600 password file.txt

=item Check current configuration

    greple -Mpw::pw_status= dummy /dev/null

=back

=head1 SEE ALSO

L<App::Greple>, L<App::Greple::pw>

L<https://github.com/kaz-utashiro/greple-pw>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright (C) 2017-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


use v5.14;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT      = qw(&pw_print &pw_epilogue &pw_status &config);
our %EXPORT_TAGS = ( );
our @EXPORT_OK   = qw();

use Carp;
use Data::Dumper;
use App::Greple::Common;
use App::Greple::PwBlock;
use Getopt::EX::Config qw(config);

my $execution = 0;

# Getopt::EX::Config support
my $config = Getopt::EX::Config->new(
    clear_clipboard => 1,
    clear_string    => 'Hasta la vista.',
    clear_screen    => 1,
    clear_buffer    => 1,
    goto_home       => 0,
    browser         => 'chrome',
    timeout         => 300,
    debug           => 0,
    # PwBlock parameters (no defaults - PwBlock manages its own)
    parse_matrix    => undef,
    parse_id        => undef,
    parse_pw        => undef,
    id_keys         => undef,
    id_chars        => undef,
    id_color        => undef,
    id_label_color  => undef,
    pw_keys         => undef,
    pw_chars        => undef,
    pw_color        => undef,
    pw_label_color  => undef,
    pw_blackout     => undef,
);

sub finalize {
    our($mod, $argv) = @_;
    $config->deal_with(
	$argv,
	"clear_clipboard|clear-clipboard!",
	"clear_string|clear-string=s",
	"clear_screen|clear-screen!",
	"clear_buffer|clear-buffer!",
	"goto_home|goto-home!",
	"browser=s",
	"timeout=i",
	"debug!",
	# PwBlock parameters - direct assignment
	"parse-matrix!" => \$App::Greple::PwBlock::parse_matrix,
	"parse-id!" => \$App::Greple::PwBlock::parse_id,
	"parse-pw!" => \$App::Greple::PwBlock::parse_pw,
	"id-chars=s" => \$App::Greple::PwBlock::id_chars,
	"id-color=s" => \$App::Greple::PwBlock::id_color,
	"id-label-color=s" => \$App::Greple::PwBlock::id_label_color,
	"pw-chars=s" => \$App::Greple::PwBlock::pw_chars,
	"pw-color=s" => \$App::Greple::PwBlock::pw_color,
	"pw-label-color=s" => \$App::Greple::PwBlock::pw_label_color,
	"pw-blackout=i" => \$App::Greple::PwBlock::pw_blackout,
	# Array parameters
	"id-keys=s" => sub { @App::Greple::PwBlock::id_keys = split /\s+/, $_[1]; },
	"pw-keys=s" => sub { @App::Greple::PwBlock::pw_keys = split /\s+/, $_[1]; },
    );
    
    # Copy --config values to PwBlock variables if set
    $App::Greple::PwBlock::parse_matrix = config('parse_matrix') if defined config('parse_matrix');
    $App::Greple::PwBlock::parse_id = config('parse_id') if defined config('parse_id');
    $App::Greple::PwBlock::parse_pw = config('parse_pw') if defined config('parse_pw');
    $App::Greple::PwBlock::id_chars = config('id_chars') if defined config('id_chars');
    $App::Greple::PwBlock::id_color = config('id_color') if defined config('id_color');
    $App::Greple::PwBlock::id_label_color = config('id_label_color') if defined config('id_label_color');
    $App::Greple::PwBlock::pw_chars = config('pw_chars') if defined config('pw_chars');
    $App::Greple::PwBlock::pw_color = config('pw_color') if defined config('pw_color');
    $App::Greple::PwBlock::pw_label_color = config('pw_label_color') if defined config('pw_label_color');
    $App::Greple::PwBlock::pw_blackout = config('pw_blackout') if defined config('pw_blackout');
    @App::Greple::PwBlock::id_keys = split /\s+/, config('id_keys') if defined config('id_keys');
    @App::Greple::PwBlock::pw_keys = split /\s+/, config('pw_keys') if defined config('pw_keys');
}

sub pw_status {
    binmode STDOUT, ":encoding(utf8)";
    for my $key (sort keys %{$config}) {
	my $val = config($key);
	if (defined $val) {
	    print "$key: $val\n";
	} else {
	    print "$key: (default)\n";
	}
    }
}

sub pw_print {
    my %attr = @_;
    my @pass;

    $execution++;

    my $pw = new App::Greple::PwBlock $_;

    print $pw->masked;

    command_loop($pw) or do { pw_epilogue(); exit };

    return '';
}


use constant { CSI => "\e[" };

sub pw_epilogue {
    $execution == 0 and return;
    copy(config('clear_string')) if config('clear_clipboard');
    print STDERR CSI, "H" if config('goto_home');
    print STDERR CSI, "2J" if config('clear_screen');
    print STDERR CSI, "3J" if config('clear_buffer');
}

sub pw_timeout {
    if (config('debug')) {
	warn "pw_timeout() called.\n";
	sleep 1;
    }
    pw_epilogue();
    exit;
}

sub command_loop {
    my $pw = shift;

    open TTY, "/dev/tty" or die;

    require Term::ReadLine;
    my $term = Term::ReadLine->new(__PACKAGE__, *TTY, *STDOUT);

    binmode TTY, ":encoding(utf8)";
    binmode STDOUT, ":encoding(utf8)";

    while ($_ = $term->readline("> ")) {
	if (config('timeout')) {
	    $SIG{ALRM} = \&pw_timeout;
	    alarm config('timeout');
	    warn "Set timeout to ", config('timeout'), " seconds\n" if config('debug');
	}
	/\S/ or next;
	$term->addhistory($_);
	s/\s+\z//;
	$_ = kana2alpha($_);

	if (my $id = $pw->id($_)) {
	    if (copy($id)) {
		printf "ID [%s] was copied to clipboard.\n", $id;
	    }
	    next;
	}
	elsif (my $pass = $pw->pw($_)) {
	    if (copy($pass)) {
		printf "Password [%s] was copied to clipboard.\n", $_;
	    }
	    next;
	}

	if (0) {}
	elsif (/^dump\b/)  { print Dumper $pw }
	elsif (/^N/i) { last }
	elsif (/^P/i) { print $pw->masked }
	elsif (/^Q/i) { return 0 }
	elsif (/^V/i) {
	    s/^.\s*//;
	    my @option = split /\s+/;
	    if (@option == 0) {
		print $pw->orig;
	    } else {
		my @values = map { $pw->any($_) // '[N/A]' } @option;
		print "@values\n";
	    }
	}
	elsif (/^show\b/i) {
	    print $pw->masked;
	}
	elsif (/^orig\b/i) {
	    print $pw->orig;
	}
	##
	## INPUT to browser
	##
	elsif (s/^input\s*//i) {
	    my %field = do {
		map {
		    m{
			( (?: name: | id: )? \w+ )
			(?|
			  \s+ (.*) # '=' がなければ残り全部
			  |
			  = ( \/.+\/ | \w+ (?:,\w+)* )
			)
		    }xg
		}
		$pw->orig =~ /^INPUT\s+(.+)/mg;
	    };
	    warn Dumper \%field if config('debug');
	    my @arg = do {
		map { /^([a-z]\d\s*){2,}$/i ? /([a-z]\d)/gi : $_ }
		map { m{^/(.+)/$} ? get_pattern($1) : $_ }
		map { $field{$_} or $_ }
		map { split /[\s=]+/ }
		map { $field{$_} or $_ }
		split /\s+/;
	    };
	    warn "@arg\n" if config('debug');
	    while (@arg >= 2) {
		my $label = shift @arg;
		my @fields = split /[,]/, $label;
		for my $field (@fields) {
		    my $item = shift @arg;
		    my $value = $pw->any($item) // $item;
		    set_browser_field($field, $value);
		}
	    }
	}
	elsif (/^set$/) {
	    for my $var (sort keys %{$config}) {
		print "$var: ";
		print config($var);
		print "\n";
	    }
	}
	elsif (s/^set\s+//) {
	    my($var, $val) = split /\s+/, $_, 2;
	    if (exists $config->{$var}) {
		$config->set($var, $val);
	    } else {
		warn "Unknown variable: $var";
	    }
	}
	elsif (/^([A-J]\d\s*)+$/i) {
	    my @chars;
	    while (/([A-J])(\d)/gi) {
		push @chars, $pw->cell(uc($1), $2) // 'ERROR';
	    }
	    print "@chars\n";
	}
	else {
	    print "Command error.\n";
	}
    }
    close TTY;

    return 1;
}

my %kana2alpha = (
    ア => 'A', イ => 'B', ウ => 'C', エ => 'D', オ => 'E',
    カ => 'F', キ => 'G', ク => 'H', ケ => 'I', コ => 'J',
    );

sub kana2alpha {
    local $_ = shift;
    s/([アイウエオカキクケコ])/$kana2alpha{$1}/g;
    $_;
}

my $clipboard;
BEGIN {
    eval "use Clipboard";
    if (not $@) {
	$clipboard = "Clipboard";
    }
    elsif (-x "/usr/bin/pbcopy") {
	$clipboard = "pbcopy";
    }
    else {
	warn("==========================================\n",
	     "Clipboard is not available on this system.\n",
	     "Install Clipboard module from CPAN.\n",
	     "==========================================\n");
    }
}

sub copy {
    my $text = shift;
    if (not $clipboard) {
	warn "Clipboard is not available.\n";
	return undef;
    }
    elsif ($clipboard eq "Clipboard") {
	Clipboard->copy($text);
    }
    elsif ($clipboard eq "pbcopy") {
	dumpto($clipboard, $text);
    }
    1;
}

sub dumpto {
    my $command = shift;
    my $text = shift;
    open COM, "| $command" or die "$command: $!\n";
    print COM $text;
    close COM;
}

sub apple_script {
    my $app = shift;
    shift if $_[0] eq 'to';
    my $do = join "\n", @_;
    my $script = <<"    end_script";
	tell Application "$app"
	    $do
	end tell
    end_script
    warn $script if config('debug');
    if ((open(CMD, "-|") // die) == 0) {
	exec 'osascript', '-e', $script or die;
    } else {
	my $result = do { local $/; <CMD> };
	close CMD;
	warn $result if config('debug');
	return $result =~ /missing value/ ? undef : $result;
    }
}

my %js_subs = (
    chrome => \&js_chrome,
    safari => \&js_safari,
    );

sub js {
    (my $sub = $js_subs{config('browser')}) // do {
	warn "Unsupported browser: ", config('browser');
	return;
    };
    goto $sub;
}

sub _js {
    goto &js_chrome;
}

sub js_google {
    my $browser = shift;
    my $js = shift;
    $js =~ s/"/\\"/g;
    $js =~ s/\n//g;
    my $script = <<"    end_script";
	tell active tab of window 1
	    execute javascript ("$js")
	end tell
    end_script
    apple_script config('browser'), $script;
}

sub js_chrome {
    js_google('Google Chrome', @_);
}

sub js_brave {
    js_google('Google Brave', @_);
}

sub js_safari {
    my $js = shift;
    $js =~ s/"/\\"/g;
    apple_script 'Safari', <<"    end_script";
	tell current tab of window 1
	    do JavaScript ("$js")
	end tell
    end_script
}

sub set_browser_field {
    my $name = shift;
    my $value = shift;
    js "document.getElementsByName('$name')[0].value='$value'"
	if defined $value;
}

sub get_pattern {
    my $pattern = shift;
    js "document.body.textContent.match(/$pattern/)";
}    

1;


__DATA__

option default \
	--paragraph \
	--print pw_print \
	--end pw_epilogue

option --config --prologue config($<shift>=$<shift>)

option --debug --config debug 1

option --timeout --config timeout

option --browser --config browser
option --chrome --browser chrome
option --safari --browser safari
