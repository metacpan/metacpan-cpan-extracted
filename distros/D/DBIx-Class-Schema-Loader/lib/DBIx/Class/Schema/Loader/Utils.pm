package # hide from PAUSE
    DBIx::Class::Schema::Loader::Utils;

use strict;
use warnings;
use String::CamelCase 'wordsplit';
use Carp::Clan qw/^DBIx::Class/;
use List::Util 'all';
use namespace::clean;
use Exporter 'import';
use Data::Dumper ();

our @EXPORT_OK = qw/split_name dumper dumper_squashed eval_package_without_redefine_warnings class_path no_warnings warnings_exist warnings_exist_silent slurp_file write_file array_eq sigwarn_silencer apply firstidx uniq/;

use constant BY_CASE_TRANSITION_V7 =>
    qr/(?<=[[:lower:]\d])[\W_]*(?=[[:upper:]])|[\W_]+/;

use constant BY_NON_ALPHANUM =>
    qr/[\W_]+/;

my $LF   = "\x0a";
my $CRLF = "\x0d\x0a";

sub split_name($;$) {
    my ($name, $v) = @_;

    my $is_camel_case = $name =~ /[[:upper:]]/ && $name =~ /[[:lower:]]/;

    if ((not $v) || $v >= 8) {
        return map split(BY_NON_ALPHANUM, $_), wordsplit($name);
    }

    return split $is_camel_case ? BY_CASE_TRANSITION_V7 : BY_NON_ALPHANUM, $name;
}

sub dumper($) {
    my $val = shift;

    my $dd = Data::Dumper->new([]);
    $dd->Terse(1)->Indent(1)->Useqq(1)->Deparse(1)->Quotekeys(0)->Sortkeys(1);
    return $dd->Values([ $val ])->Dump;
}

sub dumper_squashed($) {
    my $val = shift;

    my $dd = Data::Dumper->new([]);
    $dd->Terse(1)->Indent(1)->Useqq(1)->Deparse(1)->Quotekeys(0)->Sortkeys(1)->Indent(0);
    return $dd->Values([ $val ])->Dump;
}

# copied from DBIx::Class::_Util, import from there once it's released
sub sigwarn_silencer {
    my $pattern = shift;

    croak "Expecting a regexp" if ref $pattern ne 'Regexp';

    my $orig_sig_warn = $SIG{__WARN__} || sub { CORE::warn(@_) };

    return sub { &$orig_sig_warn unless $_[0] =~ $pattern };
}

# Copied with stylistic adjustments from List::MoreUtils::PP
sub firstidx (&@) {
    my $f = shift;
    foreach my $i (0..$#_) {
        local *_ = \$_[$i];
        return $i if $f->();
    }
    return -1;
}

sub uniq (@) {
    my %seen = ();
    grep { not $seen{$_}++ } @_;
}

sub apply (&@) {
    my $action = shift;
    $action->() foreach my @values = @_;
    wantarray ? @values : $values[-1];
}

sub eval_package_without_redefine_warnings {
    my ($pkg, $code) = @_;

    local $SIG{__WARN__} = sigwarn_silencer(qr/^Subroutine \S+ redefined/);

    # This hairiness is to handle people using "use warnings FATAL => 'all';"
    # in their custom or external content.
    my @delete_syms;
    my $try_again = 1;

    while ($try_again) {
        eval $code;

        if (my ($sym) = $@ =~ /^Subroutine (\S+) redefined/) {
            delete $INC{ +class_path($pkg) };
            push @delete_syms, $sym;

            foreach my $sym (@delete_syms) {
                no strict 'refs';
                undef *{"${pkg}::${sym}"};
            }
        }
        elsif ($@) {
            die $@ if $@;
        }
        else {
            $try_again = 0;
        }
    }
}

sub class_path {
    my $class = shift;

    my $class_path = $class;
    $class_path =~ s{::}{/}g;
    $class_path .= '.pm';

    return $class_path;
}

sub no_warnings(&;$) {
    my ($code, $test_name) = @_;

    my $failed = 0;

    my $warn_handler = $SIG{__WARN__} || sub { warn @_ };
    local $SIG{__WARN__} = sub {
        $failed = 1;
        $warn_handler->(@_);
    };

    $code->();

    Test::More::ok ((not $failed), $test_name);
}

sub warnings_exist(&$$) {
    my ($code, $re, $test_name) = @_;

    my $matched = 0;

    my $warn_handler = $SIG{__WARN__} || sub { warn @_ };
    local $SIG{__WARN__} = sub {
        if ($_[0] =~ $re) {
            $matched = 1;
        }
        else {
            $warn_handler->(@_)
        }
    };

    $code->();

    Test::More::ok $matched, $test_name;
}

sub warnings_exist_silent(&$$) {
    my ($code, $re, $test_name) = @_;

    my $matched = 0;

    local $SIG{__WARN__} = sub { $matched = 1 if $_[0] =~ $re; };

    $code->();

    Test::More::ok $matched, $test_name;
}

sub slurp_file($) {
    my $file_name = shift;

    open my $fh, '<:encoding(UTF-8)', $file_name,
        or croak "Can't open '$file_name' for reading: $!";

    my $data = do { local $/; <$fh> };

    close $fh;

    $data =~ s/$CRLF|$LF/\n/g;

    return $data;
}

sub write_file($$) {
    my $file_name = shift;

    open my $fh, '>:encoding(UTF-8)', $file_name,
        or croak "Can't open '$file_name' for writing: $!";

    print $fh shift;
    close $fh;
}

sub array_eq($$) {
    no warnings 'uninitialized';
    my ($l, $r) = @_;

    return @$l == @$r && all { $l->[$_] eq $r->[$_] } 0..$#$l;
}

1;
# vim:et sts=4 sw=4 tw=0:
