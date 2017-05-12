use 5.006;
use strict;
use warnings;

package CPAN::Testers::Fact::InstalledModules;
# ABSTRACT: Versions of particular modules installed on a system

our $VERSION = '1.999003';

use Carp ();

use Metabase::Fact::Hash 0.016;
our @ISA = qw/Metabase::Fact::Hash/;

sub optional_keys { qw/prereqs toolchain undeclared/ }

sub validate_content {
    my ($self) = @_;
    $self->SUPER::validate_content;
    my $content = $self->content;
    for my $key ( keys %$content ) {
        Carp::croak "key '$key' must be a hashref" unless ref $content->{$key} eq 'HASH';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Testers::Fact::InstalledModules - Versions of particular modules installed on a system

=head1 VERSION

version 1.999003

=head1 SYNOPSIS

  my $fact = CPAN::Testers::Fact::InstalledModules->new({
    resource => 'cpan:///distfile/RJBS/CPAN-Metabase-Fact-0.001.tar.gz',
    content     => {
      prereqs => {
        'Test::More' => '0.80',
      },
      toolchain => {
        'CPAN' => '1.92', 
      },
    },
  });

=head1 DESCRIPTION

Versions detected of modules installed on a system.  There are three valid
types: prereqs, toolchain, undeclared.  

Prereqs are the versions of modules listed in any of the prerequisite fields.  

Toolchain module versions are intended to reflect the state of the toolchain
used to test the distribution (e.g.  CPAN, Test::Harness, etc.).  

Undeclared module versions capture the version of modules that were detected
as being used by the distribution, but that were not listed explicitly as 
prerequisites.  This will often be core modules or submodules, but could 
include missing dependencies.

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
