package App::Changelord::Command::Version;
our $AUTHORITY = 'cpan:YANICK';
# SYNOPSIS: output the latest / next version
$App::Changelord::Command::Version::VERSION = 'v0.0.1';
use 5.36.0;

use Moo;
use CLI::Osprey
    desc => 'output the latest/next version';

use Path::Tiny;
use JSON;
use YAML::XS;
use List::AllUtils qw/ first min /;
use Version::Dotted::Semantic;

with 'App::Changelord::Role::Changelog';
with 'App::Changelord::Role::ChangeTypes';
with 'App::Changelord::Role::Versions';

sub run($self) {
    my $param  = shift @ARGV;

    die "invalid parameter '$param', needs to be nothing, 'next' or 'latest'\n"
        if $param and not  grep { $param eq $_ } qw/ next latest /;

        if(!$param) {
            say "latest version: ", $self->latest_version;
            say "next version:   ", $self->next_version;
        }
        elsif( $param eq 'next' ) {
        say $self->next_version;
    }
    else {
        say $self->latest_version;
    }
}

'end of App::Changelog::Command::Version';

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Command::Version

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
