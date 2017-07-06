package App::cpanminus::script::Patch::Blacklist;

our $DATE = '2017-07-04'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

use Config::IOD::Reader;

our %config;

my $p_search_module = sub {
    my $ctx = shift;
    my $orig = $ctx->{orig};
    my $res = $orig->(@_);
    return $res unless $res;

    unless ($App::cpanminus::script::Blacklist) {
        $App::cpanminus::script::Blacklist =
            Config::IOD::Reader->new->read_file(
                $ENV{HOME} . "/cpanm-blacklist.conf");
    }

    my $module_bl = $App::cpanminus::script::Blacklist->{GLOBAL}{module} // [];
    $module_bl = [$module_bl] unless ref $module_bl eq 'ARRAY';
    if (grep { $res->{module} eq $_ } @$module_bl) {
        die "Won't install $res->{module}: blacklisted by module blacklist";
    }

    my $author_bl = $App::cpanminus::script::Blacklist->{GLOBAL}{author} // [];
    $author_bl = [$author_bl] unless ref $author_bl eq 'ARRAY';
    if (grep { $res->{cpanid} eq $_ } @$author_bl) {
        die "Won't install $res->{module}: blacklisted by author blacklist ".
            "(author=$res->{cpanid})";
    }

    $res;
};

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'wrap',
                sub_name    => 'search_module',
                code        => $p_search_module,
            },
        ],
   };
}

1;
# ABSTRACT: Blacklist modules from being installed

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cpanminus::script::Patch::Blacklist - Blacklist modules from being installed

=head1 VERSION

This document describes version 0.003 of App::cpanminus::script::Patch::Blacklist (from Perl distribution App-cpanminus-script-Patch-Blacklist), released on 2017-07-04.

=head1 SYNOPSIS

In F<~/cpanm-blacklist.conf>:

 module=Some::Module
 module=Another::Module
 author=SOMEID

In the command-line:

 % perl -MModule::Load::In::INIT=App::cpanminus::script::Patch::Blacklist `which cpanm` ...

=head1 DESCRIPTION

This patch adds blacklisting feature to L<cpanm>.

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cpanminus-script-Patch-Blacklist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cpanminus-script-Patch-Blacklist>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cpanminus-script-Patch-Blacklist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
