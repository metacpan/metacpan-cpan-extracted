package Acme::Working::Out::Dependencies::From::META::files::Will::Be::Wrong::At::Some::Point::Like::This::Module::For::Instance;
BEGIN {
  $Acme::Working::Out::Dependencies::From::META::files::Will::Be::Wrong::At::Some::Point::Like::This::Module::For::Instance::VERSION = '9.99';
}

#ABSTRACT: Because there is nothing like being right

use strict;
use warnings;

qq[There must be a point];


__END__
=pod

=head1 NAME

Acme::Working::Out::Dependencies::From::META::files::Will::Be::Wrong::At::Some::Point::Like::This::Module::For::Instance - Because there is nothing like being right

=head1 VERSION

version 9.99

=head1 DESCRIPTION

Using the C<META.yml> or C<META.json> to work out the prereqs for a distribution without being aware that
authors can do what they want in C<Makefile.PL> or C<Build.PL> and what it says in the two C<META> files could
very well not be what is required once C<Makefile.PL> or C<Build.PL> has been run, is potentially flawed.

This distribution hammers home this point by not specifying any prereqs at all in C<META.yml> and C<META.json>
and autogenerates a list of prereqs when C<Makefile.PL> is executed.

So what exactly are the prereqs of this module ?

The CPAN META specification L<CPAN::Meta::Spec> states that C<dynamic_config> I<"should be set to a true value
if the distribution performs some dynamic configuration (asking questions, sensing the environment, etc.) as part
of its configuration.">. Almost all of the tools ( L<Module::Build> is the exception ) do not provide a way to
change this from the default which is C<0>.

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

