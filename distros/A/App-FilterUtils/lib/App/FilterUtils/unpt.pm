use strict;
use warnings;
package App::FilterUtils::unpt;
# ABSTRACT: Strip all dots on Arabic letters in input
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

unpt - Strip all dots on Arabic letters in input

=head1 SYNOPSIS

    $ echo "خوخ" | unpt
    حوح

=head1 OPTIONS

=head2 version / v

Shows the current version number

    $ unpt --version

=head2 help / h

Shows a brief help message

    $ unpt --help

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
        print "For more detailed help see 'perldoc App::FilterUtils::unpt'\n";

        print "\n";
        exit;
    }
    elsif ($opt->{'version'}) {
        print $App::FilterUtils::unpt::VERSION, "\n";
        exit;
    }

    return;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $readarg = @$args ? sub { shift @$args } : sub { <STDIN> };
    while (defined ($_ = $readarg->())) {
        chomp;
        $_ = NFD($_) =~ s/\p{Mn}//rg; # strip tashkeel

        # handle special cases
        s/ك\b/لـ/g;
        s/[نڹڻڼڽ](?!\b)/ٮ/g;

        tr # strip dots in arabic
         {بتث جخ ذ ز ش ض ظ غ ف ق ن ة ي }
         {ٮٮٮ حح د ر س ص ط ع ڡ ٯ ں ه ى };

        tr # strip in other langs
         {ٹٺٻټٽپٿڀ ځڂڃڿڄڅچڇ ڈډڊڋڌڍڎڏڐ ڑڒړڔڕږڗژڙ ښڛڜ ڝڞ ڟ ڠ ڡڢڣڤڥڦ ڧڨ ػؼ ڵڶڷڸ ڹڻڼڽ ۀہۂۃ ۄۅۆۇۏۈۉۊۋ ۍؽؾؿێېۑ ۓ}
         {ٮٮٮٮٮٮٮٮ حححححححح ددددددددد ررررررررر سسس صص ط ع ڡڡڡڡڡڡ ٯٯ كك لللل ںںںں هههه ووووووووو ىىىىىىى ے};

        print $_, "\n";
    }

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
