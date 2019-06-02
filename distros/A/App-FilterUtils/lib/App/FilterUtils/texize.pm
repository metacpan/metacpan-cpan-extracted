use strict;
use warnings;
package App::FilterUtils::texize;
# ABSTRACT: Filter input through TeX::Encode
our $VERSION = '0.002'; # VERSION
use base 'App::Cmd::Simple';
use utf8;
use charnames qw();
use open qw( :encoding(UTF-8) :std );

use Getopt::Long::Descriptive;

use utf8;
use Encode;
use TeX::Encode;

=pod

=encoding utf8

=head1 NAME

texize - Convert Umlauts and other fancy Mn characters to TeX notation

=head1 SYNOPSIS

    $ echo Möwe | texize
    M\"o{}we

=head1 OPTIONS

=head2 version / v

Shows the current version number

    $ texize --version

=head2 help / h

Shows a brief help message

    $ texize --help

=cut

sub opt_spec {
    return (
        [ 'version|v'    => "show version number"                               ],
        [ 'help|h'       => "display a usage message"                           ],
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
        print "For more detailed help see 'perldoc App::FilterUtils::texize'\n";

        print "\n";
        exit;
    }
    elsif ($opt->{'version'}) {
        print $App::FilterUtils::texize::VERSION, "\n";
        exit;
    }

    return;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $readarg = @$args ? sub { shift @$args } : sub { <STDIN> };
    while (defined ($_ = $readarg->())) {
        chomp;
        print encode('latex', $_), "\n"
    }

    return;
}

1;

__END__

=head1 GIT REPOSITORY

L<http://github.com/athreef/App-FilterUtils>

=head1 SEE ALSO

L<Tex::Encode>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
