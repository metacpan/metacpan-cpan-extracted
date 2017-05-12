use 5.006;
use strict;
use warnings;

package CPAN::Testers::Fact::TestSummary;
# ABSTRACT: summary of a CPAN Testers analysis of a distribution

our $VERSION = '1.999003';

use Carp ();

use Metabase::Fact::Hash 0.016;
our @ISA = qw/Metabase::Fact::Hash/;

sub required_keys { qw/grade osname osversion archname perl_version/ }

sub content_metadata {
    my ($self) = @_;
    my $content = $self->content;
    return {
        grade        => $content->{grade},
        osname       => $content->{osname},
        archname     => $content->{archname},
        perl_version => $content->{perl_version},
    };
}

sub content_metadata_types {
    return {
        grade        => '//str',
        osname       => '//str',
        archname     => '//str',
        perl_version => '//str',
    };
}

# should validate grades, etc. -- dagolden, 2009-03-30

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Testers::Fact::TestSummary - summary of a CPAN Testers analysis of a distribution

=head1 VERSION

version 1.999003

=head1 SYNOPSIS

  # assume $tr is an (upgraded) Test::Reporter object
  # that has the accessors below (it doesn't yet)
  
  my $fact = CPAN::Testers::Fact::TestSummary->new(
    resource => 'cpan:///distfile/RJBS/CPAN-Metabase-Fact-0.001.tar.gz',
    content     => {
      grade         => $tr->grade,
      osname        => $tr->osname,
      osversion     => $tr->osversion
      archname      => $tr->archname
      perl_version  => $tr->perl_version_number
    },
  );

=head1 DESCRIPTION

Summarize CPAN testers run -- this is equivalent to the content of the old
email Subject line, plus explicit OS name and perl version, which previously had
to be parsed out of the report

=head1 USAGE

See L<Metabase::Fact>.

Todo:
  # XXX document valid grades, etc. -- dagolden, 2009-03-30 

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
