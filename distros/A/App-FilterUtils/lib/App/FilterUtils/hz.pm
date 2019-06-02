use strict;
use warnings;
package App::FilterUtils::hz;
# ABSTRACT: Convert frequency to cycle period
our $VERSION = '0.002'; # VERSION
use base 'App::Cmd::Simple';
use utf8;
use charnames qw();
use open qw( :encoding(UTF-8) :std );

use Getopt::Long::Descriptive;

use utf8;

=pod

=encoding utf8

=head1 NAME

hz - Convert frequency to cycle period

=head1 SYNOPSIS

    $ hz 10000
    100us

=head1 OPTIONS

=head2 version / v

Shows the current version number

    $ hz --version

=head2 help / h

Shows a brief help message

    $ hz --help

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
        print "For more detailed help see 'perldoc App::FilterUtils::hz'\n";

        print "\n";
        exit;
    }
    elsif ($opt->{'version'}) {
        print $App::FilterUtils::hz::VERSION, "\n";
        exit;
    }

    return;
}

sub execute {
    my ($self, $opt, $args) = @_;

    $_ = $0;
    my $mult = /khz/ ? 1e3
             : /mhz/ ? 1e6
             : /ghz/ ? 1e9
             : /thz/ ? 1e12
             :         1;

    my $readarg = @$args ? sub { shift @$args } : sub { <STDIN> };
    while (defined ($_ = $readarg->())) {
        chomp;
        print fmt(1 / ($mult*$_)), "s\n";
    }

    return;
}

sub fmt {
    my $s= shift;
       if ($s < 1e-12) { $s *= 1e15; $s .= 'f'; }
    elsif ($s < 1e-9)  { $s *= 1e12; $s .= 'p'; }
    elsif ($s < 1e-6)  { $s *= 1e9;  $s .= 'n'; }
    elsif ($s < 1e-3)  { $s *= 1e6;  $s .= 'u'; }
    elsif ($s < 1)     { $s *= 1e3;  $s .= 'm'; }

    return $s;
}


1;

__END__

=head1 GIT REPOSITORY

L<http://github.com/athreef/App-FilterUtils>

=head1 SEE ALSO

L<The Perl Home Page|http://www.perl.org/>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
