#line 1
package Module::Install::StandardTests;

use warnings;
use strict;
use File::Spec;

use base 'Module::Install::Base';


our $VERSION = '0.05';


sub use_standard_tests {
    my ($self, %specs) = @_;
    
    my %with = map { $_ => 1 } qw/compile pod pod_coverage perl_critic/;
    if (exists $specs{without}) {
        $specs{without} = [ $specs{without} ] unless ref $specs{without};
        delete $with{$_} for @{ $specs{without} };
    }

    $self->build_requires('Test::More');
    $self->build_requires('UNIVERSAL::require');

    # Unlike other tests, this is mandatory.
    $self->build_requires('Test::Compile');

    $self->write_standard_test_compile;    # no if; this is mandatory
    $self->write_standard_test_pod          if $with{pod};
    $self->write_standard_test_pod_coverage if $with{pod_coverage};
    $self->write_standard_test_perl_critic  if $with{perl_critic};
}


sub write_test_file {
    my ($self, $filename, $code) = @_;
    $filename = File::Spec->catfile('t', $filename);

    # Outdent the code somewhat. Remove first empty line, if any. Then
    # determine the indent of the first line. Throw that amount of indenting
    # away from any line. This allows you to indent the code so it's visually
    # clearer (see methods below) while creating output that's indented more
    # or less correctly. Smoke result HTML pages link to the .t files, so it
    # looks neater.

    $code =~ s/^ *\n//;
    (my $indent = $code) =~ s/^( *).*/$1/s;
    $code =~ s/^$indent//gm;

    print "Creating $filename\n";
    open(my $fh, ">$filename") or die "can't create $filename $!";

    my $perl = $^X;
    print $fh <<TEST;
#!$perl -w

use strict;
use warnings;

$code
TEST

    close $fh or die "can't close $filename $!\n";
    $self->realclean_files($filename);
}


sub write_standard_test_compile {
    my $self = shift;
    $self->write_test_file('000_standard__compile.t', q/
        BEGIN {
            use Test::More;
            eval "use Test::Compile";
            Test::More->builder->BAIL_OUT(
                "Test::Compile required for testing compilation") if $@;
            all_pm_files_ok();
        }
    /);
}


sub write_standard_test_pod {
    my $self = shift;
    $self->write_test_file('000_standard__pod.t', q/
        use Test::More;
        eval "use Test::Pod";
        plan skip_all => "Test::Pod required for testing POD" if $@;
        all_pod_files_ok();
    /);
}


sub write_standard_test_pod_coverage {
    my $self = shift;
    $self->write_test_file('000_standard__pod_coverage.t', q/
        use Test::More;
        eval "use Test::Pod::Coverage";
        plan skip_all =>
            "Test::Pod::Coverage required for testing POD coverage" if $@;
        all_pod_coverage_ok();
    /);
}


sub write_standard_test_perl_critic {
    my $self = shift;
    $self->write_test_file('000_standard__perl_critic.t', q/
        use FindBin '$Bin';
        use File::Spec;
        use UNIVERSAL::require;
        use Test::More;

        plan skip_all =>
            'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.'
            unless $ENV{TEST_AUTHOR};

        my %opt;
        my $rc_file = File::Spec->catfile($Bin, 'perlcriticrc');
        $opt{'-profile'} = $rc_file if -r $rc_file;

        if (Perl::Critic->require('1.078') &&
            Test::Perl::Critic->require &&
            Test::Perl::Critic->import(%opt)) {

            all_critic_ok("lib");
        } else {
            plan skip_all => $@;
        }
    /);
}


1;

__END__

#line 249

