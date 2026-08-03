package DB::Hooks::HistoryTerminal;

use strict;
use warnings;
use Term::ReadLine::Tiny;
use File::Slurper 'read_lines';
use open qw( :encoding(UTF-8) :std );

# We can not track DB::Commands loading if 'use' it before DB::Hooks
use DB::Commands qw/ set_command get_command run /;

# Commands should be available immediately. This is important when
# we are debugging at CT: when DB is in process of loading
BEGIN { set_command next_command => \&readline; }

my $fn = $ENV{HOME} . '/.dbhooks_history';

if ( !( -e $fn ) ) {
    CleanHistory();
}

my $invitation = "\n\e[2;96mDBG>\e[0m";
my $counter    = 0;
my $term       = Term::ReadLine::Tiny->new();

#Write in file
sub SetHistory {
    my $i       = 0;
    my @content = $term->{history}->@*;

    open my $fh, '>', $fn or die "Can't open > $fn: $!";

    while ( $i <= scalar(@content) ) {

        if ( !defined( $content[$i] ) ) {
            last;
        }

        print $fh $content[$i], "\n";
        $i++;

    }

    close $fh or warn "Close failed: $!";
}

#Read from file
sub GetHistory {
    my @content = read_lines($fn);

    push( $term->{history}->@*, @content );
}

#Clean all history from file
sub CleanHistory {

    open FILE, '>', $fn or die "Can't open > $fn: $!";

    print FILE "";

    close FILE or warn "Close failed: $!";
}

# #View all command in history
# sub HistoryMenu{
# # 	my ( $history )  = @_;
# # 	$prim_command = $buffer ne "" ? $buffer : $prim_command;

# # 	print "\nHistory:\n";
# # 	foreach my $n ( @$history ) {
# # 		print $n, "\n";
# # 	}

# # 	$prim_command = $prim_command ? $prim_command : "";

# # 	return $prim_command;
# # }

my $last_command;
my $command;
GetHistory();
BEGIN { $last_command = '' }

sub readline {

    $command = $term->readline($invitation);
    chomp $command;

    return $last_command unless length $command;

    return $last_command = $command;
}

sub on_load {
    my ($file) = @_;

    return unless ( DB::state('TraceLoad') // 0 ) & 1;

    DB::say "\e[32mLoaded\e[0m: \e[1;33m$file\e[0m";
}

sub on_goto {
    my ($sub) = @_;

    return unless ( DB::state('TraceGoto') // 0 ) & 1;

    DB::say "Goto \e[32m$sub\e[0m";
}

sub on_trace {
    my ( $source, $file, $line ) = @_;
    $source =~ s/^\s+//;

    DB::say "\e[2;37m$file:$line\e[0m", "t: \e[1;33m$source\e[0m";
}

sub on_call {
    if ( DB::state('TraceStack') ) {
        my $stack = DB::state('stack');
        DB::state( stack => $stack = [] ) unless $stack;
        push @$stack, $_[1];
    }

    return unless ( DB::state('TraceCall') // 0 ) & 1;

    my ( $sub, $context, @args ) = @_;
    $context = $context ? '@' : defined $context ? '$' : ';';
    $sub     = "\e[1;32m$sub\e[0m";
    @args    = DB::vis_undef(@args);

    local $" = ', ';
    DB::say "$context $sub( \e[32m@args\e[0m )";
}

sub on_return {
    if ( DB::state('TraceStack') ) {
        my $stack = DB::state('stack');
        pop @$stack;
    }

    return unless ( DB::state('TraceReturn') // 0 ) & 1;

    my ( $sub, $context, @values ) = @_;

    $context = $context ? '@' : defined $context ? '$' : ';';
    $sub     = "\e[32m$sub\e[0m";
    @values  = DB::vis_undef(@values);

    local $" = ', ';
    DB::say "$context( \e[32m@values\e[0m ) <-- $sub";
}

sub on_binteract {
    run('l 0');
}

sub on_interact { get_command('interact')->(@_) }

# Subscribe subs to events
# on_interact (some debugger commands) does not work without on_call/on_return
# NOTICE: subscribe in the given order
use DB::Utils qw/ trace call return interact load goto binteract /;

END { SetHistory(); }

1;
