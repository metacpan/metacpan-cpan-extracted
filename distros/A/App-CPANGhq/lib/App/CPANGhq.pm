package App::CPANGhq;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.10";

use Getopt::Long ();
use Pod::Usage ();
use App::CPANRepo;

use Class::Accessor::Lite::Lazy 0.03 (
    new     => 1,
    ro_lazy => {
        _cpanrepo => sub { App::CPANRepo->new },
    }
);

## class methods
sub run {
    my ($class, @argv) = @_;

    my ($opt, $argv) = $class->parse_options(@argv);
    my @modules = @$argv;

    my $self = $class->new;
    $self->clone_modules(@modules);
}

sub parse_options {
    my ($class, @argv) = @_;

    my $parser = Getopt::Long::Parser->new(
        config => [qw/posix_default no_ignore_case bundling pass_through auto_help/],
    );

    local @ARGV = @argv;
    $parser->getoptions(\my %opt) or Pod::Usage::pod2usage(1);
    @argv = @ARGV;

    (\%opt, \@argv);
}

## object methods
sub clone_modules {
    my ($self, @modules) = @_;

    for my $module (@modules) {
        next if $module eq 'perl';

        my $repo = $self->_cpanrepo->resolve_repo($module);
        if ($repo) {
            !system 'ghq', 'get', $repo or do { warn $! if $! };
        }
        else {
            warn "Repository of $module is not found.\n";
        }
    }
}

1;
__END__
=for stopwords ghq

=encoding utf-8

=head1 NAME

App::CPANGhq - Clone module source codes with ghq

=head1 SYNOPSIS

    use App::CPANGhq;
    App::CPANGhq->run(@ARGV);

=head1 DESCRIPTION

App::CPANGhq is to clone module sources with L<ghq|https://github.com/motemen/ghq>.

This is a backend module of L<cpan-ghq>.

B<THE SOFTWARE IS STILL ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.>

=head1 INSTALL

This module requires L<ghq|https://github.com/motemen/ghq> to be installed.

=head1 SEE ALSO

L<cpan-ghq>

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
