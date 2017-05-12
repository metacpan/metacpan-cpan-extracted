package App::Term2HTML;
use strict;
use warnings;
use Getopt::Long qw/GetOptionsFromArray/;
use IO::Interactive::Tiny;
use HTML::FromANSI::Tiny;

our $VERSION = '0.02';

sub run {
    my $self = shift;
    my @argv = @_;

    my $config = {};
    _merge_opt($config, @argv);

    _main($config);
}

sub _main {
    my $config = shift;

    my $h = HTML::FromANSI::Tiny->new(
        $config->{inline_style} ? (inline_style => 1) : (),
    );

    if ( !IO::Interactive::Tiny::is_interactive(*STDIN) ) {
        print join('', '<style>', $h->css, '</style>', "\n") if !$config->{inline_style};
        print "<pre>";
        while (my $stdin = <STDIN>) {
            print $h->html($stdin);
        }
        print "</pre>\n";
    }
}

sub _merge_opt {
    my ($config, @argv) = @_;

    GetOptionsFromArray(
        \@argv,
        'is|inline-style' => \$config->{inline_style},
        'h|help'  => sub {
            _show_usage(1);
        },
        'v|version' => sub {
            print "$0 $VERSION\n";
            exit 1;
        },
    ) or _show_usage(2);
}

sub _show_usage {
    my $exitval = shift;

    require Pod::Usage;
    Pod::Usage::pod2usage(-exitval => $exitval);
}

1;

__END__

=head1 NAME

App::Term2HTML - converting colored terminal output to HTML


=head1 SYNOPSIS

    use App::Term2HTML;

    App::Term2HTML->run(@ARGV);


=head1 DESCRIPTION

App::Term2HTML provides L<term2html> command.


=head1 METHOD

=head2 run

execute term2html


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/App-Term2HTML"><img src="https://secure.travis-ci.org/bayashi/App-Term2HTML.png?_t=1449406825"/></a> <a href="https://coveralls.io/r/bayashi/App-Term2HTML"><img src="https://coveralls.io/repos/bayashi/App-Term2HTML/badge.png?_t=1449406825&branch=master"/></a>

=end html

App::Term2HTML is hosted on github: L<http://github.com/bayashi/App-Term2HTML>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<term2html>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
