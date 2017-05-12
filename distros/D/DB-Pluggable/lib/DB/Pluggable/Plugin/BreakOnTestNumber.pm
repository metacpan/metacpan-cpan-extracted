package DB::Pluggable::Plugin::BreakOnTestNumber;
use strict;
use warnings;
use 5.010;
use Role::Basic;
use Hook::LexWrap;
use Test::Builder;    # preload so we can "safely" overwrite lock()
with qw(
  DB::Pluggable::Role::Initializer
  DB::Pluggable::Role::WatchFunction
);
our $VERSION = '1.112001';

sub initialize {
    @DB::testbreak = ();
    our $cmd_b_wrapper = wrap 'DB::cmd_b', pre => sub {
        return unless $_[1] =~ /\s*#\s*(\d+(?:\s*,\s*\d+)*)$/;
        my %seen;
        @DB::testbreak = grep { !$seen{$_}++ }
          sort { $a <=> $b } (split(/\s*,\s*/, $1), @DB::testbreak);

        # Making use of the fact that Test::Builder calls lock() each
        # time before accessing {Curr_Test} is a hack, but directly
        # enabling the watchfunction here would mean everything slows
        # down to a crawl. It also means that this plugin won't work
        # with threads. And let's hope Test::Builder continues to use
        # lock()... Not nice, but it works and is fast.
        no warnings 'redefine';
        no strict 'refs';
        *Test::Builder::lock = sub {
            return if (caller(1))[3] eq 'Test::Builder::current_test';

            # Enable watchfunction
            $DB::trace |= 4;
        };

        # short-circuit (i.e., don't call the original debugger function)
        # if a plugin has handled it
        $_[-1] = 1;
        return;
      }
}

sub watchfunction {
    my $self = shift;

    # disable the watchfunction until it is next enabled by lock()
    $DB::trace &= ~4;
    return unless @DB::testbreak;
    my $next = Test::Builder->new->current_test + 1;
    if ($next >= $DB::testbreak[0]) {
        shift @DB::testbreak while @DB::testbreak && $next >= $DB::testbreak[0];
        my $depth = 1;
        while (1) {
            my $package = (caller $depth)[0];
            last unless defined $package;
            last unless $package =~ /^(DB(::|$)|Test::)/;
            $depth++;
        }
        no warnings 'once';
        $DB::stack[ -$depth + 1 ] = 1;
    }
    return;
}
1;

=pod

=for stopwords watchfunction

=for test_synopsis 1;
__END__

=head1 NAME

DB::Pluggable::Plugin::BreakOnTestNumber - Debugger plugin to break on Test::Builder-based tests

=head1 SYNOPSIS

    $ cat ~/.perldb

    use DB::Pluggable;
    DB::Pluggable->run_with_config(\<<EOINI)
    [BreakOnTestNumber]
    EOINI

    $ perl -d foo.pl

    Loading DB routines from perl5db.pl version 1.28
    Editor support available.

    Enter h or `h h' for help, or `man perldebug' for more help.

    1..9
    ...
      DB<1> b #5
      DB<2> r

=head1 DESCRIPTION

This debugger plugin extends the debugger's C<b> command - used to set
breakpoints - with the ability to stop at a specific test number. Andy
Armstrong had the idea and wrote the original code, see
L<http://use.perl.org/~AndyArmstrong/journal/35792>.

=head1 METHODS

=head2 initialize

Sets up the command handler that checks whether the command is of
the form C<b #12> or C<b #12, 34, ...>. If so, it sets breakpoints
to break as soon as the given test has finished. If test-based
breakpoints have been found, the standard C<DB::cmd_b()> function that
handles the C<b> command is short-circuited.

If it handles the command, it enables the C<watchfunction()>.

This plugin overwrites C<Test::Builder::lock()> to be able to
detect that a test is about to be finished - see the source code of
L<Test::Builder> for details. Yes, this is nasty. It also means that
this plugin will break C<Test::Builder> when using threads.

=head2 watchfunction

Checks the current test number from L<Test::Builder> and instructs the
debugger to stop if an appropriate test number has been reached.
