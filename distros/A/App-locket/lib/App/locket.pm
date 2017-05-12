package App::locket;
BEGIN {
  $App::locket::VERSION = '0.0022';
}
# ABSTRACT: Copy secrets from a YAML/JSON cipherstore into the clipboard (pbcopy, xsel, xclip)

use strict;
use warnings;

BEGIN {
    # Safe path
    $ENV{ PATH } = '/bin:/usr/bin';
}

use Term::ReadKey;
END {
    ReadMode 0;
}
use File::HomeDir;
use Path::Class;
use JSON; my $JSON = JSON->new->pretty;
use YAML::XS();
use File::Temp;
use Term::EditorEdit;
use Try::Tiny;
use String::Util qw/ trim /;
my $usage;
BEGIN {
$usage = <<_END_;

    Usage: locket [options] setup|edit|<query>

        --copy              Copy value to clipboard using pbcopy, xsel, or xclip

        --delay <delay>     Keep value in clipboard for <delay> seconds
                            If value is still in the clipboard at the end of
                            <delay> then it will be automatically wiped from
                            the clipboard

        --unsafe            Turn the safety off. This will disable prompting
                            before emitting any sensitive information in
                            plaintext. There will be no opportunity to
                            abort (via CTRL-C)

        --cfg <file>        Use <file> for configuration

        setup               Setup a new or edit an existing user configuration
                            file (~/.locket/cfg)

        edit                Edit the cipherstore
                            The configuration must have an "edit" value, e.g.:

                                /usr/bin/vim -n ~/.locket.gpg

        /<query>            Search the cipherstore for <query> and emit the
                            resulting secret
                            
                            The configuration must have a "read" value to
                            tell it how to read the cipherstore. Only piped
                            commands are supported today, and they should
                            be something like:

                                </usr/local/bin/gpg -q --no-tty -d ~/.locket.gpg'

                            If the found key in the cipherstore is of the format
                            "<username>@<site>" then the username will be emitted
                            first before the secret (which is assumed to be a password/passphrase)

        Example YAML cipherstore:

            %YAML 1.1
            ---
            # A GMail identity
            alice\@gmail: p455w0rd
            # Some frequently used credit card information
            cc4123: |
                4123412341234123
                01/23
                123

_END_
}
use Getopt::Usaginator $usage;
use Digest::SHA qw/ sha1_hex sha512_hex /;
use List::MoreUtils qw/ :all /;
use Hash::Dispatch;

use App::locket::Locket;
use App::locket::TextRandomart;
use App::locket::Util;

use App::locket::Moose;

my %n2k = (
    ( map { $_ => $_ + 1 } 0 .. 8 ),
    9 => 0,
);
my %k2n = map { trim $_ } reverse %n2k;

my %default_options = (
    delay => 45,
);

has locket => qw/ reader locket writer _locket isa App::locket::Locket lazy_build 1 /, handles =>
    [qw/
        cfg plaincfg write_cfg reload_cfg can_read read passphrase require_passphrase
        store
    /];
sub _build_locket {
    my $self = shift;
    my $locket = App::locket::Locket->open( $self->cfg_file );
    return $locket;
}

has home => qw/ is ro lazy_build 1 /;
sub _build_home {
    my $self = shift;
    my $home = File::HomeDir->my_data;
    if ( defined $home ) {
        $home = dir $home, '.locket';
    }
    return $home;
}

has_file cfg_file => qw/ is ro lazy_build 1 /;
sub _build_cfg_file {
    my $self = shift;
    if ( defined ( my $file = $self->argument_options->{ cfg } ) ) {
        return file $file;
    }
    my $home = $self->home;
    return unless $home;
    return $home->file( 'cfg' );
}

has argument_options => qw/ is ro lazy_build 1 /;
sub _build_argument_options {
    return {};
}

has options => qw/ is ro lazy_build 1 /;
sub _build_options {
    my $self = shift;

    my $cfg = $self->cfg;
    my @options;
    defined $cfg->{ $_ } and length $cfg->{ $_ } and push @options, $_ => $cfg->{ $_ } for qw/ delay /;
    push @options, $_ => $cfg->{ $_ } for qw/ unsafe /;

    my %argument_options = %{ $self->argument_options };

    return { %default_options, @options, %argument_options };
}

has stash => qw/ is ro lazy_build 1 /;
sub _build_stash {
    return {};
}

has [qw/ query found /] => qw/ is rw isa ArrayRef /, default => sub { [] };

sub run {
    my $self = shift;
    my @arguments = @_;

    my $options = $self->argument_options;
    my ( $help );
    Getopt::Usaginator->parse( \@arguments, $options,
        qw/ delay=s help|h cfg|config=s unsafe /,
    );

    if ( $self->require_passphrase ) {
        my $passphrase = $self->read_passphrase( 'Passphrase: ' );
        $self->say_stderr;
        if ( ! defined $passphrase || ! length $passphrase ) {
            $self->say_stderr( "# No passphrase entered" );
            exit 64;
        }
        $self->passphrase( $passphrase );
    }

    $options = $self->options;

    $self->dispatch( '?' );
    $self->dispatch( join( ' ', @arguments ) );
    $self->dispatch( '' ) if @arguments;
}

sub _select {
    my $self = shift;
    my $n = shift;

    my $found = $self->found;
    my $k;
    if ( !defined $n ) {
        $k = $self->stash->{_}[0];
        $n = $k2n{ $k };
    }

    return unless defined $found->[ $n ];
    my $target = $found->[ $n ];
    my $entry = $self->store->get( $target );
    return ( $target, $entry, $k, $n );
}

sub get_target_entry {
    my $self = shift;
    my $stash = $self->stash;
    my ( $target, $entry ) = @$stash{qw/ target entry /};
    if ( !defined $target ) {
        return $self->_select( 0 );
    }
}

my $_show = sub {
    my ( $self, $method ) = @_;

    return unless my ( $target, $entry, $k, $n ) = $self->_select;
    $self->emit_entry( $target, $entry );
    $self->dispatch( '.' );
};

my $_copy = sub {
    my ( $self, $method ) = @_;

    return unless my ( $target, $entry, $k, $n ) = $self->_select;
    $self->emit_entry( $target, $entry, copy => 1 );
    $self->dispatch( '.' );
};

sub emit_entry {
    my $self = shift;
    my $target = shift;
    my $entry = shift;
    my %options = @_;

    $self->say_stdout( sprintf "\n    === %s ===\n", $target );
    if ( $target =~ m/^([^@]+)@/ ) {
        $self->emit_username_password( $1, $entry, copy => $options{ copy } );
    }
    else {
        $self->emit_secret( $entry, copy => $options{ copy } );
    }
}

sub emit_username_password {
    my $self = shift;
    my ( $username, $password, %options ) = @_;

    if ( $options{ copy } ) {
        $self->copy( username => $username );
        $self->copy( password => $password );
    }
    else {
        $self->safe_stdout( <<_END_ );
        $username
        $password
_END_
    }
}

sub emit_secret {
    my $self = shift;
    my ( $secret, %options ) = @_;

    if ( $options{ copy } ) {
        $self->copy( secret => $secret );
    }
    else {
        $self->safe_stdout( $secret, "\n" );
    }
}


our $DISPATCH = Hash::Dispatch->dispatch(

    '' => sub {
        my ( $self, $method ) = @_;

        while ( 1 ) {
            $self->stdout( "> " );
            my $line = $self->stdin_readline;
            next unless defined $line;
            next unless length $line;
            $self->dispatch( $line );
        }

    },

    '?' => sub {
        my ( $self, $method ) = @_;

        my $cfg_file = $self->cfg_file;
        my $cfg_file_size = -f $cfg_file && -s _;
        defined && length or $_ = '-1' for $cfg_file_size;
        {
            my ( $read, $edit, $copy, $paste ) =
                map { defined $_ ? $_ : '~' } @{ $self->cfg }{qw/ read edit copy paste /};

            my $randomart = App::locket::TextRandomart->randomart( sha1_hex $self->plaincfg );
            my @randomart = split "\n", $randomart;
            @randomart = map { "    $_  " } @randomart;
            $randomart[ 1 ] .= "$cfg_file ($cfg_file_size)";
            $randomart[ 3 ] .= "  $read";
            $randomart[ 4 ] .= "  $edit";
            $randomart[ 5 ] .= "  $copy";
            $randomart[ 6 ] .= "  $paste";

            $randomart = join "\n", @randomart;

            $self->stdout( <<_END_ );
App::locket @{[ $App::locket::VERSION || '0.0' ]}

$randomart
_END_
            $self->say_stdout;
        }

        return;

        my $stash = $self->stash;
        my $query = $self->query;
        if ( @$query ) {
            $self->say_stdout( sprintf "    /: %s", join '/', @$query );
        }

        my ( $target, $entry ) = @$stash{qw/ target entry /};
        if ( defined $target ) {
            $self->say_stdout( sprintf "    =: %s", $target );
        }

    },

    'setup' => sub {
        my ( $self, $method ) = @_;

        my $cfg_file = $self->cfg_file;
        my $plaincfg = $self->plaincfg;
        if ( ! defined $plaincfg || $plaincfg =~ m/^\S*$/ ) {
            $plaincfg = <<_END_;
%YAML 1.1
---
#read: '</usr/bin/gpg -d <file>'
#read: '</usr/bin/openssl des3 -d -in <file>'
#edit: '/usr/bin/vim -n <file>'
#copy: -
#paste: -
_END_
        }
        my $file = File::Temp->new( template => '.locket.cfg.XXXXXXX', dir => '.', unlink => 1 ); # TODO A better dir?
        my $plaincfg_edit = Term::EditorEdit->edit( file => $file, document => $plaincfg );
        if ( length $plaincfg_edit ) {
            $self->write_cfg( $plaincfg_edit );
            $self->stdout_clear;
            $self->say_stdout( "# Reload\n---\n" );
            $self->reload_cfg;
            $self->dispatch( '?' );
        }
        else {
        }
    },

    'cfg' => 'setup',
    'config' => 'setup',

    qr/^q(?:u(?:i?)?)?$/ => 'quit',
    'quit' => sub {
        my ( $self, $method ) = @_;
        exit 0;
    },

    qr/^h(?:e(?:l?)?)?$/ => 'help',
    'help' => sub {
        my ( $self, $method ) = @_;

        my $edit = $self->cfg->{ edit };
        my $read = $self->cfg->{ read };
        my $cfg_file = $self->locket->cfg_file;

        $self->stdout( <<_END_ );
    
    /<query>            Search the store for <query> and emit the
                        resulting secret

                        Alternatively, append a term to the last query
                        and re-search

    .                   Redisplay the results of the last query

    ..                  Pop the last term off the last query (if any) 
                        and re-search

    //<query>           Search the store for <query>, ignoring
                        any previous query

    list                List all the entries in the store

    edit                Edit the store (via $edit)

    read                Show the plainstore through \$PAGER/sensible-pager (via $read)

    cfg                 Configure locket ($cfg_file)

    reset/clear         Clear the screen and wipe the last query/
                        current search

    reload              Reload the configuration file and
                        the store (the secret database)

_END_
    },

    'lock' => sub {
        my ( $self, $method ) = @_;

        my $passphrase = $self->read_passphrase( 'Passphrase: ' );
        $self->say_stderr;
        if ( ! defined $passphrase || ! length $passphrase ) {
            $self->say_stderr( "# No passphrase entered" );
        }
        else {
            $self->passphrase( $passphrase );
            $self->write_cfg( $self->plaincfg );
        }
    },

    'unlock' => sub {
        my ( $self, $method ) = @_;

        $self->passphrase( undef );
        $self->write_cfg( $self->plaincfg );
    },

    qr/^e(?:d(?:i?)?)?$/ => 'edit',
    'edit' => sub {
        my ( $self, $method ) = @_;

        my $edit = $self->cfg->{ edit };
        if ( defined $edit && length $edit ) {
            system( $edit );
            # TODO If error...
            $self->stdout_clear;
            $self->say_stdout( "# Reload\n---\n" );
            $self->locket->reload;
            $self->dispatch( '?' );

        }
        else {
            $self->say_stderr( "% Missing (edit) in cfg" );
        }
    },

    qr/^r(?:e(?:a?)?)?$/ => 'read',
    'read' => sub {
        my ( $self, $method ) = @_;
        return unless $self->check_read;

        my $plainstore = $self->read;
        $self->safe_pager( sub {
            my $fh = shift;
            $fh->print( $plainstore );
        }, clear => 1 );
        $self->dispatch( '?' );
    },


    qr/^l(?:i(?:s?)?)?$/ => 'list',
    'list' => sub {
        my ( $self, $method ) = @_;
        return unless $self->check_read;

        my @keys = $self->store->all;

        $self->do_pager( sub {
            my $fh = shift;
            $fh->print( "\n" );
            $fh->print( sprintf "# Total: %d\n", scalar @keys );
            $fh->print( "\n" );
            $fh->print( join "\n", ( map { "   $_" } @keys ), '' );
            $fh->print( "\n" );
        }, clear => 1 );
    },

    qr/^(\/+|\.\.|\.)(.*)/ => sub {
        my ( $self, $method ) = @_;

        my $store = $self->store;
        my $last_query = $self->query;
        my $last_found = $self->found;

        my $stash = $self->stash;
        my $dotted = $stash->{_}[0] eq '.';
        my $dotdotted = $stash->{_}[0] eq '..';

        my ( @query, @result_query, @result_found );
        @query = @$last_query;

        if ( $dotdotted ) {
            pop @query;
        }
        if ( $dotted ) {
            @result_query = @$last_query;
            @result_found = @$last_found;
        }
        else {
            my $slashes = length( $stash->{_}[0] ) || 0;
            my $target = $stash->{_}[1];

            if ( !$dotdotted && 2 == $slashes ) {
                undef @query;
            }

            $target = trim $target;
            if ( length $target ) {
                # Last search was a dud, so we'll pop the last term
                pop @query unless @$last_found;
                push @query, $target;
            }

            my $result = $self->store->search( \@query );
            @result_query = @{ $result->{ query } };
            @result_found = @{ $result->{ found } };

            $self->query( \@result_query );
            $self->found( \@result_found );
        }

        my $total = @result_found;
        my ( @visible, @invisible );
        @visible = @result_found;
        if ( @visible > 10 ) {
            @invisible = splice @visible, 10;
        }

        $self->stdout_clear;
        if ( @result_query and @query != @result_query ) {
            $self->say_stdout( sprintf "# Search: %s (%s)", join( '/', @result_query ), join( '/', @query ) );
        }
        elsif ( @query ) {
            $self->say_stdout( sprintf "# Search: %s", join '/', @query );
        }
        else {
            $self->say_stdout( sprintf "# Search: %s", '<nil>' );
        }
        $self->say_stdout( "---\n\n" );
        if ( @visible ) {
            my $n = 0;
            $self->say_stdout( "    $n2k{$n++}. $_" ) for @visible;
            $self->say_stdout;
        }

        if ( @invisible ) {
            $self->say_stdout( sprintf "# Showing %d out of %d", scalar @visible, $total ); 
            $self->say_stdout( "# Refine your search: /<query>" );
        }
        else {
            $self->say_stdout( sprintf "# Found %d", $total );
        }
        $self->say_stdout( "# Redo your search: //<query>" );
        #$self->say_stdout( sprintf "# Select an entry: [%s]", join '', map { $n2k{$_} } 0 .. @visible - 1 );
        #$self->say_stdout( sprintf "# Show an entry: show <entry>" );
        if ( @visible ) {
            $self->say_stdout( sprintf "# Unrefine your search: .." );
            $self->say_stdout( sprintf "# Show an entry: show [%s]", join '', map { $n2k{$_} } 0 .. @visible - 1 );
            $self->say_stdout( sprintf "# Copy the an entry to the clipboard: copy <entry>" );
        }
        else {
            $self->say_stdout( sprintf "# Show list: list" );
        }

        $self->say_stdout;
    },

    qr/^s(?:h(?:o(?:w)?)?)?\s*(\d+)/ => $_show,

    qr/^c(?:o(?:p(?:y)?)?)?\s*(\d+)/ => $_copy,

    qr/^cp\s*(\d+)/ => $_copy,

    reset => sub {
        my ( $self, $method ) = @_;
        $self->query( [] );
        $self->found( [] );
        delete @{ $self->stash }{qw/ target entry /};
        $self->stdout_clear;
        $self->dispatch( '?' );
    },

    clear => 'reset',

    reload => sub {
        my ( $self, $method ) = @_;
        $self->reload_cfg;
        $self->stdout_clear;
        $self->say_stdout( "# Reload\n---\n" );
        $self->dispatch( '?' );
    },

    qr/^([0-9])$/ => sub {
        my ( $self, $method ) = @_;

        return unless my ( $target, $entry, $k, $n ) = $self->_select;
        my $stash = $self->stash;
        @$stash{qw/ target entry /} = ( $target, $entry );

        my $query = $self->query;

        $self->stdout_clear;
        $self->say_stdout( "# Select $k ($target)\n---\n" );
        $self->say_stdout( "# Show entry ($target): show" );
        $self->say_stdout( "# Copy the entry into the clipboard: copy" );
        $self->say_stdout( sprintf "# Show last search: / (%s)", join '/', @$query ) if @$query;
        $self->say_stdout;
    },

    qr/^s(?:h(?:o?)?)?$/ => 'show',
    show => sub {
        my ( $self, $method ) = @_;

        my ( $target, $entry ) = $self->get_target_entry;
        return unless defined $target;
        $self->emit_entry( $target, $entry );
        $self->dispatch( '.' );
    },

    qr/^c(?:o(?:p)?)?$|cp$/ => 'copy',
    copy => sub {
        my ( $self, $method ) = @_;

        my ( $target, $entry ) = $self->get_target_entry;
        return unless defined $target;
        $self->emit_entry( $target, $entry, copy => 1 );
    },

);

sub dispatch {
    my $self = shift;
    my $method = shift;

    defined or $_ = '' for $method;

    my $result = $DISPATCH->dispatch( $method );

    return unless $result;

    $self->stash->{_} = [ $result->captured ];
    return $result->value->( $self, $method );
}

sub stdout {
    my $self = shift;
    my $fh = \*STDOUT if 1;
    $fh->print(  join '', @_ ) if @_;
    return $fh;
}

sub say_stdout {
    my $self = shift;
    my $emit = join '', @_;
    chomp $emit;
    $self->stdout( $emit, "\n" );
}

sub safe_pager {
    my $self = shift;
    if ( $self->options->{ unsafe } ) {
    }
    else {
        $self->stderr( "\n# Press RETURN to show the plaintext" );
        $self->stdin_readreturn;
    }
    $self->do_pager( @_ );
    $self->stdout_clear;
}

sub safe_stdout {
    my $self = shift;
    if ( $self->options->{ unsafe } ) {
    }
    else {
        $self->stderr( "\n# Press RETURN to show the plaintext" );
        $self->stdin_readreturn;
    }
    $self->stdout_clear;
    $self->stdout( "\n", @_ );
    $self->stderr( "\n# Press RETURN to clear the screen and continue" );
    $self->stdin_readreturn;
    $self->stdout_clear;
}

sub stdout_clear {
    my $self = shift;
    $self->stdout( "\x1b[2J\x1b[H" );
}

sub stderr {
    my $self = shift;
    my $fh = \*STDERR if 1;
    $fh->print(  join '', @_ ) if @_;
    return $fh;
}

sub say_stderr {
    my $self = shift;
    my $emit = join '', @_;
    chomp $emit;
    $self->stderr( $emit, "\n" );
}

sub stdin {
    return \*STDIN;
}

sub read_passphrase {
    my $self = shift;
    my $prompt = shift;
    if ( defined $prompt ) {
        $self->stderr( $prompt );
    }

    my $passphrase;
    ReadMode 2;
    try {
        $passphrase = $self->stdin->getline;
        chomp $passphrase;
    }
    finally {
        ReadMode 0;
    };

    return $passphrase;
}

sub stdin_readline {
    my $self = shift;

    my $input = "";

    try {
        ReadMode 3;
        my $escape = 0;
        my $chr;
        while ( defined ( $chr = ReadKey ) ) {
            if ( $escape ) {
                $escape--;
                next;
            }
            my $ord = ord $chr;
            if ( $ord >= 32 && $ord < 127 ) {
                print $chr;
                $input .= $chr;
            }
            elsif ( $ord == 27 ) {
                $escape = 2;
            }
            elsif ( $ord == 13 || $ord == 10 ) {
                print "\n";
                last;
            }
            else {
                if ( $ord == 8 || $ord == 127 ) {
                    if ( length $input ) {
                        $input = substr $input, 0, -1 + length $input;
                        print "\b \b";
                    }
                }
                elsif ( $ord == 21 ) {
                    print "\r", (" " x ( 2 * length $input ) ), "\r";
                    print "> ";
                    $input = "";
                }
            }
        }
    }
    catch {
        print "\n";
    }
    finally {
        ReadMode 0;
    };

    return $input;
}

sub check_read {
    my $self = shift;
    return 1 if $self->can_read;
    $self->say_stderr( "% Missing (read) in cfg" );
    return 0;
}

sub stdin_readreturn {
    my $self = shift;
    my $delay = shift;
    ReadMode 2; # Disable keypress echo
    while ( 1 ) {
        my $continue = ReadKey $delay;
        last unless defined $continue;
        chomp $continue;
        last unless length $continue;
    }
    ReadMode 0;
}

sub copy {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    my $SIG_INT = $SIG{ INT } || sub { exit 1 };
    local $SIG{ INT } = sub {
        $self->do_copy( '' );
        ReadMode 0;
        $SIG_INT->();
    };

    my $delay = $self->options->{ delay };
    if ( $delay ) {
        $self->say_stdout( sprintf "# Press RETURN to copy {$name} into clipboard with %d:%02d delay", int( $delay / 60 ), $delay % 60 );
    }
    else {
        $self->say_stdout( "# Press RETURN to copy {$name} into clipboard for NO delay" );
    }
    $self->stdin_readreturn;
    $self->do_copy( $value );
    $self->say_stdout( "# Copied -- Press RETURN again to wipe clipboard and continue" );
    $self->stdin_readreturn( $delay );
    $self->say_stdout;
    my $paste = $self->do_paste;
    if ( ! defined $paste || $paste eq $value ) {
        # To be safe, we wipe out the clipboard in the case where
        # we were unable to get a read on the clipboard (pbpaste, xsel, or
        # xclip failed)
        $self->do_copy( '' ); # Wipe out clipboard
    }
}

sub editor_prgm {
    my $self = shift;

    my $found = $self->cfg->{ editor };
    defined and return $_ for $found;

    $found = $self->_find_prgm( 'sensible-editor' );
    defined and return $_ for $found;

    $found = $ENV{ VISUAL };
    defined and return $_ for $found;

    $found = $ENV{ EDITOR };
    defined and return $_ for $found;

    return;
}

sub do_pager {
    my $self = shift;
    my $content = shift;
    my %options = @_;

    my $prgm = $self->pager_prgm;

    if ( ! defined $prgm ) {
        $self->say_stderr( "% Missing (pager) in cfg/\$PAGER" );
        return;
    }

    if ( $options{ clear } ) {
        $self->stdout_clear;
    }

    open my $fh, '|-', $prgm;
    if ( ref $content eq 'CODE' ) {
        $content->( $fh );
    }
    else {
        $fh->print( $content );
    }
    close $fh;

    return 1;
}

sub pager_prgm {
    my $self = shift;

    my $found = $self->cfg->{ pager };
    defined and return $_ for $found;

    $found = $self->_find_prgm( 'sensible-pager' );
    defined and return $_ for $found;

    $found = $ENV{ PAGER };
    defined and return $_ for $found;

    $found = $self->_find_prgm( 'less' );
    defined and return $_ for $found;

    return;
}

sub _find_prgm {
    my $self = shift;
    my $name = shift;

    for (qw{ /bin /usr/bin }) {
        my $cmd = file split( '/', $_ ), $name;
        return $cmd if -f $cmd && -x $cmd;
    }

    return undef;
}

sub do_copy {
    my $self = shift;
    my $value = shift;

    my $copy = $self->cfg->{ copy };
    if ( defined $copy ) {
        $self->_pipe_into( $copy => $value );
        return 1;
    }

    if ( lc $^O eq 'darwin' ) {
        return 1 if $self->_try_copy( 'pbcopy', $value );
    }

    return 1 if $self->_try_copy( 'xsel', $value );
    return 1 if $self->_try_copy( 'xclip', $value );
    return;
}

sub _try_copy {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    my $execute = $App::locket::Util::COPY{ $name };
    if ( ! $execute ) {
        warn "*** Missing (copy) CODE for $name";
        return;
    }
    return unless my $prgm = $self->_find_prgm( $name );
    $execute->( $self, $prgm, $value );
    return 1;
}

sub _pipe_into {
    my $self = shift;
    my $cmd = shift;
    my $value = shift;

    open my $pipe, '|-', $cmd or die $!;
    $pipe->print( $value );
    close $pipe;
}

sub do_paste {
    my $self = shift;

    my $paste = $self->cfg->{ paste };
    if ( defined $paste ) {
        return $self->_pipe_outfrom( $paste );
    }

    my $value;
    if ( lc $^O eq 'darwin' ) {
        $value = $self->_try_paste( 'pbpaste' );
        return $value if defined $value;
    }

    $value = $self->_try_paste( 'xsel' );
    return $value if defined $value;

    $value = $self->_try_paste( 'xclip' );
    return $value if defined $value;

    return;
}

sub _try_paste {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    my $execute = $App::locket::Util::PASTE{ $name };
    if ( ! $execute ) {
        warn "*** Missing (paste) CODE for $name";
        return;
    }
    return unless my $prgm = $self->_find_prgm( $name );
    return $execute->( $self, $prgm );
}

sub _pipe_outfrom {
    my $self = shift;
    my $cmd = shift;
    my $value = shift;

    open my $pipe, '-|', $cmd or die $!;
    return join '', <$pipe>;
}

1;



=pod

=head1 NAME

App::locket - Copy secrets from a YAML/JSON cipherstore into the clipboard (pbcopy, xsel, xclip)

=head1 VERSION

version 0.0022

=head1 SYNOPSIS

    # Setup the configuration file for the cipherstore:
    # (How to read the cipherstore, how to edit the cipherstore, etc.)
    $ locket setup

    # Add or change data in the cipherstore:
    $ locket edit

    # List all the entries in the cipherstore:
    $ locket /

    # Show a secret from the cipherstore:
    $ locket /alice@gmail

=head1 DESCRIPTION

App::locket is a tool for querying a simple YAML/JSON-based cipherstore 

It has a simple commandline-based querying method and supports copying into the clipboard 

Currently, encryption and decryption is performed via external tools (e.g. GnuPG, OpenSSL, etc.)

App::locket is best used with:

* gnupg.vim L<http://www.vim.org/scripts/script.php?script_id=661>

* openssl.vim L<http://www.vim.org/scripts/script.php?script_id=2012>

* EasyPG L<http://www.emacswiki.org/emacs/AutoEncryption>

=head1 SECURITY

=head2 Encryption/decryption

App::locket defers actual encryption/decryption to external tools. The choice of the actual
cipher/encryption method is left up to you

If you're using GnuPG, then you could use C<gpg-agent> for passphrase prompting and limited retention

=head2 In-memory encryption

App::locket does not perform any in-memory encryption; once the cipherstore is loaded it is exposed in memory

In addition, if the process is swapped out while running then the plaintextstore could be written to disk

Encrypting swap is one way of mitigating this problem

=head2 Clipboard access

App::locket uses third-party tools for read/write access to the clipboard. It tries to detect if
C<pbcopy>, C<xsel>, or C<xclip> are available. It does this by looking in C</bin> and C</usr/bin>

=head2 Purging the clipboard

By default, App::locket will purge the clipboard of a secret it put there after a set delay. It will try to verify that it is
wiping what it put there in the first place (so it doesn't accidentally erase something else you copied)

If for some reason App::locket cannot read from the clipboard, it will purge it just in case

If you prematurely cancel a secret copying operation via CTRL-C, App::locket will catch the signal and purge the clipboard first

=head2 Attack via configuration

Currently, App::locket does not encrypt/protect the configuration file. This means an attacker can potentially (unknown to you) modify
the reading/editing commands to divert the plaintext elsewhere

There is an option to lock the configuration file, but given the ease of code injection you're probably better off installing and using App::locket in a dedicated VM

=head2 Resetting $PATH

C<$PATH> is reset to C</bin:/usr/bin>

=head1 INSTALL

    $ cpanm -i App::locket

=head1 INSTALL cpanm

L<http://search.cpan.org/perldoc?App::cpanminus#INSTALLATION> 

=head1 USAGE

    locket [options] setup|edit|<query>

        --delay <delay>     Keep value in clipboard for <delay> seconds
                            If value is still in the clipboard at the end of
                            <delay> then it will be automatically wiped from
                            the clipboard

        --unsafe            Turn the safety off. This will disable prompting
                            before emitting any sensitive information in
                            plaintext. There will be no opportunity to
                            abort (via CTRL-C)

        setup               Setup a new or edit an existing user configuration
                            file (~/.locket/cfg)

        edit                Edit the cipherstore
                            The configuration must have an "edit" value, e.g.:

                                /usr/bin/vim -n ~/.locket.gpg


        /<query>            Search the cipherstore for <query> and emit the
                            resulting secret
                            
                            The configuration must have a "read" value to
                            tell it how to read the cipherstore. Only piped
                            commands are supported today, and they should
                            be something like:

                                </usr/local/bin/gpg -q --no-tty -d ~/.locket.gpg'

                            If the found key in the cipherstore is of the format
                            "<username>@<site>" then the username will be emitted
                            first before the secret (which is assumed to be a password/passphrase)

        Type <help> in-process for additional usage

=head1 Example YAML cipherstore

    %YAML 1.1
    ---
    # A GMail identity
    alice@gmail: p455w0rd
    # Some frequently used credit card information
    cc4123: |
        4123412341234123
        01/23
        123

=head1 Example configuration file

    %YAML 1.1
    ---
    read: '</usr/local/bin/gpg --no-tty --decrypt --quiet ~/.locket.gpg'
    edit: '/usr/bin/vim -n ~/.locket.gpg'

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

