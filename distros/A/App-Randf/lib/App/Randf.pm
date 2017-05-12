package App::Randf;
use strict;
use warnings;
use Config::CmdRC '.randfrc';
use Getopt::Long qw/GetOptionsFromArray/;

our $VERSION = '0.02';

sub run {
    my $self = shift;
    my @argv = @_;

    my $config = RC();
    _merge_opt($config, @argv);

    _main($config);
}

sub _main {
    my $config = shift;

    while (my $stdin = <STDIN>) {
        print $stdin if !$config->{per} || $config->{per}*100 > rand(10000);
    }
}

sub _merge_opt {
    my ($config, @argv) = @_;

    GetOptionsFromArray(
        \@argv,
        'p|per=i' => \$config->{per},
        'h|help'  => sub {
            _show_usage(1);
        },
        'v|version' => sub {
            print "$0 $VERSION\n";
            exit 1;
        },
    ) or _show_usage(2);

    $config->{per} = shift @argv if scalar @argv > 0;
}

sub _show_usage {
    my $exitval = shift;

    require Pod::Usage;
    Pod::Usage::pod2usage(-exitval => $exitval);
}

1;

__END__

=head1 NAME

App::Randf - random filter for STDIN


=head1 SYNOPSIS

    use App::Randf;

    App::Randf->run(@ARGV);


=head1 DESCRIPTION

App::Randf provides L<randf> command for filtering high flow log.


=head1 METHOD

=head2 run

execute randf


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/App-Randf"><img src="https://secure.travis-ci.org/bayashi/App-Randf.png?_t=1440937201"/></a> <a href="https://coveralls.io/r/bayashi/App-Randf"><img src="https://coveralls.io/repos/bayashi/App-Randf/badge.png?_t=1440937201&branch=master"/></a>

=end html

App::Randf is hosted on github: L<http://github.com/bayashi/App-Randf>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<randf>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
