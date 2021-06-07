package App::PDRUtils::DistIniCmd::_modify_prereq_version;

our $DATE = '2021-05-25'; # DATE
our $VERSION = '0.122'; # VERSION

use 5.010001;
use strict;
use warnings;

use Version::Util qw(version_eq version_gt version_lt
                     add_version subtract_version);

sub _modify_prereq_version {
    require Config::IOD;
    require File::Slurper;

    my $which = shift;
    my %args = @_;

    my $iod = $args{parsed_dist_ini};
    my $mod = $args{module};

    my $found;
    my $modified;
    my ($old_v, $new_v);

  SECTION:
    for my $section ($iod->list_sections) {
        next unless $section =~ m!\APrereqs(?:\s*/\s*\w+)?\z!;
        for my $param ($iod->list_keys($section)) {
            next unless $param eq $mod;
            $old_v = $iod->get_value($section, $param);
            return [412, "Prereq '$mod' is specified multiple times"]
                if ref($old_v) eq 'ARRAY';
            $found++;
            if ($which eq 'set_to') {
                $new_v = $args{module_version};
                if (version_eq($old_v, $new_v)) {
                    return [304, "Version of '$mod' already the same ($old_v)"];
                }
                $iod->set_value({all=>1}, $section, $param, $new_v);
                $modified++;
            } elsif ($which eq 'inc_to') {
                $new_v = $args{module_version};
                unless (version_gt($new_v, $old_v)) {
                    return [304, "Version of '$mod' ($old_v) already >= $new_v"];
                }
                $iod->set_value({all=>1}, $section, $param, $new_v);
                $modified++;
            } elsif ($which eq 'dec_to') {
                $new_v = $args{module_version};
                unless (version_lt($new_v, $old_v)) {
                    return [304, "Version of '$mod' ($old_v) already <= $new_v"];
                }
                $iod->set_value({all=>1}, $section, $param, $new_v);
                $modified++;
            } elsif ($which eq 'inc_by') {
                eval { $new_v = add_version($old_v, $args{by}) };
                return [500, "Can't add version ($old_v + $args{by}): $@"] if $@;
                if (version_eq($new_v, $old_v)) {
                    return [304, "Version of '$mod' ($old_v) already = $new_v"];
                }
                $iod->set_value({all=>1}, $section, $param, $new_v);
                $modified++;
            } elsif ($which eq 'dec_by') {
                eval { $new_v = subtract_version($old_v, $args{by}) };
                return [500, "Can't subtract version ($old_v - $args{by}): $@"] if $@;
                if (version_eq($new_v, $old_v)) {
                    return [304, "Version of '$mod' ($old_v) already = $new_v"];
                }
                $iod->set_value({all=>1}, $section, $param, $new_v);
                $modified++;
            } else {
                return [500, "BUG: Unknown which '$which'"];
            }
        }
    }

    if ($found) {
        if ($modified) {
            return [200, "Set prereq '$mod' version from $old_v to $new_v", $iod];
        } else {
            return [304, "Not modified"];
        }
    } else {
        return [304, "No prereq to '$mod' specified"];
    }
}

1;
# ABSTRACT: Common routines for set_prereq_version_to, {inc,dec}_prereq_version_{to,by}

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PDRUtils::DistIniCmd::_modify_prereq_version - Common routines for set_prereq_version_to, {inc,dec}_prereq_version_{to,by}

=head1 VERSION

This document describes version 0.122 of App::PDRUtils::DistIniCmd::_modify_prereq_version (from Perl distribution App-PDRUtils), released on 2021-05-25.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PDRUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PDRUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PDRUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
