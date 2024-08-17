package App::optex::mask;

use 5.024;
use warnings;

our $VERSION = "0.01";

=encoding utf-8

=head1 NAME

App::optex::mask - optex data masking module

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    optex -Mmask patterns -- command

=head1 DESCRIPTION

App::optex::mask is an B<optex> module for masking data given as
standard input to a command to be executed. It transforms strings
matching a specified pattern according to a set of rules before giving
them as input to a command, and restores the resulting content to the
original string.

Multiple conversion rules can be specified, but currently only C<xml>
is supported.  This is for B<deepl> translation interface, and
converts a string to an XML tag such as C<< <m id=999 /> >>.

The following example translates an English sentence into French.

    $ echo All men are created equal | deepl text --to FR "$(cat)"
    Tous les hommes sont créés égaux

If you want to leave part of a sentence untranslated, specify a
pattern that matches the string.

    $ echo All men are created equal | \
        optex -Mmask::set=debug men -- sh -c 'deepl text --to FR "$(cat)"'
    [1] All men are created equal
    [2] All <m id=1 /> are created equal
    [3] Tous les <m id=1 /> sont créés égaux
    [4] Tous les men sont créés égaux
    Tous les men sont créés égaux

=head1 PARAMETERS

Parameters are given as options for C<set> function at module startup.

For example, to enable the debugging option, specify the following. If
no value is specified, it defaults to 1 and can be omitted.

    optex -Mmask::set(debug=1)
    optex -Mmask::set(debug)

This could be written as follows.  This is somewhat easier to type
from the shell, since it does not use parentheses.

    optex -Mmask::set=debug=1
    optex -Mmask::set=debug

=over 7

=item B<encode>

=item B<decode>

Enable encoding and decoding.  You can check how it is encoded by
disabling the C<decode> option.

=item B<mode>

The default is C<xml>, which is the only supported at this time.

=item B<start>

Specifies the initial value of the number used as id in xml tag.
Default is 1.

=item B<debug>

Enable debugging.

=back

=head1 INSTALL

=head2 CPANM

    cpanm App::optex::mask

=head1 SEE ALSO

=over 2

=item *

L<App::optex>

=item *

L<App::Greple::xlate>

=item *

L<https://www.deepl.com>

=item *

L<https://github.com/DeepLcom/deepl-python>

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright ©︎ 2024 Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use List::Util qw(first);
use Hash::Util qw(lock_keys);
use Data::Dumper;

our @mask_pattern;
my  @restore_list;

my %option = (
    mode   => 'xml',
    encode => 1,
    decode => 1,
    start  => 1,
    debug  => undef,
);
lock_keys(%option);

my($mod, $argv);

sub initialize {
    ($mod, $argv) = @_;
    if (defined (my $i = first { $argv->[$_] eq '--' } keys @$argv)) {
	@mask_pattern = splice @$argv, 0, $i;
	shift @$argv eq '--' or die;
    }
}

sub debug {
    $option{debug} or return;
    my $mark = shift // 'debug';
    local *_ = @_ ? \$_[0] : \$_;
    warn s/^/[$mark] /mgr;
}

my %newtag = (
    xml => sub {
	my $s = shift;
	state $id = $option{start};
	sprintf "<m id=%d />", $id++;
    },
);

sub newtag {
    state $f = $newtag{$option{mode}}
	or die "$option{mode}: unknown mode.\n";
    $f->(@_);
}

sub mask {
    my %arg = @_;
    my $mode = $arg{mode};
    local $_ = do { local $/; <> } // die $!;
    $option{encode} or return $_;
    my $id = 0;
    debug 1;
    for my $pat (@mask_pattern) {
	s{$pat}{
	    my $tag = newtag(${^MATCH});
	    push @restore_list, $tag, ${^MATCH};
	    $tag;
	}gpe;
    }
    debug 2;
    return $_;
}

sub unmask {
    my %arg = @_;
    my $mode = $arg{mode};
    local $_ = do { local $/; <> } // die $!;
    $option{decode} or do { print $_; return };
    my @restore = @restore_list;
    debug 3;
    while (my($str, $replacement) = splice @restore, 0, 2) {
	s/\Q$str/$replacement/g;
    }
    use Encode ();
    $_ = Encode::decode('utf8', $_) if not utf8::is_utf8($_);
    debug 4;
    print $_;
}

sub set {
    while (my($k, $v) = splice(@_, 0, 2)) {
	exists $option{$k} or next;
	$option{$k} = $v;
    }
    ();
}

1;

__DATA__

autoload -Mutil::filter --osub --psub

option default \
    --psub __PACKAGE__::mask \
    --osub __PACKAGE__::unmask
