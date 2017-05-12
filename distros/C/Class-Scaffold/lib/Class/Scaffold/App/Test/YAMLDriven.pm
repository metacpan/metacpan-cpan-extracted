use 5.008;
use warnings;
use strict;

package Class::Scaffold::App::Test::YAMLDriven;
BEGIN {
  $Class::Scaffold::App::Test::YAMLDriven::VERSION = '1.102280';
}
# ABSTRACT: Base class for YAML-driven test programs
use Class::Scaffold::App;
use Error::Hierarchy::Util 'assert_defined';
use File::Find;
use List::Util 'shuffle';
use String::FlexMatch;    # in case some tests need it
use Test::More;
use Test::Builder;
use Encode;
use parent 'Class::Scaffold::App::Test';
use Error;
$Error::Debug = 1;        # to trigger a stacktrace on an exception
__PACKAGE__->mk_abstract_accessors(qw(run_subtest plan_test))
  ->mk_hash_accessors(qw(test_def))->mk_scalar_accessors(
    qw(
      testdir testname expect run_num runs current_test_def
      )
  );
use constant SHARED => '00shared.yaml';
use constant GETOPT => (
    qw/
      shuffle reverse
      /
);

# 'runs' is the number of stage runs per test file ensure idempotency
use constant DEFAULTS => (
    runs    => 1,
    testdir => '.',
);

sub app_code {
    my $self = shift;
    $self->SUPER::app_code(@_);
    $self->read_test_defs;
    plan tests => $self->make_plan;
    for my $testname ($self->ordered_test_def_keys) {
        next if $testname eq SHARED;
        $self->execute_test_def($testname);
    }
}

sub read_test_defs {
    my $self = shift;

    # It's possible to pass args to the test program. If there are any
    # such args, then in order for a test file to be used its name has to
    # contain one of the args as a substring. For example, to only run
    # the policy tests whose name contains 'unnamed' or '99', you'd use:
    #
    #   perl t/10Policy.t unnamed 99
    my $name_filter = join '|' => map { "\Q$_\E" } @ARGV;
    my $testdir = $self->testdir;

    # First collect the files to process into a hash, then process that
    # hash sorted by name. This separation is necessary because some test
    # files depend on others, but find() doesn't ensure that the files are
    # returned in sorted order.
    my %file;
    find(
        sub {
            return unless -f && /\.yaml$/;
            (my $name = $File::Find::name) =~ s!^$testdir/!!;
            return
              if $name ne SHARED && $name_filter && $name !~ /$name_filter/o;
            $file{$name} = $File::Find::name;
        },
        $testdir
    );
    for my $name (sort keys %file) {
        note "Loading test file $name";
        (   my $tests_yaml =
              do { local (@ARGV, $/) = $file{$name}; <> }
        ) =~ s/%%PID%%/sprintf("%06d", $$)/ge;
        $tests_yaml =~ s/%%CNT%%/sprintf("%03d", ++(our $cnt))/ge;

        # Quick regex check whether the test wants to be skipped. To use
        # Load() on a test that wants to be skipped would be a bad idea as it
        # might be work in progress; it will be skipped for a reason.
        if ($tests_yaml =~ /^skip:\s*1/m) {
            note 'Test wants to be skipped, no activation';
        } else {

            # support for value classes
            local $Class::Value::SkipChecks = 1;

            # require(), not use(), YAML classes because YAML and YAML::Active
            # might conflict.
            my $test_def;
            if ($tests_yaml =~ /^use_yaml_active:\s*1/m) {
                note 'Loading with YAML::Active.pm';
                require YAML::Active;
                $test_def = YAML::Active::Load($tests_yaml);
            } else {
                require YAML;

                # Erik P. Ostlyngen writes:
                #
                # There seems to be a difference in the behaviour of YAML and
                # YAML::XS when it comes to wide characters. YAML::Load()
                # wants the string to be a perl wide character string whereas
                # YAML::XS::Load() wants a string of bytes which it tries to
                # utf-8 decode afterwards.
                #
                # This is a problem in Class::Scaffold::App::Test::YAMLDriven
                # because it uses both of the two YAML modules. So if we're
                # writing our tests with the use_yaml_active tag, we can
                # include utf-8 in the document. But if we instead use YAML
                # with the marshall classes, we cannot use utf-8 directly.
                #
                # I think it would be a good idea to support utf-8 encoding
                # both in yaml-active and yaml-marshall documents and in the
                # same way. This could easily be fixed with [decode_utf8()].
                $test_def = YAML::Load(decode_utf8($tests_yaml));

                # note explain $test_def;
            }
            $self->test_def($name => $test_def);
        }
    }
}

sub ordered_test_def_keys {
    my $self = shift;
    my @tests;
    if ($self->opt->{shuffle}) {
        note 'test order: shuffle';
        @tests = shuffle $self->test_def_keys;
    } elsif ($self->opt->{reverse}) {
        note 'test order: reverse';
        @tests = reverse sort $self->test_def_keys;
    } else {
        note 'test order: sort';
        @tests = sort $self->test_def_keys;

        # Perl::Critic complains about "return sort ... "
    }
    @tests;
}

sub should_skip_testname {
    my ($self, $testname) = @_;
    return 'wants to be skipped' if $self->test_def($testname)->{skip};
    return undef;
}

sub make_plan {
    my $self = shift;

    # Each YAML file produces either a skip or a subtest, except for the
    # shared file, which is expected to only contain YAML::Active objects for
    # setup.
    $self->runs * (grep { $_ ne SHARED } $self->test_def_keys);
}

sub execute_test_def {
    my ($self, $testname) = @_;
    assert_defined $testname, 'called without testname';

    # In case subclasses need to do special things, like multiple tickets in a
    # test definition:
    $self->current_test_def($self->test_def($testname));
    $self->expect($self->current_test_def->{expect} || {});
    for my $run (1 .. $self->runs) {
        $self->run_num($run);
        $self->testname(
            sprintf('%s run %d of %d', $testname, $run, $self->runs));

        # If the current test def specifies that it wants to be skipped, just
        # pass.
        if (my $reason = $self->should_skip_testname($testname)) {
            $self->todo_skip_test($reason);
        } else {
            $self->run_test;
        }
    }
}

sub run_test {
    my $self = shift;
    subtest $self->testname, sub {
        plan tests => $self->plan_test($self->current_test_def, $self->run_num);
        $self->run_subtest;
    };
}

sub named_test {
    my ($self, $suffix) = @_;
    sprintf '%s: %s', $self->testname, $suffix;
}

sub todo_skip_test {
    my ($self, $reason) = @_;
    Test::Builder->new->todo_skip($reason, 1);
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::App::Test::YAMLDriven - Base class for YAML-driven test programs

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 execute_test_def

FIXME

=head2 make_plan

FIXME

=head2 named_test

FIXME

=head2 ordered_test_def_keys

FIXME

=head2 read_test_defs

FIXME

=head2 run_test

FIXME

=head2 should_skip_testname

FIXME

=head2 todo_skip_test

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Scaffold/>.

The development version lives at
L<http://github.com/hanekomu/Class-Scaffold/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

