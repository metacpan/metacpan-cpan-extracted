package App::perlfind::Plugin::FoundIn;
use strict;
use warnings;
use App::perlfind;
our $VERSION = '2.07';

# Specify like this because it's easier. We compute the reverse later (i.e.,
# it should be easier on the hacker than on the computer).
#
# Note: 'for' is a keyword for perlpod as well ('=for'), but is listed for
# perlsyn here, as that's more likely to be the intended meaning.
our %found_in = (
    perlop => [
        qw(lt gt le ge eq ne cmp not and or xor
          q qq qr qx qw \l \u \L \U \Q \E)
    ],
    perlsyn => [qw(if else elsif unless while until for foreach)],
    perlobj => [qw(isa ISA can VERSION)],
    perlsub => [qw(AUTOLOAD DESTROY)],
    perlmod => [qw(BEGIN UNITCHECK CHECK INIT END)],
    perltie => [
        qw(TIESCALAR TIEARRAY TIEHASH TIEHANDLE FETCH STORE UNTIE
          FETCHSIZE STORESIZE POP PUSH SHIFT UNSHIFT SPLICE DELETE EXISTS
          EXTEND CLEAR FIRSTKEY NEXTKEY WRITE PRINT PRINTF READ READLINE GETC
          CLOSE)
    ],
    perlrun => [
        qw(HOME LOGDIR PATH PERL5LIB PERL5OPT PERLIO PERLIO_DEBUG PERLLIB
          PERL5DB PERL5DB_THREADED PERL5SHELL PERL_ALLOW_NON_IFS_LSP
          PERL_DEBUG_MSTATS PERL_DESTRUCT_LEVEL PERL_DL_NONLAZY PERL_ENCODING
          PERL_HASH_SEED PERL_HASH_SEED_DEBUG PERL_ROOT PERL_SIGNALS
          PERL_UNICODE)
    ],
    perlpod => [ map { ($_, "=$_") }
        qw(head1 head2 head3 head4 over item back cut pod begin end)
    ],
    perldata => [qw(__DATA__ __END__)],

    # We could also list common functions and methods provided by some
    # commonly used modules, like:
    Moose => [
        qw(has before after around super override inner augment confessed
          extends with)
    ],
    Error        => [qw(try catch except otherwise finally record)],
    Storable     => [qw(freeze thaw)],
    Carp         => [qw(carp cluck croak confess shortmess longmess)],
    'Test::More' => [
        qw(plan use_ok require_ok ok is isnt like unlike cmp_ok
          is_deeply diag can_ok isa_ok pass fail eq_array eq_hash eq_set skip
          todo_skip builder SKIP: TODO:)
    ],
    'Getopt::Long' => [qw(GetOptions)],
    'File::Find'   => [qw(find finddepth)],
    'File::Path'   => [qw(mkpath rmtree)],
    'File::Spec'   => [
        qw(canonpath catdir catfile curdir devnull rootdir
          tmpdir updir no_upwards case_tolerant file_name_is_absolute path
          splitpath splitdir catpath abs2rel rel2abs)
    ],
    'File::Basename' => [
        qw(fileparse fileparse_set_fstype basename
          dirname)
    ],
    'File::Temp' => [
        qw(tempfile tempdir tmpnam tmpfile mkstemp mkstemps
          mkdtemp mktemp unlink0 safe_level)
    ],
    'File::Copy' => [qw(copy move cp mv rmscopy)],
    'PerlIO' =>
      [qw(:bytes :crlf :mmap :perlio :pop :raw :stdio :unix :utf8 :win32)],
);

App::perlfind->add_trigger(
    'matches.add' => sub {
        my ($class, $word, $matches) = @_;
        while (my ($file, $words) = each our %found_in) {
            for (@$words) {
                push @$matches, $file if $_ eq $$word;
            }
        }
    }
);
1;
__END__

=pod

=head1 NAME

App::perlfind::Plugin::FoundIn - Plugin to find documentation for syntax and concepts

=head1 SYNOPSIS

    # perlfind elsif
    # (runs `perldoc perlsyn`)

=head1 DESCRIPTION

This plugin for L<App::perlfind> knows where to find documentation for syntax
and built-in Perl concepts. It knows about things like

    elsif
    VERSION
    END
    head3
    =head3
    :utf8

