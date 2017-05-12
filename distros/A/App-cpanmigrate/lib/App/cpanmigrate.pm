package App::cpanmigrate;
use strict;
use warnings;
our $VERSION = '0.04';

local $SIG{__DIE__} = sub {
    my $msg = shift;
    warn "$msg\n";
    exit 1;
};

sub new {
    my ($class, $new_version, %args) = @_;

    ($new_version && $new_version =~ /^perl/)
        or __PACKAGE__->usage();

    return bless {
        args    => { %args },
        version => $new_version,
    }, $class;
}

sub run {
    my $self = shift;

    $self->detect_shell;
    my $command = $self->fetch_script;

    exec $self->{shell}{path}, @{$self->{shell}{opts}}, $command;
}

sub fetch_script {
    my $self = shift;
    my $shell = $self->{shell};

    require "App/cpanmigrate/$shell->{name}.pm"; ## no critic

    my $cmd = "App::cpanmigrate::$shell->{name}"->script($self->{version});
    $cmd =~ s/\s+/ /g;

    return $cmd;
}

sub usage {
    die <<"USAGE";
Usage:
    $0 [perl-version]
USAGE
}

sub detect_shell {
    my $self = shift;

    $self->{shell}{path} = $ENV{SHELL};

    if ($self->{shell}{path} =~ /(bash|zsh)/) {
        $self->{shell}{name} = 'bash';
        $self->{shell}{opts} = [ '-c' ];

    } elsif ($self->{shell}{path} =~ /(csh)/) {
        $self->{shell}{name} = 'csh';
        $self->{shell}{opts} = [ '-c' ];

    } else {
        $self->{shell}{name} = 'unknown';
    }
}

1;
__END__

=head1 NAME

App::cpanmigrate - migrate installed modules to new environment

=head1 SYNOPSIS

  $ cpanmigrate perl-5.14.1

=head1 DESCRIPTION

App::cpanmigrate is a helper tool to migrate installed modules to new environment.

C<cpanmigrate> is integrated with L<App::cpanminus> and L<App::perlbrew>.

=head1 SUPPORTED ENVIRONMENT

=over 4

=item * C<bash>

=item * C<zsh>

=item * C<csh>

=back

=head2 HOW TO DEVELOP A HELPER FOR UNSUPPORTED ENVIRONMENT

Take a look at L<App::cpanmigrate::bash>. The main part of development is writing shell script.

Additionally, write some logic to detect shell. See also C<< App::cpanmigrate->detect_shell() >>.

Then, please send me a pull request at L<https://github.com/punytan/p5-App-cpanmigrate> :)

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 CONTRIBUTORS

toritori0318 - patches for C<zsh> and C<csh>

=head1 SEE ALSO

L<App::perlbrew>, L<App::cpanminus>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
