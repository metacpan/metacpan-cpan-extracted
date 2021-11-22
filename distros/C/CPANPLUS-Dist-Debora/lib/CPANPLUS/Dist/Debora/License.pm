package CPANPLUS::Dist::Debora::License;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = '0.005';

use parent qw(Software::License);

use File::Spec::Functions qw(catfile);
use Scalar::Util qw(weaken);
use Text::Wrap qw();

use CPANPLUS::Dist::Debora::Util qw(slurp_utf8);

# Common modules whose license might not be guessed.
my %LICENSE_NAME_FOR = (
    'Coro' => '(Artistic-1.0-Perl OR GPL-1.0-or-later) '
        . 'AND (BSD-2-Clause OR GPL-2.0-or-later)',
    'Crypt-Blowfish' => 'BSD-4-Clause',
    'Data-Hexdumper' => 'Artistic-1.0-Perl OR GPL-2.0-or-later',
    'EV'             => '(Artistic-1.0-Perl OR GPL-1.0-or-later) '
        . 'AND (BSD-2-Clause OR GPL-2.0-or-later)',
    'Exporter-Tidy' => 'SUSE-Permissive '
        . 'OR GPL-2.0-or-later OR LGPL-2.1-or-later OR MPL-2.0',
    'FCGI'           => 'BSD-2-Clause',
    'Net-Patricia'   => 'GPL-2.0-or-later AND BSD-2-Clause',
    'Time-ParseDate' => 'SUSE-Permissive',
);

sub new {
    my ($class, $attrs) = @_;

    my $package = $attrs->{package};
    delete $attrs->{package};

    my $self = $class->SUPER::new($attrs);

    $self->{package} = $package;
    weaken $self->{package};

    return $self;
}

sub name {
    my $self = shift;

    return 'Unknown license';
}

sub url {
    my $self = shift;

    return;
}

sub meta_name {
    my $self = shift;

    return 'restrictive';
}

sub meta2_name {
    my $self = shift;

    return 'restricted';
}

sub spdx_expression {
    my $self = shift;

    my $package   = $self->{package};
    my $dist_name = $package->dist_name;

    return $LICENSE_NAME_FOR{$dist_name} // 'Unknown';
}

sub license {
    my $self = shift;

    my $package  = $self->{package};
    my $builddir = $package->builddir;

    my $text = q{};

    # Read the license files.
    my @license_files = @{$package->files_by_type('license')};
    for my $filename (@license_files) {
        my $buf = eval { slurp_utf8(catfile($builddir, $filename)) };
        if ($buf) {
            $buf =~ s{\A \v+}{}xms;    # Remove leading newlines.
            $buf =~ s{\v+ \z}{}xms;    # Remove trailing newlines.

            if ($text) {
                $text .= "\n\n";
            }

            if (@license_files > 1) {
                $text .= "-- $filename file --\n\n";
            }

            $text .= $buf;
        }
    }

    # Is there a LICENSE section in the Pod document?
    if (!$text) {
        my $pod = $package->_pod;
        if ($pod) {
            my $section = $pod->section(q{1}, qr{LICEN[CS]E}xmsi);
            if ($section) {
                ## no critic (Variables::ProhibitPackageVars)
                # Remove headings.
                $section =~ s{^ =head\d \h (\V+) \v+}{}xmsg;
                local $Text::Wrap::unexpand = 0;
                $text = Text::Wrap::wrap(q{}, q{}, $section);
            }
        }
    }

    return $text;
}

1;

## no critic (Documentation::RequirePodAtEnd)

=pod

=encoding UTF-8

=head1 NAME

CPANPLUS::Dist::Debora::License - Read license files

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use CPANPLUS::Dist::Debora::License;

  my $license = CPANPLUS::Dist::Debora::License->new({
      package => $package,
      holder  => $holder,
      year    => $year,
  });

  print $license->license;

=head1 DESCRIPTION

This Software::License subclass reads license texts from files and Pod
documents.

=head1 SUBROUTINES/METHODS

=head2 new

  my $license = CPANPLUS::Dist::Debora::License->new({
      package => $package,
      holder  => $holder,
  });

Creates a new object.  The CPANPLUS::Dist::Debora::Package object parameter
and the copyright holder are mandatory.

=head2 name

Returns "Unknown license".

=head2 url

Returns the undefined value.

=head2 meta_name

Returns "restrictive".

=head2 meta2_name

Returns "restricted".

=head2 spdx_expression

Returns a short license name or "Unknown".

=head2 license

Returns the license text or the empty string.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

Requires the module Software::License from CPAN.

=head1 INCOMPATIBILITIES

None.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

None known.

=head1 LICENSE AND COPYRIGHT

Copyright 2021 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__DATA__
__NOTICE__
Copyright {{$self->year}} {{$self->_dotless_holder}}
