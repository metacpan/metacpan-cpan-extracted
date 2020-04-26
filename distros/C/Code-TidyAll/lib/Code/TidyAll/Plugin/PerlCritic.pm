package Code::TidyAll::Plugin::PerlCritic;

use strict;
use warnings;

use Moo;

extends 'Code::TidyAll::Plugin';

with 'Code::TidyAll::Role::RunsCommand';

our $VERSION = '0.78';

# On Windows only the batch file is actually executable.
my $cmd = $^O eq 'MSWin32' ? 'perlcritic.bat' : 'perlcritic';
sub _build_cmd {$cmd}

sub validate_file {
    my ( $self, $file ) = @_;

    my $output = $self->_run_or_die($file);
    die "$output\n" unless $output =~ /^.* source OK\n/s;

    return;
}

1;

# ABSTRACT: Use perlcritic with tidyall

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::PerlCritic - Use perlcritic with tidyall

=head1 VERSION

version 0.78

=head1 SYNOPSIS

   In configuration:

   ; Configure in-line
   ;
   [PerlCritic]
   select = lib/**/*.pm
   argv = --severity 5 --exclude=nowarnings

   ; or refer to a .perlcriticrc in the same directory
   ;
   [PerlCritic]
   select = lib/**/*.pm
   argv = --profile $ROOT/.perlcriticrc

=head1 DESCRIPTION

Runs L<perlcritic>, a Perl validator, and dies if any problems were found.

=head1 INSTALLATION

Install perlcritic from CPAN.

    cpanm perlcritic

=head1 CONFIGURATION

This plugin accepts the following configuration options:

=head2 argv

Arguments to pass to C<perlcritic>.

=head1 SUPPORT

Bugs may be submitted at
L<https://github.com/houseabsolute/perl-code-tidyall/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Code-TidyAll can be found at
L<https://github.com/houseabsolute/perl-code-tidyall>.

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2020 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut
