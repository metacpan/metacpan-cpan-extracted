package App::CPANRepo;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use MetaCPAN::Client 1.005000;
use Getopt::Long ();
use Pod::Usage ();

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro_lazy => {
        _client => sub { MetaCPAN::Client->new },
    },
);

sub resolve_repo {
    my ($self, $name) = @_;

    my $repo;
    eval {
        my $module = $self->_client->module($name);
        my $release = $self->_client->release($module->distribution);
        if ($release->resources->{repository}) {
            $repo = $release->resources->{repository}{url};
        }
    };

    return $repo;
}

sub run {
    my ($class, @argv) = @_;

    my ($opt, $argv) = $class->parse_options(@argv);

    my $self = $class->new(%$opt);
    for my $module (@$argv) {
        print( ($self->resolve_repo($module) || '') . "\n");
    }
}

sub parse_options {
    my ($class, @argv) = @_;

    my $parser = Getopt::Long::Parser->new(
        config => [qw/posix_default no_ignore_case bundling pass_through auto_help/],
    );

    local @ARGV = @argv;
    $parser->getoptions(\my %opt) or Pod::Usage::pod2usage(1);
    @argv = @ARGV;

    Pod::Usage::pod2usage(1) unless @argv;
    (\%opt, \@argv);
}

1;
__END__

=encoding utf-8

=head1 NAME

App::CPANRepo - Resolve repository of CPAN Module

=head1 SYNOPSIS

    use App::CPANRepo;
    my $obj = App::CPANRepo->new;
    print $obj->resolve_repo('Module::Name');

=head1 DESCRIPTION

App::CPANRepo is to resolve repository URL by CPAN module name.

=head1 METHODS

=head2 C<< $repo_url:Str = $obj->resolve_repo($module_name:Str) >>

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

