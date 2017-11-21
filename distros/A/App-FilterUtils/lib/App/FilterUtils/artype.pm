use strict;
use warnings;
package App::FilterUtils::artype;
# ABSTRACT: Fix-up display of Arabic characters on unsupporting UIs
our $VERSION = '0.001'; # VERSION
use base 'App::Cmd::Simple';
use utf8;
use charnames qw();
use open qw( :encoding(UTF-8) :std );
use Module::Load qw(load);
use Getopt::Long::Descriptive;

use utf8;

=pod

=encoding utf8

=head1 NAME

artype - Fix-up display of Arabic characters on unsupporting UIs

=head1 SYNOPSIS

    $ echo "مِــكَــرٍّ مِــفَــرٍّ مُــقْــبِــلٍ مُــدْبِــرٍ مَــعــاً" | artype
    ٍّرــَﻜــِﻣ ٍّرــَﻔــِﻣ ٍﻠــِﺒــْﻘــُﻣ ٍرــِﺒْدــُﻣ ًاــﻌــَﻣ

=head1 OPTIONS

=head2 version / v

Shows the current version number

    $ artype --version

=head2 help / h

Shows a brief help message

    $ artype --help

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
        print "For more detailed help see 'perldoc App::FilterUtils::artype'\n";

        print "\n";
        exit;
    }
    elsif ($opt->{'version'}) {
        print $App::FilterUtils::artype::VERSION, "\n";
        exit;
    }

    return;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $display_only = -t STDOUT;

    use constant {
        ISOLATED => 0,
        ENDING => 1,
        MIDDLE => 2,
        BEGINNING => 3,
    };

    my %shapes = (
        أ => [qw/ﺃ ﺄ/],
        ب => [qw/ﺏ ﺐ ﺒ ﺑ/],
        ت => [qw/ﺕ ﺖ ﺘ ﺗ/],
        ث => [qw/ﺙ ﺚ ﺜ ﺛ/],
        ج => [qw/ﺝ ﺞ ﺠ ﺟ/],
        ح => [qw/ﺡ ﺢ ﺤ ﺣ/],
        خ => [qw/ﺥ ﺦ ﺨ ﺧ/],
        د => [qw/ﺩ ﺪ/],
        ذ => [qw/ﺫ ﺬ/],
        ر => [qw/ﺭ ﺮ/],
        ز => [qw/ﺯ ﺰ/],
        س => [qw/ﺱ ﺲ ﺴ ﺳ/],
        ش => [qw/ﺵ ﺶ ﺸ ﺷ/],
        ص => [qw/ﺹ ﺺ ﺼ ﺻ/],
        ض => [qw/ﺽ ﺾ ﻀ ﺿ/],
        ط => [qw/ﻁ ﻂ ﻄ ﻃ/],
        ظ => [qw/ﻅ ﻆ ﻈ ﻇ /],
        ع => [qw/ﻉ ﻊ ﻌ ﻋ/],
        غ => [qw/ﻍ ﻎ ﻐ ﻏ/],
        ف => [qw/ﻑ ﻒ ﻔ ﻓ/],
        ق => [qw/ﻕ ﻖ ﻘ ﻗ/],
        ك => [qw/ﻙ ﻚ ﻜ ﻛ/],
        ل => [qw/ﻝ ﻞ ﻠ ﻟ/],
        م => [qw/ﻡ ﻢ ﻤ ﻣ/],
        ن => [qw/ﻥ ﻦ ﻨ ﻧ/],
        ه => [qw/ﻩ ﻪ ﻬ ﻫ/],
        و => [qw/ﻭ ﻮ/],
        ي => [qw/ﻱ ﻲ ﻴ ﻳ/],
        آ => [qw/ﺁ ﺂ/],
        ة => [qw/ﺓ ﺔ/],
        ى => [qw/ﻯ ﻰ/],
    );

    local $/;
    $_ = <>;

    s/(\p{InArabic}+)/reverse $1/ge;

    s/\b(\p{InArabic})\b/$shapes{$1}[ISOLATED] || $1/ge;
    s/\b(\p{InArabic})/$shapes{$1}[ENDING] || $1/ge;
    s/(\p{InArabic})\b/$shapes{$1}[BEGINNING] || $1/ge;
    s/(\p{InArabic})/$shapes{$1}[MIDDLE] || $1/ge;

    print $_;

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
