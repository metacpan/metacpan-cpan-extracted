package CLI::Dispatch::Docopt;
use strict;
use warnings;

our $VERSION = '0.01';

my $SubCmd = 'sub_command';

sub import {
    my ($class, $name) = @_;

    $SubCmd = $name if defined $name;

    my $caller = caller;

    no strict 'refs'; ## no critic
    *{"${caller}::run"} = sub {
        CLI::Dispatch::Docopt->run(@_);
    };
}

sub run {
    my ($class, $base, $opt, $method) = @_;

    $method ||= 'run';

    my $module = $base;

    for my $key (keys %{$opt}) {
        next unless $key eq "<$SubCmd>";
        $module = "${base}::". ucfirst($opt->{$key});
        last;
    }

    my $module_path = $module;
    $module_path =~ s!::!/!g;
    $module_path .= ".pm";

    require $module_path;
    $module->$method($opt);
}

1;

__END__

=head1 NAME

CLI::Dispatch::Docopt - CLI dispatcher with affinity for Docopt


=head1 SYNOPSIS

in C<my_command>.

    use Docopt;
    use CLI::Dispatch::Docopt;

    my $opt = docopt(argv => \@ARGV);
    run('MyApp::CLI' => $opt);

    __END__

    =head1 NAME

    my_command

    =head1 SYNOPSIS

        my_command <sub_command> [--foo]

in C<MyApp::CLI::Qux>.

    package MyApp::CLI::Qux;
    use Data::Dumper;

    sub run {
        my ($self, $opt) = @_;

        warn __PACKAGE__. " run!\n". Dumper($opt);
    }

    1;

then execute C<my_command> like this.

    $ my_command qux --foo
    MyApp::CLI::Qux run!
    $VAR1 = {
              '<sub_command>' => 'qux',
              '--foo' => bless( do{\(my $o = '1')}, 'boolean' )
            };


=head1 DESCRIPTION

CLI::Dispatch::Docopt is the CLI dispatcher with affinity for Docopt.


=head1 METHODS

=head2 run($base_class, $opt[, $method])

The C<run> function is exported from C<CLI::Dispatch::Docopt>.


=head1 REPOSITORY

CLI::Dispatch::Docopt is hosted on github
<http://github.com/bayashi/CLI-Dispatch-Docopt>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Docopt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
