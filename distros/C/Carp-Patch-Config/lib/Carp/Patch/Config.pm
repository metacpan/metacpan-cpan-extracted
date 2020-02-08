package Carp::Patch::Config;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-09'; # DATE
our $DIST = 'Carp-Patch-Config'; # DIST
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch qw();
use base qw(Module::Patch);

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

    # when value is 0
    $Carp::RefArgFormatter = undef;

    # when value is 1
    $Carp::RefArgFormatter = sub {
        require Data::Dmp;
        Data::Dmp::dmp($_[0]);
    };

    # when value is 2
    $Carp::RefArgFormatter = sub {
        require Data::Dump;
        Data::Dump::dump($_[0]);
    };

_
            },
        },
        after_patch => sub {
            no strict 'refs';
            my $oldvals = {};
            for my $name (keys %config) {
                my $carp_config_name = $name;
                my $carp_config_val  = $config{$name};
                if ($name =~ /\A-?Dump\z/) {
                    $carp_config_name = 'RefArgFormatter';
                    $carp_config_val  =
                        !$config{$name} ? undef :
                        $config{$name} == 1 ? sub { require Data::Dmp ; Data::Dmp::dmp  ($_[0]) } :
                        $config{$name} == 2 ? sub { require Data::Dump; Data::Dump::dump($_[0]) } :
                        die "Unknown value for -Dump, please choose 0, 1, or 2";
                }
                $oldvals->{$carp_config_name} = ${"Carp::$carp_config_name"};
                ${"Carp::$carp_config_name"} = $carp_config_val;
            }
            push @oldvals, $oldvals;
        },
        after_unpatch => sub {
            no strict 'refs';
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

This document describes version 0.005 of Carp::Patch::Config (from Perl distribution Carp-Patch-Config), released on 2019-12-09.

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

 # when value is 0
 $Carp::RefArgFormatter = undef;
 
 # when value is 1
 $Carp::RefArgFormatter = sub {
     require Data::Dmp;
     Data::Dmp::dmp($_[0]);
 };
 
 # when value is 2
 $Carp::RefArgFormatter = sub {
     require Data::Dump;
     Data::Dump::dump($_[0]);
 };


=item * -MaxArgLen => int

=item * -MaxArgNums => int

=back

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Carp-Patch-Config>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Carp-Patch-Config>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Carp-Patch-Config>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Patch>

L<Carp>

L<Devel::Confess>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
