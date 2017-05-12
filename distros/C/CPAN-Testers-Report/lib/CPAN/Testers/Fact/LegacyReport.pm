use 5.006;
use strict;
use warnings;

package CPAN::Testers::Fact::LegacyReport;
# ABSTRACT: an email-style report for CPAN Testers

our $VERSION = '1.999003';

use Carp ();

use Metabase::Fact::Hash 0.016;
our @ISA = qw/Metabase::Fact::Hash/;

sub required_keys { qw/grade osname osversion archname perl_version textreport/ }

sub content_metadata {
    my ($self) = @_;
    my $content = $self->content;
    return {
        grade        => $content->{grade},
        osname       => $content->{osname},
        osversion    => $content->{osversion},
        archname     => $content->{archname},
        perl_version => $content->{perl_version},
    };
}

sub content_metadata_types {
    return {
        grade        => '//str',
        osname       => '//str',
        osversion    => '//str',
        archname     => '//str',
        perl_version => '//str',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Testers::Fact::LegacyReport - an email-style report for CPAN Testers

=head1 VERSION

version 1.999003

=head1 SYNOPSIS

  # assume $tr is an (upgraded) Test::Reporter object
  # that has the accessors below (it doesn't yet)
  
  my $fact = CPAN::Testers::Fact::LegacyReport->new({
    resource => 'cpan:///distfile/RJBS/CPAN-Metabase-Fact-0.001.tar.gz',
    content     => {
      grade         => $tr->grade,
      osname        => $tr->osname,
      osversion     => $tr->osversion
      archname      => $tr->archname
      perl_version  => $tr->perl_version_number
      textreport    => $tr->report
    },
  });

=head1 DESCRIPTION

Wraps up old-style CPAN Testers report

=head1 USAGE

See L<Metabase::Fact>.

=for Pod::Coverage required_keys

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=CPAN-Testers-Report>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
