package BorderStyleRole::Spec::Basic;

use strict;
use warnings;

use Role::Tiny;
#use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-14'; # DATE
our $DIST = 'BorderStyle'; # DIST
our $VERSION = '3.0.2'; # VERSION

### requires

requires 'get_border_char';

### provides

sub new {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    my $class = shift;

    # check that %BORDER exists
    my $bs_hash = \%{"$class\::BORDER"};
    unless (defined $bs_hash->{v}) {
        die "Class $class does not define \%BORDER with 'v' key";
    }
    unless ($bs_hash->{v} == 3) {
        die "\%$class\::BORDER's v is $bs_hash->{v}, I only support v=2";
    }

    # check for known and required arguments
    my %args = @_;
    {
        my $args_spec = $bs_hash->{args};
        last unless $args_spec;
        for my $arg_name (keys %args) {
            die "Unknown argument '$arg_name'" unless $args_spec->{$arg_name};
        }
        for my $arg_name (keys %$args_spec) {
            die "Missing required argument '$arg_name'"
                if $args_spec->{$arg_name}{req} && !exists($args{$arg_name});
            # apply default
            $args{$arg_name} = $args_spec->{$arg_name}{default}
                if !defined($args{$arg_name}) &&
                exists $args_spec->{$arg_name}{default};
        }
    }

    bless {
        args => \%args,

        # we store this because applying roles to object will rebless the object
        # into some other package.
        orig_class => $class,
    }, $class;
}

sub get_struct {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    my $self_or_class = shift;
    if (ref $self_or_class) {
        \%{"$self_or_class->{orig_class}::BORDER"};
    } else {
        \%{"$self_or_class\::BORDER"};
    }
}

sub get_args {
    my $self = shift;
    $self->{args};
}

my @role_prefixes = qw(BorderStyleRole);
sub apply_roles {
    my ($obj, @unqualified_roles) = @_;

    my @roles_to_apply;
  ROLE:
    for my $ur (@unqualified_roles) {
      PREFIX:
        for my $prefix (@role_prefixes) {
            my ($mod, $modpm);
            $mod = "$prefix\::$ur";
            ($modpm = "$mod.pm") =~ s!::!/!g;
            eval { require $modpm; 1 };
            unless ($@) {
                #print "D:$mod\n";
                push @roles_to_apply, $mod;
                next ROLE;
            }
        }
        die "Can't find role '$ur' to apply (searched these prefixes: ".
            join(", ", @role_prefixes);
    }

    Role::Tiny->apply_roles_to_object($obj, @roles_to_apply);

    # return something useful
    $obj;
}

1;
# ABSTRACT: Required methods for all BorderStyle::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyleRole::Spec::Basic - Required methods for all BorderStyle::* modules

=head1 VERSION

This document describes version 3.0.2 of BorderStyleRole::Spec::Basic (from Perl distribution BorderStyle), released on 2022-02-14.

=head1 DESCRIPTION

L<BorderStyle>::* modules define border styles.

=head1 REQUIRED METHODS

=head2 new

Usage:

 my $bs = BorderStyle::Foo->new([ %args ]);

Constructor. Must accept a pair of argument names and values.

=head2 get_struct

=head2 get_args

=head2 get_border_char

=head1 PROVIDED METHODS

=head2 apply_roles

Usage:

 $obj->apply_roles('R1', 'R2', ...)

Apply roles to object. R1, R2, ... are unqualified role names that will be
searched under C<BorderStyleRole::*> namespace. It's a convenience shortcut for
C<< Role::Tiny->apply_roles_to_object >>.

Return the object.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyle>.

=head1 SEE ALSO

L<BorderStyle>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
