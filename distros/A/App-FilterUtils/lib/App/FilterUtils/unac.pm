use strict;
use warnings;
package App::FilterUtils::unac;
# ABSTRACT: Strip accents and other Non-Spacing Marks
our $VERSION = '0.002'; # VERSION
use base 'App::Cmd::Simple';
use utf8;
use charnames qw();
use open qw( :encoding(UTF-8) :std );

use Getopt::Long::Descriptive;

use utf8;
use Unicode::Normalize;

=pod

=encoding utf8

=head1 NAME

unac - Strip accents and other Non-Spacing Marks

=head1 SYNOPSIS

    $ unac café
    cafe

=head1 OPTIONS

=head2 version / v

Shows the current version number

    $ unac --version

=head2 help / h

Shows a brief help message

    $ unac --help

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
        print "For more detailed help see 'perldoc App::FilterUtils::unac'\n";

        print "\n";
        exit;
    }
    elsif ($opt->{'version'}) {
        print $App::FilterUtils::unac::VERSION, "\n";
        exit;
    }

    return;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $readarg = @$args ? sub { shift @$args } : sub { <STDIN> };
    print NFD($_) =~ s/\p{Mn}|\n//rg, "\n" while defined ($_ = $readarg->());


    return;
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
