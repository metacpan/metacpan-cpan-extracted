package Amon2::Plugin::CLI;
use strict;
use warnings;

use Plack::Util;
use Amon2::Util qw/add_method/;

my $CLI_OPT_KEY = '.'. __PACKAGE__;

sub init {
    my ($self, $c, $code_conf) = @_;

    if ($code_conf->{cli_opt_key}) {
        $CLI_OPT_KEY = $code_conf->{cli_opt_key};
    }

    _load_getopt_long($code_conf->{getopt});

    add_method($c => ($code_conf->{run_method} || 'run'), _run($code_conf));

    add_method($c => 'show_usage', \&_show_usage);
    add_method($c => 'parse_opt',  \&_parse_opt);
    add_method($c => 'setopt',     \&_setopt);
    add_method($c => 'getopt',     \&_getopt);
}

sub _load_getopt_long {
    my $getopt = shift || [qw/:config posix_default no_ignore_case gnu_compat/];

    require Getopt::Long;
    Getopt::Long->import(@{$getopt});
}

sub _run {
    my $code_conf = shift;

    return sub {
        my ($c, $arg) = @_;

        eval {
            if (my $before_run = $code_conf->{before_run}) {
                $before_run->($c, $arg);
            }
            if (ref $arg eq 'CODE') {
                $arg->($c);
            }
            else {
                my $runner = Plack::Util::load_class($arg, $code_conf->{base});
                my $method = $code_conf->{method} || 'main';
                $runner->$method($c);
            }
            if (my $after_run = $code_conf->{after_run}) {
                $after_run->($c, $arg);
            }
        };
        if (my $e = $@) {
            if ($code_conf->{on_error}) {
                $code_conf->{on_error}->($c, $e);
            }
            else {
                _croak("$0\t$e");
            }
        }
    };
}

sub _show_usage {
    my ($self, %args) = @_;

    require Pod::Usage;
    Pod::Usage::pod2usage(%args);
}

sub _parse_opt {
    my ($c, %options) = @_;

    my @cli_args = @ARGV; # save @ARGV

    Getopt::Long::GetOptionsFromArray(
        \@cli_args,
        %options,
        'h' => sub {
            $c->show_usage(-exitval => 1);
        },
        'help' => sub {
            $c->show_usage(-exitval => 1, -verbose => 2);
        },
    ) or $c->show_usage(-exitval => 2);

    return $c;
}

sub _setopt {
    my ($c, $opt) = @_;

    _croak('$opt is not HASH') unless ref $opt eq 'HASH';

    $c->{$CLI_OPT_KEY} = $opt;

    return $c;
}

sub _getopt {
    my ($c, $opt_key) = @_;

    if (!defined $opt_key || $opt_key eq '') {
        return $c->{$CLI_OPT_KEY};
    }

    return $c->{$CLI_OPT_KEY}{$opt_key};
}

sub _croak {
    my ($msg) = @_;

    require Carp;
    Carp::croak($msg);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Amon2::Plugin::CLI - CLI plugin for Amon2 App


=head1 DESCRIPTION

see more detail L<Amon2::CLI>


=head1 METHOD

=head2 init

initialize the plugin


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Amon2::CLI>

L<Amon2>

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
