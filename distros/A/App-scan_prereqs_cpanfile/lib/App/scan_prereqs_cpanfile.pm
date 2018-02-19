package App::scan_prereqs_cpanfile;
use strict;
use warnings;
use 5.008005;
our $VERSION = "1.10";

use Exporter 5.57 'import';
our @EXPORT_OK = qw(
    debugf find_perl_files scan_inner_packages scan scan_test_requires load_diff_src
);

use version ();
use CPAN::Meta ();
use CPAN::Meta::Requirements ();
use File::Find qw(find);
use Module::CoreList ();
use Module::CPANfile 0.9020 ();
use File::Spec ();
use File::Basename ();
use Module::Metadata ();
use Perl::PrereqScanner::Lite 0.21;

sub debugf {
    if ($ENV{SCAN_PREREQS_CPANFILE_DEBUG}) {
        require Data::Dumper;
        my $format = shift;
        no warnings 'once';
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;
        my $txt = sprintf($format, map { defined($_) ? Data::Dumper::Dumper($_) : '-' } @_);
        print $txt, "\n";
    }
}

sub scan {
    my ($files, $inner_packages, $meta_prereqs, $prereq_types, $type, $optional_prereqs) = @_;

    my $prereqs = scan_files(@$files);

    # Remove internal packages.
    remove_prereqs($prereqs, +{ map { $_ => 1 } @$inner_packages });

    # Remove from meta
    for my $type (@$prereq_types) {
        remove_prereqs($prereqs, $meta_prereqs->{$type}->{requires});
        remove_prereqs($prereqs, $meta_prereqs->{$type}->{recommends});
    }

    # Runtime prereqs.
    if ($optional_prereqs) {
        remove_prereqs($prereqs, $optional_prereqs);
    }

    # Remove core modules.
    my $perl_version = $meta_prereqs->{perl} || '5.008001';
    remove_prereqs($prereqs, blead_corelist($perl_version));

    return $prereqs;
}

sub scan_inner_packages {
    my @files = @_;
    my %uniq;
    my @list;
    for my $file (@files) {
        push @list, grep { !$uniq{$_}++ } Module::Metadata->new_from_file($file)->packages_inside();
    }
    return @list;
}

sub scan_files {
    my @files = @_;

    my $combined = CPAN::Meta::Requirements->new;
    for my $file (@files) {
        debugf("Reading %s", $file);

        my $scanner = Perl::PrereqScanner::Lite->new;
        $scanner->add_extra_scanner('Moose');
        my $prereqs = $scanner->scan_file($file);
        $combined->add_requirements($prereqs);
    }
    my $prereqs = $combined->as_string_hash;
}

sub blead_corelist {
    my $perl_version = shift;
    my %corelist = %{$Module::CoreList::version{$perl_version}};
    for my $module (keys %corelist) {
        my $upstream = $Module::CoreList::upstream{$module};
        if ($upstream && $upstream eq 'cpan') {
            delete $corelist{$module};
        }
    }
    return \%corelist;
}

sub remove_prereqs {
    my ($prereqs, $allowed) = @_;
    return unless $allowed;

    for my $module (keys %$allowed) {
        if (exists $allowed->{$module}) {
            if (parse_version($allowed->{$module}) >= parse_version($prereqs->{$module})) {
                debugf("Core: %s %s >= %s", $module, $allowed->{$module}, $prereqs->{$module});
                delete $prereqs->{$module}
            }
        }
    }
}

sub parse_version {
    my $v = shift;
    return version->parse(0) unless defined $v;
    return version->parse(''.$v);
}

sub load_diff_src {
    my $src = shift;
    if (File::Basename::basename($src) eq 'cpanfile') {
        return Module::CPANfile->load($src)->prereq_specs;
    } elsif ($src =~ /\.(yml|json)$/) {
        my $meta = CPAN::Meta->load_file($src);
        my $meta_prereqs = CPAN::Meta::Prereqs->new($meta->prereqs)->as_string_hash;
        return $meta_prereqs;
    } else {
        die "No META.json and cpanfile\n";
    }
}

sub read_from_file {
    my ($fname, $length) = @_;
    return q{} if !-f $fname;
    open my $fh, '<', $fname
        or Carp::croak("Can't open '$fname' for reading: '$!'");
    my $buf;
    read $fh, $buf, $length;
    return $buf;
}

sub find_perl_files {
    my ($dir, %opts) = @_;
    my $ignore = $opts{ignore} || [];
    my $ignore_regexp = $opts{ignore_regexp};

    my (@runtime_files, @test_files, @configure_files, @develop_files);
    find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if $_ eq '.';
                return if -S $_; # Ignore UNIX socket

                # Ignore files.
                my (undef, $topdir, ) = File::Spec->splitdir($_);
                my $basename = File::Basename::basename($_);
                return if $basename eq 'Build';
                return if defined($ignore_regexp) && $_ =~ m/$ignore_regexp/;

                # Ignore build dir like Dist-Name-0.01/.
                return if -f "$topdir/META.json";

                for my $ignored (@$ignore) {
                    return if $topdir eq $ignored;
                }

                if ($basename eq 'Build.PL' || $basename eq 'Makefile.PL') {
                    push @configure_files, $_
                } elsif ($topdir eq 't') {
                    if (/\.(pl|pm|psgi|t)$/) {
                        if ($basename =~ /^(?:author|release)-/) {
                            # dzil creates author test files to t/author-XXX.t
                            push @develop_files, $_
                        } else {
                            push @test_files, $_
                        }
                    }
                } elsif ($topdir eq 'xt' || $topdir eq 'author' || $topdir eq 'benchmark') {
                    if (/\.(pl|pm|psgi|t)$/) {
                        push @develop_files, $_
                    }
                } else {
                    if (/\.(pl|pm|psgi)$/) {
                        push @runtime_files, $_
                    } else {
                        my $header = read_from_file($_, 1024);
                        if ($header && $header =~ /^#!.*perl/) {
                            # Skip fatpacked file.
                            if ($header =~ /This chunk of stuff was generated by App::FatPacker./) {
                                debugf("fatpacked %s", $_);
                                return;
                            }

                            push @runtime_files, $_
                        }
                    }
                }
            }
        },
        $dir
    );
    return (\@runtime_files, \@test_files, \@configure_files, \@develop_files);
}

sub scan_test_requires {
    my ($dir, $develop_prereqs) = @_;

    require Test::Requires::Scanner;

    my @test_files;
    find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if $_ eq '.';
                return if -S $_; # Ignore UNIX socket

                my (undef, $topdir, ) = File::Spec->splitdir($_);
                if (($topdir eq 'xt' || $topdir eq 't') && /\.(?:t|pm)$/ ) {
                    push @test_files, $_
                }
            },
        },
        $dir
    );
    my $test_requires_prereqs = Test::Requires::Scanner->scan_files(@test_files);

    for my $module (keys %$test_requires_prereqs) {
        my $version = $test_requires_prereqs->{$module};

        if (! exists $develop_prereqs->{$module} ||
            parse_version($version) > parse_version($develop_prereqs->{$module})
        ) {
            $develop_prereqs->{$module} = $version || 0;
        }
    }

    return $develop_prereqs;
}


1;
__END__

=head1 NAME

App::scan_prereqs_cpanfile - Scan prerequisite modules and generate CPANfile

=head1 DESCRIPTION

Please look L<scan-prereqs-cpanfile>.

=head1 LICENSE

Copyright (C) tokuhirom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

