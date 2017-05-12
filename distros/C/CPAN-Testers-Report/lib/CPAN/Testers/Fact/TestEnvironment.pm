use 5.006;
use strict;
use warnings;

package CPAN::Testers::Fact::TestEnvironment;
# ABSTRACT: Environment vars and other local context during a CPAN Testers report

our $VERSION = '1.999003';

use Carp ();

use Metabase::Fact::Hash 0.016;
our @ISA = qw/Metabase::Fact::Hash/;

# special_vars: $^X, UID/EID, GID/EGID, win32 stuff from CPAN::Reporter
# -- dagolden, 2009-03-30
sub optional_keys { qw/environment_vars special_vars/ }

sub validate_content {
    my ($self) = @_;
    $self->SUPER::validate_content;
    my $content = $self->content;
    for my $key ( keys %$content ) {
        Carp::croak "key '$key' must be a hashref" unless ref $content->{$key} eq 'HASH';
    }
}

# XXX do we want content_metadata? -- dagolden, 2009-03-30

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Testers::Fact::TestEnvironment - Environment vars and other local context during a CPAN Testers report

=head1 VERSION

version 1.999003

=head1 SYNOPSIS

  my $fact = CPAN::Testers::Fact::TestEnvironment->new(
    resource => 'cpan:///distfile/RJBS/CPAN-Metabase-Fact-0.001.tar.gz',
    content     => {
      environment_vars => {
        PERL5LIB  => $ENV{PERL5LIB},
        TEMP      => $ENV{TEMP},
      },
      special_vars => {
        'EXECUTABLE_NAME' => $^X,
        'UID'             => $<,
      },
    },
  );

=head1 DESCRIPTION

Describes aspects of the environment during a CPAN Testers run.

=head1 USAGE

See L<Metabase::Fact>.

=for Pod::Coverage optional_keys

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
