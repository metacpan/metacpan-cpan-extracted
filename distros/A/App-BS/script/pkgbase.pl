#!/usr/bin/env perl

use utf8;
use v5.40;

use lib 'lib';

use IPC::Run3;
use Const::Fast;
use Data::Dumper;
use List::Util 'uniq';

use BS::Common;
use BS::Ext::pacman;
use BS::Ext::expac;

our $DEBUG        => $ENV{DEBUG}        // 0;
our $SHORTCIRCUIT => $ENV{SHORTCIRCUIT} // 0;

const our $pkgnamebase_re => qr/[:a-zA-Z0-9\@_\+]{1}[a-zA-Z0-9\@_\+\.\+]+/;

# Prepends pkgname
const our $repo_re => qr/(?:([\/])\/)?/;
const our $type_re => qr/(?:(lib)\:)?/;

const our %sep_re => ( ver => qr/(\=|[\<\>]\=?)/, dssc => qr/(:\s*(.+))?/ );
const our $not_pkgver_rew => quotemeta(':/-') . '\s';

const our $fpath_re =>
  qr/^(?:\/)?([a-zA-Z0-9\@_\+\.\+]+\/)?([a-zA-Z0-9\@_\+\.\+]+)$/;

# Apppends pkgname (cmpop, ver, description)

our @pkg        = ();
our %outbuffers = ();

sub expac_parse_line ( $line, %opts ) {
    $opts{on_parse_success}->( $line, %opts );
}

sub handle_run3_out ( $in, %opts ) {
    chomp $in;
    return undef unless $in;

    push $opts{out}->@*, expac_parse_line( $in, %opts );
}

sub parse_pkgstr ( $pkgstr, %opts ) {

    # These are newer/more general versions of constants above/in other
    # modules (currently, at least)
    const my $pkgstr_name_ptn => qr'[a-zA-Z0-9\@_\+]{1}[a-zA-Z0-9\@_\+\.\-]+';

    const my $pkgstr_name_re =>
      qr/^(lib\:)?($pkgstr_name_ptn(\.so(?:\.[0-9]+)?)|$pkgstr_name_ptn)/;

    const my $pkgver_forbidden => quotemeta(':/-') . '\s';

    #const my $pkgver_delim     => qr'(?:(\=|[\<\>]\=?)';

    const my @pkgstr_re_arr => (
        $pkgstr_name_re,             '(?:(\=|[\<\>]\=?)',
        "([^$pkgver_forbidden]+))?", '|(?:(:)\s*(.+))?'
    );

    const my $pkgstr_re_str => join '', @pkgstr_re_arr;

    const my $pkgstr_re  => qr/@pkgstr_re_arr/;    # Not working...
    const my $_pkgstr_re => qr/$pkgstr_re_str/;

    #:wqwarn np nojoin => $pkgstr_re join => $_pkgstr_re if $DEBUG;

    my ( $prefix, $_pkgstr, $isfile, $sep, $attr, @extra ) =
      $pkgstr =~ $_pkgstr_re;

    my %pkgstub = ();

    $pkgstub{name} = $_pkgstr;

    if ($sep) {
        if ( $sep ne ':' ) {
            $pkgstub{version} = $attr;
            $pkgstub{cmp_op}  = $sep;
        }
        elsif ( $sep eq ':' ) {    # Optional dependency most likely
                                   # Will have parsed that out elsewhere
            $pkgstub{description} = $attr;
            $pkgstub{name}        = $_pkgstr;
        }
    }

    if ( $isfile || $opts{database} && $opts{database} eq 'file' ) {
        $pkgstub{file} //= $_pkgstr;

        my $res = BS::Ext::pacman->pacman_query( $_pkgstr, database => 'file' );

        #BS::Common::dmsg { res => $res };

        $pkgstub{repo} = $$res{repo}    if $$res{repo};
        $pkgstub{name} = $$res{pkgname} if $$res{pkgname};
    }

    BS::Common::dmsg(
        {
            _pkgstr => $_pkgstr,
            isfile  => $isfile,
            sep     => $sep,
            attr    => $attr,
            pkgstub => \%pkgstub
        }
    ) if $BS::Common::DEBUG;

    \%pkgstub;
}

foreach my $arg (@ARGV) {
    my ( @out, $err );
    run3(
        [ qw"expac -Qs %e", "^$arg\$" ],
        \undef,
        sub ( $in, %opts ) {
            handle_run3_out(
                $in,
                out              => \@out,
                on_parse_success => sub ( $line, %opts ) {
                    push @pkg, $line;
                }
            );
        },
        $err
    );

    my $status = $?;

    if ($err) {
        warn "$status: $err";
        exit $status if $SHORTCIRCUIT;
        next;
    }
}

printf "%s\n", join ' ', @pkg;

warn Dumper(
    argv => \@ARGV,
    pkg  => \@pkg,
    diff => ( List::Util::uniqstr @ARGV, @pkg )
  )
  if $DEBUG
