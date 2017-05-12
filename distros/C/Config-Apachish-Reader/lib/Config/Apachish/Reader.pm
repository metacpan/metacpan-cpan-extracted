package Config::Apachish::Reader;

our $DATE = '2016-03-11'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Config::Apachish::Base);

sub _init_read {
    my $self = shift;

    $self->SUPER::_init_read;
    $self->{_context_stack} = [ ['', []] ]; # name, nodes
}

sub _read_string {
    my ($self, $str) = @_;

    my $ctxs  = $self->{_context_stack};
    my $nodes = $ctxs->[0][1];

    my @lines = split /^/, $str;
    local $self->{_linum} = 0;
  LINE:
    for my $line (@lines) {
        $self->{_linum}++;

        #use DD; dd $ctxs; say '';

        # blank line
        if ($line !~ /\S/) {
            next LINE;
        }

        # open/close context line
        if ($line =~ s!\A\s*<!!) {
            if ($line =~ s!\A/!!) {
                # close context
                $self->_err("Invalid close context line")
                    unless $line =~ /\A(\w+)>$/;
                my $ctx_name = lc($1);
                $self->_err("Close context line '$ctx_name' without ".
                                "previous open")
                    unless @$ctxs > 1 && $ctxs->[-1][0] eq $ctx_name;
                pop @$ctxs;
            } else {
                # open context
                $self->_err("Invalid open context line")
                    unless $line =~ s/\A(\w+)(?:\s+(\S.*))?>$//;
                my $ctx_name = lc($1);
                my $args_s = $2;
                my $args;
                if (length($args_s)) {
                    $args = $self->_parse_command_line($args_s);
                    $self->_err("Invalid argument syntax in open context line")
                        unless defined $args;
                } else {
                    $args = [];
                }
                my $children = [];
                my $node = ['C', $ctx_name, $args, $children];
                push @$nodes, $node;
                $nodes = $children;
                push @$ctxs, [$ctx_name, $nodes];
            }
            next LINE;
        }

        # comment line
        if ($line =~ /\A\s*#/) {
            next LINE;
        }

        # directive line
        if ($line =~ /\A\s*(\w+)\s+(\S.*)$/) {
            my $dir_name = lc($1);
            my $args = $self->_parse_command_line($2);
            if (!defined($args)) {
                $self->_err("Invalid argument syntax in directive line");
            }
            push @{$ctxs->[-1][1]}, ['D', $dir_name, $args];
            # TODO: handle include
            next LINE;
        }

        $self->_err("Invalid directive syntax");
    }

    #use DD; dd $ctxs;

    if (@$ctxs > 1) {
        $self->_err("Unclosed context '$ctxs->[-1][0]'");
    }

    $ctxs->[0][1];
}

1;
# ABSTRACT: Read Apachish configuration files

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Apachish::Reader - Read Apachish configuration files

=head1 VERSION

This document describes version 0.03 of Config::Apachish::Reader (from Perl distribution Config-Apachish-Reader), released on 2016-03-11.

=head1 SYNOPSIS

 use Config::Apachish::Reader;
 my $reader = Config::Apachish::Reader->new(
     # list of known attributes, with their default values
 );
 my $config_array = $reader->read_file('config.conf');

=head1 DESCRIPTION

This module reads L<Apachish> configuration files (a format mostly compatible
with Apache webserver configuration format). It is a minimalist alternative to
the more fully-featured L<Config::Apachish>. It cannot write/modify Apachish
files and is optimized for low startup overhead.

=head1 ATTRIBUTES

=head1 METHODS

=head2 new(%attrs) => obj

=head2 $reader->read_file($filename) => hash

Read configuration from a file. Die on errors.

=head2 $reader->read_string($str) => hash

Read configuration from a string. Die on errors.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Config-Apachish-Reader>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Config-Apachish-Reader>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-Apachish-Reader>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Apachish> - specification

L<Config::Apachish> - round-trip parser for reading as well as writing Apachish
documents

L<Apachish::Examples> - sample documents

Prior arts: L<Config::ApacheFormat>, L<Apache::ConfigFile>, L<Config::General>,
L<Config::ApacheExtended>. A more in-depth comparison between these modules and
Apachish will be made in the future.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
