package App::Prove::Plugin::TraceUse;

use warnings;
use strict;

use version qw/is_lax qv/; our $VERSION = qv('1.0.3');

use Carp;
use Tree::Simple;
use Set::Object qw/set/;
use Pod::Perldoc;
use File::Slurp;
use Safe;

my $pd;

sub _parse_module_and_version {

    my @parsed = ();

    if ( $_[0] =~ /^\s+\d+\.\s+(\S+)(?: ([\d\._]+))?,/ ) {
        @parsed = grep defined , ($1,$2);
    }
    return @parsed;

}

sub _parse_traceuse {

    # General idea:
    # * create a tree from the indentation levels
    # * root nodes should be modules with [main]
    # * output that has less indent modules than any [main]
    #   should give a parse error

    # When tree done:
    # * check @INC of local system
    # * root nodes are candidates for being a dependency
    # * root nodes not in @INC shoule be skipped and next level considered instead

    my @lines = split /\n/, $_[0];

    my %indent_parents =
      ( 0 => Tree::Simple->new( 1, Tree::Simple->ROOT ) );

    for ( @lines ) {

        my($mod,$ver) = _parse_module_and_version($_);

        next unless $mod;

        my $node = Tree::Simple->new([$mod,$ver]);

        my ($indent) = /^\s+\d+\.(\s+)\S+/;

        my $indent_level = length $indent;

        $indent_parents{$indent_level} = $node;
        my $parent = $indent_parents{$indent_level - 2};

        unless ( $parent ) {
            confess "Odd, should have had a parent for:\n$_\nIndent: $indent_level, indent: [$indent]\n";
        }

        $parent->addChild( $node );

    }

    return $indent_parents{0};

}

sub _system_inc {

    my $negate = shift;

    my $s1 = set( @INC );

    my $s2 = set( ".",
                  (exists($ENV{PERL5LIB}) ? split( ":", $ENV{PERL5LIB}) : ())
                );

    my @i = $negate ? (@$s2) : @{$s1 - $s2};

    return @i;

}

sub _module_dir {

    my ($mod,$check_noninc) = @_;

    my @inc = _system_inc;
    my @noninc = _system_inc(1);

    $pd ||= Pod::Perldoc->new;

    my $d = $check_noninc ? $pd->searchfor( 1, $mod, @noninc ) : $pd->searchfor( 1, $mod, @inc );

    return unless $d;

    (my $m2 = $mod) =~ s|::|/|g;
    $m2 .= ".pm";

    $d =~ s|/$m2||;

    return unless -d $d;

    return $d;

}

sub __recursively_check_loaded_modules {
    my($node,$dep_ref) = @_;

    for ( @{ $node->getAllChildren } ) {

        my $mdir = _module_dir( $_->getNodeValue->[0] );
        my $mdir_n = _module_dir( $_->getNodeValue->[0], 1 );

        if (
            defined($mdir) and not defined($mdir_n)
           ) {
            push @$dep_ref, $_->getNodeValue;
        } else {
            __recursively_check_loaded_modules($_, $dep_ref);
        }

    }

}

sub _find_dependent_modules {

    my ($t) = @_;

    my @dependencies;

    __recursively_check_loaded_modules($t,\@dependencies);

    return \@dependencies;

}

sub _find_module_in_code {

    my($mod,$code) = @_;

    ## super simple test if the module is present in the code without being comented
    return $code =~ /^[^#]*\b$mod\b.*\d.*$/m;

}

sub _check_makefile_pl_for_module {

    my($mod) = @_;

    my $mf = read_file( "./Makefile.PL" );

    return _find_module_in_code($mod,$mf);

}

sub _check_build_pl_for_module {

    my($mod) = @_;

    my $bf = read_file( "./Build.PL" );

    return _find_module_in_code($mod,$bf);

}

sub _parse_makefile_pl {

    my ($makefile_input) = @_;

    my $makefile_content;

    if ( $makefile_input ) {

        if ( -e $makefile_input ) {
            $makefile_content = read_file($makefile_input);
        }
        else {
            croak "Dont know what to do with input";
        }

    }
    elsif ( -e "Makefile.PL" ) {
        $makefile_content = read_file("Makefile.PL");
    }

    return unless $makefile_content;

    my($prereq_content) = $makefile_content =~ /^\s*PREREQ_PM\s*=>\s*({\s*[^}]+})/m;

    my $compartment = Safe->new;

    my $prereq_hash_ref = $compartment->reval($prereq_content);

    ## make sure it is sane
    while ( my($mod,$ver) = each %$prereq_hash_ref) {

        if ( not is_lax($ver) ) {
            delete $prereq_hash_ref->{$mod};
        }

    }

    return $prereq_hash_ref;

}

sub _parse_build_pl {

    my ($build_input) = @_;

    my $build_content;

    if ( $build_input ) {

        if ( -e $build_input ) {
            $build_content = read_file($build_input);
        }
        else {
            croak "Dont know what to do with input";
        }

    }
    elsif ( -e "Build.PL" ) {
        $build_content = read_file("Build.PL");
    }

    return unless $build_content;

    my($prereq_content) = $build_content =~ /^\s*requires\s*=>\s*({\s*[^}]+})/m;

    return unless $prereq_content;

    my $compartment = Safe->new;
    my $prereq_hash_ref = $compartment->reval($prereq_content);

    ## make sure it is sane
    while ( my($mod,$ver) = each %$prereq_hash_ref) {

        if ( not is_lax($ver) ) {
            delete $prereq_hash_ref->{$mod};
        }

    }

    return $prereq_hash_ref;

}

{
    package TAP::Harness::FOO;

    use strict;
    use warnings;
    use version;

    use base 'TAP::Harness';

    use File::Temp;
    use File::Slurp;

    use List::Util qw/max/;

    use Term::ANSIColor;

    sub _uniquify_dependencies {

        my $self = shift;

        my %d;

        for ( @{ $self->{collected_dependencies} } ) {

            if ( version->new($_->[1]) > version->new($d{ $_->[0] } || 0) ) {
                $d{ $_->[0] } = $_->[1];
            }

        }

        my @d;
        while ( my ($k,$v) = each %d ) {
            push @d, [$k,$v];
        }

        $self->{collected_dependencies} = \@d;

    }

    sub present_dependencies {

        my $self = shift;

        my @d = sort {
            $a->[0] cmp $b->[0]
        } @{ $self->{collected_dependencies} };

        my $n = max( map {length $_->[0]} @d ) + 2;

        print "# TraceUse report:\n";

        if ( not @d ) {
            print "# no noncore dependencies found\n";
            return;
        }

        my $makefile_requirements = App::Prove::Plugin::TraceUse::_parse_makefile_pl();
        my $build_requirements = App::Prove::Plugin::TraceUse::_parse_build_pl();

        my $present_file_dep = sub {
            my ($dep_hash) = @_;

            my $hash_fails = 0;

            for (@d) {

                my($mod,$ver) = @$_;

                my $v = $dep_hash->{$mod};

                if ( not $v ) {
                    print "# ";
                    print colored ['bold red'], sprintf "%-${n}s => '%s',\n", "'".$_->[0]."'", $_->[1];
                    $hash_fails = 1;
                }
                elsif ( $v and qv($v) < qv($ver) ) {
                    print "# ";
                    print colored ['bold yellow'], sprintf "%-${n}s => '%s',\n", "'".$_->[0]."'", $_->[1];
                    $hash_fails = 1;
                }

            }

            if ( not $hash_fails ) {
                print "# - dependencies are ok\n";
            }

            return not $hash_fails;

        };

        my $dependencies_are_good = 1;

        if ( $makefile_requirements ) {

            print "# Makefile.PL:\n";
            my $ok = $present_file_dep->($makefile_requirements);
            $dependencies_are_good &&= $ok;

        }

        if ( $build_requirements ) {

            print "# Build.PL:\n";
            my $ok = $present_file_dep->($build_requirements);
            $dependencies_are_good &&= $ok;

        }

        if ( not $dependencies_are_good and 0 ) {
            print "# List of dependencies found during testing:\n";
            for ( @d ) {
                printf "# %-${n}s => '%s',\n", "'".$_->[0]."'", $_->[1];
            }
        }

    }

    sub new {

        my $self = shift;

        my $tf = File::Temp->new;
        my $fn = "$tf";

        ## add the traceuse option
        $_[0]->{switches} = ["-d:TraceUse=hidecore,output:$fn"];

        my $obj = $self->SUPER::new(@_);

        $obj->{collected_dependencies} = [];

        my $trace_use_sub = sub {

            my $dt = read_file( $fn );
            my $p = App::Prove::Plugin::TraceUse::_parse_traceuse($dt);
            my $deps = App::Prove::Plugin::TraceUse::_find_dependent_modules($p);
            push @{ $obj->{collected_dependencies} }, @$deps;

        };

        $obj->callback( "after_test", $trace_use_sub );

        my $collected_dependencies = sub {
            $obj->_uniquify_dependencies;
            $obj->present_dependencies;
        };

        $obj->callback( "after_runtests", $collected_dependencies );

        return $obj;

    }

}


sub load {

    my( $class, $p ) = @_;

    my $app = $p->{app_prove};

    if ( defined($app->harness) and $app->harness ne "TAP::Harness" ) {
        croak "TraceUse plugin is only compatible wtih TAP::Harness";
    }

    $app->{harness_class} = "TAP::Harness::FOO";

    1;

}

1;                        # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

App::Prove::Plugin::TraceUse - Report all modules used during testing
and check if they are listed as dependencies in Makefile.PL and
Build.PL


=head1 VERSION

This document describes App::Prove::Plugin::TraceUse version 1.0.3


=head1 SYNOPSIS

    # Run this module as a plugin to the prove script, ie:
    # cd /your/module/folder
    # prove -l -PTraceUse

    # Will output the following in the end
    # if dependencies are missing in MakeFile/Build:
    # (missing deps in red, bad version in yellow)
    #
    # [...]
    # TraceUse report:
    # Makefile.PL:
    # 'File::Slurp'         => '9999.19',
    # 'Tree::Simple'        => '1.18',
    # Build.PL:
    # 'File::Slurp'         => '9999.19',
    # 'Tree::Simple'        => '1.18',


=head1 DESCRIPTION

This module keeps track of all modules and versions loaded during
testing. if Makefile.PL and Build.PL are formatted as they come from a
plain module-starter, it will recognize the requirement list and check
this list with what was found during testing. It reports any non-core
modules not listed as requirements

Currently it does not care about core modules changing between perl
versions.

=head1 INTERFACE

=head2 load

Don't call this. It gets called by App::Prove. Does the following:

=over

=item Makes sure user didnt specify any other harness class than TAP::Harness

=item Creates a subclass of TAP::Harness and makes App::Prove use that.

=item Adds -d:TraceUse=hidecore,output:$fn to perl switches for perl
tests. $fn is a temp file name for this test.

=item Adds a callback to "after_test" to catch TraceUse output

=back

=head1 DIAGNOSTICS

=over

=item C<< TraceUse plugin is only compatible wtih TAP::Harness >>

Apparently you use something else than TAP::Harness. Unfortunately
that does not compute with this plugin.

=item C<< Odd, should have had a parent for... >>

Parsing the Devel::TraceUse output failed. Send me data to investigate.

=back


=head1 CONFIGURATION AND ENVIRONMENT

App::Prove::Plugin::TraceUse requires no configuration files or environment variables.


=head1 DEPENDENCIES

App::Prove
Test::Perl::Critic
Test::Pod::Coverage
Test::Most
Set::Object
Test::Pod
File::Slurp
Tree::Simple

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-prove-plugin-traceuse@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Torbjørn Lindahl  C<< <torbjorn.lindahl@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Torbjørn Lindahl C<< <torbjorn.lindahl@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
