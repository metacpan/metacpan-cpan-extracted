package Carp::Patch::Config;

use 5.010001;
use strict;
no warnings;

use Module::Patch qw();
use base qw(Module::Patch);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-16'; # DATE
our $DIST = 'Carp-Patch-Config'; # DIST
our $VERSION = '0.008'; # VERSION

my @oldvals;
our %config;

sub patch_data {
    return {
        v => 3,
        patches => [
        ],
        config => {
            -MaxArgLen  => {
                schema => 'int*',
            },
            -MaxArgNums => {
                schema => 'int*',
            },
            -Dump => {
                schema => 'str*',
                description => <<'_',

This is not an actual configuration for Carp, but a shortcut for:

    # when value is 0 or 'none'
    $Carp::RefArgFormatter = undef;

    # when value is 1 or 'Data::Dmp'
    $Carp::RefArgFormatter = sub {
        require Data::Dmp;
        Data::Dmp::dmp($_[0]);
    };

    # when value is 2 or 'Data::Dump'
    $Carp::RefArgFormatter = sub {
        require Data::Dump;
        Data::Dump::dump($_[0]);
    };

    # when value is 3 or 'Data::Dump::ObjectAsString'
    $Carp::RefArgFormatter = sub {
        require Data::Dump::ObjectAsString;
        Data::Dump::ObjectAsString::dump($_[0]);
    };

    # when value is 4 or 'Data::Dump::IfSmall'
    $Carp::RefArgFormatter = sub {
        require Data::Dump::IfSmall;
        Data::Dump::IfSmall::dump($_[0]);
    };

_
            },
        },
        after_patch => sub {
            no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
            no warnings 'numeric';
            my $oldvals = {};
            for my $name (keys %config) {
                (my $carp_config_name = $name) =~ s/\A-//;
                my $carp_config_val  = $config{$name};
                if ($name =~ /\A-?Dump\z/) {
                    $carp_config_name = 'RefArgFormatter';
                    $carp_config_val  =
                        $config{$name} eq '0' || $config{$name} eq 'none' ? undef :
                        $config{$name} == 1   || $config{$name} eq 'Data::Dmp'                  ? sub { require Data::Dmp ; Data::Dmp::dmp  ($_[0]) } :
                        $config{$name} == 2   || $config{$name} eq 'Data::Dump'                 ? sub { require Data::Dump; Data::Dump::dump($_[0]) } :
                        $config{$name} == 3   || $config{$name} eq 'Data::Dump::ObjectAsString' ? sub { require Data::Dump::ObjectAsString; Data::Dump::ObjectAsString::dump($_[0]) } :
                        $config{$name} == 4   || $config{$name} eq 'Data::Dump::IfSmall'        ? sub { require Data::Dump::IfSmall; Data::Dump::IfSmall::dump($_[0]) } :
                        die "Unknown value for -Dump, please choose 0/none, 1/Data::Dmp, 2/Data::Dump, 3/Data::Dump::ObjectAsString, 4/Data::Dump::IfSmall";
                }
                $oldvals->{$carp_config_name} = ${"Carp::$carp_config_name"};
                ${"Carp::$carp_config_name"} = $carp_config_val;
            }
            push @oldvals, $oldvals;
        },
        after_unpatch => sub {
            no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
            my $oldvals = shift @oldvals or return;
            for (keys %$oldvals) {
                ${"Carp::$_"} = $oldvals->{$_};
            }
        },
   };
}

1;
# ABSTRACT: Set some Carp variables

__END__

=pod

=encoding UTF-8

=head1 NAME

Carp::Patch::Config - Set some Carp variables

=head1 VERSION

This document describes version 0.008 of Carp::Patch::Config (from Perl distribution Carp-Patch-Config), released on 2024-02-16.

=head1 SYNOPSIS

 % perl -MCarp::Patch::Config=-MaxArgNums,20,-Dump,1 -d:Confess ...

=head1 DESCRIPTION

This is not so much a "patch" for L<Carp>, but just a convenient way to set some
Carp package variables from the command-line. Currently can set these variables:
C<MaxArgLen>, C<MaxArgNums>.

=head1 PATCH CONTENTS

=over

=back

=head1 PATCH CONFIGURATION

=over

=item * -Dump => str

This is not an actual configuration for Carp, but a shortcut for:

 # when value is 0 or 'none'
 $Carp::RefArgFormatter = undef;
 
 # when value is 1 or 'Data::Dmp'
 $Carp::RefArgFormatter = sub {
     require Data::Dmp;
     Data::Dmp::dmp($_[0]);
 };
 
 # when value is 2 or 'Data::Dump'
 $Carp::RefArgFormatter = sub {
     require Data::Dump;
     Data::Dump::dump($_[0]);
 };
 
 # when value is 3 or 'Data::Dump::ObjectAsString'
 $Carp::RefArgFormatter = sub {
     require Data::Dump::ObjectAsString;
     Data::Dump::ObjectAsString::dump($_[0]);
 };
 
 # when value is 4 or 'Data::Dump::IfSmall'
 $Carp::RefArgFormatter = sub {
     require Data::Dump::IfSmall;
     Data::Dump::IfSmall::dump($_[0]);
 };


=item * -MaxArgLen => int

=item * -MaxArgNums => int

=back

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Carp-Patch-Config>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Carp-Patch-Config>.

=head1 SEE ALSO

L<Module::Patch>

L<Carp>

L<Devel::Confess>

L<Carp::Patch::Verbose>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2020, 2019, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Carp-Patch-Config>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
