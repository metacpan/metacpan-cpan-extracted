package App::QuoteCC;
BEGIN {
  $App::QuoteCC::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $App::QuoteCC::VERSION = '0.10';
}

use 5.010;
use strict;
use warnings;
use Moose;
use namespace::clean -except => 'meta';

with qw/ MooseX::Getopt::Dashes /;

# MooseX::Getopt 81b19ed83c by Karen Etheridge changed the help
# attribute to help_flag.
{
my @go_attrs = MooseX::Getopt::GLD->meta->get_attribute_list;
my $help_attr = 'help_flag' ~~ @go_attrs ? 'help_flag' : 'help';
has $help_attr => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'h',
    cmd_flag      => 'help',
    isa           => 'Bool',
    is            => 'ro',
    default       => 0,
    documentation => 'This help message',
);
}

has input => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'i',
    cmd_flag      => 'input',
    isa           => 'Str',
    is            => 'ro',
    documentation => 'The quotes file to compile from. - for STDIN',
);

has input_format => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'I',
    cmd_flag      => 'input-type',
    isa           => 'Str',
    is            => 'ro',
    documentation => 'The format of the input quotes file. Any App::QuotesCC::Input::*',
);

has output => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'o',
    cmd_flag      => 'output',
    isa           => 'Str',
    is            => 'ro',
    default       => '-',
    documentation => 'Where to output the compiled file, - for STDOUT',
);

has output_format => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'O',
    cmd_flag      => 'output-type',
    isa           => 'Str',
    is            => 'ro',
    documentation => 'The format of the output file. Any App::QuotesCC::Output::*',
);

sub run {
    my ($self) = @_;

    my $dynaload = sub {
        my ($vars, $new_args) = @_;
        my ($self_method_type, $class_type) = @$vars;
        my %args = %$new_args;

        my $x_class_short = $self->$self_method_type;
        my $x_class = "App::QuoteCC::${class_type}::" . $x_class_short;
        {
            my $x_class_pm = $x_class;
            $x_class_pm =~ s[::][/]g;
            $x_class_pm .= ".pm";
            require $x_class_pm;
        }
        my $obj = $x_class->new(%args);
        return $obj;
    };

    my $input  = $dynaload->(
        [ qw/ input_format Input / ],
        { file => $self->input },
    );
    my $quotes = $input->quotes;
    my $output = $dynaload->(
        [ qw/ output_format Output / ],
        {
            file => $self->output,
            quotes => $quotes,
        },
    );
    $output->output;

    return;
}

__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 NAME

App::QuoteCC - Take a quote file and emit a standalone program that spews a random quote

=head1 SYNOPSIS

Compile a quotes file to a stand-alone binary:

    curl http://v.nix.is/~failo/quotes.yml | quotecc -i - -I YAML -o - -O C | gcc -x c -o failo-wisdom -
    curl http://www.trout.me.uk/quotes.txt | quotecc -i - -I Fortune -o - -O C | gcc -x c -o perl-wisdom -

Or to a fast stand-alone minimal Perl script:

    curl http://v.nix.is/~failo/quotes.yml | quotecc -i - -I YAML -o failo-wisdom.pl -O Perl
    curl http://www.trout.me.uk/quotes.txt | quotecc -i - -I Fortune -o perl-wisdom.pl -O Perl

See how small they are:

    $ du -sh *-wisdom*
    56K     failo-wisdom
    44K     failo-wisdom.pl
    80K     perl-wisdom
    76K     perl-wisdom.pl

Emit a random quote with the C program:

    time (./failo-wisdom && ./perl-wisdom)
    Support Batman - vote for the British National Party
    < dha> Now all I have to do is learn php
    <@sungo> it's easy.
    <@sungo> take your perl knowledge. now smash it against child pornography

    real    0m0.004s
    user    0m0.000s
    sys     0m0.008s

Or with the Perl program:

    $ time (perl failo-wisdom.pl && perl perl-wisdom.pl)
    I just see foreign words like private public static void feces implements shit extending penis
    <@pndc> Imagine if cleaners were treated like sysadmins. "I've just
            pissed all over the office floor; it's the cleaner's fault."

    real    0m0.022s
    user    0m0.012s
    sys     0m0.004s

Emit all quotes:

    ./failo-wisdom --all > /tmp/quotes.txt

Emit quotes to interactive shells on login, in F</etc/profile>:

    # spread failo's wisdom to interactive shells
    if [[ $- == *i* ]] ; then
        failo-wisdom
    fi

=head1 DESCRIPTION

I wrote this program because using L<fortune(1)> and Perl in
F</etc/profile> to emit a random quote on login was too slow. On my
system L<fortune(1)> can take ~100 ms from a cold start, although
subsequent invocations when it's in cache are ~10-20 ms.

Similarly using Perl is also slow, this is in the 80 ms range:

    perl -COEL -MYAML::XS=LoadFile -E'@q = @{ LoadFile("/path/to/quotes.yml") }; @q && say $q[rand @q]'

Either way, when you have a 40 ms ping time to the remote machine
showing that quote is the major noticeable delay when you do I<ssh
machine>.

L<quotecc> solves that problem, showing a quote takes around 4 ms
now. That's comparable with any hello wold program in C that I
produce.

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

