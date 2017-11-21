use strict;
use warnings;

package App::adler32;
# ABSTRACT: Comand-line utility for computing Adler32 digest
our $VERSION = '0.001'; # VERSION
use base 'App::Cmd::Simple';
use charnames qw();
use open qw( :encoding(UTF-8) :std );
use Module::Load qw(load);
use Getopt::Long::Descriptive;


use utf8;
use Digest::Adler32 qw(adler32);

=pod

=encoding utf8

=head1 NAME

adler32 - Command-line utility for computing Adler32 digest

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    $ echo Hey | adler32
    31014f03

=head1 OPTIONS

=head2 version / v

Shows the current version number

    $ adler32 --version

=head2 help / h

Shows a brief help message

    $ adler32 --help

=cut

sub opt_spec {
    return (
        [ 'version|v'         => "show version number"     ],
        [ 'help|h'            => "display a usage message" ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    if ($opt->{'help'}) {
        my ($opt, $usage) = describe_options(
            $self->usage_desc(),
            $self->opt_spec(),
        );
        print $usage;
        print "\n";
        print "For more detailed help see 'perldoc App::adler32'\n";

        print "\n";
        exit;
    }
    elsif ($opt->{'version'}) {
        print $App::adler32::VERSION, "\n";
        exit;
    }

    return;
}

sub execute {
    my ($self, $opt, $args) = @_;

    while (<>) {
        my $a32 = Digest::Adler32->new;
        $a32->add($_);
        my $digest = unpack 'H*', pack 'N', unpack 'L', $a32->digest;
        print $digest, "\n";
    }

    return;
}

1;

__END__

=head1 GIT REPOSITORY

L<http://github.com/athreef/App-adler32>

=head1 SEE ALSO

L<Digest::Adler32>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
